#--------------------------==============================================-------------------------#
# Sript_Figures.R
#
# Script for the manuscript:
# 
# Linking on-site water recovery options to key resilience drivers using the open OSiRIS tool
#
# Author: Seppe Ongena
# Date: 25/04/2025
#--------------------------==============================================-------------------------#


# 0. Packages and options =========================================================================
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # Set working directory


library(jsonlite)
library(ggplot2)
library(reshape2)
library(lubridate)
library(pracma)
library(ggpubr)
library(ggh4x)
library(readr)

# Colour def.
col_CW <- rgb(68/255, 114/255, 196/255)
col_E <- rgb(255/255, 192/255, 0/255)
col_LGW <- rgb(175/255, 171/255, 171/255)
col_DGW <- rgb(118/255, 113/255, 113/255)
col_BW <- rgb(102/255, 51/255, 0/255)
col_RW <- rgb(91/255, 155/255, 213/255)
col_GA <- rgb(52/255, 134/255, 14/255)
col_PGW_strict <- rgb(173/255, 185/255, 202/255)
col_PW_strict <- rgb(0/255, 176/255, 240/255)
col_PBW <- rgb(213/255, 183/255, 172/255)
col_GWBW <- rgb(195/255, 183/255, 189/255)

ggplot.thema <- function(fntsize = 5,lnwdth = 0.25,mrksize = 0.5,lgd.keysize.cm = 0.8){
  return(theme(panel.border=element_blank(),
               axis.line = element_line(linewidth = lnwdth),
               axis.ticks = element_line(linewidth = lnwdth),
               panel.grid.minor  = element_line(linewidth     = lnwdth,
                                                linetype  = 'solid',
                                                colour    = 'grey95'),
               panel.grid.major  = element_line(linewidth     = lnwdth,
                                                linetype  = 'solid',
                                                colour    = 'grey80'),
               panel.background  = element_rect(fill     = 'white'),
               panel.spacing = unit(2, "lines"),
               text              = element_text(family = "sans", size = fntsize),
               legend.text       = element_text(size = 0.8*fntsize),
               legend.title      = element_text(size = 0.8*fntsize),
               legend.text.align = 0,
               plot.title        = element_text(size = fntsize, face = "bold"),
               axis.title        = element_text(size = fntsize), 
               legend.background = element_rect(fill = alpha("white", 0.0)),
               legend.key.size   = unit(lgd.keysize.cm, 'cm'),
               strip.placement = "outside",
               strip.background.x = element_blank()))
}

func.save.image <- function(filename, plot = last_plot(), SaveAs = '.png', dpi = 1000, width = 6.3, height = 4, transparent = T){
  if(SaveAs==".png"){
    Device <- "png"  
    dpi_fb <- NA
  }else if(SaveAs == ".eps"){
    Device <- cairo_ps
    dpi_fb <- dpi
  }else if(SaveAs == ".pdf"){
    Device <- pdf
    dpi_fb <- NA
  }else if(SaveAs == ".svg"){
    Device <- svg
  } 
  
  if(transparent){
    BG = 'transparent'
  }else{
    BG = NULL
  }
  
  ggsave(filename = paste(filename,SaveAs, sep =""),
         plot = plot,
         width  = width, height = height, units = 'in',
         dpi    = dpi,
         device = Device,
         bg = BG)
}

# Figure dimensions
textwidth <- 8.27-2 # inches, for SI
singlecolumn <- 88/25.4 # inches, for manuscript
doublecolumn <- 180/25.4 # inches, for manuscript


#  1. Simulation and load data ====================================================================
ScenList <- list('0 - Centralized',
                 '1 - Rainwater use',
                 '2 - GW treatment for reuse',
                 '3 - Dec. treatment and infil.',
                 '4 - PW production',
                 '5 - GW reuse and PW production',
                 '6 - Dec. treatment + PW',
                 '7 - Extreme dec.',
                 '8 - Extreme dec. + BW reuse')

ScenNames <- list('0 - Fully centralized',
                  '1 - Rainwater use',
                  '2 - Local greywater reuse',
                  '3 - Local infiltration',
                  '4 - Local potable water',
                  '5 - Decentralized, no infiltration',
                  '6 - Decentralized, no reuse',
                  '7 - Extreme decentralization',
                  '8 - Extreme decentr. (+ BW reuse)')

# Sims
for(sceni in 1:length(ScenList)){
  cmd <- paste0('./Model/OSiRIS-4.0.0.exe "./Settings/',ScenList[sceni],'.json" "./Data/InputDataset.csv" "./Results/',ScenList[sceni],'.csv"')
  print(paste0('Running scenario: ',ScenList[sceni]))
  system(cmd)
}

rm(cmd,sceni)

# Data load
Scenario <- matrix(list(),9,1)
Settings <- matrix(list(),9,1)

for(sceni in 1:length(ScenList)){
  start <- Sys.time()
  Scenario[[sceni]] <- read.csv(paste('Results/',ScenList[sceni],'.csv',sep = ""))
  Scenario[[sceni]] <- Scenario[[sceni]][1:(length(Scenario[[sceni]]$Time)-1),]
  Settings[[sceni]] <- fromJSON(paste('./Settings/',ScenList[sceni],'.json',sep = ""), flatten=F)
  Scenario[[sceni]]$Time <- gsub('([-+][0-9]{2}):([0-9]{2})$','\\1\\2',Scenario[[sceni]]$Time)
  Scenario[[sceni]]$Time <- as.POSIXct(Scenario[[sceni]]$Time,tz = "Europe/Brussels",format="%FT%H:%M:%OS%z")
  print(paste0("Scenario ",ScenList[sceni]," loaded in ",Sys.time()-start, " seconds."))
}

rm(start,sceni)
ggplot(Scenario[[9]],aes(x = Time, y = c_Infiltration))+geom_line()

#  2. Source data =================================================================================

SolarGen <- read.csv("Data/SolarGen.csv")
SolarGen$Time <- gsub('([-+][0-9]{2}):([0-9]{2})$','\\1\\2',SolarGen$Time)
SolarGen$Time <- as.POSIXct(SolarGen$Time,format="%FT%H:%M:%OS%z")

SolarData <- read.csv("Data/SolarData.csv")
SolarData$Time <- gsub('([-+][0-9]{2}):([0-9]{2})$','\\1\\2',SolarData$Time)
SolarData$Time <- as.POSIXct(SolarData$Time,format="%FT%H:%M:%OS%z")

Rain <- read.csv("Data/Rain.csv")
Rain$Time <- gsub('([-+][0-9]{2}):([0-9]{2})$','\\1\\2',Rain$Time)
Rain$Time <- as.POSIXct(Rain$Time,format="%FT%H:%M:%OS%z")

CloudsGen <- read.csv("Data/CloudsGen.csv")
CloudsGen$Time <- gsub('([-+][0-9]{2}):([0-9]{2})$','\\1\\2',CloudsGen$Time)
CloudsGen$Time <- as.POSIXct(CloudsGen$Time,format="%FT%H:%M:%OS%z")

