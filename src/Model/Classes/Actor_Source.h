#pragma once
#include "Actor.h"
#include "Actor_Tank.h"
#include "../Math/Math.h"

class source: public actor{};

class catchment: public source{
  private:
  actor *SinkTank;

  public:
  double A;
  double eta_rain;
  int8_T DataColumn = 2;

  catchment(std::string iName, int8_T iDataColumn, double iA, actor *iSinkTank, double ieta_rain, double ic) : SinkTank(iSinkTank) {
    Name = iName;
    A = iA;
    DataColumn = iDataColumn;
    eta_rain = ieta_rain;
    c= ic;
    ClassType = "catchment";
  };

  void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    // cannot return flow except for precipitation
  }

  void RequestVolume(double Q_in, double c_in, double Q_out) override{
     // cannot return volume except for precipitation
  }

  double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    return 0; // cannot return flow except for precipitation
  };

  double EvaluateVolume(double Flow) override{
    return 0;
  };

  void StepReset() override{
    Q_used = 0;
  };
  void Update(double Q_in, double c_in, double Q_out) override{
    //do nothing
  };

  void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd) override{
    // do nothing
  };

  void Rain(double precipitation){
    double Q_rain = precipitation/1000.*A*eta_rain;
    (*SinkTank).Update(Q_rain,c,0.);
    Q_used += Q_rain;
  };

};

class tap: public source{
 public:

  tap(std::string iName, double ic){Name = iName; c = ic; ClassType = "tap";  Q_design = 1.7976e308;}

  tap(){ClassType = "tap"; Q_design = 1.7976e308;}

  void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    Q_pending += Flow; // Sources have no limit, energy = tap pressure
    // RequestFlow is only for those performing the flow. If a source performs the flow, only sink needs to be checked.
    if(UseEMSInd.size()>0){
      (*Sink).RequestVolume(Flow,c,0.);
    }
  }

  void RequestVolume(double Q_in, double c_in, double Q_out) override{
    //if((Flow-0.)<eps){
    if(Q_out>0.){
      V_pending_out += Q_out; // Sinks have no limit, energy = provided by sink. E.g., sewer/infil = gravity, truck = truck pump
    }else if(Q_in>0.){
      V_pending_in += Q_in;
    } // if flow is positive (source used as sink)
  }

  double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    if(UseEMSInd.size()>0){
      return (*Sink).EvaluateVolume(Flow);
    } else {
      return 1.;
    }
  };

  double EvaluateVolume(double Flow) override{
    //if ((V_pending_in-0.)>eps || (Flow-0.)>eps){
    if(V_pending_in>eps || Flow>0.){
      return 0.; // Source used as sink
    } else {
      return 1.; // Source is endless
    }
  };

  void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd) override{
    (*Sink).Update(Flow,c+c_added,0.);
    Q_used += Flow;
  };

  void Update(double Q_in, double c_in, double Q_out) override{};

  void StepReset() override {Q_used=0;};
};
