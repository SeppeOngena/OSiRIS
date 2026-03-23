#pragma once
#include "Actor.h"
#include "../Math/Math.h"

class tank: public actor {
  public:
  double R;

  tank(std::string iName, double V_maximum, double V_init_set, double c_init_set, double removal_sedimentation){
    ClassType = "tank";
    Name = iName;
    V_max = V_maximum;
    V_init = V_init_set;
    m_init = c_init_set*V_init_set;
    V = V_init;
    c = c_init_set;
    m = m_init;
    if(V_max>0.){
        R = removal_sedimentation;
    } else {
      R = 0.;
    }
    
  };

  tank(){
    V_max = 1.;
    V_init = 0.;
    m_init = 0.;
    V = 0.;
    c = 0.;
    R = 0.;
    m = 0;
    ClassType = "tank";
  };

  void Set(std::string iName, double V_maximum, double V_init_set, double c_init_set, double removal_sedimentation){
    ClassType = "tank";
    Name = iName;
    V_max = V_maximum;
    V_init = V_init_set;
    m_init = c_init_set*V_init_set;
    V = V_init;
    c = c_init_set;
    m = m_init;
    if(V_max>0.){
        R = removal_sedimentation;
    } else {
      R = 0.;
    }
    
  };

  void Update(double Q_in, double c_in, double Q_out) override{
    m_sediment += R*c_in*Q_in;

    // first in
    if(Q_in>0.){
    m += (1.-R)*c_in*Q_in;
    V += Q_in;
    }

    // then out
    //if((V-0.)>eps){
    if(Q_out>0. && V>eps){
    m -= Q_out*m/V;
    V -= Q_out;
    }
    
    //if((V-0.)>eps){
    if(V>eps){
      c = m/V;
    } else {
      c = 0.;
    }

   
    if((Q_incoming+Q_in)>0.){
    //if(Q_incoming+Q_in >0.){
      c_incoming = (Q_incoming*c_incoming+Q_in*c_in)/(Q_incoming+Q_in);
      Q_incoming += Q_in;
    }
    
  }

  void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    // Tanks cannot act to provide flows, only when they're sinks
  }

  void RequestVolume(double Q_in, double c_in, double Q_out) override{
    //if((Flow-0.)<eps){
    //if(Flow<0.){ 
    //  V_pending_out += -Flow;
    //} else {
    //  V_pending_in += Flow;
    //}

     // first in
    if(Q_in>0.){
    m_pending += (1.-R)*c_in*Q_in;
    V_pending_in += Q_in;
    }

    // then out
    //if((V-0.)>eps){
    if(Q_out>0.){
    V_pending_out += Q_out;
      if((V+V_pending_in-V_pending_out)>eps)
        m_pending -= Q_out*m_pending/(V+V_pending_in-V_pending_out);
      else{
        m_pending = 0.;
      }
    }
  }

  double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    return 0; // Tanks cannot act to provide flows, only when they're sinks
  };

  double EvaluateVolume(double Flow) override{
    double dV = V_pending_in-V_pending_out;
    //if ((dV-0.)<eps){
    if(dV<-eps){
      return std::min(V/(-dV),1.); // ratio of volume left vs outflow requested
    } else if(dV > eps) {
      return std::min((V_max-V)/dV,1.); // ratio of capacity left vs inflow requested
    } else {
      return 1.;
    }
  };

  void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd) override{
    // Tanks cannot act to provide flows, only when they're sinks
  };

  void StepReset() override{
    Q_incoming = c_incoming =  0.;
    m_sediment = 0.;
  }
};

class sink: public tank{
  public:

  sink(std::string iName){
    ClassType = "sink";
    Name = iName;
    V_max = 1.7976e308;
    V_init = 0;
    m_init = 0;
    V = 0.;
    c = 0.;
    m = 0.;
    R = 0.;    
  };

  sink(){
    ClassType = "sink";
    V_max = 1.7976e308;
    V_init = 0;
    m_init = 0;
    V = V_init;
    if(V_init>0.){
      c = m_init/V_init;
    } else {
      c = 0.;
    }
    m = m_init;
    R = 0.;    
  };

  void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    Q_pending += Flow; // Sinks have no limit, energy = provided by sink. E.g., sewer/infil = gravity, truck = truck pump
    // RequestFlow is only for those performing the flow. If a sink performs the flow, only source needs to be checked.
    (*Source).RequestVolume(0.,0.,Flow);
  }

  void RequestVolume(double Q_in, double c_in, double Q_out) override{
    //if((Flow-0.)<eps){
    //if(Flow<0.){ 
    //  V_pending_out += -Flow;
    //} else {
    //  V_pending_in += Flow;
    //}

    // first in
    if(Q_in>0.){
    m_pending += (1.-R)*c_in*Q_in;
    V_pending_in += Q_in;
    }

    // then out
    //if((V-0.)>eps){
    if(Q_out>0.){
    V_pending_out += Q_out;
      if((V+V_pending_in-V_pending_out)>eps)
        m_pending -= Q_out*m_pending/(V+V_pending_in-V_pending_out);
      else{
        m_pending = 0.;
      }
    }
  }

  double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    return (*Source).EvaluateVolume(-Flow);
  };

  double EvaluateVolume(double Flow) override{
    if (V_pending_out>0.|| Flow<0.){
      return 0.; // Sink used as source
    } else {
      return 1.; // Sink is endless
    }
  };

  void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd) override{
    //energy = provided by sink. E.g., sewer/infil = gravity, truck = truck pump
    (*Sink).Update(Flow,(*Source).c+c_added,0.);
    (*Source).Update(0.,0.,Flow);
    // No waste, r = 1
  };

};