Q_appl <- read.csv("Data/Q_appl.csv")
Q_appl$Time <- gsub('([-+][0-9]{2}):([0-9]{2})$','\\1\\2',Q_appl$Time)
Q_appl$Time <- as.POSIXct(Q_appl$Time,format="%FT%H:%M:%OS%z")


#  3. Data processing =============================================================================

nyears <- as.numeric(Rain$Time[length(Rain$Time)]-Rain$Time[1],units="days")/365;
IE <- Settings[[1]]$Scenario$Applications$TL$IE; # Inhabitant equivalents

# Init empty dfs
E_use <- data.frame(Scenario = NULL, E_ROPW = NULL, E_MBRGW = NULL, E_MBRBW = NULL, E_ROGWBW = NULL, E_pump = NULL,E_PumpRW = NULL,E_PumpPW = NULL,E_PumpPGW = NULL,E_PumpGW = NULL,E_PumpBW = NULL); # kWh / p / year
Q_use <-data.frame(Scenario = NULL, Q_ROPW = NULL, Q_MBRGW = NULL, Q_MBRBW = NULL, Q_ROGWBW = NULL, Q_pump = NULL, Q_PumpRW = NULL,  Q_PumpPW = NULL, Q_PumpPGW = NULL, Q_PumpGW = NULL, Q_PumpBW = NULL); # m³ / p / year
E_use_specific <- data.frame(Scenario = NULL, E_use_specific_CW = NULL, E_use_specific = NULL, CW_use = NULL); # kWh / m³ CW saved / year, kWh/m³ treated / year, and m³ / person / year
KPI <-  data.frame(Scenario = NULL, WIFI = NULL,WIFE = NULL,CF = NULL, RCF = NULL, DTF = NULL, EIF = NULL, BCF = NULL);
CW_use <- zeros(9,1)

# Fetch energy use of treatment kWh/p/y
FetchTreatment_E_use <- function(treatmentname,Scenario,Settings){
  IE <- Settings$Applications$TL$IE;
  nyears <- as.numeric(Scenario$Time[length(Scenario$Time)]-Scenario$Time[1],units="days")/365;
  if(any(names(Settings$Technologies)==treatmentname)){
    return(sum(Scenario[[strcat("Q_",treatmentname)]]*Settings$Technologies[[treatmentname]]$E/(IE*nyears)));
  }
  else{
    return(0);
  }
}

# Fetch flow of treatment m³/p/y
FetchTreatment_Q_use <- function(treatmentname,Scenario,Settings){
  IE <- Settings$Applications$TL$IE;
  nyears <- as.numeric(Scenario$Time[length(Scenario$Time)]-Scenario$Time[1],units="days")/365;
  if(any(names(Settings$Technologies)==treatmentname)){
    return(sum(Scenario[[strcat("Q_",treatmentname)]]/(IE*nyears)));
  }
  else if(treatmentname == "pump"){
    return((sum(Scenario[["Q_PumpRW"]])+sum(Scenario[["Q_PumpPW"]])+sum(Scenario[["Q_PumpPGW"]])+sum(Scenario[["Q_PumpGW"]])+sum(Scenario[["Q_PumpBW"]]))/(IE*nyears));
  } else {
    return(0);
  }
}

# Init application names
applnames = list('TL','BT','SH','BS','WM','DW','KS','CL','GA');

