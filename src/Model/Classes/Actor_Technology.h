#pragma once
#include "Actor.h"
#include "../Math/Math.h"

class technology: public actor {
};

class treatment: public technology {
  public:
    double R; // Rejection
    double D; // Degradation
    

    treatment(std::string iName, std::vector<energy*> iEMS, std::vector<int8_T> iEMSConnectedInd, double removal_concentration, double removal_degradation, double Recovery, double EnergyUse, double DesignFlow){
      Name = iName;
      r = Recovery;
      //if(fabs(r-1.)<eps){
	    D = removal_degradation;
      if(r == 1.){
		  R = 0.;
		  D += removal_concentration;
		  D = std::min(1.,D); 
	  } else if(r == 0.){
		  R = 1.;
		  D += (1.-removal_concentration);
		  D = std::min(1.,D); 
	  } else {
		  R = removal_concentration;
	  }
    
      E_use = EnergyUse;
      Q_design = DesignFlow;
      EMS = iEMS;
      EMSConnectedInd = iEMSConnectedInd;
      ClassType = "treatment";
    }

  private:
    double c_conc = 0.;
    double c_perm = 0.;
    double Q_perm = 0.;
    double Q_conc = 0.;

  public:
  void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    bool UseOwnEMS = false;
    Q_pending += Flow;
    (*Source).RequestVolume(0.,0.,Flow);
    if(UseEMSInd.size()>0){ // Control flow, otherwise sink and waste will have to comply
      if(r>0.){
        (*Sink).RequestVolume(Flow*r,c*(1.-D)*(1.-R),0.);
      }
      if(r<1.){
        (*Waste).RequestVolume(Flow*(1.-r),c*(1.-D)*(1.+r*R/(1.-r)),0.);
      }       
    } else {
      UseOwnEMS = true;
    }

    // Submit requests to all EMS
    for (int8_T emsInd:EMSConnectedInd){
      if(UseOwnEMS){
        (*EMS[emsInd]).Active = true; // set active if not controlled
      }
      (*EMS[emsInd]).RequestEnergy(E_use*Flow);
    }

  }

  void RequestVolume(double Q_in, double c_in, double Q_out) override{
    //V_pending.push_back(Flow);
    if(Q_out>0.){
     V_pending_out += Q_out;
    } else if (Q_in>0.){
     V_pending_in += Q_in;
    }
  }

  double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{

    double FractionFeasible = (*Source).EvaluateVolume(-Flow);
    if(UseEMSInd.size()>0){
      if(r>0.){
        FractionFeasible = std::min(FractionFeasible,(*Sink).EvaluateVolume(Flow*r));
      }
      if(r<1.){
        FractionFeasible = std::min(FractionFeasible,(*Waste).EvaluateVolume(Flow*(1-r)));
      }   
    } 

    if((Q_design-Q_used)>eps){
      FractionFeasible = std::min(FractionFeasible,std::min(1.,(Q_design-Q_used)/Flow));
    }
    

    // Evaluate requests from all EMS
    double FeasibleEnergy = 0.;
    for (int8_T emsInd:EMSConnectedInd){
      FeasibleEnergy += (*EMS[emsInd]).EvaluateEnergy();
    }

    return std::min(FractionFeasible,std::min(1.,FeasibleEnergy));
  };

  void clear() override{
    Q_pending = V_pending_in = V_pending_out = 0.;
    m_pending = m;
    for (energy* ems:EMS){
      (*ems).clear();
    }
  }

  double EvaluateVolume(double Flow) override{
    if (Flow<0.){ // outgoing flow
      //double dV_in = SumOfDeque(V_pending,1);
      double dV_in = V_pending_in+V;
      return std::min(1.,dV_in/(-Flow)); // Cannot return more than going in.
    } else { // ingoing flow
      return 1.; // Tech can always take more flow
    }
  };

    void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd) override{
      
       if(std::abs(Flow)>eps){
       double c_source = (*Source).c+c_added;
       (*Source).Update(0.,0.,Flow); // do tank updates
       (*Sink).Update(Flow*r,c_source*(1.-D)*(1.-R),0.);
       m_degraded += Flow*c_source*D; // basically, the treatment is taken as 2 compartment: 1st is degradation, 2nd is filtration/concentration
       //if(fabs(r-1)>eps){
       if(r<1.){
         (*Waste).Update(Flow*(1.-r),c_source*(1.-D)*(1.+r*R/(1.-r)),0.);
       }

    double FlowNeeded = Flow;
    double FlowPossible = 0.;
    std::vector<signed char>::iterator EMSfound;
      int8_T EMSInd;
      std::vector<int8_T> EMSIndList;
      if(UseEMSInd.size()>0){
        EMSIndList = UseEMSInd;
      } else {
        EMSIndList = EMSConnectedInd;
      }
      if(E_use>eps){
        for (size_t i = 0; i < EMSIndList.size(); i++){
            EMSfound = find(EMSConnectedInd.begin(),EMSConnectedInd.end(),EMSIndList[i]);
            if(EMSfound != EMSConnectedInd.end()){
              EMSInd = distance(EMSConnectedInd.begin(), EMSfound);
              FlowPossible = std::min(FlowNeeded,(*EMS[EMSConnectedInd[EMSInd]]).Available()/E_use);
              (*EMS[EMSConnectedInd[EMSInd]]).Use(E_use*FlowPossible);
              FlowNeeded -= FlowPossible;
            }
        }
        Q_used += Flow;
       E_used += E_use*Flow;
       }
     }
    }

    void Update(double Q_in, double c_in, double Q_out){ // Allows a treatment to temporarily store water
      // first in
      if(Q_in>0.){
      m += c_in*Q_in;
      V += Q_in;
      }

      // then out
      if(Q_out>0. && V>eps){
      m -= Q_out*m/V;
      V -= Q_out;
      }
      
      if(V>eps){
        c = m/V;
      } else {
        c = 0.;
      }
      
      // if(Q_in>0.){
      //   V_pending_in += Q_in;
      //   V = V_pending_in - V_pending_out;
      //   m += Q_in*c_in;
      // }

      // if(Q_out>0.){
      //   V_pending_out += Q_out;
      //   V = V_pending_in - V_pending_out;
      //   if(V>0.){
      //     m -= Q_out*m/V;
      //   } else {
      //     m = 0.;
      //   }
      // }
      
      // if(V>eps && m>eps){
      //   c = m/V;
      // }
  }

    void StepReset() override{
      Q_used = E_used = Q_incoming = c_incoming =  0.;
      //C_conc = C_perm = Q_perm = Q_conc = 0;
      m_degraded = 0.;
    }

   // void GetConcentrations(double &C_concentrate, double &Q_concentrate, double &C_permeate, double &Q_permeate){
    //  C_concentrate = C_conc;
    //  C_permeate = C_perm;
    //  Q_concentrate = Q_conc;
    //  Q_permeate = Q_perm;
    //}
};

