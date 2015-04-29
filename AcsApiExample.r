library(XML)
library(RCurl)

library(stringr)
library(ggplot2)
library(maptools)

library(rgeos)

library(ggmap)
library(plyr)
library(RJSONIO)

###ZIPCODE CENSUS###
load("zipCityCountyStateMap.rda")
head(zipMap2)

cntyList = c("Alameda County, CA")

zipIndy=zipMap2[zipMap2$ctyname %in% cntyList,]
zipIndy2=zipIndy[!duplicated(zipIndy$ZCTA5),]
head(zipIndy2)


zipShp = readShapePoly("tl_2010_06_zcta510.shp")
zipShp2=fortify(zipShp,region="ZCTA5CE10")

zipShp3=zipShp2[zipShp2$id %in% zipIndy$ZCTA5,]

x=get_googlemap(center="Oakland",maptype=c("roadmap"))

p=ggmap(x)
p=p+geom_polygon(data=zipShp3,aes(x=long,y=lat,group=id),fill="blue",color="black",alpha=0.2)
print(p)

###ZILLOW####

zwsid = "X1-ZWz1e1nlxcy39n_2f38x"

zipList = zipIndy2$ZCTA5

zdemodata=list(zip=character(),medListPrice=numeric(),medValSqFt=numeric())

for (i in 1:length(zipList)){
	url = paste("http://www.zillow.com/webservice/GetDemographics.htm?zws-id=",zwsid,"&zip=",zipList[i],sep="")
	x = xmlInternalTreeParse(url)
	zdemodata$zip[i]=zipList[i]
	x2=xpathApply(x,"//table[name = 'Affordability Data']/data/attribute[name = 'Median List Price']/values/zip/value",xmlValue)
	zdemodata$medListPrice[i]=x2[[1]][1]
	x3=xpathApply(x,"//table[name = 'Affordability Data']/data/attribute[name = 'Median Value Per Sq Ft']/values/zip/value",xmlValue)
	zdemodata$medValSqFt[i]=x3[[1]][1]
}

zdemodata2=data.frame(zdemodata,stringsAsFactors=FALSE)
zdemodata2$medListPrice=as.numeric(zdemodata2$medListPrice)
zdemodata2$medValSqFt=as.numeric(zdemodata2$medValSqFt)
head(zdemodata2)

summary(zdemodata2)

zdemodata2$medListPriceLvl=cut(zdemodata2$medListPrice,
                               breaks=c(0,200000,400000,600000,800000,1400000),
                               labels=c("<200K","200-400K","400-600K","600-800K",">800K"))
zdemodata2$medValSqFtLvl=cut(zdemodata2$medValSqFt,
                               breaks=c(0,100,200,300,400,600),
                               labels=c("<100","100-200","200-300","300-400",">400"))

#qc
ddply(zdemodata2,c("medListPriceLvl"),summarize,minval=min(medListPrice),maxval=max(medListPrice))


ddply(zdemodata2,c("medValSqFtLvl"),summarize,minval=min(medValSqFt),
                                              maxval=max(medValSqFt))


zdemodata2=zdemodata2[zdemodata2$medListPrice != 0,]
zdemodata2=zdemodata2[!duplicated(zdemodata2$zip),]
head(zdemodata2)

###CENSUS###

APIkey ="68c9ac687e1e210c4d44bfd6ade4b0c5d1c34e38" 

# state code (CA)
state=06

# function to retrieve data from 2010 US census data
getCensusData=function(APIkey,state,fieldnm, fieldName){
  resURL=paste("http://api.census.gov/data/2010/sf1?get=",fieldnm,
               "&for=zip+code+tabulation+area:*&in=state:",state,"&key=",
               APIkey,sep="")
  dfJSON=fromJSON(resURL)
  dfJSON=dfJSON[2:length(dfJSON)]
  dfJSON_zip=sapply(dfJSON,function(x) x[3])
  dfJSON_val=sapply(dfJSON,function(x) x[1])
  df=data.frame(dfJSON_zip,as.numeric(dfJSON_val))
  names(df)=c("zip", fieldName)
  return(df)
}

# get Population and Race Data from US census 2010 for a state
fieldnm="P0030001" #Total Population
fieldName = "TotalPop"
dfTotPop=getCensusData(APIkey,state,fieldnm, fieldName)
names(dfTotPop)=c("zip","TotalPop")
head(dfTotPop)

fieldnm="P0060003"  #Black or African American alone 
				#or in combination with one or more other races
fieldName = "BlackPop"
dfBlackPop=getCensusData(APIkey,state,fieldnm, fieldName)
names(dfBlackPop)=c("zip","BlackPop")
head(dfBlackPop)

popZip = merge (dfTotPop, dfBlackPop,by=c("zip"),all.x=TRUE)
popZip <- transform(popZip, percentBlack = (BlackPop/TotalPop)*100)

##MAP IT!##

head(popZip)

popZip$percentBlackLvl=cut(popZip$percentBlack,
					breaks=c(-1,5,10,20,40,100),
					labels=c("<5","5-10","10-20","20-40",">40"))

zipShp3$rnum=seq(1,nrow(zipShp3))
zipPlt=merge(zipShp3,popZip,by.x=c("id"),by.y=c("zip"))
zipPlt=zipPlt[order(zipPlt$rnum),]

x=get_googlemap(center="oakland",maptype=c("roadmap"))
p = ggmap(x)
p = p + geom_polygon(data = zipPlt, aes(x=long,y=lat,group=id,fill=percentBlackLvl),color="black",alpha=0.2)
p = p + scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p = p + labs(title="Percent Black by Zip Code")
p = p + theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p)