# Calculations for all scenarios
for(sceni in 1:9){
  # Fetch settings and data
  ScenSettings <- Settings[[sceni]]$Scenario;
  Scen <- Scenario[[sceni]];
  
  # Get installed tanknames
  tanknames <- {};
  if("Tanks"%in%names(ScenSettings)){
  tanknames = names(ScenSettings$Tanks);
  }
  
  # Get installed technology names
  treatnames <- {};
  if("Technologies"%in%names(ScenSettings)){
  treatnames = names(ScenSettings$Technologies);
  }
  
  # Get variable names from data
  varnames = names(Scen);
  
  # Assign energy use
  E_use <- rbind(E_use, data.frame(
    Scenario = ScenList[[sceni]],
    E_ROPW = FetchTreatment_E_use("ROPW",Scen,ScenSettings),
    E_MBRGW = FetchTreatment_E_use("MBRGW",Scen,ScenSettings),
    E_MBRBW = FetchTreatment_E_use("MBRBW",Scen,ScenSettings),
    E_ROGWBW = FetchTreatment_E_use("ROGWBW",Scen,ScenSettings),
    E_pump = sum(Scen$E_use_Renewable+Scen$E_use_Grid)/(IE*nyears),
    E_PumpRW = FetchTreatment_E_use("PumpRW",Scen,ScenSettings),
    E_PumpPW = FetchTreatment_E_use("PumpPW",Scen,ScenSettings),
    E_PumpPGW = FetchTreatment_E_use("PumpPGW",Scen,ScenSettings),
    E_PumpGW = FetchTreatment_E_use("PumpGW",Scen,ScenSettings),
    E_PumpBW = FetchTreatment_E_use("PumpBW",Scen,ScenSettings)))
  
  # Assign flow use
  Q_use <- rbind(Q_use, data.frame(
    Scenario = ScenList[[sceni]],
    Q_ROPW = FetchTreatment_Q_use("ROPW",Scen,ScenSettings),
    Q_MBRGW = FetchTreatment_Q_use("MBRGW",Scen,ScenSettings),
    Q_MBRBW = FetchTreatment_Q_use("MBRBW",Scen,ScenSettings),
    Q_ROGWBW = FetchTreatment_Q_use("ROGWBW",Scen,ScenSettings),
    Q_pump = FetchTreatment_Q_use("pump",Scen,ScenSettings),
    Q_PumpRW = FetchTreatment_Q_use("PumpRW",Scen,ScenSettings),
    Q_PumpPW = FetchTreatment_Q_use("PumpPW",Scen,ScenSettings),
    Q_PumpPGW = FetchTreatment_Q_use("PumpPGW",Scen,ScenSettings),
    Q_PumpGW = FetchTreatment_Q_use("PumpGW",Scen,ScenSettings),
    Q_PumpBW = FetchTreatment_Q_use("PumpBW",Scen,ScenSettings)))
  
  # Calculate pump energy use as remainder
  E_use$E_pump[E_use$Scenario==ScenList[[sceni]]] <- E_use$E_pump[E_use$Scenario==ScenList[[sceni]]]-sum(E_use[E_use$Scenario==ScenList[[sceni]],2:5])
  
  # Fetch city water use (m³/p/y)
  CW_use[sceni] <-  sum(Scenario[[sceni]]$Q_CityWater)/(IE*nyears)
  
  # Calculate specific enery use (kWh/m³ city water saved)
  E_use_specific <- rbind(E_use_specific, data.frame(
    Scenario = ScenList[[sceni]],
    CW_use = CW_use[sceni],
    E_use_specific_CW = ifelse(sceni==1,0,sum(E_use[sceni,2:6])/(CW_use[1]-CW_use[sceni])),
    E_use_specific = NA
  ))
  
  # KPI calculation
  Q_RW_out <- data.frame(month_id = month(Scenario[[sceni]]$Time)+12*year(Scenario[[sceni]]$Time),Q_RW_out = zeros(length(Scenario[[sceni]]$Time),1))
  V_WW_prod = 0;
  
  for(i in 1:length(applnames)){
    if(ScenSettings$Applications[[applnames[[i]]]]$Sourcewater=="RW"){
    Q_RW_out$Q_RW_out <- Q_RW_out$Q_RW_out + Scen[[strcat('Q_',applnames[[i]])]];
    }
    if(!("GA"==applnames[[i]])){
    V_WW_prod = V_WW_prod + sum(Scen[[strcat('Q_',applnames[[i]])]]);
    }
  }
  
  if("Q_RWPW_Treat"%in%varnames){
    Q_RW_out$Q_RW_out = Q_RW_out$Q_RW_out + Scen$Q_RWPW_Treat;
  }
  
  if("Q_RWPGW_Treat"%in%varnames){
    Q_RW_out$Q_RW_out = Q_RW_out$Q_RW_out + Scen$Q_RWPGW_Treat;
  }
  
  if("Q_Purge_Purge"%in%varnames){
    Q_RW_out$Q_RW_out = Q_RW_out$Q_RW_out + Scen$Q_Purge_Purge;
  }
  
  V_RW_out_all = sum(Q_RW_out$Q_RW_out);
  
  V_infil = 0;
  V_infil_monthly = 0;
  if("Q_Infiltration"%in%varnames){
    V_infil = sum(Scen$Q_Infiltration);
    V_infil_monthly <- data.frame(month_id = month(Scen$Time)+12*year(Scen$Time),V_infil = Scen$Q_Infiltration)
  }
 
  
  V_sewer = 0;
  if("Q_Sewer"%in%varnames){
    V_sewer = sum(Scen$Q_Sewer);
  }
  
  V_truck = 0;
  if("Q_Truck"%in%varnames){
    V_truck = sum(Scen$Q_Truck);
  }
  
  rGW = 1;
  rBW = 1;
  if(!isempty(treatnames)){
  if("MBRGW"%in%treatnames){
    rGW = rGW*ScenSettings$Technologies$MBRGW$r;
  }
  if("MBRBW"%in%treatnames){
    rBW = rBW*ScenSettings$Technologies$MBRBW$r;
  }
  if("ROGWBW"%in%treatnames){
  rBW = rBW*ScenSettings$Technologies$ROGWBW$r;
  rGW = rGW*ScenSettings$Technologies$ROGWBW$r;
  }
  }
  V_reuse = 0;
  if("Q_GWPGW_emptyGW_Treat"%in%varnames){
    V_reuse = V_reuse + rGW*sum(Scen$Q_GWPGW_emptyGW_Treat);
  }
  if("Q_GWPGW_refillPGW_Treat"%in%varnames){
    V_reuse = V_reuse + rGW*sum(Scen$Q_GWPGW_refillPGW_Treat);
  }
  if("Q_BWPGW_Treat"%in%varnames){
    V_reuse = V_reuse + rBW*sum(Scen$Q_BWPGW_Treat);
  }
  
  V_RW_out_monthly <- aggregate(.~month_id,data = Q_RW_out,FUN=sum);
  V_RW_out_peak <- max(V_RW_out_monthly$Q_RW_out);

  
  V_infil_monthly <- aggregate(.~month_id,data = V_infil_monthly,FUN=sum)$V_infil;
  
  
  if("E_use_Renewable"%in%varnames){
    E_use_Renewable = sum(Scen$E_use_Renewable);
  } else {
    E_use_Renewable = 0;
  }
  
  E_use_Grid <- sum(Scen$E_use_Grid)
  E_use_total <- E_use_Renewable+E_use_Grid;
  
  
  
  KPI <- rbind(KPI,data.frame(
    Scenario = ScenList[[sceni]],
    WIFI =  V_RW_out_all/(V_RW_out_all+sum(Scen$Q_CityWater)),
    WIFE = V_infil/(V_infil+V_sewer+V_truck),
    CF   = V_reuse/V_WW_prod,
    RCF  = V_infil/sum(Scen$Q_Roof),
    DTF  = ifelse(V_RW_out_peak ==0,0,(ScenSettings$Tanks$RW$V_tank/V_RW_out_peak)),
    EIF  = ifelse(E_use_total==0,ifelse("E_use_Renewable"%in%varnames,1,0),E_use_Renewable/E_use_total),
    BCF  = 1-min(sum(abs(mean(V_infil_monthly)-V_infil_monthly)/mean(V_infil_monthly))/(nyears*12),1)
  ))
  
  print(paste("Scenario calculations",sceni,"done."))
}

# Subtotals for energy use:
E_use$E_treatments = E_use$E_MBRBW+E_use$E_ROPW+E_use$E_MBRGW+E_use$E_ROGWBW
E_use$E_total = E_use$E_pump+E_use$E_treatments
E_use_specific$E_use_specific <- (E_use$E_ROPW + E_use$E_MBRGW + E_use$E_MBRBW+E_use$E_ROGWBW + E_use$E_pump)/(Q_use$Q_ROPW + Q_use$Q_MBRGW + Q_use$Q_MBRBW+Q_use$Q_ROGWBW + Q_use$Q_pump)
E_use <- E_use[,c(1:5,12,7:11,6,13)] # reorder

# Check KPI and E_use (SI tables 4.1 and 4.2)
KPI
E_use

rm(i,nyears, IE, sceni, FetchTreatment_E_use,FetchTreatment_Q_use,E_use_Grid,E_use_total,E_use_Renewable,V_infil,
   V_infil_monthly,V_reuse,V_RW_out_all,V_RW_out_peak,V_sewer,V_truck,V_WW_prod,varnames,rGW,rBW,tanknames,treatnames,
   V_RW_out_monthly,ScenSettings,Scen,Q_RW_out,applnames,Q_use,CW_use)

#  4. Plots =======================================================================================
# . . 4.2 KPI results -----------------------------------------------------------------------------

# Plot options
KPIsel <- c(T,T,T,T,T,T,F); # Not the BCF
KPIlabeller <- as_labeller(c(`WIFI` = "WI:I (%)", `WIFE` = "WI:E (%)",`CF` = "CI (%)", `RCF` = "RC (%)", `DTF` = "DT (months)", `EIF` = "EI (%)", `BF` = "BF (%)"))
colplot <- c('#5B9BD5','#663300','#4472C4','#70AD47','#C55A11','#FFC000','#663300')

library(grImport)
library(egg)
#EPS_WIFI <- PostScriptTrace("Figures/KPI_icons/WIFI.eps","Figures/KPI_icons/WIFI.xml")
#EPS_WIFE <- PostScriptTrace("Figures//KPI_icons/WIFE.eps","Figures/KPI_icons/WIFE.xml")
#EPS_CF <- PostScriptTrace("Figures/KPI_icons/CF.eps","Figures/KPI_icons/CF.xml")
#EPS_RCF <- PostScriptTrace("Figures/KPI_icons/RCF.eps","Figures/KPI_icons/RCF.xml")
#EPS_DTF <- PostScriptTrace("Figures/KPI_icons/DTF.eps","Figures/KPI_icons/DTF.xml")
#EPS_EIF <- PostScriptTrace("Figures/KPI_icons/EIF.eps","Figures/KPI_icons/EIF.xml")

