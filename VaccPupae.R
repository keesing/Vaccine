# ------------------------------------------------------------------------------
# Borrelia Vaccine gypsy moth pupae script
# 10 January 2017
# Modified: 
# Input:  GCPupae2015.csv
#         HCPupae2015.csv
#         TCPupae2015.csv
#         GXPupae2015.csv
#         HXPupae2015.csv
#         TXPupae2015.csv
#         PupMDensity2015.csv
# Output: Graphs
#
# ------------------------------------------------------------------------------
# Reset R's brain
rm(list=ls())

#Package for Mixed Effects model
install.packages("lme4")
library("lme4")

#for negative binomial regression
library("MASS")


# Find where R is currently working
getwd()

# Reset to desired working directory
setwd("~/Ostfeld_et_al_2018_Ecology_and_Evolution/gypsy moth data files")



library("ggplot2")

####################################################################
# PART ONE: 2015 data organization and combination
####################################################################

# read in the gypsy moth pupae datafiles
GC<-read.csv("GCPupae2015.csv")
HC<-read.csv("HCPupae2015.csv")
TC<-read.csv("TCPupae2015.csv")
GX<-read.csv("GXPupae2015.csv")
HX<-read.csv("HXPupae2015.csv")
TX<-read.csv("TXPupae2015.csv")
v1 <- rbind(GC, HC)
v2 <- rbind(v1,TC)
v3 <- rbind(GX,v2)
v4 <- rbind(v3,HX)
v5 <- rbind(v4,TX)

head(v5)
dim(v5)

# get the dates sorted out
v5$NewDate <- as.character(v5$Date,format="%m/%d/%y") # convert imported date into characters
v5$date <- as.Date(v5$NewDate, format="%m/%d/%Y") # convert characters into date recognized by R
v5$NewDate <- NULL
v5$Date <- NULL
head(v5)

# split "Site" into two variables: "Location" and "Treatment"
v5[,16] <- data.frame(Location =   substr(v5$Site, start = 1, stop = 1))
v5[,17] <- data.frame(Treatment = substr(v5$Site, start = 2, stop = 2) )
#head(v5)
p <- v5

#write.csv(p,"AllGridsPup2015.csv") # used this to find some missing values in original files
# some data entry omitted 0 values after a pupa was found missing at an earlier check

# aggregate by grid, adding up all the remaining pupae to get Number Remaining
p.grid <- aggregate(p$Day.7, by=list(p$Site), FUN=sum)
names(p.grid) <- c("Site", "NumRemaining")
p.grid <- aggregate(p$Day.7, by=list(p$Location, p$Treatment, p$Site), FUN=sum)
names(p.grid) <- c("Location", "Treatment", "Site", "NumRemaining")
p.grid$PropEaten <- 1-p.grid$NumRemaining/81 #calculate the proportion eaten

#read in mouse densities on each grid
d <- read.csv("PupMDensity2015.csv")

# merge to get master result
p.dens <- merge(p.grid, d, by="Site")


# THIS SECTION TREATS EACH GRID AS UNIT OF REPLICATION
mean.Man <- tapply(p.grid$PropEaten, list(p.grid$Treatment), mean)
# Calculate standard deviation of each group using tapply
# which returns a matrix--it will be the same dimension as mean.burde 
sd.Man <- tapply(p.grid$PropEaten, list(p.grid$Treatment), sd)
# Calculate sample size in each group
n.Man <- tapply(p.grid$PropEaten, list(p.grid$Treatment), length)
# Calculate the standard error 
se.Man <- sd.Man/sqrt(n.Man)


# DATA ANALYSIS HERE


#number remaining
#paired t-test
t.test(c(17,30,47), c(14,16,33), paired=TRUE)

GLM1<-glm(NumRemaining~ Treatment, poisson(link = "log"), data=p.grid)
#fixed effect on Location
GLM2<-glm(NumRemaining~ Treatment + Location, poisson(link = "log"), data=p.grid)
GLM3<-glm(NumRemaining~ Treatment.x + Location.x + MNA, poisson(link = "log"), data=p.dens)

