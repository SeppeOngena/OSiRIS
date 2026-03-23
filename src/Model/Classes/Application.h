#pragma once
#include "Actor.h"

// 3. Applications
class application{
  private: 
  actor *Source;
  actor *Sink;
  actor *Actor;
  public:
  int8_T DataColumn = 2;
  double IE = 2.3;
  double Q_lpd = 21.3;
  double c_added = 530.0;
  double Q_used = 0;
  bool warn = false;
  std::string Name;
  std::vector<int8_T> UseEMSInd; // Empty, so tech uses its own EMS

  application(std::string iName, int8_T iType, double iIE, double iQ_lpd, double ic_added, actor *iSourceTank, actor *iSinkTank, actor *iActor) : Source(iSourceTank), Sink(iSinkTank), Actor(iActor){
    Name = iName;
    DataColumn = iType;
    IE = iIE;
    Q_lpd = iQ_lpd;
    c_added = ic_added;
    warn = false;
    }

  void Use(double &DistributionDaily){
    double Flow = Q_lpd*IE*DistributionDaily*0.001;

    if(Flow>0.){
      (*Actor).RequestFlow(Flow,Source,Sink,Sink,UseEMSInd);
      double FractionFeasible = (*Actor).EvaluateFlow(Flow,Source,Sink,Sink,UseEMSInd);

      // 3. Process warning
      if(FractionFeasible<1.){
        warn = true; // non-use of application because of energy or source limits
      }

      (*Actor).Use(FractionFeasible*Flow, Source,Sink,Sink,c_added,UseEMSInd); // Perform flow with the actor's connected EMS's as priority

      (*Source).clear();
      (*Actor).clear();
      (*Sink).clear();

      Q_used += FractionFeasible*Flow;
    }
  }

  void StepReset(){
    warn = false;
    Q_used = 0;
  }

};