# Data frame for plotting icons at each KPI
grobs = data.frame(variable = c("WIFI", "WIFE", "CF","RCF","DTF","EIF"),
                   Scenario = c(1,1,1,1,1,1),
                   value = c(50,50,50,100,3,50),
                   data = c('Figures/KPI_icons/WIFI.xml',
                            'Figures/KPI_icons/WIFE.xml',
                            'Figures/KPI_icons/CF.xml',
                            'Figures/KPI_icons/RCF.xml',
                            'Figures/KPI_icons/DTF.xml',
                            'Figures/KPI_icons/EIF.xml'))
grobs$variable <- as.factor(grobs$variable)

# Function to read grobs
grobber <- function(img){
  pGrob <- pictureGrob(readPicture(img),width = 0.35,height=0.35,y=-0.15)
  pGrob$x <- unit(0.5, "npc")
  pGrob$y <- unit(0.5, "npc")
  return(pGrob) 
}

# Vertical lines for relevant KPI
xideal <- data.frame(variable = c('WIFI','WIFE','RCF','EIF'), value = c(100,100,100,100))
xideal$variable <- as.factor(xideal$variable)

# Percentages
KPIplot <- melt(data = KPI[,c(T,KPIsel)],id.vars = c("Scenario"))
KPIplot[KPIplot$variable!="DTF",]$value <- KPIplot[KPIplot$variable!="DTF",]$value*100

# Plot
ggplot(KPIplot,aes(x=Scenario,y=value,fill = variable, col=variable,group=variable))+
  geom_col(width = 1)+
  coord_flip(clip='off')+
  labs(x="",y="",col="",fill="")+
  facet_grid2(.~variable,independent = "x",scales="free",labeller = KPIlabeller, switch = "x")+
  facetted_pos_scales(
    y = list(scale_y_continuous(breaks = c(0,100),limits = c(0,100)),
             scale_y_continuous(breaks = c(0,100),limits = c(0,100)),
             scale_y_continuous(breaks = c(0,100),limits = c(0,100)),
             scale_y_continuous(breaks = c(0,100,200),limits = c(0,200)),
             NULL,
             scale_y_continuous(breaks = c(0,100),limits = c(0,100)))
  )+
  geom_hline(data = xideal, aes(yintercept=value),linewidth = 0.5)+
  scale_x_discrete(labels = ScenNames)+
  scale_color_manual(values = colplot[KPIsel])+
  scale_fill_manual(values = colplot[KPIsel])+
  ggplot.thema(fntsize = 7,lgd.keysize.cm = 0.4)+
  geom_custom(data = grobs, aes(data = data),grob_fun = grobber)+
  theme(panel.grid.major.y = element_blank(),legend.position = "none", panel.spacing = unit(1, "lines"),
        strip.text.x = element_text(margin = margin(20,1,1,1,"pt")),axis.line.y = element_blank(),axis.title.x = element_blank())#margin(0,0,0,0,"pt"))

func.save.image(filename = 'Figures/FIG02_ScenarioKPI',SaveAs = ".svg", width = doublecolumn,height = doublecolumn/3)

rm(KPIsel,KPIlabeller,colplot,grobs,grobber,xideal,KPIplot,EPS_WIFI,EPS_WIFE,EPS_RCF,EPS_EIF,EPS_DTF,EPS_CF)

# . . 4.3 Renewable energy ------------------------------------------------------------------------------------------------------------------

scenlist <- c(3,6,9) # Which scenarios to plot, 2,5,8
EnergyPlot <- data.frame(Time = NULL, Scenario = NULL, month_id = NULL, E_use_grid = NULL, E_use_renewable = NULL, E_solar = NULL) # init

# Fetch grid use, renewable use, and solar power
for(ibal in scenlist){
  EnergyPlot <- rbind(EnergyPlot,data.frame(Time = Scenario[[ibal]]$Time,
                                            Scenario = ScenList[[ibal]],
                                            month_id = month(Scenario[[ibal]]$Time)+12*year(Scenario[[ibal]]$Time),
                                            E_use_grid = Scenario[[ibal]]$E_use_Grid,
                                            E_use_renewable = Scenario[[ibal]]$E_use_Renewable,
                                            E_solar = SolarGen$E_solar*
                                              Settings[[ibal]]$Scenario$EnergyManagementSystems$Renewable$Generators$SolarPanels$kWp_panels*
                                              Settings[[ibal]]$Scenario$EnergyManagementSystems$Renewable$Generators$SolarPanels$eta_inverter*
                                              Settings[[ibal]]$Scenario$EnergyManagementSystems$Renewable$Generators$SolarPanels$eta_heat))
}

# Monthly sum
EP <- aggregate(.~month_id+Scenario,data = EnergyPlot,FUN=sum);
EP$Time <- aggregate(.~month_id+Scenario,data = EnergyPlot,FUN=mean)$Time;
EnergyPlot <- EP
EnergyPlot$month_id <- NULL
EnergyPlot <- melt(EnergyPlot,id.vars = c("Time","Scenario"))
EnergyPlot$Time <- as.POSIXct(EnergyPlot$Time,origin = "1970-01-01",tz = "Europe/Brussels")

ScenLabeller <- as_labeller(c(`5 - GW reuse and PW production` = "Scenario 5", `2 - GW treatment for reuse` = "Scenario 2",`8 - Extreme dec. + BW reuse` = "Scenario 8"))

ggplot(EnergyPlot,aes(group=variable,x=Time,y=value))+
  geom_line(data = EnergyPlot[EnergyPlot$variable=="E_solar",],aes(x=Time,y=value,col = variable),linewidth=0.2)+
  geom_area(data = EnergyPlot[EnergyPlot$variable!="E_solar",],aes(x=Time,y=value,fill = variable),alpha = 0.5)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(lim = c(0,80),expand = c(0,0),breaks = scales::pretty_breaks(n=4))+
  facet_grid2(Scenario~.,switch="y",labeller = labeller(Scenario = ScenLabeller))+
  scale_color_manual(values = c(rgb(0.6, 0, 0)),labels = c('Solar panel power'))+
  scale_fill_manual(values = c(rgb(0.46, 0.44, 0.44),rgb(1, 0.75, 0)),labels = c('Grid energy use','Renewable energy use'))+
  labs(col="",fill = "",y = 'Monthly solar power and energy use (kWh)')+
  ggplot.thema(fntsize = 5,lgd.keysize.cm = 0.3)+
  theme(panel.spacing = unit(0.75, "lines"),
        strip.text.y = element_text(margin = margin(2,2,2,2,"pt")),
        legend.spacing.y = unit(2,'pt'),
        legend.box.margin = margin(0,0,0,0,"pt"),
        legend.box.spacing = unit(5,'pt'),
        legend.margin = margin(0,0,0,0,'pt'))

func.save.image(filename = 'Figures/FIG03_E_balance',SaveAs = ".pdf", width = singlecolumn,height = singlecolumn)

rm(ibal,EP,EnergyPlot,ScenLabeller,scenlist)


# . . 4.4 Energy use ------------------------------------------------------------------------------

E_use$E_total

