##PROPOSED SCRIPT FOR NOMENCLATURE STANDARDIZATION AND PLAUSIBILITY FILTERING OF 
##EFTEON WEATHER STATION (Full AWS and ERS) data

#Inputs are from EFTEON's central data repository on ARCUS (V:\EFTEON\EFTEON Data)
#Navigate to the station of choice and set the working directory to the "Master file" folder.

#example: V:\EFTEON\EFTEON Data\Enhanced Rain Stations\EFTEON ND Bambanani ERS\Master files
library(dplyr)

setwd("V:/EFTEON/EFTEON Data/Enhanced Rain Stations/EFTEON ND Bambanani ERS/Master files")

##Then we read in the three master files, 10 min, hourly and daily
#For AWS
#f<-read.csv("EFTEON_Spioenkop_AWS_10min_checked.csv",skip=0)
#h<-read.csv("EFTEON_Spioenkop_AWS_hourly_checked.csv",skip=0)
#d<-read.csv("EFTEON_Spioenkop_AWS_daily_checked.csv",skip=0)

#For ERS
f<-read.csv("EFTEON_Bambanani_ERS_10min_checked.csv",skip=0)
h<-read.csv("EFTEON_Bambanani_ERS_hourly_checked.csv",skip=0)
d<-read.csv("EFTEON_Bambanani_ERS_daily_checked.csv",skip=0)
####################################################################################
##Prepare the data into the format required for upload to the ObsDB, including:
#Remove columns we don't want to publish
#Rename columns we do want to publish in accordance with SAEON nomenclature standards
#Do a duplicate check one more time
####################################################################################
#Duplicate checks

duplicated(f) ##Identify
f[duplicated(f), ] ##View duplicates
f<-f[!duplicated(f), ] ##Save dataframe without duplicates

duplicated(h) ##Identify
h[duplicated(h), ] ##View duplicates
h<-h[!duplicated(h), ] ##Save dataframe without duplicates

duplicated(d) ##Identify
d[duplicated(d), ] ##View duplicates
d<-d[!duplicated(d), ] ##Save dataframe without duplicates


############################################################################
#REMOVE COLUMNS THAT WE DON'T WANT TO PUBLISH AND STANDARDIZE COLUMN HEADERS
#ACCORDING TO SAEON STANDARDS
############################################################################

#Five/10 minute data tables
############################################################################
f$RECORD<-NULL
f$StationID<-NULL

#Wind - nomenclature standardization and removal of data with low sample count
#600 samples are expected per 10 minute interval. 480/600 samples = 80%
f$WSpd_Min<-NULL
colnames(f)[colnames(f) == "WSpd_Max"] <- "wind_speed_max"
f$wind_speed_max <- ifelse((f$Wind_Success_Tot < 480),NA,f$wind_speed_max) 
colnames(f)[colnames(f) == "WSpd_Avg"] <- "wind_speed_avg"
f$wind_speed_avg <- ifelse((f$Wind_Success_Tot < 480),NA,f$wind_speed_avg)
colnames(f)[colnames(f) == "WSpd_Std"] <- "wind_speed_sd"
f$wind_speed_sd <- ifelse((f$Wind_Success_Tot < 480),NA,f$wind_speed_sd)
colnames(f)[colnames(f) == "WDir_Avg"] <- "wind_dir_avg"
f$wind_dir_avg <- ifelse((f$Wind_Success_Tot < 480),NA,f$wind_dir_avg)
colnames(f)[colnames(f) == "WDir_Std"] <- "wind_dir_sd"
f$wind_dir_sd <- ifelse((f$Wind_Success_Tot < 480),NA,f$wind_dir_sd)
f$Wind_Success_Tot <-NULL

#Temperature & humidity - nomenclature standardization
colnames(f)[colnames(f) == "AirTemp_Avg"] <- "temp_air_avg"
colnames(f)[colnames(f) == "RH"] <- "humid_rel"
colnames(f)[colnames(f) == "DewPointTemp_Avg"] <- "temp_dew_point_avg"
colnames(f)[colnames(f) == "Temp_Avg"] <- "temp_ground_avg"

