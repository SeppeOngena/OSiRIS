#ifndef MATH_H
#pragma once
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <array>
#include <vector>
#include <deque>
#include <string>
#include <numeric>
#include <algorithm>
#include <memory>

#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
//#include "rtwtypes.h"
#endif

#define MATH_H
//using namespace std;

// Some basic functions
static double eps = 1e-14;

// static double sumprod(const double* arr1,const double* arr2, int sz){
//   double summed=0;
//     for(int count=0;count<sz;count++){
//         summed+=arr1[count]*arr2[count];
//     }
//     return summed;
// };

// static double sumprod(const vector<double> arr1,const vector<double> arr2, int sz){
//   double summed=0;
//     for(int count=0;count<sz;count++){
//         summed+=arr1[count]*arr2[count];
//     }
//     return summed;
// };

// static double sum(const vector<double> arr){
//     double summed=0;
//     for(int count=0;count<arr.size();count++){
//         summed+=arr[count];
//     }
//     return summed;
// };

// static double sum(const double arr[],int sz){
//     double summed=0;
//     for(int count=0;count<sz;count++){
//         summed+=arr[count];
//     }
//     return summed;
// };

// typedef double ( *binary_operation)(double, double); 

// static vector<double> forEach( vector<double> arr, binary_operation binOp, double rArg){ 
//     int k; 
 
//     for(k= 0; k < arr.size(); k++){ 
//         arr[k] = (*binOp)(arr[k], rArg);  
//     }
 
//     return arr; 
// }

// static vector<double> forEach2( vector<double> arr, binary_operation binOp, vector<double> arr2){ 
//     int    j; 
 
//     for(j = 0; j< arr.size(); j++){ 
//         arr[j]= (*binOp)(arr[j], arr2[j]); 
//     } 
 
//     return arr; 
// }
 
// static double mul(double lArg, double rArg){ 
//     return lArg * rArg; 
// }

// static double add(double lArg, double rArg){
//    return lArg + rArg;
// }

// static double min(double val1, double val2){
//   if (val1>val2){
//     return val2;
//   } else {
//     return val1;
//   }
// };


// static double max(double val1, double val2){
//    if (val1>val2){
//     return val1;
//   } else {
//     return val2;
//   }
// };

// static vector<double> operator+ (const vector<double> arr1, const vector<double> arr2){
//   return forEach2(arr1,add,arr2);
// }

// static vector<double> operator* (const vector<double> arr1, const vector<double> arr2){
//   return forEach2(arr1,mul,arr2);
// }

// static vector<double> operator+ (const vector<double> arr1, const double rArg){
//   return forEach(arr1,add,rArg);
// }

// static vector<double> operator* (const vector<double> arr1, const double rArg){
//   return forEach(arr1,mul,rArg);
// }

// static vector<double> CArr2Vect(const double arr[],int sz){
//   vector<double> arr2(arr,arr+sz);
//   return arr2;
// };


// static vector<bool> strcmp(vector<string> Str1,string Str2){
//   vector<bool> out = {false};
 
//     for(size_t g = 0; g < Str1.size(); g++){ 
//         out[g] = !Str1[g].compare(Str2);  
//     }
 
//     return out; 
// };

// static vector<double> strcmp_real(vector<string> Str1,string Str2){
//       vector<double> out = {0};
 
//     for(size_t g = 0; g < Str1.size(); g++){ 
//       if(g==0){
//         out[0] = 1*!Str1[g].compare(Str2);
//       }else{
//         out.push_back(1*!Str1[g].compare(Str2));  
//       }
//     }
 
//     return out; 
// };

template <typename T> int sgn(T val) {
    return (T(0) < val) - (val < T(0));
}

// static double SumOfDeque(std::deque<double> Deque, int dir){
// double summed = 0;
// int cursign;
// for (size_t i = 0; i < Deque.size(); i++){
//   cursign = sgn(Deque[i]);
//   if (cursign==dir){
//     summed += Deque[i];
//   }
// }
// return summed;
// }

static std::string RemoveCarriageReturn(std::string strval){ 
  if (!strval.empty() && strval[strval.size() - 1] == '\r'){
      strval.erase(strval.size() - 1);
  }
  return strval;
}

static double Str2Num(std::string strval){
  strval = RemoveCarriageReturn(strval);
  return std::stof(strval);
}
#endif