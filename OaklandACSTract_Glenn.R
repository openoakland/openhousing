rm(list=ls(all=TRUE)) 
##Source of Code: http://notesofdabbler.bitbucket.org/2013_12_censusBlog/censusHomeValueExplore_wdesc.html

##Necessary data 
	#Request APIkey at census.gov/developers. Place the key in line 59
	#Shape Files
	#	http://www2.census.gov/geo/tiger/TIGER2010/TRACT/2010/tl_2010_06001_tract10.zip
	#Download OakPlace.csv (found in openoakland/openhousing/data)
	  #In gitHub, view RAW version of OakPlace.csv 
	  #Then, copy and paste raw data to text editor (for me, notepad works better than excel)
	  #Finally, save new file as .csv
###BEGIN SCRIPT###

getwd()#Make sure 'OakPlace.csv' and ALL OF 5 FILES downloaded from the shapefile-link are 
#	in the file path returned by this function. While only one file will be called by name, 
# 	the other four provide support. 


#Load Libraries/Packages
##Install any needed packages using "install.packages('nameOfPackage')"
library(XML)
library(RCurl)

library(stringr)
library(ggplot2)
library(maptools)

library(rgeos)

library(ggmap)
library(plyr)
library(RJSONIO)

library(methods)
library(acs) ##This library is the bread & butter of this version


####SET-UP Mapping Data####
placeOak = read.csv("OakPlace.csv", header=TRUE)

#get shape files http://www2.census.gov/geo/tiger/TIGER2010/TRACT/2010/tl_2010_06001_tract10.zip
#ensure all five files downloaded from the link are in the working directory 
tractShp = readShapePoly("tl_2010_06001_tract10.shp")
tractShp2=fortify(tractShp,region="TRACTCE10")
tractShp3=tractShp2[tractShp2$id %in% placeOak$TRACT,]

#Google base map
x=get_googlemap(center="Oakland",maptype=c("roadmap"))

##TEST BASE MAP###
placeShp3 = tractShp3
p=ggmap(x)
p=p+geom_polygon(data=placeShp3,aes(x=long,y=lat,group=id),fill="blue",color="black",alpha=0.2)
print(p)


####GET DEMOGRAPHICS####
#Global Values
APIkey ="" #Place your API key in the quotes 
#name TRACT as the place
placeShp3 = tractShp3


###2011 ACS DATA###
api.key.install(key=APIkey) 
tracts = placeOak$TRACT

#Median Income
fieldnm="B19013_001E"
fieldName="MedInc"

##This funtion is the entire point of the code. The acs library allows for the manipulation of ACS data while
#	maintaining its statistical integrity. 
medInc2 = acs.fetch(geo=geo.make(state=06,county = 001, tract=tracts),variable="B19013_001" )
medInc = data.frame(cbind(tracts, as.numeric(estimate(medInc2))))
names(medInc) = c("tract",fieldName)


###MAP ACS Example Data###
medInc$medIncCut = cut(medInc$MedInc, 
		breaks = c(0,40000,60000,80000,500000),
		labels=c("<40K","40-60K","60-80K",">80K"))

placeShp3$rnum=seq(1,nrow(placeShp3))
placePlt=merge(placeShp3,medInc,by.x=c("id"),by.y=c("tract"))
placePlt=placePlt[order(placePlt$rnum),]
		
p = ggmap(x)
p = p + geom_polygon(data = placePlt, aes(x=long,y=lat,group=id,fill=medIncCut),color="black",alpha=0.2)
p = p + scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p = p + labs(title="Percent Black by Census Tract")
p = p + theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p)

#Export to a csv
exportPlace = placePlt[,(colnames(placePlt)%in% c("id","long","lat","MedInc"))]
names(exportPlace) = c("tract","long","lat","MedInc")
write.csv(exportPlace, file = "MedianIncome.csv")