#Some instruments (like leaf wetness sensors, barometers and UV radiometers) don't apply to ERS,
#but running the script doesn't cause issues because the columns don't exist.

#Radiation - nomenclature standardization
colnames(f)[colnames(f) == "SlrW_Avg"] <- "rad_short_in_avg"
colnames(f)[colnames(f) == "SlrMJ_Tot"] <- "rad_short_in_tot"
colnames(f)[colnames(f) == "UVSlrW_Avg"] <- "rad_uv_avg"

#Rain - nomenclature standardization
colnames(f)[colnames(f) == "Rain_Tot"] <- "rain_tot"

#Leaf wetness - nomenclature standardization
colnames(f)[colnames(f) == "LeafWetmV_Avg"] <- "leaf_mv_avg"
colnames(f)[colnames(f) == "LeafDryCount_Tot"] <- "leaf_dry_tot"
colnames(f)[colnames(f) == "LeafConCount_Tot"] <- "leaf_con_tot"
colnames(f)[colnames(f) == "LeafWetCount_Tot"] <- "leaf_wet_tot"

#Barometer - nomenclature standardization
colnames(f)[colnames(f) == "BPress_Avg"] <- "press_atm_avg"

#Station metadata
f$LoggerSerialNumber<-NULL
f$ProgramName<-NULL
f$ProgramSignature<-NULL
f$LoggerBattery_Avg<-NULL
f$LoggerTemp_Avg<-NULL
f$LoggerLithiumBatt_Avg<-NULL
f$PingTime_Avg<-NULL
f$ScanCount<-NULL
##############################################################################

#Hourly data tables
#############################################################################
h$RECORD<-NULL
h$StationID<-NULL

#Wind - nomenclature standardization and removal of data with low sample count
#3600 samples are expected per hour. 2880/3600 = 80%
h$WSpd_Min<-NULL
colnames(h)[colnames(h) == "WSpd_Max"] <- "wind_speed_max"
h$wind_speed_max <- ifelse((h$Wind_Success_Tot < 2880),NA,h$wind_speed_max)
colnames(h)[colnames(h) == "WSpd_Avg"] <- "wind_speed_avg"
h$wind_speed_avg <- ifelse((h$Wind_Success_Tot < 2880),NA,h$wind_speed_avg)
colnames(h)[colnames(h) == "WSpd_Std"] <- "wind_speed_sd"
h$wind_speed_sd<- ifelse((h$Wind_Success_Tot < 2880),NA,h$wind_speed_sd)
colnames(h)[colnames(h) == "WDir_Avg"] <- "wind_dir_avg"
h$wind_dir_avg <- ifelse((h$Wind_Success_Tot < 2880),NA,h$wind_dir_avg)
colnames(h)[colnames(h) == "WDir_Std"] <- "wind_dir_sd"
h$wind_dir_sd <- ifelse((h$Wind_Success_Tot < 2880),NA,h$wind_dir_sd)
h$Wind_Success_Tot <-NULL

#Temperature & humidity - nomenclature standardization 
colnames(h)[colnames(h) == "AirTemp_Avg"] <- "temp_air_avg"
colnames(h)[colnames(h) == "RH"] <- "humid_rel"
colnames(h)[colnames(h) == "DewPointTemp_Avg"] <- "temp_dew_point_avg"
colnames(h)[colnames(h) == "Temp_Avg"] <- "temp_ground_avg"

#Radiation - nomenclature standardization 
colnames(h)[colnames(h) == "SlrW_Avg"] <- "rad_short_in_avg"
colnames(h)[colnames(h) == "SlrMJ_Tot"] <- "rad_short_in_tot"
colnames(h)[colnames(h) == "UVSlrW_Avg"] <- "rad_uv_avg"

#Rain - nomenclature standardization 
colnames(h)[colnames(h) == "Rain_Tot"] <- "rain_tot"

