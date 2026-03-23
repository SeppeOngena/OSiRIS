#pragma once
#include "../Math/Math.h"
#include "Energy.h"

class actor{
  public:
  double V;
  double V_init;
  double V_max;
  double c;
  double m_init;

  double Q_incoming = 0.;
  double c_incoming = 0.;

  double Q_design = 0;
  double E_use = 0.;
  double r = 1.;

  double m = 0;
  double m_sediment =0.;
  double m_degraded = 0.;

  double Q_used = 0.;
  double E_used = 0.;

  double Q_pending;
  double m_pending;
  double V_pending_in; double V_pending_out;

  std::vector<energy*> EMS; // Energy management system
  std::vector<int8_T> EMSConnectedInd;

  std::string Name;
  std::string ClassType = "actor";

  virtual void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) = 0;
  virtual void RequestVolume(double Q_in, double c_in, double Q_out) = 0;
  virtual double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) = 0;
  virtual double EvaluateVolume(double Flow) = 0;
  virtual void clear(){
    Q_pending = V_pending_in = V_pending_out = 0.;
    m_pending = m;
  }
  
  virtual void Update(double Q_in, double c_in, double Q_out) = 0;
  virtual void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd)=0;
  virtual void StepReset(){
      Q_used = E_used = Q_incoming = c_incoming = 0.;
    }
};