#pragma once
#include "../Math/Math.h"

class battery {
  public:
  double C_battery;
  std::string Name;

  battery(std::string iName, double iC_battery_max, double iC_init, double ieta_battery){
    Name = iName;
    eta_battery = ieta_battery;
    C_battery_max = iC_battery_max;
    C_battery = std::max(0.,std::min(iC_battery_max,iC_init));
  }

  battery(){
    Name = "default";
    eta_battery = 0.9;
    C_battery_max = 2.7;
    C_battery = 2.7;
  }

  void Charge(double E){
    //if (fabs(C_battery - 0.)<eps){
    if(C_battery_max ==0. || eta_battery == 0.){
      C_battery = 0.;
    } else if(E>0.) {
      C_battery += E*eta_battery;
    } else {
      C_battery += E/eta_battery;
    }
    C_battery = std::min(C_battery, C_battery_max);
  }

  double Available(){
      return eta_battery*C_battery;
  }

  double ChargingPossible(){
      return (C_battery_max-C_battery)/eta_battery;
  }
  
  private:
  double eta_battery;
  double C_battery_max;
};

class energy { // Energy management system
  public:
  double Input;
  double E_pending;
  std::vector<battery> Batteries;
  double Usage_Unattributable; // should be zero if two EMS configured
  double Usage;
  std::string Name;
  bool Active = false;

  energy(std::string iName, std::vector<battery> iBatteries) : Batteries(iBatteries){
    Name = iName;
    Input = 0.;
    Usage_Unattributable = 0.;
    Usage = 0.;
  };

  double BatteryAvailable(){
    double batcap = 0.;
    for (battery bat:Batteries){
      batcap += bat.Available();
    }
    return batcap;
  }

  void BatteryCharge(double E){
    if(E>0.) {
      double E_battery = 0.;
      for (size_t k = 0; k < Batteries.size(); k++){
        E_battery = std::min(E,Batteries[k].ChargingPossible());
        Batteries[k].Charge(E_battery);
        E -= E_battery;
      }
    } else {
      double E_battery = 0.;
      for (size_t k = 0; k < Batteries.size(); k++){
        E_battery = std::min(-E,Batteries[k].Available());
        Batteries[k].Charge(-E_battery);
        E += E_battery;
      }
    }
  }

  double Available(){
    return BatteryAvailable()+Input;
  }

  void Use(double E){
    double E_max;
    // check against direct input
    E_max = std::min(E,Input);
    Input -= E_max;
    Usage += E_max;
    E -= E_max;
          
    // check against battery charge
    if(E>0.){
    E_max = std::min(E,BatteryAvailable());
    BatteryCharge(-E_max);
    Usage += E_max;
    E -= E_max;
    }
    
    // Whatever left is grid, should normally be zero
    Usage_Unattributable += E;
  }

  void RequestEnergy(double E){
    E_pending += E;
  }

  double EvaluateEnergy(){
    if(E_pending>eps){
      if(Active){
        return std::min(1.,(Available()/E_pending));
      } else {
        return 0.;
      }
    } else {
      return 1.;
    }
  }

  void clear(){
    E_pending = 0.;
  }

  void StepReset(){
    Usage = 0.;
    BatteryCharge(Input);
    Active = false;
    Input = 0.;
    E_pending = 0.;
  }

};

class generator{
  public:
  std::string Name;
  int8_T DataColumn = 1;
  std::string ClassType;

  virtual void Generate(double DataInput) = 0;
};

class misc_generator :  public generator{
  public:
  energy *EMS;
  double Multiplier;

  misc_generator(std::string iName, double iMultiplier, energy *iEMS, int8_T iDataColumn) : EMS(iEMS){
    ClassType = "misc_generator";
    Name = iName;
    DataColumn = iDataColumn;
    Multiplier = iMultiplier;
  };

  void Generate(double DataInput) override{
      (*EMS).Input += Multiplier*DataInput;
  };
};

class pv_installation : public generator{
  public:
  double kWp_panels;
  double eta_heat;
  double eta_inverter;
  energy *EMS;

  pv_installation(std::string iName, energy *iEMS, int8_T iDataColumn, double ikWp_panels, double ieta_heat, double ieta_inverter) : EMS(iEMS){
    ClassType = "pv_installation";
    Name = iName;
    DataColumn = iDataColumn;
    kWp_panels = ikWp_panels;
    eta_heat = ieta_heat;
    eta_inverter = ieta_inverter;
  };

  void Generate(double DataInput) override{
      (*EMS).Input += DataInput*kWp_panels*eta_heat*eta_inverter;
  };
};