#offset
p.dens$offset<-1:6*0+log(81)
GLM3o<-glm(NumRemaining~ Treatment.x + Location.x + MNA, poisson(link = "log"), offset(offset), data=p.dens)
#GLM3o2<-glm(NumRemaining/log(81)~ Treatment.x + Location.x + MNA, poisson(link = "log"),data=p.dens)
#GLM3o3<-glm(NumRemaining/81~ Treatment.x + Location.x + MNA, poisson(link = "log"),data=p.dens)

#overdispersed
GLM3b<-glm(NumRemaining~ Treatment.x + Location.x + MNA, quasipoisson(link = "log"), data=p.dens)
#GLM3nb<-glm.nb(NumRemaining~ Treatment.x + Location.x + MNA, data=p.dens)
GLM4<-glm(NumRemaining~ Treatment.x  + MNA, poisson(link = "log"),  data=p.dens)

#Gaussian data
GLM5<-glm(NumRemaining~ Treatment.x + Location.x + MNA, data=p.dens)
ANOVA1<-anova(lm(NumRemaining ~ MNA+ Treatment.x + Location.x, data=p.dens))

#random effect on Location
GLMER1<-glmer(NumRemaining~ Treatment.x  + MNA +(1|Location.x), poisson(link = "log"),  data=p.dens)



################################################################
# JUST LOOK AT THE ONES WITH RODENT SIGN
################################################################

# subset the ones with rodent sign
p.sign <- subset(p, Sign == "yes")
# aggregate by grid, count number with sign on each grid
p.signcount <- aggregate(p.sign$Day.7, by=list(p.sign$Location, p.sign$Treatment, p.sign$Site), FUN=length)
names(p.signcount) <- c("Location", "Treatment", "Site", "NumWithSign")
#  
p.signsum <- aggregate(p.sign$Day.7, by=list(p.sign$Location, p.sign$Treatment, p.sign$Site), FUN=sum)
names(p.signsum) <- c("Location", "Treatment", "Site", "NumRemaining")
# merge the two to get the count and sum in one data file
p.sign.grid <- merge(p.signsum, p.signcount, by="Site")
p.sign.grid[,5:6] <- NULL
p.sign.grid$PropEaten <- 1-p.sign.grid$NumRemaining/p.sign.grid$NumWithSign #calculate the proportion eaten

#read in mouse densities on each grid
d <- read.csv("PupMDensity2015.csv")

p.sign.dens <- merge(p.sign.grid, d, by="Site")


# THIS SECTION TREATS EACH GRID AS UNIT OF REPLICATION, but only for pupae with rodent sign
mean.Man <- tapply(p.sign.grid$PropEaten, list(p.sign.grid$Treatment), mean)
# Calculate standard deviation of each group using tapply
# which returns a matrix--it will be the same dimension as mean.burde 
sd.Man <- tapply(p.sign.grid$PropEaten, list(p.sign.grid$Treatment), sd)
# Calculate sample size in each group
n.Man <- tapply(p.sign.grid$PropEaten, list(p.sign.grid$Treatment), length)
# Calculate the standard error 
se.Man <- sd.Man/sqrt(n.Man)


# THIS SECTION TREATS EACH GRID AS UNIT OF REPLICATION, but only for pupae with rodent sign
mean.Man <- tapply(p.sign.grid$NumWithSign, list(p.sign.grid$Treatment), mean)
# Calculate standard deviation of each group using tapply
# which returns a matrix--it will be the same dimension as mean.burde 
sd.Man <- tapply(p.sign.grid$NumWithSign, list(p.sign.grid$Treatment), sd)
# Calculate sample size in each group
n.Man <- tapply(p.sign.grid$NumWithSign, list(p.sign.grid$Treatment), length)
# Calculate the standard error 
se.Man <- sd.Man/sqrt(n.Man)



anova(lm(p.dens$PropEaten ~ p.dens$MNA))



