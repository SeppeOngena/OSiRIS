<p align="center">
  <img src="https://github.com/user-attachments/assets/a2c73657-41c9-4ba1-aeec-a4094ce89a89" alt="OSiRIS logo" width="50%"/>
</p>

### Simulate and evaluate the effect of on-site water reuse interventions on energy use and water and pollutant flows in a household, building, or community!

## OSiRIS model features:
- High flexibility with building blocks, configuration in .json files for standalone execution:
  - **Water tanks:** volume tracked over time
  - **Treatments and pumps:** recovery, energy use, design flow, rejection, degradation
  - **Household applications:** water use and wastewater production
  - **Catchments and tap water:** supply of water
  - **Water sinks:** final discharge of water
  - **Energy management systems:** generators (solar or general), batteries, energy supply management
  - **Control system:** separate control limits per EMS, ensuring water availability and prioritizing energy use
- Rapid simulation of C++ based model: < 1 min for 10 years @ 15 min resolution (depends on hardware platform)
- Scalable from single household to district or city level
- Water and pollutant balance: incoming precipitation, storage tanks, usage in household, and sinks

## OSiRIS app with user interface:
<img src="https://github.com/user-attachments/assets/a4b705e9-f133-476a-a0c1-4bd5786a53d3" alt="App screenshot" />

- Pre-configured set of building block elements:
  - **Five tanks:** (filtered) rainwater, potable water (treated rainwater), greywater, blackwater, and purified greywater
  - **Four treatments:** potable water, greywater, blackwater, and combined grey- and blackwater
  - **Nine applications:** toilet flushing, bathing, showering, bathroom sink, washing machine, dishwasher, kitchen sink, cleaning, and garden watering
  - **Two sources:** tap/city mains water and rainwater catchment
  - **Three sinks:** infiltration, sewer, and collection by truck
  - **Two energy management systems:** locally produced renewable (PV system with battery) and centralized electricity grid (backup)
  - **Thirtheen control flows:** automatically selected based on current settings
- Scenario framework: Create different settings combinations from fully centralized to extremely decentralized or load from a file, simulate in bulk, and save results to file
- Dynamic scheme automatically adapts to user settings:
  
<p align="center">
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/0%20-%20Centralized.png" alt="Fully centralized" width="32%"/>
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/3%20-%20Dec.%20treatment%20and%20infil..png" alt="Rainwater use and individual treatment and infiltration of wastewater" width="32%"/>
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/8%20-%20Extreme%20dec.%20%2B%20BW%20reuse.png" alt="Fully decentralized" width="32%"/>
</p>

- High modifiability, easily change up to 99 model variables, for example:
  - Which water quality to reuse and for which applications
  - Which tanks and treatments to install (including volumes, specifications,...)
  - What to do with excess wastewater
- Built-in key performance indicators (KPI) for scenario analysis:
  - Water independence on import, water independence on export, circularity, local water recharge, drought tolerance, energy independence
 
  <p align="center">
    <img src="https://github.com/user-attachments/assets/3880e966-0a78-4fc2-b363-8349a9c512ca" alt="KPI" width="75%"/>
  </p>

- Evaluate simulation results in graphs for the volume and concentration of tanks, renewable and grid energy use, and battery capacity

  <p align="center">
    <img src="https://github.com/user-attachments/assets/b7c8134c-1146-4030-b8ab-8859393627b3" alt="E_balance" width="36%"/>
    <img src="https://github.com/user-attachments/assets/99e95781-21fa-42a8-8a36-a7145f71b018" alt="Water_plots" width="54%"/>
  </p>


- Built-in submodels for simplified data loading:
  - Diurnal water usage patterns enabling high resolution
  <p align="center">
    <img src="https://github.com/user-attachments/assets/d4d4e55f-debf-49d5-a849-23289ef365c1" alt="DiurnalPatterns" width="60%"/>
  </p>
  
  - Solar insolation, cloud, and photovoltaic models if data is unavailable
  <p align="center">
    <img src="https://github.com/user-attachments/assets/b9ada165-90be-4931-a66b-03193e55b996" alt="SimSolar" width="60%"/>
  </p>
  
  - Simulation of garden irrigation based on solar irradiance and precipitation
   <p align="center">
    <img src="https://github.com/user-attachments/assets/18459c44-9f94-4863-a70d-29be5304057d" alt="Gardening" width="60%"/>
  </p>


### Example [data](https://github.com/SeppeOngena/Decentralized-House-Model/tree/main/Example%20Data) and [results](https://github.com/SeppeOngena/Decentralized-House-Model/tree/main/Example%20Results) included
### View the [manual](https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Manual.pdf) for detailed walktrough of app and example workflow
