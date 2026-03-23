#pragma once
#include "Actor.h"
#include <chrono>

class step{
  public:
  actor *Actor;
  private:
  actor *Source;
  actor *Sink;
  actor *Waste;
  public:
  double Fraction;
  double Q_used = 0.;
  std::string Name;
  double epscontrol = 1e-9;
  double StepFlow = 0.;

  step(std::string iName, double iFraction, actor *iActor, actor *iSource, actor *iSink, actor *iWaste) : Actor(iActor), Source(iSource), Sink(iSink), Waste(iWaste){
    Fraction = iFraction;
    Name = iName;
  }

  void SubmitRequests(double &Flow,std::vector<int8_T> EMSOn){
    if(Flow<epscontrol){
      return;
    }
    StepFlow = Flow*Fraction;
    (*Actor).RequestFlow(Flow,Source,Sink,Waste,EMSOn);
  };

  double EvaluateRequests(std::vector<int8_T> EMSOn){
    if(StepFlow<epscontrol){
      return 0.;
    }
    return (*Actor).EvaluateFlow(StepFlow,Source,Sink,Waste,EMSOn);
  };

  void clear(){
    (*Actor).clear();
    (*Source).clear();
    (*Sink).clear();
    (*Waste).clear();
  };

  void Execute(std::vector<int8_T> EMSOn){
    if(StepFlow<epscontrol){
      return;
    }

    if((*Source).ClassType == "treatment"){
      StepFlow = std::min(StepFlow,std::max(0.,(*Source).V)); // for if actor is used as source
    }
    (*Actor).Use(StepFlow,Source,Sink,Waste,0.,EMSOn);
    Q_used += StepFlow;
  }

  void StepReset(){
    Q_used = 0;
  }
};

class EMScontrol {
public:
    std::string Name;
    int8_T Ind;
    double Limit_High;
    double Limit_Low;
    bool On = false;
    EMScontrol(std::string iName, int8_T iInd, double iLimit_High, double iLimit_Low) {
        Name = iName;
        Ind = iInd;
        Limit_High = iLimit_High;
        Limit_Low = iLimit_Low;
        On = false;

    };
};

class control {
  public:
  std::string Name;
  
  double target = 0.;
  int direction; // type of flow: fill/increase = 1 or empty/lower = 0
  int type; // Full = 1, Hysteresis = 0
  std::string Parameter; // c or V
  double FlowOn;

  double epscontrol = 1e-9;

  actor *ControlledTank;
  std::vector<step> Steps; // steps to execute in order
  std::vector<EMScontrol> EMSControl;
  std::vector<energy*> EMS;
  std::vector<int8_T> EMSOn;

  control(std::string iName, std::vector<EMScontrol> iEMSControl, std::vector<energy*> iEMS, std::vector<step> iSteps, int iDirection, int iType, actor *iControlledTank, std::string iParameter, double iFlowOn) : ControlledTank(iControlledTank), Steps(iSteps), EMSControl(iEMSControl) {
    Name = iName;
    direction = iDirection;
    type = iType;
    Parameter = iParameter;
    FlowOn = iFlowOn;
    EMSControl = iEMSControl;
    EMS = iEMS;
    //min_grid = imin_grid;
    //max_grid = imax_grid;
    //min_rene = imin_rene;
    //max_rene = imax_rene;
  }

  double ControlValue(){
    double ControlParameter = 0;
    if(Parameter == "c"){
      ControlParameter = (*ControlledTank).c;
    }else if(Parameter == "V"){
      ControlParameter = (*ControlledTank).V;
    }
        
    if (UseEMS(ControlParameter)){
      if(Parameter=="V"){ // on volume
        if(type){ // full
          if(direction){ // fill
            return target-(*ControlledTank).V;
          } else { // empty
            return (*ControlledTank).V-target;
          }
        } else { // hyst
          if(direction){ // fill
            return std::min(target-(*ControlledTank).V,FlowOn);
          } else { // empty
            return std::min((*ControlledTank).V-target,FlowOn);
          }
        }
      } else { // on concentration
        return FlowOn; // limit later through overshoot     
      }
    } else {
      return 0.;
    }
  };

  bool UseEMS(double &ControlParameter){
    EMSOn.clear();

    if(direction){
      target = 0.;
      for (size_t i = 0; i < EMSControl.size(); i++){
        if(ControlParameter<=EMSControl[i].Limit_Low){
            EMSControl[i].On = true;
        }
        if(ControlParameter>=EMSControl[i].Limit_High){
            EMSControl[i].On = false;
        }

        if(EMSControl[i].On){
          (*EMS[EMSControl[i].Ind]).Active = true;
          EMSOn.push_back(EMSControl[i].Ind);
          target = std::max(target,EMSControl[i].Limit_High);
        } else {
          (*EMS[EMSControl[i].Ind]).Active = false;
        }
      }
    } else {
      target=1e308;
      for (size_t i = 0; i < EMSControl.size(); i++){
        if(ControlParameter<=EMSControl[i].Limit_Low){
            EMSControl[i].On = false;
        }
        if(ControlParameter>=EMSControl[i].Limit_High){
            EMSControl[i].On = true;
        }
        if(EMSControl[i].On){
          (*EMS[EMSControl[i].Ind]).Active = true;
          EMSOn.push_back(EMSControl[i].Ind);
          target = std::min(target,EMSControl[i].Limit_Low);
        } else {
          (*EMS[EMSControl[i].Ind]).Active = false;
        }
    }
  }
    return EMSOn.size()>0;
  };

  void Execute(){
    double Flow = fabs(ControlValue());

    if(Flow<epscontrol){
      return;
    }

    // Submit requests
    for (size_t k = 0; k < Steps.size(); k++){
      Steps[k].SubmitRequests(Flow,EMSOn);
    }

    // Evaluate requests
    double FeasibleFrac = 1.;
    for (size_t k = 0; k < Steps.size(); k++){
      FeasibleFrac = std::min(FeasibleFrac, Steps[k].EvaluateRequests(EMSOn));  // Reduction applies globally
    }

    for (size_t k = 0; k < Steps.size(); k++){
        Steps[k].StepFlow = Steps[k].StepFlow*FeasibleFrac;
    }

    // Evaluate overshoot for conc
    if(Parameter=="c"){
      
      double c_pending = (*ControlledTank).m_pending/((*ControlledTank).V+(*ControlledTank).V_pending_in-(*ControlledTank).V_pending_out);
      double Overshoot = std::max(0.,std::min(1.,((*ControlledTank).c-target)/((*ControlledTank).c-c_pending))); // direction doesn't matter

      for (size_t k = 0; k < Steps.size(); k++){
          Steps[k].StepFlow = Steps[k].StepFlow*Overshoot*1.001; // just a smidge overshoot to turn control off
      }
    }

    // Execute steps
    for (size_t k = 0; k < Steps.size(); k++)
    {
      Steps[k].Execute(EMSOn);
    }

    // Clear steps
    for (size_t k = 0; k < Steps.size(); k++){
      Steps[k].clear(); 
    }
      
  };

  void StepReset(){
    for (size_t k = 0; k < Steps.size(); k++){
      Steps[k].StepReset();
    }
  }
};

