#define NOMINMAX
#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>
#include <vector>
#include <memory>
#include <chrono>
#include <thread>

#ifndef JSON
#define JSON
#include <json/json.h>
#endif

#include "csv2.hpp"

#include "OSiRIS_Functions_4.0.0.h"
#include "OSiRIS_JsonLoad.h"
#include "DataStream.h"
#include "dtoa_milo.h"

int main(int argc, char** argv) {
    if (argc < 4) {
        std::cerr << "Usage: " << argv[0] << " <Settings.json> <InputData.csv> <OutputData.csv>" << std::endl;
        return 1;
    }

auto startfullall = std::chrono::high_resolution_clock::now();
auto durLoad = startfullall - std::chrono::high_resolution_clock::now();
auto durSave = durLoad;

    // Filepaths
    //std::string SettingPath ="./Default.json";
    std::string SettingPath = argv[1];
    //std::string SettingPath = "./SettingsCombined/Settings/4. - PW production.json";
    std::string InPath = argv[2];
    std::string OutPath = argv[3];
    //std::string InPath = "./InputData.csv";
    //std::string OutPath = "./OutputData.csv";

    // Load settings
    std::ifstream f(SettingPath, std::ifstream::binary);
    Json::Value Settings;
    Json::CharReaderBuilder readerBuilder;
    std::string errs;
    Json::parseFromStream(readerBuilder, f, &Settings, &errs);
    f.close();

    // Create datastreams
    datastream<std::vector<double>> DataIn(10000);
    datastream<std::vector<double>> DataOut(10000);
    datastream<std::string> TimeOut(10000);
    datastream<std::vector<std::string>> DataInNames(10000);
    datastream<std::vector<std::string>> DataOutNames(10000);

    // Function defs
    auto LoadData = [&] {
        csv2::Reader<csv2::delimiter<','>, 
                    csv2::quote_character<'"'>, 
                    csv2::first_row_is_header<true>,
                    csv2::trim_policy::trim_whitespace> csv;
                    
        std::string strval;
        std::vector<std::string> tmpnames;
        std::vector<double> tmpvect;
        auto i = 0;

        auto start = std::chrono::high_resolution_clock::now();
        auto stop = start;

        if (csv.mmap(InPath)) {
            const auto header = csv.header();
            for (const auto &cell: header){
            cell.read_value(strval);
            tmpnames.push_back(RemoveCarriageReturn(std::move(strval)));
            }
            DataInNames.push(std::move(tmpnames));

            for (const auto &row: csv) {
                start = std::chrono::high_resolution_clock::now();
                i = 0;
            for (const auto &cell: row) {
                if(i==0){
                    cell.read_value(strval);
                    TimeOut.push(RemoveCarriageReturn(std::move(strval)));
                } else {
                    cell.read_value(strval);
                    tmpvect.push_back(Str2Num(std::move(strval)));
                }
                i++;
            }
            stop = std::chrono::high_resolution_clock::now();
            durLoad += stop-start;
            if(tmpvect.size()>0){
                DataIn.push(std::move(tmpvect));
                tmpvect.clear();
            }
            }

            DataIn.RequestShutdown();
            TimeOut.RequestShutdown();
        }
    };

    auto SaveData = [&] {
        std::vector<double> DataNum;
        std::vector<std::string> DataStr;
        std::string TimeStr;
        char buff[1024];

        std::ofstream stream(OutPath);
        
        csv2::Writer<csv2::delimiter<','>> writer(stream);

        DataOutNames.pop(DataStr);
        writer.write_row(std::move(DataStr));
        DataStr.clear();

        auto start = std::chrono::high_resolution_clock::now();
        auto stop = start;
        bool var = true;
        while(var){
            var = DataOut.pop(DataNum)&TimeOut.pop(TimeStr);
            start = std::chrono::high_resolution_clock::now();
            stream << TimeStr;
            for (size_t i = 0; i < DataNum.size(); i++){
                //stream << ',' << std::to_string(DataNum[i]);
                dtoa_milo(DataNum[i],buff);
                stream << ',' << std::move(buff);
            }    
            stream << '\n';

            //ss.seekp(0, std::ios::end);
            //size = ss.tellp();
            //if(size>10000 || ~var){
            //stream << ss.rdbuf();
            //ss.str(std::string());
            //}
            stop = std::chrono::high_resolution_clock::now();
            durSave += stop-start;
        }
        stream.close();
    };

    auto OSiRIS = [&] {
        std::vector<double> datarowtmp;
        std::vector<std::string> OutDataNames;

        // Parse scenario settings to model objects
        std::vector<actor*> Actors;
        std::vector<catchment> Catchments;
        std::vector<control> Controls;
        std::vector<application> Appls;
        std::vector<generator*> Generators;
        std::vector<energy*> Energy;

        std::vector<std::string> DataNames;
        DataInNames.pop(DataNames);

        parseScenario(Settings, Actors,Catchments, Appls, Controls, Energy, Generators, DataNames);

        // Return indices of catchments, tap
        std::vector<int_T> SinkID;
        std::vector<int_T> TapID;
        std::vector<int_T> TankID;
        std::vector<int_T> TreatID;
        std::vector<int_T> PumpID;
        std::vector<int_T> SourceID;

        returnInd(Actors, TapID, SinkID, TankID, TreatID,PumpID,SourceID);                               

        // Vars for balances
        double Q_rain_collected;// current precipitation
        double Q_CW_use;        // current tap water use
        double V_input = 0;     // total water input (sources)
        double V_output;        // total water output (sinks)
        double V_buffer;        // total water buffered (tanks, treatments)
        double m_rain = 0;      // total pollutant mass added through rain 
        double m_CW_use = 0;    // total pollutant mass added through tap
        double m_appl = 0;      // total pollutant mass added through application use
        double m_sedi = 0 ;     // total pollutant mass removed through sedimentation
        double m_degr = 0;      // total pollutant mass removed through degradation
        double m_input;         // total pollutant mass input
        double m_output;        // total pollutant mass output
        double m_sink;          // total pollutant mass sent to sinks
        double m_buffer;        // total pollutant mass buffered (tanks, treatments)

        double Water_balance;
        double Pollutant_balance;

        double TmpData = 0;     // Temporarily stores data without needing re-indexing data

        //double dt = Settings["Dataset"]["dt"].asDouble(); 

        int i = 0;
        //auto len = 0;

        // timers
        auto start = std::chrono::high_resolution_clock::now();
        auto stop  = std::chrono::high_resolution_clock::now();
        auto startfull = start;
        auto stopfull = stop;
        auto Dur1 = stop-start;
        auto Dur2 = stop-start;
        auto Dur3 = stop-start;
        auto Dur4 = stop-start;
        auto Dur5 = stop-start;
        auto Dur6 = stop-start;
        auto Dur7 = stop-start;
        auto Dur8 = stop-start;
        auto Dur9 = stop-start;
        auto Dur10 = stop-start;
        auto Dur11 = stop-start;
        auto Dur12 = stop-start;
        //double test;
        std::vector<double> Data;
        while (DataIn.pop(Data)){
            //if(i==604){
            //    test = 0;
            //}
    
            start = std::chrono::high_resolution_clock::now();
            startfull = start;
            // Precipitation
            Q_rain_collected = 0;
            for (size_t j = 0; j < Catchments.size(); j++){
                TmpData = Data[Catchments[j].DataColumn];
                if(TmpData>0.){
                    Catchments[j].Rain(TmpData);
                    Q_rain_collected += Catchments[j].Q_used;
                    m_rain += Catchments[j].Q_used*Catchments[j].c;
                }
            }
            
            // Generators
             for (size_t j = 0; j < Generators.size(); j++){
                TmpData = Data[(*Generators[j]).DataColumn];
                if(TmpData>0.){
                    (*Generators[j]).Generate(TmpData);
                }
            }
           
            stop  = std::chrono::high_resolution_clock::now();
            Dur1 += stop-start;
            start  = std::chrono::high_resolution_clock::now();

            // Use applications
            for (size_t j = 0; j < Appls.size(); j++){
                TmpData = Data[Appls[j].DataColumn];
                if(TmpData>0.){
                Appls[j].Use(TmpData);
                m_appl += Appls[j].Q_used*Appls[j].c_added;
                if(Appls[j].warn){
                    //cout<< "Application " << Appls[j].Name << " could not be used fully.\n";
                }
            
            }
            }

            stop  = std::chrono::high_resolution_clock::now();
            Dur2 += stop-start;
            start  = std::chrono::high_resolution_clock::now();

            // Execute control flows
            for (size_t j = 0; j < Controls.size(); j++){
                Controls[j].Execute();                
            }
            //stop = std::chrono::high_resolution_clock::now();
            //Dur4 += stop-start;

            stop  = std::chrono::high_resolution_clock::now();
            Dur3 += stop-start;
            start  = std::chrono::high_resolution_clock::now();

            // BALANCES
            // Calculate city water use
            Q_CW_use = 0;
            for (size_t j = 0; j < TapID.size(); j++){
            Q_CW_use += (*Actors[TapID[j]]).Q_used;
            m_CW_use += (*Actors[TapID[j]]).Q_used*(*Actors[TapID[j]]).c;
            }

            // Calculate outgoing volume
            V_output = 0;
            m_sink = 0;
            for (size_t j = 0; j < SinkID.size(); j++){
            V_output += (*Actors[SinkID[j]]).V;
            m_sink += (*Actors[SinkID[j]]).m;
            }

            // Calculate buffer volume and sediment
            V_buffer = 0;
            m_buffer = 0;
            for (size_t j = 0; j < TankID.size(); j++){
            V_buffer += (*Actors[TankID[j]]).V_init-(*Actors[TankID[j]]).V;
            m_sedi += (*Actors[TankID[j]]).m_sediment;
            m_buffer += (*Actors[TankID[j]]).m_init-(*Actors[TankID[j]]).m;
            }

            // Calculate treatment degradation and storage
            for (size_t j = 0; j < TreatID.size(); j++){
            m_degr += (*Actors[TreatID[j]]).m_degraded;
            m_buffer += (*Actors[TreatID[j]]).m;
            V_buffer += (*Actors[TreatID[j]]).V;
            }

            V_input += Q_rain_collected + Q_CW_use;
            Water_balance = V_input + V_buffer - V_output;

                        
            m_input = m_appl + m_rain + m_CW_use;
            m_output = m_sedi + m_degr + m_sink;
            Pollutant_balance = m_input + m_buffer - m_output;

            stop  = std::chrono::high_resolution_clock::now();
            Dur4 += stop-start;
            start  = std::chrono::high_resolution_clock::now();


        // Write output data: double
        if(i==0){
            OutDataNames.push_back("Time");
            OutDataNames.push_back("Water_balance");
            OutDataNames.push_back("Pollutant_balance");

            //OutDataNames.push_back("C_battery_charge");
            //OutDataNames.push_back("E_use");
            //OutDataNames.push_back("E_use_GridBackup");

            for (size_t j = 0; j < Energy.size(); j++){
                for (size_t k = 0; k < (*Energy[j]).Batteries.size(); k++){
                    OutDataNames.push_back("C_"+(*Energy[j]).Name+"_"+(*Energy[j]).Batteries[k].Name);
                }
                OutDataNames.push_back("E_use_"+(*Energy[j]).Name);
            }

            for (size_t j = 0; j < TankID.size(); j++){
            OutDataNames.push_back((*Actors[TankID[j]]).Name + "_V");
            OutDataNames.push_back((*Actors[TankID[j]]).Name + "_c");
            }

            for (size_t j = 0; j < TreatID.size(); j++){
            OutDataNames.push_back("Q_"+(*Actors[TreatID[j]]).Name);
            }

            for (size_t j = 0; j < PumpID.size(); j++){
            OutDataNames.push_back("Q_"+(*Actors[PumpID[j]]).Name);
            }
            
            for (size_t j = 0; j < SinkID.size(); j++){
            OutDataNames.push_back("Q_"+(*Actors[SinkID[j]]).Name);
            OutDataNames.push_back("c_"+(*Actors[SinkID[j]]).Name);
            }

            for (size_t j = 0; j < SourceID.size(); j++){
            OutDataNames.push_back("Q_"+(*Actors[SourceID[j]]).Name);
            }

            for (size_t j = 0; j < Catchments.size(); j++){
            OutDataNames.push_back("Q_"+Catchments[j].Name);
            }

            for (size_t j = 0; j < Appls.size(); j++){
            OutDataNames.push_back("Q_"+Appls[j].Name);
            }
            for (size_t j = 0; j < Controls.size(); j++){
                for (size_t k = 0; k < Controls[j].Steps.size(); k++){
                    OutDataNames.push_back("Q_"+Controls[j].Name + "_" + Controls[j].Steps[k].Name);
                }
            }
            DataOutNames.push(OutDataNames);
        }
               
        datarowtmp.push_back(Water_balance);
        datarowtmp.push_back(Pollutant_balance);

        for (size_t j = 0; j < Energy.size(); j++){
                for (size_t k = 0; k < (*Energy[j]).Batteries.size(); k++){
                    datarowtmp.push_back((*Energy[j]).Batteries[k].C_battery);
                }
                datarowtmp.push_back((*Energy[j]).Usage);
            }
        
        for (size_t j = 0; j < TankID.size(); j++){
            datarowtmp.push_back((*Actors[TankID[j]]).V);
            datarowtmp.push_back((*Actors[TankID[j]]).c);
        }


        for (size_t j = 0; j < TreatID.size(); j++){
            datarowtmp.push_back((*Actors[TreatID[j]]).Q_used);
        }

        for (size_t j = 0; j < PumpID.size(); j++){
            datarowtmp.push_back((*Actors[PumpID[j]]).Q_used);
        }

        for (size_t j = 0; j < SinkID.size(); j++){
            datarowtmp.push_back((*Actors[SinkID[j]]).Q_incoming);
            datarowtmp.push_back((*Actors[SinkID[j]]).c_incoming);
        }

        for (size_t j = 0; j < SourceID.size(); j++){
            datarowtmp.push_back((*Actors[SourceID[j]]).Q_used);
        }

        for (size_t j = 0; j < Catchments.size(); j++){
            datarowtmp.push_back(Catchments[j].Q_used);
        }

        for (size_t j = 0; j < Appls.size(); j++){
            datarowtmp.push_back(Appls[j].Q_used);
        }

        for (size_t j = 0; j < Controls.size(); j++){
            for (size_t k = 0; k < Controls[j].Steps.size(); k++){
                datarowtmp.push_back(Controls[j].Steps[k].Q_used);
            }
        }

        stop  = std::chrono::high_resolution_clock::now();
            Dur5 += stop-start;
        start  = std::chrono::high_resolution_clock::now();

            //StepResets
            for (size_t j = 0; j < Energy.size(); j++){
            (*Energy[j]).StepReset();
            }

            for (size_t j = 0; j < Actors.size(); j++){
            (*Actors[j]).StepReset();
            }
            for (size_t j = 0; j < Appls.size(); j++){
            Appls[j].StepReset();
            }
            for (size_t j = 0; j < Catchments.size(); j++){
            Catchments[j].StepReset();
            }
            for (size_t j = 0; j < Controls.size(); j++){
            Controls[j].StepReset();
            }

            stop  = std::chrono::high_resolution_clock::now();
            stopfull = stop;
            Dur6 += stop-start;
            Dur7 += stopfull-startfull;

            DataOut.push(datarowtmp);
            datarowtmp.clear();
            i++;
        }
        DataOut.RequestShutdown();
        
        std::cout << "==============================================" << std::endl; 
        std::cout << "Precip. and gener.:  " << std::chrono::duration_cast<std::chrono::milliseconds>(Dur1).count() << " milliseconds" << std::endl;
        std::cout << "Using applications:  " << std::chrono::duration_cast<std::chrono::milliseconds>(Dur2).count() << " milliseconds" << std::endl;
        std::cout << "Executing controls:  " << std::chrono::duration_cast<std::chrono::milliseconds>(Dur3).count() << " milliseconds" << std::endl;
        std::cout << "Calculating balance: " << std::chrono::duration_cast<std::chrono::milliseconds>(Dur4).count() << " milliseconds" << std::endl;
        std::cout << "Passing data output: " << std::chrono::duration_cast<std::chrono::milliseconds>(Dur5).count() << " milliseconds" << std::endl;
        std::cout << "Resetting steps:     " << std::chrono::duration_cast<std::chrono::milliseconds>(Dur6).count() << " milliseconds" << std::endl;
        std::cout << "------------------------------------------" << std::endl;
        std::cout << "Simulation time:     " << 1./1000.*std::chrono::duration_cast<std::chrono::milliseconds>(Dur7).count() << " seconds" << std::endl;
        };


    // Create threads
    std::thread Loader(LoadData);
    std::thread Saver(SaveData);
    std::thread Worker(OSiRIS);

    Loader.join();
    Worker.join();
    Saver.join();

    auto stop = std::chrono::high_resolution_clock::now();
    std::cout << "Data loading:        " << 1./1000.*std::chrono::duration_cast<std::chrono::milliseconds>(durLoad).count() << " seconds" << std::endl;
    std::cout << "Data saving:         " << 1./1000.*std::chrono::duration_cast<std::chrono::milliseconds>(durSave).count() << " seconds" << std::endl;
    std::cout << "Total time:          " << 1./1000.*std::chrono::duration_cast<std::chrono::milliseconds>(stop-startfullall).count() << " seconds" << std::endl;
    std::cout << "==============================================" << std::endl;
    return 1;
}
  