#Leaf wetness - nomenclature standardization 
colnames(h)[colnames(h) == "LeafWetmV_Avg"] <- "leaf_mv_avg"
colnames(h)[colnames(h) == "LeafDryCount_Tot"] <- "leaf_dry_tot"
colnames(h)[colnames(h) == "LeafConCount_Tot"] <- "leaf_con_tot"
colnames(h)[colnames(h) == "LeafWetCount_Tot"] <- "leaf_wet_tot"

#Barometer - nomenclature standardization 
colnames(h)[colnames(h) == "BPress_Avg"] <- "press_atm_avg"

#Station metadata
h$LoggerLithiumBatt<-NULL
h$LoggerSerialNumber<-NULL
h$ProgramName<-NULL
h$ProgramSignature<-NULL
h$LoggerTemp_Avg<-NULL
h$LoggerLithiumBatt_Avg<-NULL
h$PingTime_Avg<-NULL
h$ScanCount<-NULL

#THEN do the daily data before turning the hourly battery voltage column off

###############################################################################
#Daily data table
###############################################################################
d$RECORD<-NULL
d$StationID<-NULL

#Wind - nomenclature standardization and removal of data with low sample count
#86400 samples are expected per day. 69120/86400 = 80%
d$WSpd_Min<-NULL
d$WSpd_TMn<-NULL
colnames(d)[colnames(d) == "WSpd_Max"] <- "wind_speed_max"
d$wind_speed_max <- ifelse((d$Wind_Success_Tot < 69120),NA,d$wind_speed_max)
colnames(d)[colnames(d) == "WSpd_TMx"] <- "wind_speed_max_time"
colnames(d)[colnames(d) == "WSpd_Avg"] <- "wind_speed_avg"
d$wind_speed_avg <- ifelse((d$Wind_Success_Tot < 69120),NA,d$wind_speed_avg)
colnames(d)[colnames(d) == "WSpd_Std"] <- "wind_speed_sd"
d$wind_speed_sd<- ifelse((d$Wind_Success_Tot < 69120),NA,d$wind_speed_sd)
colnames(d)[colnames(d) == "WDir_Avg"] <- "wind_dir_avg"
d$wind_dir_avg <- ifelse((d$Wind_Success_Tot < 69120),NA,d$wind_dir_avg)
colnames(d)[colnames(d) == "WDir_Std"] <- "wind_dir_sd"
d$wind_dir_sd <- ifelse((d$Wind_Success_Tot < 69120),NA,d$wind_dir_sd)
d$Wind_Success_Tot <-NULL


#Temperature & humidity - nomenclature standardization
colnames(d)[colnames(d) == "AirTemp_Min"] <- "temp_air_min"
colnames(d)[colnames(d) == "AirTemp_TMn"] <- "temp_air_min_time"
colnames(d)[colnames(d) == "AirTemp_Max"] <- "temp_air_max"
colnames(d)[colnames(d) == "AirTemp_TMx"] <- "temp_air_max_time"
colnames(d)[colnames(d) == "AirTemp_Avg"] <- "temp_air_avg"

colnames(d)[colnames(d) == "RH_Min"] <- "humid_rel_min"
colnames(d)[colnames(d) == "RH_TMn"] <- "humid_rel_min_time"
colnames(d)[colnames(d) == "RH_Max"] <- "humid_rel_max"
colnames(d)[colnames(d) == "RH_TMx"] <- "humid_rel_max_time"

colnames(d)[colnames(d) == "DewPointTemp_Min"] <- "temp_dew_point_min"
d$DewPointTemp_TMn<-NULL
colnames(d)[colnames(d) == "DewPointTemp_Avg"] <- "temp_dew_point_avg"
colnames(d)[colnames(d) == "DewPointTemp_Max"] <- "temp_dew_point_max"
d$DewPointTemp_TMx<-NULL

colnames(d)[colnames(d) == "Temp_Min"] <- "temp_ground_min"
colnames(d)[colnames(d) == "Temp_TMn"] <- "temp_ground_min_time"
colnames(d)[colnames(d) == "Temp_Max"] <- "temp_ground_max"
colnames(d)[colnames(d) == "Temp_TMx"] <- "temp_ground_max_time"
colnames(d)[colnames(d) == "Temp_Avg"] <- "temp_ground_avg"

