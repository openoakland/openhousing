rm(list=ls(all=TRUE)) 
##Source of Code: http://notesofdabbler.bitbucket.org/2013_12_censusBlog/censusHomeValueExplore_wdesc.html
##Install any needed packages using "install.packages('nameOfPackage')"

##Hyperlinks to necessary data 
	#Request APIkey at census.gov/developers
	#Shape Files
		#http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi
			#1) Census Tracts ("return to: main download page"-> "layer type: census tract" -> 
				#"2010: California" -> "county: alameda")
			
###BEGIN SCRIPT###
#set working directory (place all of the data downloaded above into this directory)
wDir = "~/Open Oakland/Oakland Tract and ZipCode/Data"
setwd(wDir)

#Load Libraries/Packages
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
library(acs)


####SET-UP Mapping Data####
placeOak = read.csv("OakPlace.csv", header=TRUE)

# get shape file of tracts in California (http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi)
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
#APIkey =("get your own")
#name TRACT as the place
	placeShp3 = tractShp3


###2011 ACS DATA###
#api.key.install(key=APIkey)
tracts = placeOak$TRACT

#Median Income
fieldnm="B19013_001E"
fieldName="MedInc"

medInc2 = acs.fetch(geo=geo.make(state=06,county = 001, tract=tracts),variable="B19013_001" )
medInc = data.frame(cbind(tracts, as.numeric(estimate(medInc2))))
names(medInc) = c("tract",fieldName)


###MAP ACS Data###
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