# Get median income by ZCTA from 2011 ACS data (this is for all states)
fieldnm="B19013_001E"
resURL=paste("http://api.census.gov/data/2011/acs5?get=",fieldnm,"&for=zip+code+tabulation+area:*&key=",
             APIkey,sep="")
dfInc=fromJSON(resURL)
dfInc=dfInc[2:length(dfInc)]
dfInc_zip=as.character(sapply(dfInc,function(x) x[2]))
dfInc_medinc=as.character(sapply(dfInc,function(x) x[1]))
dfInc2=data.frame(dfInc_zip,as.numeric(dfInc_medinc))



names(dfInc2)=c("zip","medInc")
dfInc2=dfInc2[!is.na(dfInc2$medInc),]
head(dfInc2)

zdata=merge(zdemodata2,dfage,by=c("zip"),all.x=TRUE)
zdata=merge(zdata,dfInc2,by=c("zip"),all.x=TRUE)

zdata$medAgeLvl=cut(zdata$medAge,
                             breaks=c(0,30,35,40,45,50),
                             labels=c("<30","30-35","35-40","40-45",">45"))
zdata$medIncLvl=cut(zdata$medInc,
                    breaks=c(0,50000,75000,100000,120000),
                    labels=c("<50K","50-75K","75-100K",">100K"))
head(zdata)


ddply(zdata,c("medAgeLvl"),summarize,minval=min(medAge),maxval=max(medAge))

ddply(zdata,c("medIncLvl"),summarize,minval=min(medInc),maxval=max(medInc))

zipShp3$rnum=seq(1,nrow(zipShp3))
zipPlt=merge(zipShp3,zdata,by.x=c("id"),by.y=c("zip"))
zipPlt=zipPlt[order(zipPlt$rnum),]

# choropleth map of median Age
x=get_googlemap(center="oakland",maptype=c("roadmap"))

p1=ggmap(x)
p1=p1+geom_polygon(data=zipPlt,aes(x=long,y=lat,group=id,fill=medAgeLvl),color="black",alpha=0.2)
p1=p1+scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p1=p1+labs(title="Median Age by Zip Code (US Census data)")
p1=p1+theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p1)

x=get_googlemap(center="indianapolis",maptype=c("roadmap"))

p2=ggmap(x)
p2=p2+geom_polygon(data=zipPlt,aes(x=long,y=lat,group=id,fill=medIncLvl),color="black",alpha=0.2)
p2=p2+scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p2=p2+labs(title="Median Income by Zip Code (US census - ACS data)")
p2=p2+theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p2)

p3=ggmap(x)
p3=p3+geom_polygon(data=zipPlt,aes(x=long,y=lat,group=id,fill=medListPriceLvl),color="black",alpha=0.2)
p3=p3+scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p3=p3+labs(title="Median Listing Price (Zillow API data)")
p3=p3+theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p3)


p4=ggmap(x)
p4=p4+geom_polygon(data=zipPlt,aes(x=long,y=lat,group=id,fill=medValSqFtLvl),color="black",alpha=0.2)
p4=p4+scale_fill_manual(values=rainbow(20)[c(4,8,12,16,20)])
p4=p4+labs(title="Median Value per Square Feet (Zillow API data)")
p4=p4+theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p4)



##EDUCATION API###
eduAPIkey = "53e23bdbb43b2b80adbab8150e52007b"


lat=37.795227
lon=-122.228111
radius=10

resURL=paste("http://api.education.com/service/service.php?f=schoolSearch&key=",eduAPIkey,
             "&sn=sf&v=4&latitude=",lat,"&longitude=",lon,"&distance=",radius,"&resf=json",
             sep="")

schdata=fromJSON(resURL)

fieldList=c("nces_id","schoolname","districleaid",
            "zip","city","state","latitude",
            "longitude","schooltype","testrating_text","gradelevel","studentteacherratio")

# convert list into a dataframe
x=sapply(schdata,function(x) unlist(x$school[fieldList]))
schdata2=rbind.fill(lapply(x,function(y) as.data.frame(t(y),stringsAsFactors=FALSE)))
schdata2$latitude=as.numeric(schdata2$latitude)
schdata2$longitude=as.numeric(schdata2$longitude)

# extract numeric school test rating from testrating_text field
schdata2$testrating=as.numeric(gsub("[^0-9]","",schdata2$testrating_text))


head(schdata2)


ddply(schdata2,c("testrating_text","testrating"),summarize,count=length(testrating))

# keep only public schools
schdata3=schdata2[schdata2$schooltype=="Public",]
# group test ratings into buckets (<7, 7-8, 9-10)
schdata3$testratingLvl=cut(schdata3$testrating,breaks=c(0,4,6,8,10),
                     labels=c("< 5","5-6","7-8","9-10"))

#QC
ddply(schdata3,c("testratingLvl"),summarize,min=min(testrating),max=max(testrating),count=length(testrating))

head(schdata3)

x=get_googlemap(center="Oakland",maptype=c("roadmap"))

p=ggmap(x)
p=p+geom_point(data=schdata3,aes(x=longitude,y=latitude,color=testratingLvl),size=4)
p=p+scale_color_manual(values=c("red","orange","yellow","green"))
p=p+labs(title="School Ratings (Education.com API data)")
p=p+theme(legend.title=element_blank(),plot.title=element_text(face="bold"))
print(p)