#Radiation - nomenclature standardization
colnames(d)[colnames(d) == "SlrW_Max"] <- "rad_short_in_max"
d$SlrW_TMx<-NULL
colnames(d)[colnames(d) == "SlrW_Avg"] <- "rad_short_in_avg"
colnames(d)[colnames(d) == "SlrMJ_Tot"] <- "rad_short_in_tot"
colnames(d)[colnames(d) == "UVSlrW_Max"] <- "rad_uv_max"
d$UVSlrW_TMx<-NULL
colnames(d)[colnames(d) == "UVSlrW_Avg"] <- "rad_uv_avg"

#Rain - nomenclature standardization
colnames(d)[colnames(d) == "Rain_Tot"] <- "rain_tot"

#Leaf wetness - nomenclature standardization
d$LeafWetmV_Min<-NULL
d$LeafWetmV_TMn<-NULL
d$LeafWetmV_Max<-NULL
d$LeafWetmV_TMx<-NULL
d$LeafWetmV_Avg<-NULL
colnames(d)[colnames(d) == "LeafDryCount_Tot"] <- "leaf_dry_tot"
colnames(d)[colnames(d) == "LeafConCount_Tot"] <- "leaf_con_tot"
colnames(d)[colnames(d) == "LeafWetCount_Tot"] <- "leaf_wet_tot"

#Barometer - nomenclature standardization
colnames(d)[colnames(d) == "BPress_Min"] <- "pressure_atm_min"
colnames(d)[colnames(d) == "BPress_TMn"] <- "pressure_atm_min_time"
colnames(d)[colnames(d) == "BPress_Max"] <- "pressure_atm_max"
colnames(d)[colnames(d) == "BPress_TMx"] <- "pressure_atm_max_time"
colnames(d)[colnames(d) == "BPress_Avg"] <- "pressure_atm_avg"

#Station metadata
d$LoggerSerialNumber<-NULL
d$ProgramName<-NULL
d$ProgramSignature<-NULL
d$LoggerBattery_Min<-NULL
d$LoggerBattery_TMn<-NULL
d$LoggerBattery_Max<-NULL
d$LoggerBattery_TMx<-NULL
d$LoggerBattery_Avg<-NULL

d$LoggerTemp_Min<-NULL
d$LoggerTemp_TMn<-NULL
d$LoggerTemp_Max<-NULL
d$LoggerTemp_TMx<-NULL
d$LoggerTemp_Avg<-NULL
d$LoggerLithiumBatt_Avg<-NULL
d$LoggerLithiumBatt<-NULL
d$PingTime_Avg<-NULL
d$ScanCount<-NULL

##############################################################################
#Abri's convoluted attempt to deal with phony daily data that 
#occurs as a result of power supply failures
##############################################################################
#set a threshold which, if detected, probably means the power failed for part of the day
h$lowbatwarning<-as.Date(ifelse(h$LoggerBattery_Avg < 10.0,strftime(h$TIMESTAMP, "%Y/%m/%d"), NA))+1

#Make a date column in the daily dataset
d$date<-as.Date(strftime(d$TIMESTAMP, "%Y/%m/%d"))

#Identify the unique dates where lowbatwarings occurred
b<-as.data.frame(unique(h$lowbatwarning))
colnames(b) <- c("date")
#Match the lowbatwarning dates to the daily data table dates
d$datematch<-as.integer(d$date %in% b$date)
#replace the rows where the dates match with NA
replacerows<-which(d$datematch == 1)

##################################################################################
#STOP HERE - YOU HAVE A CHOICE TO MAKE FOR THE NEXT STEP
##################################################################################
#FOR AWS
d[replacerows, 2:38] <-NA

#FOR ERS
d[replacerows, 2:25] <-NA
##############################################################################

#NOW we can turn the battery and battery warning columns off
h$LoggerBattery_Avg<-NULL
h$lowbatwarning<-NULL

d$date<-NULL
d$datematch<-NULL