class pump: public technology {
  public:
  pump(std::string iName, std::vector<energy*> iEMS, std::vector<int8_T> iEMSConnectedInd,double iE_use, double iQ_design){
    Name = iName;
    E_use = iE_use;
    Q_design = iQ_design;
    Q_used =0;
    E_used = 0;
    ClassType = "pump";
    EMS = iEMS;
    EMSConnectedInd = iEMSConnectedInd;
  }
  
  void RequestFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    bool UseOwnEMS = false;
    Q_pending += Flow;
    (*Source).RequestVolume(0.,0.,Flow);
    if(UseEMSInd.size()>0){
    (*Sink).RequestVolume(Flow,(*Source).c,0.);
    } else {
      UseOwnEMS = true;
    }
    // Pumps have recovery 1;

    // Submit requests to all EMS
    for (energy* ems:EMS){
      if(UseOwnEMS){
        (*ems).Active = true; // set active if not controlled
      }
      (*ems).RequestEnergy(E_use*Flow);
    }
  }

  void RequestVolume(double Q_in, double c_in, double Q_out) override{
    // pumps cannot buffer
  }

  double EvaluateFlow(double Flow, actor *Source, actor *Sink, actor *Waste, std::vector<int8_T> UseEMSInd) override{
    
    double FractionFeasible = (*Source).EvaluateVolume(-Flow);

    if(UseEMSInd.size()>0){
    FractionFeasible = std::min(FractionFeasible,(*Sink).EvaluateVolume(Flow));
    }

    if((Q_design-Q_used)>eps){
      FractionFeasible = std::min(FractionFeasible,std::min(1.,(Q_design-Q_used)/Flow));
    }

    // Evaluate requests from all EMS
    double FeasibleEnergy = 0.;
    for (energy* ems:EMS){
      FeasibleEnergy += (*ems).EvaluateEnergy();
    }

    return std::min(FractionFeasible,std::min(1.,FeasibleEnergy));
  };

  double EvaluateVolume(double Flow) override{
    return 0.; // pumps cannot buffer
  };

   void Use(double Flow, actor *Source, actor *Sink, actor *Waste, double c_added, std::vector<int8_T> UseEMSInd) override{
    (*Sink).Update(Flow,(*Source).c+c_added,0.);
    (*Source).Update(0.,0.,Flow);

    double FlowNeeded = Flow;
    double FlowPossible = 0.;
    std::vector<signed char>::iterator EMSfound;
      int8_T EMSInd;
      std::vector<int8_T> EMSIndList;
      if(UseEMSInd.size()>0){
        EMSIndList = UseEMSInd;
      } else {
        EMSIndList = EMSConnectedInd;
      }
      if(E_use>eps){
        for (size_t i = 0; i < EMSIndList.size(); i++){
            EMSfound = find(EMSConnectedInd.begin(),EMSConnectedInd.end(),EMSIndList[i]);
            if(EMSfound != EMSConnectedInd.end()){
              EMSInd = distance(EMSConnectedInd.begin(), EMSfound);
              FlowPossible = std::min(FlowNeeded,(*EMS[EMSConnectedInd[EMSInd]]).Available()/E_use);
              (*EMS[EMSConnectedInd[EMSInd]]).Use(E_use*FlowPossible);
              FlowNeeded -= FlowPossible;
            }
        }
      }
            
    Q_used += Flow;
    E_used += E_use*Flow;
      
  }

   void Update(double Q_in, double c_in, double Q_out){ // Pump cannot temporarily store water
  }

  void clear() override{
    Q_pending = V_pending_in = V_pending_out = 0.;
    m_pending = m;
    for (energy* ems:EMS){
      (*ems).clear();
    }
  }
};
