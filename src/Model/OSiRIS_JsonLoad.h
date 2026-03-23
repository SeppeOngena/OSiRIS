#pragma once
#include <array>
#include <vector>
#include <string>
#include <algorithm>
#include <memory>
#include <ranges>

#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
//#include "Math/rtwtypes.h"
#endif

#include "Math/Math.h"

#include "Classes/Energy.h"
#include "Classes/Actor_Tank.h"
#include "Classes/Actor_Technology.h"
#include "Classes/Actor_Source.h"
#include "Classes/Application.h"
#include "Classes/Control.h"

#ifndef JSON
#define JSON
#include <json/json.h>
#endif

#include "OSiRIS_Functions_4.0.0.h"

//using namespace std;

void parseScenario(Json::Value Settings,std::vector<actor*> &Actors, std::vector<catchment> &Catchments, std::vector<application> &Appls, std::vector<control> &Controls, std::vector<energy*> &Energy, std::vector<generator*> &Generators, std::vector<std::string> DataNames){
  real_T dt = Settings["Dataset"]["dt"].asDouble();
  real_T conv = 1./24./3600.*dt; 
  Json::Value it;

  // Energy
  std::vector<battery> Batteries;
  Json::Value bat;
  Json::Value gen;
  std::vector<std::string> BatteryNames;
  std::vector<std::string> GeneratorNames;

  std::vector<std::string> EMSNames = Settings["Scenario"]["EnergyManagementSystems"].getMemberNames();
  for (size_t i = 0; i < EMSNames.size(); i++){
    it = Settings["Scenario"]["EnergyManagementSystems"][EMSNames[i]];

    BatteryNames = it["Batteries"].getMemberNames();
    Batteries.clear();
    for (size_t j = 0; j < BatteryNames.size(); j++){
      bat = it["Batteries"][BatteryNames[j]];
      Batteries.push_back(battery(BatteryNames[j], bat["C_battery"].asDouble(), bat["C_battery_init"].asDouble(), bat["eta_battery"].asDouble()));
    }
    Energy.emplace_back(new energy(EMSNames[i],std::move(Batteries)));
        
    GeneratorNames = it["Generators"].getMemberNames();
    for (size_t j = 0; j < GeneratorNames.size(); j++){
      gen = it["Generators"][GeneratorNames[j]];
      if (gen["Type"].asString() == "PV"){
        Generators.emplace_back(new pv_installation(GeneratorNames[j],Energy[i],
                              distance(DataNames.begin(), find(DataNames.begin(),DataNames.end(),gen["Data"].asString()))-1, // Minus one for time that is not there
                              gen["kWp_panels"].asDouble(), gen["eta_heat"].asDouble(), gen["eta_inverter"].asDouble()));
      } else if(gen["Type"].asString() == "Other"){
        Generators.emplace_back(new misc_generator(GeneratorNames[j],gen["Multiplier"].asDouble(),Energy[i],distance(DataNames.begin(), find(DataNames.begin(),DataNames.end(),gen["Data"].asString())-1)));
      }
    }

  };


  //Tanks
  std::vector<std::string> TankNames = Settings["Scenario"]["Tanks"].getMemberNames();                         
  for (size_t i = 0; i < TankNames.size(); i++){
    it = Settings["Scenario"]["Tanks"][TankNames[i]];
    if (it["prefill"].asBool()){
       Actors.emplace_back(new tank(TankNames[i], it["V_tank"].asDouble(), it["V_init"].asDouble(), it["c_init"].asDouble(), it["R"].asDouble()));
    } else {
       Actors.emplace_back(new tank(TankNames[i], it["V_tank"].asDouble(), 0, 0, it["R"].asDouble()));
    }
   
  }

  // Sinks
  std::vector<std::string> SinkNames = Settings["Scenario"]["Sinks"].getMemberNames();
  for (size_t i = 0; i < SinkNames.size(); i++){
    Actors.emplace_back(new sink(SinkNames[i]));
  }

  // Technologies
  Json::Value EMSJson;
  std::vector<int8_T> EMSConnectedInd;
  
  std::vector<std::string> TechNames = Settings["Scenario"]["Technologies"].getMemberNames();
  for (size_t i = 0; i < TechNames.size(); i++){
  it = Settings["Scenario"]["Technologies"][TechNames[i]];
      EMSJson = it["EMS"];
      EMSConnectedInd.clear();
      //std::ranges::reverse_view rv {EMSJson};
      for (auto el : EMSJson) {
        EMSConnectedInd.push_back(distance(EMSNames.begin(), find(EMSNames.begin(),EMSNames.end(),el.asString())));
      }
    
    if (it["Type"].asString() == "Pump") {
      Actors.emplace_back(new pump(TechNames[i],Energy,EMSConnectedInd, it["E"].asDouble(), it["Q"].asDouble()*conv));
    } else {
      Actors.emplace_back(new treatment(TechNames[i],Energy,EMSConnectedInd, it["R"].asDouble(), it["D"].asDouble(), it["r"].asDouble(), it["E"].asDouble(), it["Q"].asDouble()*conv));
    }
  };

  // Sources
  std::vector<std::string> SourceNames = Settings["Scenario"]["Sources"].getMemberNames();
  for (size_t i = 0; i < SourceNames.size(); i++){
  it = Settings["Scenario"]["Sources"][SourceNames[i]];
    if (it["Type"].asString() == "Catchment")
    {
    Catchments.emplace_back(SourceNames[i],
                            distance(DataNames.begin(), find(DataNames.begin(),DataNames.end(),it["Data"].asString()))-1,
                            it["A"].asDouble(), SelectItem(it["Feeds"].asString(),Actors), it["eta_rain"].asDouble(), it["c"].asDouble());
    } else {
      Actors.emplace_back(new tap(SourceNames[i],it["c"].asDouble()));
    }
    
};

// Applications
double Q_lpd;
double IE;
std::vector<std::string> ApplMembers;
std::string Search = "Q_lpd";

std::vector<std::string> ApplNames = Settings["Scenario"]["Applications"].getMemberNames();
for (size_t i = 0; i < ApplNames.size(); i++){
it = Settings["Scenario"]["Applications"][ApplNames[i]];
ApplMembers = it.getMemberNames();
if (std::find(ApplMembers.begin(), ApplMembers.end(),Search)!=ApplMembers.end()){
  Q_lpd =  it["Q_lpd"].asDouble();
  IE = it["IE"].asDouble();
} else {
  Q_lpd =  it["Q_ld"].asDouble();
  IE = 1.;
}
  Appls.emplace_back(ApplNames[i],
                    distance(DataNames.begin(), find(DataNames.begin(),DataNames.end(),it["DistributionData"].asString())-1),
                    IE, Q_lpd,
                    it["c_added"].asDouble(),
                    SelectItem(it["Sourcewater"].asString(),Actors),
                    SelectItem(it["Wastewater"].asString(),Actors),
                    SelectItem(it["Actor"].asString(),Actors));
};

// Controls
std::vector<step> Steps;
Json::Value StepsJson;
std::string st;

std::string ct;
int type;
int direction;

std::vector<EMScontrol> EMSControl;
//Json::Value EMSJson;
std::string ems;

Json::Value ControlsJson = Settings["Scenario"]["Controls"];
  for (auto it : ControlsJson){
    ct = it.getMemberNames()[0];
    
    StepsJson = it[ct]["Steps"];
    Steps.clear();
    for (auto el : StepsJson){
      st = el.getMemberNames()[0];
      Steps.push_back(step(st,
                            el[st]["Fraction"].asDouble(),
                            SelectItem(el[st]["Actor"].asString(),Actors),
                            SelectItem(el[st]["Source"].asString(),Actors),
                            SelectItem(el[st]["Sink"].asString(),Actors),
                            SelectItem(el[st]["Waste"].asString(),Actors)));
    }

    EMSJson = it[ct]["Limits"];
    EMSControl.clear();
    for(auto el : EMSJson){
      ems = el.getMemberNames()[0];
      EMSControl.push_back(EMScontrol(ems,
                            distance(EMSNames.begin(), find(EMSNames.begin(),EMSNames.end(),ems)),
                            el[ems]["High"].asDouble(),
                            el[ems]["Low"].asDouble()));
    }

    if(it[ct]["Type"].asString()=="empty/lower"){direction = 0;} else {direction = 1;}
    if(it[ct]["ControlType"].asString()=="hysteresis"){type = 0;} else {type = 1;}

    Controls.emplace_back(ct,
                          std::move(EMSControl),
                          Energy,
                          std::move(Steps),
                          direction,type, 
                          SelectItem(it[ct]["Tank"].asString(),Actors),
                          it[ct]["Parameter"].asString(),
                          it[ct]["Flow"].asDouble()*conv);
};
};
