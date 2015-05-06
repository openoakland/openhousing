##Source of Code: http://notesofdabbler.bitbucket.org/2013_12_censusBlog/censusHomeValueExplore_wdesc.html
##Install any needed packages using "install.packages('nameOfPackage')"

##Hyperlinks to necessary data (copy data into new file: "stateCntyCodes.txt")
  #1) state and county id-name maps
  #http://www.census.gov/econ/cbp/download/georef02.txt

  #2) zcta to census tract (Option 1)
  #http://www.census.gov/geo/maps-data/data/zcta_rel_download.html

  #3) shape file of tracts in Oakland ("return to: main download page"-> "layer type: census tract" -> 
  # "2010: California" -> "county: alameda")
  #http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi


###BEGIN SCRIPT###
#set working directory 
wDir = "~/Open Oakland/Oakland Tracts/Data"
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

library(stringr)
library(zipcode)


####SET-UP Mapping Data####

#get state and county id-name maps
#http://www.census.gov/econ/cbp/download/georef02.txt
stateCntyCodes = read.table("stateCntyCodes.txt", sep = ",", colClasses = c("character"), 
    header = TRUE)
head(stateCntyCodes)


#get zcta to tract map
#http://www.census.gov/geo/maps-data/data/zcta_rel_download.html
zipTract = read.table("zcta_CTract_rel_10.txt", sep = ",", colClasses = c("character"), 
    header = TRUE)
head(zipTract)


# get zip to city map - from package zipcode
data(zipcode)
head(zipcode)


# merge zip-city with zip-county-state
zipMap = merge(zipTract[, c("ZCTA5", "STATE", "COUNTY","TRACT")], zipcode[, c("zip", 
    "city")], by.x = "ZCTA5", by.y = "zip")

	
# get names of county and state
zipMap2 = merge(zipMap, stateCntyCodes, by.x = c("STATE", "COUNTY"), by.y = c("fipstate", 
    "fipscty"))
zipMap2$stname = sapply(zipMap2$ctyname, function(x) str_split(x, ",")[[1]][2])
head(zipMap2)

# list of places in Oakland area
cntyList = c("Alameda County, CA")
cityList = c("Oakland")

#Data frame of tracts in Oakland
tractOak=zipMap2[zipMap2$ctyname %in% cntyList,]
tractOak = tractOak[tractOak$city %in% cityList,]
tractOak2=tractOak[!duplicated(tractOak$TRACT),]

head(tractOak2)

# get shape file of tracts in California
# http://www.census.gov/cgi-bin/geo/shapefiles2010/layers.cgi
tractShp = readShapePoly("tl_2010_06001_tract10.shp")
tractShp2=fortify(tractShp,region="TRACTCE10")

tractShp3=tractShp2[tractShp2$id %in% tractOak$TRACT,]

#preliminary map, to check base information
x=get_googlemap(center="Oakland",maptype=c("roadmap"))
p=ggmap(x)
p=p+geom_polygon(data=tractShp3,aes(x=long,y=lat,group=id),fill="blue",color="black",alpha=0.2)
print(p)


####START GETTING DATA TO MAP####

###2010 CENSUS DATA###

APIkey ="68c9ac687e1e210c4d44bfd6ade4b0c5d1c34e38" 

# state code (CA)
state=06
county = 001

# function to retrieve data from 2010 US census data
getCensusData=function(APIkey,state,fieldnm, fieldName){
  resURL=paste("http://api.census.gov/data/2010/sf1?get=",fieldnm,
               "&for=tract:*&in=state:",state,"&key=",
               APIkey,sep="")
  dfJSON=fromJSON(resURL)
  dfJSON=dfJSON[2:length(dfJSON)]
  dfJSON_tract=sapply(dfJSON,function(x) x[4])
  dfJSON_val=sapply(dfJSON,function(x) x[1])
  df=data.frame(dfJSON_tract,as.numeric(dfJSON_val))
  names(df)=c("tract", fieldName)
  return(df)
}

##Population and Race Data from US census 2010(Per State)##

#Total Population
fieldnm="P0030001" 
fieldName = "TotalPop"
dfTotPop=getCensusData(APIkey,state,fieldnm, fieldName)
names(dfTotPop)=c("tract","TotalPop")
head(dfTotPop)

#Black or African American alone/ or in combination with one or more other races
fieldnm="P0060003"  
fieldName = "BlackPop"
dfBlackPop=getCensusData(APIkey,state,fieldnm, fieldName)
names(dfBlackPop)=c("tract","BlackPop")
head(dfBlackPop)

#Find percent black
popTract = merge (dfTotPop, dfBlackPop,by=c("tract"),all.x=TRUE)
popTract <- transform(popTract, percentBlack = (BlackPop/TotalPop)*100)

head(popTract)



##MAP THE CENSUS##
popTract$percentBlackLvl=cut(popTract$percentBlack,
					breaks=c(-1,5,10,20,40,100),
					labels=c("<5","5-10","10-20","20-40",">40"))

tractShp3$rnum=seq(1,nrow(tractShp3))
tractPlt=merge(tractShp3,popTract,by.x=c("id"),by.y=c("tract"))
tractPlt=tractPlt[order(tractPlt$rnum),]

x=get_googlemap(center="oakland",maptype=c("roadmap"))
p = ggmap(x)
p = p + geom_polygon(data = tractPlt, aes(x=long,y=lat,group=id,fill=percentBlackLvl),color="black",alpha=0.2)
p = p + scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p = p + labs(title="Percent Black by Census Tract")
p = p + theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p)



###EXPORT DATA TO CSV
##Reduce to only desired columns
exportTract = tractPlt[,(colnames(tractPlt)%in% c("id","long","lat","percentBlack"))]
##Rename columns
names(exportTract) = c("tract", "long",'lat', "prcntBlck")
write.csv(exportTract, file = "PercentBlack.csv")
