# OSiRIS
## On-Site water Reuse Instant-Simulator
### Simulate and evaluate the effect of on-site water reuse interventions on energy use and water and pollutant flows in a household, building, or community!
<p align="center">
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/8%20-%20Extreme%20dec.%20%2B%20BW%20reuse.png" alt="Dynamic scheme" width="50%"/>
</p>

## Simulation model features:
- High temporal resolution, enabled by diurnal water usage patterns\
  \
  <img src="https://github.com/user-attachments/assets/025d5782-76b1-46bb-ae1d-8a3f137388a3" alt="Diurnal patterns" width="30%"/>

- Rapid simulation of C++ based model: < 1 min for 10 years @ 15 min resolution (depends on hardware platform)
- High flexibility
  - From centralized to extremely decentralized: direct use of city water, selection of installed tanks and treatments
<p align="center">
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/0%20-%20Centralized.png" alt="Fully centralized" width="32%"/>
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/3%20-%20Dec.%20treatment%20and%20infil..png" alt="Rainwater use and individual treatment and infiltration of wastewater" width="32%"/>
  <img src="https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Example%20Results/Schemes/8%20-%20Extreme%20dec.%20%2B%20BW%20reuse.png" alt="Fully decentralized" width="32%"/>
</p>

  - Scalable from single household to district level (e.g. weighted rain correction factor for roads vs. roofs, increased pump energy for greater distances,…)
- Water and pollutant balance: incoming precipitation, storage tanks, usage in household, and infiltration, sewer, or collection by truck
- Simplified treatment for water reuse simulation based on treatment "specsheet": recovery, energy use, design flow, rejection (membranes), degradation\
  \
  <img src="https://github.com/user-attachments/assets/848a225a-11ef-4ce9-a5f9-8af4ca9a56ac" alt="Treatment specsheet" width="20%"/>

- Renewable energy simulation for water pumping + treatments\
\
  <img src="https://github.com/user-attachments/assets/18a2dc9a-ac12-4113-ac2b-2fb5beeff058" alt="Energy use" width="50%"/>
  - Energy use is prioritized between demanding treatments
  - Battery can be used in conjunction with solar panels
  - Grid electricity is used as back-up
  - Built-in solar insolation, cloud, and photovoltaic models if data is unavailable
- Simulation of garden irrigation based on solar irradiance and precipitation

## Standalone app with user interface
- Scenario framework: Create different settings combinations or load from a file, simulate in bulk, and save settings, scheme, KPI, and data to files\
\
  <img src="https://github.com/user-attachments/assets/d96aedfd-ca75-401a-bf16-3ebd8f0a63ac" alt="Scenario" width="50%"/>
  <img src="https://github.com/user-attachments/assets/82a0cb79-41ce-4ec3-9201-1fca01ee6dbd" alt="Scenario" width="50%"/>
- Dynamic scheme (see above) automatically adapts to user settings
- High modifiability, easily change up to 112 model variables, for example:
  - Which water quality to reuse and for which applications
  - Which tanks and treatments to install (including volumes, specifications,...)
  - What to do with excess wastewater
- Built-in key performance indicators (KPI) for scenario analysis:
  - Water independence on import, water independence on export, circularity, local water recharge, drought tolerance, energy independence
  - Display KPI in graph (line or spider), choose which KPIs and which scenarios to display\
\
        <img src="https://github.com/user-attachments/assets/72ffc170-1907-4983-9597-546ee2cac3cc" alt="KPI line plot" width="40%"/>
        <img src="https://github.com/user-attachments/assets/1cc3effc-c474-41e9-ab05-7b3a3c3e4dbd" alt="KPI spider plot" width="40%"/>
- Evaluate simulation results in graphs for the volume and concentration of tanks, renewable and grid energy use, and battery capacity

### Example [data](https://github.com/SeppeOngena/Decentralized-House-Model/tree/main/Example%20Data) and [results](https://github.com/SeppeOngena/Decentralized-House-Model/tree/main/Example%20Results) included
### View the [manual](https://github.com/SeppeOngena/Decentralized-House-Model/blob/main/Manual.pdf) for detailed walktrough of app and example workflow