###############################################################################
#Renaming has been done and QC based on record completeness has been done
#Next, plausibility checks
###############################################################################

##Plausibility checks
###############################################################################
#5 or 10 minute data tables
###################################

#Wind checks 10 min
f$wind_speed_max[f$wind_speed_max < 0] <- NA 
f$wind_speed_max[f$wind_speed_max > 100] <- NA  
f$wind_speed_avg[f$wind_speed_avg < 0] <- NA 
f$wind_speed_avg[f$wind_speed_avg > 75] <- NA  
f$wind_speed_sd[is.na(f$wind_speed_avg)] <- NA 
f$wind_dir_avg[f$wind_dir_avg > 360] <- NA  
f$wind_dir_avg[f$wind_dir_avg < 0] <- NA  
f$wind_dir_sd[f$wind_dir_sd > 360] <- NA  
f$wind_dir_sd[f$wind_dir_sd < 0] <- NA  

#Temperature checks 10 min
f$temp_air_avg[f$temp_air_avg < -25] <- NA 
f$temp_air_avg[f$temp_air_avg > 60] <- NA #this high to record fire events
f$humid_rel[f$humid_rel > 100] <- NA 
f$humid_rel[f$humid_rel < 0] <- NA
f$temp_dew_point_avg[is.na(f$humid_rel) ] <- NA
f$temp_dew_point_avg[is.na(f$temp_air_avg)] <- NA


#Radiation checks 10 min
f$rad_short_in_avg[f$rad_short_in_avg > 1400] <- NA
f$rad_short_in_avg[f$rad_short_in_avg < 0] <- NA
f$rad_short_in_tot[f$rad_short_in_tot < 0] <- NA
f$rad_short_in_tot[f$rad_short_in_tot > 10] <- NA

#Rain checks 10 min
f$rain_tot[f$rain_tot < 0] <- NA
f$rain_tot[f$rain_tot > 35] <- NA #this rainfall rate equates to 210mm/hour


###############################################################################
#Hourly data tables
###################################

#Wind checks hourly
h$wind_speed_max[h$wind_speed_max < 0] <- NA 
h$wind_speed_max[h$wind_speed_max > 100] <- NA  
h$wind_speed_avg[h$wind_speed_avg < 0] <- NA 
h$wind_speed_avg[h$wind_speed_avg > 75] <- NA  
h$wind_speed_sd[is.na(h$wind_speed_avg)] <- NA 
h$wind_dir_avg[h$wind_dir_avg > 360] <- NA  
h$wind_dir_avg[h$wind_dir_avg < 0] <- NA  
h$wind_dir_sd[h$wind_dir_sd > 360] <- NA  
h$wind_dir_sd[h$wind_dir_sd < 0] <- NA  

#Temperature checks hourly
h$temp_air_avg[h$temp_air_avg < -25] <- NA 
h$temp_air_avg[h$temp_air_avg > 60] <- NA  
h$humid_rel[h$humid_rel > 100] <- NA 
h$humid_rel[h$humid_rel < 0] <- NA
h$temp_dew_point_avg[is.na(h$humid_rel)] <- NA
h$temp_dew_point_avg[is.na(h$temp_air_avg)] <- NA

#Radiation checks hourly
h$rad_short_in_avg[h$rad_short_in_avg > 1300] <- NA
h$rad_short_in_avg[h$rad_short_in_avg < 0] <- NA
h$rad_short_in_tot[h$rad_short_in_tot < 0] <- NA
h$rad_short_in_tot[h$rad_short_in_tot > 10] <- NA

#Rain checks hourly
h$rain_tot[h$rain_tot < 0] <- NA
h$rain_tot[h$rain_tot > 305] <- NA #this is the world record

###############################################################################
#Daily data tables
###################################