E_use_labels = c('Potable water treatment', 'Greywater treatment', 'Blackwater treatment','Combined treatment','Pump energy (no treatment)');
E_use_plot <- melt(data = E_use[,c(1:5,12)],id.vars = c("Scenario"))


ggplot(E_use_plot,aes(x=Scenario, y=value,fill = variable))+
  geom_col(position =  position_stack(reverse=T))+
  coord_flip()+
  scale_fill_manual(labels = E_use_labels, values = c(col_PW_strict,col_DGW,col_BW,col_GWBW,col_E))+
  scale_x_discrete(labels = ScenNames)+
  xlab("")+
  ylab(expression('Energy use'~(kWh%.%person^-1%.%year^-1)))+
  labs(fill = "")+
  ylim(c(0,300))+
  ggplot.thema(fntsize = 5,lgd.keysize.cm = 0.3)+
  theme(legend.box.margin = margin(0,0,0,0,"pt"),
        legend.box.spacing = unit(5,'pt'),
        legend.margin = margin(0,0,0,0,'pt'))
 
func.save.image(filename = 'Figures/FIG04_E_use',SaveAs = ".pdf", width = singlecolumn,height = singlecolumn*2/3)

rm(E_use_labels,E_use_plot)


# . . 4.5 Water tank vs infil and balance and everything ------------------------------------------

scen <- 8; # scenario to plot 7 - Extreme decentralization

# Monthly precipitation
RainPlot = data.frame(Time = Rain$Time,month_id = month(Rain$Time)+12*year(Rain$Time), Q_rain = Rain$Q_rain*Settings[[scen]]$Scenario$Sources$Roof$A*Settings[[scen]]$Scenario$Sources$Roof$eta_rain);
RP = aggregate(.~month_id, data = RainPlot,FUN = sum);
RP$Time = aggregate(.~month_id,data = RainPlot,FUN=mean)$Time;
RP$Time_start = aggregate(.~month_id,data = RainPlot,FUN=min)$Time;
RP$Time_end = aggregate(.~month_id,data = RainPlot,FUN=max)$Time;
RainPlot <- RP
RainPlot$Time <- as.POSIXct(RainPlot$Time,origin = "1970-01-01",tz = "Europe/Brussels")
RainPlot$Time_start <- as.POSIXct(RainPlot$Time_start,origin = "1970-01-01",tz = "Europe/Brussels")
RainPlot$Time_end <- as.POSIXct(RainPlot$Time_end,origin = "1970-01-01",tz = "Europe/Brussels")

# Refill times
t_refill <- Scenario[[scen]]$n_refill;
t_refill[-1] <- Scenario[[scen]]$n_refill[-1]-Scenario[[scen]]$n_refill[-length(t_refill)];
t_refill <- Scenario[[scen]]$Time[which(as.logical(t_refill))];

# Monthly infiltration
InfilPlot <- data.frame(Time = Scenario[[scen]]$Time,month_id = month(Scenario[[scen]]$Time)+12*year(Scenario[[scen]]$Time), Q_infil = Scenario[[scen]]$Q_Infiltration)
IP = aggregate(.~month_id, data = InfilPlot,FUN = sum);
IP$Time = aggregate(.~month_id,data = InfilPlot,FUN=mean)$Time;
IP$Time_start = aggregate(.~month_id,data = InfilPlot,FUN=min)$Time;
IP$Time_end = aggregate(.~month_id,data = InfilPlot,FUN=max)$Time;
InfilPlot <- IP
InfilPlot$Time <- as.POSIXct(InfilPlot$Time,origin = "1970-01-01",tz = "Europe/Brussels")
InfilPlot$Time_start <- as.POSIXct(InfilPlot$Time_start,origin = "1970-01-01",tz = "Europe/Brussels")
InfilPlot$Time_end <- as.POSIXct(InfilPlot$Time_end,origin = "1970-01-01",tz = "Europe/Brussels")

# Daily mean infiltration concentration
InfilConcPlot <- data.frame(Time = Scenario[[scen]]$Time,day_id = yday(Scenario[[scen]]$Time)+365*year(Scenario[[scen]]$Time), c_infil = Scenario[[scen]]$c_Infiltration,V_infil = Scenario[[scen]]$Q_Infiltration, m_infil = Scenario[[scen]]$Q_Infiltration*Scenario[[scen]]$c_Infiltration)
ICP = aggregate(.~day_id, data = InfilConcPlot[InfilConcPlot$V_infil!=0,],FUN = sum);
ICP$Time = aggregate(.~day_id,data = InfilConcPlot[InfilConcPlot$V_infil!=0,],FUN=mean)$Time;
InfilConcPlot <- ICP
InfilConcPlot$Time <- as.POSIXct(InfilConcPlot$Time,origin = "1970-01-01",tz = "Europe/Brussels")

# Check if norm distributed
qqnorm(InfilConcPlot$m_infil/InfilConcPlot$V_infil)
qqline(InfilConcPlot$m_infil/InfilConcPlot$V_infil)
# No, so mean, min, max (no SD)
mean(InfilConcPlot$m_infil/InfilConcPlot$V_infil,na.rm = T) # used in manuscript
min(InfilConcPlot$m_infil/InfilConcPlot$V_infil,na.rm = T) # used in manuscript
max(InfilConcPlot$m_infil/InfilConcPlot$V_infil,na.rm = T) # used in manuscript

# Same but for scenario 8 -Extreme dec. (+ BW reuse)
InfilConcPlot9 <- data.frame(Time = Scenario[[9]]$Time,day_id = yday(Scenario[[9]]$Time)+365*year(Scenario[[9]]$Time), c_infil = Scenario[[9]]$c_Infiltration, V_infil = Scenario[[9]]$Q_Infiltration, m_infil = Scenario[[9]]$Q_Infiltration*Scenario[[9]]$c_Infiltration)
ICP9 = aggregate(.~day_id, data = InfilConcPlot9[InfilConcPlot9$V_infil!=0,],FUN = sum);
ICP9$Time = aggregate(.~day_id,data = InfilConcPlot9[InfilConcPlot9$V_infil!=0,],FUN=mean)$Time;
InfilConcPlot9 <- ICP9
InfilConcPlot9$Time <- as.POSIXct(InfilConcPlot9$Time,origin = "1970-01-01",tz = "Europe/Brussels")

qqnorm(InfilConcPlot9$m_infil/InfilConcPlot9$V_infil)
qqline(InfilConcPlot9$m_infil/InfilConcPlot9$V_infil)
mean(InfilConcPlot9$m_infil/InfilConcPlot9$V_infil,na.rm = T) # used in manuscript
min(InfilConcPlot9$m_infil/InfilConcPlot9$V_infil,na.rm = T) # used in manuscript
max(InfilConcPlot9$m_infil/InfilConcPlot9$V_infil,na.rm = T) # used in manuscript

# Rainwater tank level
p1 <- ggplot(data.frame(Time = Scenario[[scen]]$Time, V_RW = Scenario[[scen]]$RW_V),aes(x = Time, y = V_RW))+
  geom_line(col = rgb(0, 0, 0.6),linewidth = 0.15)+
  scale_y_continuous(limits = c(0,10),expand = c(0,0))+
  labs(y = expression(Level~(m^3)))+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  ggplot.thema(fntsize = 7,lgd.keysize.cm = 0.4)+
  theme(axis.title.x = element_blank(),axis.text.x = element_blank(),axis.ticks.x = element_blank())

