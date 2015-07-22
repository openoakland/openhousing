
##Clear All Variables
rm(list=ls(all=TRUE)) 
##Source of Code: http://notesofdabbler.bitbucket.org/2013_12_censusBlog/censusHomeValueExplore_wdesc.html

##Hyperlinks to necessary data 
	#Request APIkey at census.gov/developers
	#Shape Files
		#http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi
			#1) Census Tracts ("return to: main download page"-> "layer type: census tract" -> 
				#"2010: California" -> "county: alameda")
  	#Download OakPlace.csv from openoakland/openhousing/data

##Set working directory
wDir = "~/Open Oakland/Oakland Advanced ACS Data Extraction/Data"
setwd(wDir)

##Load Libraries/Packages
#Install any needed packages using "install.packages('nameOfPackage')"
#ACS
library(methods)
library(stringr)
library(plyr)
library(XML)
library(acs)
#Fortify
library(ggplot2)
#ReadShapePoly
library(maptools)
library(rgeos)

##Retrieve Oakland Tracts
placeOak = read.csv("OakPlace.csv", header=TRUE)
tracts = placeOak$TRACT

##Get shape file of tracts in California (http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi)
placeShp = readShapePoly("tl_2010_06001_tract10.shp")
placeShp2=fortify(placeShp,region="TRACTCE10")
placeShp3=placeShp2[placeShp2$id %in% placeOak$TRACT,]
placeShp3$rnum=seq(1,nrow(placeShp3))

##ACS Data
APIkey ="Get Chur ERn" 
#api.key.install(key=APIkey) #Only need to do this once per computer, ever

#Function: grab data and accuracy/precision
ACSData <- function(fieldnm, fieldName){
 
	#Pull from the API
	getData = acs.fetch(geo=geo.make(state=06,county = 001, tract=tracts),variable=fieldnm )
	#Assign Estimates to each tract
	estimateData = data.frame(cbind(tracts, as.numeric(estimate(getData))))
	#Assign Errors to each tract
	errorData = data.frame(cbind(tracts, as.numeric(standard.error(getData))))
	#Merge Estimates and Errors 
	mergedData = merge(estimateData,errorData, by =c("tracts"))
	#Name Columns
	names(mergedData) = c("tract", fieldName, "Error")

	#Determine how precise/accurate the estimates are, by percentage
	percentError <- transform(mergedData, perError = (Error/get(fieldName)*100))
	attach(percentError)
	print(paste("Mean: ",round(mean(perError),2)))    # average error rate of the median value (as a percent)
	print(paste("Standard Deviation: ",round(sd(perError),2)))   #standard deviation of above
	detach(percentError)
	
	return(mergedData)
}

#Function: Add coordinates and export 
	###Add Coordinates###
locACSData <- function(mergedData, fieldName){
	placePlt=merge(placeShp3,mergedData,by.x=c("id"),by.y=c("tract"))
	placePlt=placePlt[order(placePlt$rnum),]
		
	#Export to a csv
	exportPlace = placePlt[,(colnames(placePlt)%in% c("id","long","lat",fieldName, "Error"))]
	names(exportPlace) = c("tract","long","lat",fieldName, "Error")
	write.csv(exportPlace, file = paste(fieldName, ".csv"))
	return(exportPlace)
}

##Start Grabbing ACS Data 
#Median Income
fieldnm="B19013_001"
fieldName="MedianIncome"
extractData = ACSData(fieldnm, fieldName)
MedianIncome = locACSData(extractData, fieldName)
#"Mean:  15.32"
#"Standard Deviation:  10.04"

#Occupancy Status: Total
fieldnm="B25002_001"
fieldName="OccupancyStatusTotal"
extractData = ACSData(fieldnm, fieldName)
OccupancyStatusTotal = locACSData(extractData, fieldName)
#"Mean:  3.03"
#"Standard Deviation:  5.29"

#Occupancy Status: Occupied
fieldnm="B25002_002"
fieldName="OccupancyStatusOccupied"
extractData = ACSData(fieldnm, fieldName)
OccupancyStatusOccupied = locACSData(extractData, fieldName)
#"Mean:  5.41"
#"Standard Deviation:  5.04"

#Occupancy Status: Vacant
fieldnm="B25002_003"
fieldName="OccupancyStatusVacant"
extractData = ACSData(fieldnm, fieldName)
OccupancyStatusVacant = locACSData(extractData, fieldName)
# "Mean:  Inf"
# "Standard Deviation:  NaN"

#TotalPopulation
fieldnm="B01003_001"
fieldName="TotalPopulation"
extractData = ACSData(fieldnm, fieldName)
TotalPopulation = locACSData(extractData, fieldName)
# "Mean:  7.95"
# "Standard Deviation:  5.59"