#Wind checks daily
d$wind_speed_max[d$wind_speed_max < 0] <- NA 
d$wind_speed_max[d$wind_speed_max > 100] <- NA  
d$wind_speed_avg[d$wind_speed_avg < 0] <- NA 
d$wind_speed_avg[d$wind_speed_avg > 75] <- NA  
d$wind_speed_sd[is.na(d$wind_speed_avg)] <- NA 
d$wind_dir_avg[d$wind_dir_avg > 360] <- NA  
d$wind_dir_avg[d$wind_dir_avg < 0] <- NA  
d$wind_dir_sd[d$wind_dir_sd > 360] <- NA  
d$wind_dir_sd[d$wind_dir_sd < 0] <- NA  

#Temperature checks daily
d$temp_air_min[d$temp_air_min < -25] <- NA #national record is -20
d$temp_air_avg[d$temp_air_avg < -25] <- NA 
d$temp_air_avg[d$temp_air_avg > 60] <- NA  #should we make this the instrument limit or a reasonable environmental limit?
d$temp_air_max[d$temp_air_max > 120] <- NA #to capture fire events
d$humid_rel_max[d$humid_rel_max > 100] <- NA 
d$humid_rel_min[d$humid_rel_min < 0] <- NA
d$temp_dew_point_min[is.na(d$humid_rel) ] <- NA
d$temp_dew_point_min[is.na(d$temp_air_avg)] <- NA
d$temp_dew_point_avg[is.na(d$humid_rel)] <- NA
d$temp_dew_point_avg[is.na(d$temp_air_avg)] <- NA
d$temp_dew_point_max[is.na(d$humid_rel)] <- NA
d$temp_dew_point_max[is.na(d$temp_air_avg)] <- NA
d$temp_dew_point_max[d$temp_dew_point_max > 35 ] <- NA #this is the global record
d$temp_dew_point_min[d$temp_dew_point_min < -34] <- NA #this is the global record

#Radiation checks daily
d$rad_short_in_avg[d$rad_short_in_avg > 1300] <- NA
d$rad_short_in_avg[d$rad_short_in_avg < 0] <- NA
d$rad_short_in_max[d$rad_short_in_max > 1900] <- NA 
d$rad_short_in_tot[d$rad_short_in_tot < 0] <- NA
d$rad_short_in_tot[d$rad_short_in_tot > 40] <- NA # our record is about 33, figure out what's reasonable

#Rain checks daily
d$rain_tot[d$rain_tot < 0] <- NA
d$rain_tot[d$rain_tot > 500] <- NA #what's the SA record?

####################################################
#STOP HERE - THE FOLLOWING ONLY APPLIES TO FULL AWS, NOT ERS
#####################################################
#Additional for full AWS

#10 min
#Ground temp 10 min
f$temp_ground_avg[f$temp_ground_avg < -25] <- NA
f$temp_ground_avg[f$temp_ground_avg > 80] <- NA 

#UV radiation 10 min
f$rad_uv_avg[f$rad_uv_avg < 0] <- NA
f$rad_uv_avg[f$rad_uv_avg > 80] <- NA

#Leaf wetness checks 10 min
f$leaf_mv_avg[f$leaf_mv_avg > 1100] <- NA
f$leaf_mv_avg[f$leaf_mv_avg < 150] <- NA
f$leaf_dry_tot[f$leaf_dry_tot < 0] <- NA
f$leaf_dry_tot[f$leaf_dry_tot > 600] <- NA
f$leaf_con_tot[f$leaf_con_tot < 0] <- NA
f$leaf_con_tot[f$leaf_con_tot > 600] <- NA
f$leaf_wet_tot[f$leaf_wet_tot < 0] <- NA
f$leaf_wet_tot[f$leaf_wet_tot > 600] <- NA

#Barometric pressure checks 10 min
f$press_atm_avg[f$press_atm_avg < 650] <- NA #this takes SA altitudes into consideration
f$press_atm_avg[f$press_atm_avg > 1085] <- NA #1083 is the world record

#hourly
#Ground temperature checks hourly
h$temp_ground_avg[h$temp_ground_avg < -25] <- NA  #should we make this the instrument limit or a reasonable environmental limit?
h$temp_ground_avg[h$temp_ground_avg > 80] <- NA  #should we make this the instrument limit or a reasonable environmental limit?

#UV radiation checks hourly
h$rad_uv_avg[h$rad_uv_avg < 0] <- NA
h$rad_uv_avg[h$rad_uv_avg > 80] <- NA

