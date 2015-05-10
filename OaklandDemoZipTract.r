rm(list=ls(all=TRUE)) ##Erase value of all variables
##Source of Code: http://notesofdabbler.bitbucket.org/2013_12_censusBlog/censusHomeValueExplore_wdesc.html

##BEFORE BEGINNING, get necessary support files/accounts
	#Request APIkey at census.gov/developers
	#Download OakPlace.csv (found in openoakland/openhousing/data)
	  #In gitHub, view RAW version of OakPlace.csv 
	  #Then, copy and paste raw data to text editor (for me, notepad works better than excel)
	  #Finally, save new file as .csv 
	#Download two sets of Shape Files
		#http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi
			#1) Census Tracts ("return to: main download page"-> "layer type: census tract" -> 
				#"2010: California" -> "county: alameda")
			#2) Zip-codes ('return to: main download page' -> 'layer type: zipcode tabulation areas'->
				#'2010: California')
  ##Install any needed libraries using "install.packages('nameOfPackage')"

##INSTRUCTIONS: How to switch between zipcodes and census tracts
  #To use census tracts (current setting of script)
    #Ensure comments ('#') are present on lines 71 and 72
    #	" 	"      "    "  absent from lines 73 and 74
  #To use zip codes 
    #Ensure comments ('#') are present on lines 73 and 74
    #	" 	"      "    "  absent from lines 71 and 72
  #This will change the values of place and placeShp3, used throughout the code 
    
###BEGIN SCRIPT###
#set working directory (Into this directory, place all of the data downloaded above)
wDir = "~/your directory here" #(in Windows, the ~ represents "C:/Users/'username'/Documents")
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

####SET-UP Mapping Data####
placeOak = read.csv("OakPlace.csv", header=TRUE)

# get shape file of tracts in California (http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi)
tractShp = readShapePoly("tl_2010_06001_tract10.shp")
tractShp2=fortify(tractShp,region="TRACTCE10")
tractShp3=tractShp2[tractShp2$id %in% placeOak$TRACT,]

# get shape file of zip-codes in California (http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi)
zipShp = readShapePoly("tl_2010_06_zcta510.shp")
zipShp2=fortify(zipShp,region="ZCTA5CE10")
zipShp3=zipShp2[zipShp2$id %in% placeOak$ZCTA5,]

#Google base map
x=get_googlemap(center="Oakland",maptype=c("roadmap"))

####GET DEMOGRAPHICS####
#Global Values
APIkey = #Request your own key, as required by census api user agreement
state=06 #California
county = 001 #Alameda County
#Set-up zip code and tract
retrieveTract = c("&for=tract:*&in=state:", 4, "tract", 06, 4)
retrieveZip = c("&for=zip+code+tabulation+area:*&in=state:",3,"zip", "",2)
#Choose ZipCode or TRACT
	#place = retrieveZip
	#placeShp3 = zipShp3
	place = retrieveTract
	placeShp3 = tractShp3

###2010 CENSUS DATA###

# function to retrieve data from 2010 US census data
getCensusData=function(APIkey,state,place, fieldnm, fieldName){
  resURL=paste("http://api.census.gov/data/2010/sf1?get=",fieldnm,
               place[1],state,"&key=",
               APIkey,sep="")
  dfJSON=fromJSON(resURL)
  dfJSON=dfJSON[2:length(dfJSON)]
  num = as.integer(place[[2]])
  dfJSON_place=sapply(dfJSON,function(x) x[num])
  dfJSON_val=sapply(dfJSON,function(x) x[1])
  df=data.frame(dfJSON_place,as.numeric(dfJSON_val))
  names(df)=c(place[3], fieldName)
  return(df)
}

##Population and Race Data from US census 2010(Per State)##

#Total Population
fieldnm="P0030001" 
fieldName = "TotalPop"
dfTotPop=getCensusData(APIkey,state, place, fieldnm, fieldName)
names(dfTotPop)=c(place[3],fieldName)
head(dfTotPop)

#Black or African American alone/ or in combination with one or more other races
fieldnm="P0060003"  
fieldName = "BlackPop"
dfBlackPop=getCensusData(APIkey,state,place, fieldnm, fieldName)
names(dfBlackPop)=c(place[3],fieldName)
head(dfBlackPop)

#Find percent black
popTract = merge (dfTotPop, dfBlackPop,by=c(place[3]),all.x=TRUE)
popTract <- transform(popTract, percentBlack = (BlackPop/TotalPop)*100)

head(popTract)



##MAP THE CENSUS##
popTract$percentBlackLvl=cut(popTract$percentBlack,
					breaks=c(-1,5,10,20,40,100),
					labels=c("<5","5-10","10-20","20-40",">40"))

placeShp3$rnum=seq(1,nrow(placeShp3))
placePlt=merge(placeShp3,popTract,by.x=c("id"),by.y=c(place[3]))
placePlt=placePlt[order(placePlt$rnum),]			

p=ggmap(x)
p = p + geom_polygon(data = placePlt, aes(x=long,y=lat,group=id,fill=percentBlackLvl),color="black",alpha=0.2)
p = p + scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p = p + labs(title="Percent Black")
p = p + theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p)



###EXPORT Current DATA TO CSV###
##Reduce to only desired columns
exportPlace = placePlt[,(colnames(placePlt)%in% c("id","long","lat","percentBlack"))]
##Rename columns
names(exportPlace) = c(place[3], "long",'lat', "percentBlack")
write.csv(exportPlace, file = "PercentBlack.csv")


###2011 ACS DATA###
#Function to get ACS data
getACSData=function(APIkey, place, fieldnm, fieldName){
	resURL=paste("http://api.census.gov/data/2011/acs5?get=",fieldnm,
               place[1],place[4],"&key=",
               APIkey,sep="")
	dfJSON = fromJSON(resURL)
	dfJSON=dfJSON[2:length(dfJSON)]
	num = as.integer(place[5])
	dfJSON_place=as.character(sapply(dfJSON,function(x) x[num]))
	dfJSON_val=as.character(sapply(dfJSON,function(x) x[1]))
	df=data.frame(dfJSON_place,as.numeric(dfJSON_val))
	names(df)=c(place[3],fieldName)
	return(df)
}

#Median Income
fieldnm="B19013_001E"
fieldName="MedInc"
medInc = getACSData(APIkey, place, fieldnm, fieldName)

###MAP ACS Data###
medInc$medIncCut = cut(medInc$MedInc, 
		breaks = c(0,20000,40000,60000,500000),
		labels=c("<20K","20-40K","40-60K",">60K"))

placeShp3$rnum=seq(1,nrow(placeShp3))
placePlt=merge(placeShp3,medInc,by.x=c("id"),by.y=c(place[3]))
placePlt=placePlt[order(placePlt$rnum),]
		
p = ggmap(x)
p = p + geom_polygon(data = placePlt, aes(x=long,y=lat,group=id,fill=medIncCut),color="black",alpha=0.2)
p = p + scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p = p + labs(title="Percent Black by Census Tract")
p = p + theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p)

#Export to a csv
exportPlace = placePlt[,(colnames(placePlt)%in% c("id","long","lat","MedInc"))]
names(exportPlace) = c(place[3],"long","lat","MedInc")
write.csv(exportPlace, file = "MedianIncome.csv")