# Precipitation
p2 <- ggplot(RainPlot,aes(x = Time, y=Q_rain))+
  geom_rect(data = RainPlot,aes(xmin = Time_start,xmax = Time_end, ymin = 0, ymax = Q_rain),fill = rgb(0.1,0.6,0),alpha = 0.6)+
  scale_y_continuous(limits = c(0,max(RainPlot$Q_rain)*1.05),expand = c(0,0))+
  labs(y = expression(Precipitation~(m^3)))+
  scale_x_datetime(lim = c(as.POSIXct("2014-12-31",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  ggplot.thema(fntsize = 7,lgd.keysize.cm = 0.4)+
  theme(axis.title.x = element_blank(),axis.text.x = element_blank(),axis.ticks.x = element_blank())

# Rainwater tank chloride concentration
p3 <- ggplot(data.frame(Time = Scenario[[scen]]$Time, c_RW = Scenario[[scen]]$RW_c),aes(x = Time, y = c_RW))+
  geom_line(col = rgb(0, 0, 0.6),linewidth = 0.15)+
  scale_y_continuous(limits = c(0,max(Scenario[[scen]]$RW_c)*1.05),expand = c(0,0))+
  labs(y =  expression(Cl^{-phantom(1)}~concentration~(mg%.%L^-1)))+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  ggplot.thema(fntsize = 7,lgd.keysize.cm = 0.4)

# Left column
p123 <- ggpubr::ggarrange(plotlist = list(p1,p2,p3),nrow = 3,heights = c(2/7,2/7,3/7),align = "v")
p123 <- p123+ theme(plot.margin =  margin(t=30,r=15,b=0,l=0,'pt'))

# Infiltration and precipitation overlay
p4 <-  ggplot(InfilPlot,aes(x = Time, y = Q_infil))+
  geom_rect(data = InfilPlot,aes(xmin = Time_start, xmax = Time_end, ymin = 0, ymax = Q_infil), fill = rgb(0,0,0.6),alpha = 0.6)+
  geom_rect(data = RainPlot,aes(xmin = Time_start,xmax = Time_end, ymin = 0, ymax = Q_rain),fill = rgb(0.1,0.6,0),alpha = 0.6, inherit.aes = F)+
  scale_y_continuous(name = expression(Infiltration~(m^3)),limits = c(0,max(InfilPlot$Q_infil)*1.05),expand = c(0,0),sec.axis = sec_axis(transform = ~.*1,name = expression(Precipitation~(m^3))))+
  scale_x_datetime(lim = c(as.POSIXct("2015-12-31",tz="Europe/Brussels"),as.POSIXct("2025-01-02",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  ggplot.thema(fntsize = 7,lgd.keysize.cm = 0.4)+
  theme(axis.title.x = element_blank(),axis.text.x = element_blank(),axis.ticks.x = element_blank(),
        axis.title.y.left = element_text(colour = rgb(0,0,0.6)),
        axis.line.y.left = element_line(colour = rgb(0,0,0.6)),
        axis.ticks.y.left = element_line(colour = rgb(0,0,0.6)),
        axis.text.y.left = element_text(colour = rgb(0,0,0.6)),
        axis.title.y.right = element_text(colour = rgb(0.1,0.6,0)),
        axis.line.y.right = element_line(colour = rgb(0.1,0.6,0)),
        axis.ticks.y.right = element_line(colour = rgb(0.1,0.6,0)),
        axis.text.y.right = element_text(colour = rgb(0.1,0.6,0)))

# Daily mean infiltration concentration plot
p5 <- ggplot(InfilConcPlot,aes(x = Time, y = m_infil/V_infil))+
  geom_line(col = rgb(0, 0, 0.6),linewidth = 0.15)+
  scale_y_continuous(limits = c(0,max(InfilConcPlot$m_infil/InfilConcPlot$V_infil)*1.05),expand = c(0,0))+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  labs(y = expression(Cl^{-phantom(1)}~concentration~(mg%.%L^-1)))+
  ggplot.thema(fntsize = 7,lgd.keysize.cm = 0.4)


# Right column
p45 <- ggpubr::ggarrange(plotlist = list(p4,p5),nrow = 2,heights = c(4/7,3/7),align = "v")
p45 <- p45+ theme(plot.margin =   margin(t=30,r=0,b=0,l=15,'pt'))

ggpubr::ggarrange (plotlist = list(p123,p45),nrow = 1,ncol = 2, align = "h",
                   labels=c("Rainwater tank","Infiltration basin"), label.x = c(0.275,0.255),label.y = c(0.965,0.965),font.label = list(size =9))

func.save.image(filename = 'Figures/FIG05_RW_and_Infiltration_V_and_c',SaveAs = ".pdf", width = doublecolumn,height = doublecolumn*2/3)

# About 800mm precipitation
RainYearly = aggregate(.~year(Time), data = Rain,FUN = sum);
RainYearly$Time <- NULL
RainYearly$Q_rain<- NULL
RainYearly


rm(RainYearly,RP,RainPlot,p1,p2,p3,p4,p5,p123,p45,InfilPlot,InfilConcPlot,InfilConcPlot9,IP,ICP,ICP9,scen,t_refill)

# . . 4.6 Specific energy vs CW use ---------------------------------------------------------------

E_use_specific$Scenario <- as.factor(E_use_specific$Scenario)
E_use_specific_Plot <- melt(E_use_specific,id.vars = c("Scenario"))
E_use_specific_Plot$value[E_use_specific_Plot$Scenario=="0 - Centralized" & E_use_specific_Plot$variable=="E_use_specific"] <- 0

# positioning of plot x axes, as 'atop()' had ridiculous spacing
strip.x.texts = data.frame(variable = c("CW_use", "CW_use", "E_use_specific_CW","E_use_specific_CW"),
                   Scenario = c(E_use_specific$Scenario[1],E_use_specific$Scenario[1],E_use_specific$Scenario[1],E_use_specific$Scenario[1]),
                   value = c(20,20,4,4),
                   vju = c(5,5.1,5,5.1),
                   data = c('City~water~use',"'(m'^3%.%person^-1%.%year^-1*')'",'Specific~energy~use', "'(kWh'%.%'m'^-3~'city water saved)'"))

ggplot(E_use_specific_Plot[E_use_specific_Plot$variable!="E_use_specific",],aes(x=Scenario, y=value,group =variable,col=variable))+
  geom_line(linewidth = 0.2)+
  geom_line(data = NULL, aes(y = c(rep(NA,9),rep(1,9))),color = 'red3',linewidth = 0.2,na.rm = T)+
  facet_grid2(.~variable,independent = "x",scales="free", switch = "x")+
  coord_flip(clip='off')+
  xlab("")+
  ylab("")+
  scale_color_manual(values = c(col_CW,col_E))+
  scale_x_discrete(labels = ScenNames)+
  #ylab(expression('Energy use'~(kWh%.%person^-1%.%year^-1)))+
  guides(col="none")+#labs(fill = "")+
  ggplot.thema(fntsize = 5,lgd.keysize.cm = 0.3)+
  theme(panel.spacing = unit(0.75, "lines"),
        strip.text = element_blank(),
        plot.margin = margin(0,0,10,0,unit='pt'))+
  geom_text(data = strip.x.texts, aes(y =value, x = Scenario, label = data,vjust = vju), size = 5,size.unit = 'pt', col="black",parse = T)

func.save.image(filename = 'Figures/FIG06_CW_saved_vs_E_specific',SaveAs = ".pdf", width = singlecolumn,height = singlecolumn/2)

E_use_belgium <- 80974*1e6  # kWh, statbel (residential)
n_p_belgium <- 11.8e6 # persons

E_use_belgium/n_p_belgium # 6862, no additional energy use
E_use_belgium/n_p_belgium+E_use$E_total[9] # 7122, most intensive treatment scenario
# --> 7000 in manuscript

perct_1 <- mean(E_use$E_total[3:5])/(E_use_belgium/n_p_belgium+mean(E_use$E_total[3:5]))*100 # used in manuscript
perct_2 <- E_use$E_total[9]/(E_use_belgium/n_p_belgium+E_use$E_total[9])*100 # used in manuscript


rm(E_use_belgium,n_p_belgium,perct_1,perct_2,strip.x.texts,E_use_specific_Plot)



# 5. Plots for SI =================================================================================

# . . 5.1 Day type distribution of clouds ---------------------------------------------------------

# Daily mean
CloudsGen$day_id <- yday(CloudsGen$Time)+year(CloudsGen$Time)*365;
CloudsGen_daily <- aggregate(.~day_id,data = CloudsGen,FUN=mean);
CloudsGen_daily$Time_start <- aggregate(.~day_id,data = CloudsGen,FUN=min)$Time;
CloudsGen_daily$Time_end <- aggregate(.~day_id,data = CloudsGen,FUN=max)$Time;
CloudsGen_daily$Time <- as.POSIXct(CloudsGen_daily$Time,origin = "1970-01-01",tz = "Europe/Brussels")
CloudsGen_daily$Time_start <- as.POSIXct(CloudsGen_daily$Time_start,origin = "1970-01-01",tz = "Europe/Brussels")
CloudsGen_daily$Time_end <- as.POSIXct(CloudsGen_daily$Time_end,origin = "1970-01-01",tz = "Europe/Brussels")

# Melt for plot
CloudsGen_daily_distribution <- melt(CloudsGen_daily[,c(1:5,9:10)],id.vars = c('day_id','Time','Time_start','Time_end'))

ggplot(CloudsGen_daily_distribution,aes(x= Time, y = value, fill = variable))+
  geom_rect(aes(xmin=Time_start,xmax = Time_end,ymin = 0, ymax = value))+
  scale_y_continuous(limits = c(0,1),expand = c(0,0))+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_fill_manual(values = c(rgb(74/255,76/255,79/255),rgb(64/255,115/255,191/255),rgb(252/255,182/255,28/255)),labels = c("Overcast",'Cloudy','Clear'))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(fill="",x="")+
  theme(axis.title.y = element_blank(),axis.text.y = element_blank(),axis.ticks.y = element_blank(),axis.line.y = element_blank())+
  theme(plot.margin =  unit(c(0.5,0,0,1),'lines'))

func.save.image(filename = 'Figures/FIGS02_DayTypeDistribution',SaveAs = ".pdf", width = textwidth,height = 2)

rm(CloudsGen_daily_distribution)

# . . 5.2 Cloud probability and occurrence --------------------------------------------------------
p1 <- ggplot(CloudsGen,aes(x = Time, y = CloudProb))+
  geom_line(col = rgb(64/255,115/255,191/255),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(limits = c(0,1),expand = c(0,0))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y="Cloud probability")


p2 <- ggplot(CloudsGen,aes(x = Time, y = Cloud))+
  geom_line(col = rgb(64/255,115/255,191/255),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(limits = c(0,1),expand = c(0,0))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y="Cloud occurrence")
  
p3 <- ggplot(CloudsGen_daily,aes(x = Time, y = Cloud*100))+
  geom_line(col = rgb(64/255,115/255,191/255),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(limits = c(0,100),expand = c(0,0))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y="Daily cloud coverage (% of sky)")

ggpubr::ggarrange (plotlist = list(p1,p2,p3),ncol = 1,nrow = 3,align = "v")+theme(plot.margin = unit(c(0,0.5,0,0),'lines'))

func.save.image(filename = 'Figures/FIGS03_CloudOccurrence',SaveAs = ".pdf", width = textwidth,height = textwidth)


rm(CloudsGen_daily,p1,p2,p3)

# . . 5.3 Components of simulated insolation ------------------------------------------------------
max_irrad <- 300
dt_sun <- 3600
dt <- 900

p1 <- ggplot(SolarGen,aes(x = Time, y = G0))+
  geom_line(col = rgb(0.6,0,0),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0),lim = c(0,max_irrad))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y=bquote(G[0]~(Wh%.%m^-2)))+
  theme(axis.title.x = element_blank(),axis.text.x = element_blank(),axis.ticks.x = element_blank())

p2 <- ggplot(SolarGen,aes(x = Time, y = G))+
  geom_line(col = rgb(0.6,0,0),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0),lim = c(0,max_irrad))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y=bquote(G~(Wh%.%m^-2)))+
  theme(axis.title.x = element_blank(),axis.text.x = element_blank(),axis.ticks.x = element_blank())

p3 <- ggplot(SolarGen,aes(x = Time, y = Gc))+
  geom_line(col = rgb(0.6,0,0),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0),lim = c(0,max_irrad))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y=bquote(G[c]~(Wh%.%m^-2)))+
  theme(axis.title.x = element_blank(),axis.text.x = element_blank(),axis.ticks.x = element_blank())