#Leaf wetness checks hourly
h$leaf_mv_avg[h$leaf_mv_avg > 700] <- NA
h$leaf_mv_avg[h$leaf_mv_avg < 200] <- NA
h$leaf_dry_tot[h$leaf_dry_tot < 0] <- NA
h$leaf_dry_tot[h$leaf_dry_tot > 3600] <- NA
h$leaf_con_tot[h$leaf_con_tot < 0] <- NA
h$leaf_con_tot[h$leaf_con_tot > 3600] <- NA
h$leaf_wet_tot[h$leaf_wet_tot < 0] <- NA
h$leaf_wet_tot[h$leaf_wet_tot > 3600] <- NA

#Barometric pressure checks hourly
h$press_atm_avg[h$press_atm_avg < 650] <- NA #this takes SA altitude into account
h$press_atm_avg[h$press_atm_avg > 1085] <- NA #1083 is the world record at sea level

#Daily

#Ground temperature checks daily
d$temp_ground_avg[d$temp_ground_avg > 80] <- NA  #should we make this the instrument limit or a reasonable environmental limit?
d$temp_ground_avg[d$temp_ground_avg < -25] <- NA  #should we make this the instrument limit or a reasonable environmental limit?
d$temp_ground_max[d$temp_ground_max > 80] <- NA  #should we make this the instrument limit or a reasonable environmental limit?
d$temp_ground_max[is.na(d$temp_ground_avg)] <- NA
d$temp_ground_min[d$temp_ground_min < -25] <- NA  #should we make this the instrument limit or a reasonable environmental limit?
d$temp_ground_min[is.na(d$temp_ground_avg)] <- NA  #should we make this the instrument limit or a reasonable environmental limit?

#UV radiation checks daily
d$rad_uv_avg[d$rad_uv_avg < 0] <- NA
d$rad_uv_avg[d$rad_uv_avg > 30] <- NA #our record is around 20

#Leaf wetness checks daily
#d$leaf_mv_avg[d$leaf_mv_avg > 950] <- NA
#d$leaf_mv_avg[d$leaf_mv_avg < 200] <- NA
d$leaf_dry_tot[d$leaf_dry_tot < 0] <- NA
d$leaf_dry_tot[d$leaf_dry_tot > 86400] <- NA
d$leaf_con_tot[d$leaf_con_tot < 0] <- NA
d$leaf_con_tot[d$leaf_con_tot > 86400] <- NA
d$leaf_wet_tot[d$leaf_wet_tot < 0] <- NA
d$leaf_wet_tot[d$leaf_wet_tot > 86400] <- NA

#Barometric pressure checks daily
d$pressure_atm_min[d$pressure_atm_min < 650] <- NA #this takes SA altitudes in consideration
d$pressure_atm_avg[d$pressure_atm_avg < 650] <- NA #this takes SA altitudes in consideration
d$pressure_atm_avg[d$pressure_atm_avg > 1085] <- NA #1083 is the world record at sea level
d$pressure_atm_max[d$pressure_atm_max > 1085] <- NA


#verify if min max dewpoint & RH are ever reported in literature at 1 hourly time steps

##THEN WE HAVE TO MAKE A DECISION WHERE THE L1 DATA SETS GO.
##Do technicians store them locally and perform monthly uploads? 

setwd('C:/Users/Abri/Documents/SAEON/EFTEON/Data management/Weather cleaning script testing')

#Write new excel file with set thresholds
write.csv(f,"C:/Users/Abri/Documents/SAEON/EFTEON/Data management/Weather cleaning script testing/tenmin_L1.csv", row.names = FALSE)
write.csv(h,"C:/Users/Abri/Documents/SAEON/EFTEON/Data management/Weather cleaning script testing/hourly_L1.csv", row.names = FALSE)
write.csv(d,"C:/Users/Abri/Documents/SAEON/EFTEON/Data management/Weather cleaning script testing/daily_L1.csv", row.names = FALSE)

#Last updated by Abri on 25 September