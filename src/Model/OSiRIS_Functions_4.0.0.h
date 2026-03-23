 #pragma once
 #include <array>
 #include <vector>
 #include <string>
 #include <algorithm>
 #include <memory>

 #if defined(MATLAB_MEX_FILE)
 #include "tmwtypes.h"
 #include "simstruc_types.h"
 #else
 #include "Math/rtwtypes.h"
 #endif

 #include "Math/Math.h"

 #include "Classes/Energy.h"
 #include "Classes/Actor_Tank.h"
 #include "Classes/Actor_Technology.h"
 #include "Classes/Actor_Source.h"
 #include "Classes/Application.h"
 #include "Classes/Control.h"



 actor* SelectItem(std::string Name, std::vector<actor*> &Selectable){
   auto ind = distance(Selectable.begin(), std::find_if(Selectable.begin(), Selectable.end(), [&](const auto &e) { return (*e).Name == Name;}));

  //auto ind = distance(Names.begin(), find(Names.begin(),Names.end(),Name));
  return Selectable[ind];
};

energy* SelectEMS(std::string Name, std::vector<energy*> &Selectable){
   auto ind = distance(Selectable.begin(), std::find_if(Selectable.begin(), Selectable.end(), [&](const auto &e) { return (*e).Name == Name;}));

  return Selectable[ind];
};

void SortByInd(std::vector<control> &Vec, std::vector<int_T> ind){
  std::vector<control> tmp = Vec;
  for (size_t i = 0; i < ind.size(); i++)
  {
    tmp[ind[i]] = Vec[i];
  }
  Vec = tmp;
}

void returnInd(std::vector<actor*> &Actors, std::vector<int_T> &TapID, std::vector<int_T> &SinkID, std::vector<int_T> &TankID, std::vector<int_T> &TreatID, std::vector<int_T> &PumpID, std::vector<int_T> &SourceID){
  for (size_t i = 0; i < Actors.size(); i++)
  {
    if ((*Actors[i]).ClassType == "tap"){TapID.push_back(i);}
    if ((*Actors[i]).ClassType == "sink"){SinkID.push_back(i);}
    if ((*Actors[i]).ClassType == "tank"){TankID.push_back(i);}
    if ((*Actors[i]).ClassType == "treatment"){TreatID.push_back(i);}
    if ((*Actors[i]).ClassType == "pump"){PumpID.push_back(i);}
    if ((*Actors[i]).ClassType == "tap"){SourceID.push_back(i);}
  }
};