p4 <- ggplot(SolarGen,aes(x = Time, y = G.i.))+
  geom_line(col = rgb(0.6,0,0),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0),lim = c(0,max_irrad))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y=bquote(G[p]~(Wh%.%m^-2)))

ggpubr::ggarrange (plotlist = list(p1,p2,p3,p4),ncol = 1,nrow = 4,align = "v")+theme(plot.margin = unit(c(0,0.5,0,0),'lines'))

func.save.image(filename = 'Figures/FIGS04_SolarModel',SaveAs = ".pdf", width = textwidth,height = textwidth/3*4)


rm(max_irrad,p1,p2,p3,p4)


# . . 5.4 Solar model vs data ---------------------------------------------------------------------

# Hourly data
SolarGen$hid <- hour(SolarGen$Time)+24*(yday(SolarGen$Time)+year(SolarGen$Time)*365) # hour id
SolarGen_hourly <- aggregate(.~hid,data = SolarGen,FUN=sum)
SolarGen_hourly$Time <-  aggregate(.~hid,data = SolarGen,FUN=mean)$Time
SolarGen_hourly$Time <- as.POSIXct(SolarGen_hourly$Time,origin = "1970-01-01",tz = "Europe/Brussels")

p1 <- ggplot(SolarGen_hourly,aes(x = Time, y = E_solar/dt_sun*dt))+
  geom_line(col = rgb(0.6,0,0),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0),lim = c(0,0.301))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y=bquote(E[paste(solar,',',sim)]~(kWh%.%h^-1)))

p2 <- ggplot(SolarData,aes(x = Time, y = E_solar))+
  geom_line(col = rgb(0.6,0,0),linewidth = 0.25)+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0),lim = c(0,0.301))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  labs(x="",y=bquote(E[paste(solar,',',data)]~(kWh%.%h^-1)))

ggpubr::ggarrange (plotlist = list(p2,p1),ncol = 1,nrow = 2,align = "v")+theme(plot.margin = unit(c(0,0.5,0,0),'lines'))

func.save.image(filename = 'Figures/FIGS05_DataSimSolar',SaveAs = ".pdf", width = textwidth,height = textwidth/3*2)

rm(dt,dt_sun,SolarGen_hourly,p1,p2)

# . . 5.5 Solar model vs data months --------------------------------------------------------------

# Monthly data
SolarGen$month_id <- month(SolarGen$Time)+12*year(SolarGen$Time)
SolarData$month_id <- month(SolarData$Time)+12*year(SolarData$Time)

SolarGen$month <- month(SolarGen$Time)
SolarData$month <- month(SolarData$Time)

SolarGen_monthly <- aggregate(.~month_id, data = SolarGen, FUN = sum, na.action = na.pass)
SolarGen_monthly$month <- aggregate(.~month_id, data = SolarGen, FUN = mean, na.action = na.pass)$month
SolarData_monthly <- aggregate(.~month_id, data = SolarData, FUN = sum, na.action = na.pass)
SolarData_monthly$month <- aggregate(.~month_id, data = SolarData, FUN = mean, na.action = na.pass)$month

SolarGen_monthly <- SolarGen_monthly[,c(6:9,12)]
SolarGen_monthly$type <- "Model"

SolarData_monthly <- SolarData_monthly[,c(3:5,10,12)]
SolarData_monthly$type <- "Data"

SolarComp_monthly <- rbind(SolarGen_monthly,SolarData_monthly)
SolarComp_monthly <- melt(SolarComp_monthly,id.vars = c("month","type")) 

SolarComp_monthly <- SolarComp_monthly[SolarComp_monthly$value!=0,]

SolarComp_monthly.Summary <- aggregate(.~month+type+variable, data = SolarComp_monthly,FUN = function(x) c(mean = mean(x), sd = sd(x)))

position_dodge2 <- function(x, dodge_by, width = 0.2) {
  offsets <- (as.numeric(factor(dodge_by))-mean(as.numeric(factor(dodge_by))))
  offsets <- offsets/max(abs(offsets))
  x + offsets*width
}

ggplot(SolarComp_monthly.Summary, aes(x = month, y = value[,"mean"]/1000,linetype = type, col = variable))+
  geom_line(linewidth = 0.25)+
  scale_x_continuous(limits = c(0,13),breaks = scales::pretty_breaks(n=12),expand = c(0,0))+
  scale_y_continuous(limits = c(0,NA),expand = c(0,0))+
  scale_color_discrete(labels = c(expression(G[p]),expression(B[p]),expression(D[p]),expression(R[p])))+
  geom_errorbar(linewidth = 0.25,aes(x = position_dodge2(month, interaction(variable,type)), ymin = value[,"mean"]/1000-value[,"sd"]/1000,ymax =  value[,"mean"]/1000+value[,"sd"]/1000,linetype = type, col = variable),
                width =0.5)+
  ggplot.thema(fntsize = 8,lgd.keysize.cm = 0.4)+
  labs(linetype = "",col = "Component",x = "Month of the year", y = expression(Monthly~insolation~(kWh%.%m^-2)))


func.save.image(filename = 'Figures/FIGS06_MonthlySum',SaveAs = ".pdf", width = 0.5*textwidth,height = 2)


rm(SolarData_monthly,SolarGen_monthly,SolarComp_monthly,SolarComp_monthly.Summary)


# . . 5.6 Flow distribution data-------------------------------------------------------------------

Usage <- read_csv("Data/SourceData/FlowDistributionData.csv",show_col_types = FALSE); # Reads flow patterns from the given csv
#Usage.Time = datetime(Usage.Time,'InputFormat','HH:mm');
#Usage = table2timetable(Usage);
Usage<- melt(Usage,id.vars = c("Time"))
Usage <- Usage[Usage$variable!="BT"&Usage$variable!="DW"&Usage$variable!="CL"&Usage$variable!="GA",]

ggplot(Usage,aes(x=Time,y=value,col=variable))+geom_line(linewidth = 0.25)+
  scale_y_continuous(limits = c(0,NA),expand = c(0,0))+
  labs(x = "Time of day",y = "Normalized flow distribution (-)",col = "Appliance")+
  scale_x_time(expand = c(0,0) ,breaks=scales::breaks_width(width = "6 hours"),minor_breaks = scales::breaks_width(width = "1 hours"),limits = c(hm("00:00"),hm("24:00")),labels = function(t) strftime(as_datetime(t,tz = "UTC"),format = "%H:%M",tz = "UTC"))+
  scale_color_discrete(labels = c("Toilet","Kitchen sink (or dishwasher)","Bathroom sink","Washing machine","Bath or shower"))+
  ggplot.thema(fntsize = 8,lgd.keysize.cm = 0.4)

func.save.image(filename = 'Figures/FIGS07_DiurnalPatterns',SaveAs = ".pdf", width = textwidth,height = 2)
func.save.image(filename = 'Figures/FIGS07_DiurnalPatterns',SaveAs = ".svg", width = textwidth,height = 2)

rm(Usage)


# . . 5.7 Gardening -------------------------------------------------------------------------------

# Daily data
Q_appl$day_id <- yday(Q_appl$Time)+365*year(Q_appl$Time)
Q_appl_daily <- aggregate(data = Q_appl,.~day_id,FUN = sum);
Q_appl_daily$Time <- aggregate(data = Q_appl,.~day_id,FUN = mean)$Time;
Q_appl_daily$Time <- as.POSIXct(Q_appl_daily$Time,origin = "1970-01-01",tz = "Europe/Brussels")


ggplot(Q_appl_daily,aes(x=Time,y=Q_GA*1000))+
  geom_line(col = rgb(64/255,115/255,191/255),linewidth = 0.25)+
  labs(x = "",y = expression(Q[paste(GA,',',d)]~(L)))+
  scale_x_datetime(lim = c(as.POSIXct("2015-01-01",tz="Europe/Brussels"),as.POSIXct("2025-01-01",tz="Europe/Brussels")),expand = c(0,0),breaks = scales::pretty_breaks(n=10))+
  scale_y_continuous(expand = c(0,0))+
  ggplot.thema(fntsize = 10,lgd.keysize.cm = 0.4)+
  theme(plot.margin = unit(c(0,1,0,0),'lines'))

func.save.image(filename = 'Figures/FIGS08_GardenWatering',SaveAs = ".pdf", width = textwidth,height = 2)

rm(Q_appl_daily)

