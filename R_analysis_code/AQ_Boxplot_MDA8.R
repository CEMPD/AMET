################################################################
### THIS FILE CONTAINS CODE TO DRAW A CUSTOMIZED HOURLY BOXPLOT DISPLAY.  It
### draws side-by-side boxplots for the various groups, without median value.
### This particular code uses hourly data to create a diurnal average curve 
### showing the data trend throughout the course of a 24-hr period.  The
### code is designed to use AQS ozone data, but can be used with any hourly
### data (SEARCH, TEOM, etc).  
###
### Last updated by Wyat Appel April, 2017
################################################################

# get some environmental variables and setup some directories
ametbase        <- Sys.getenv("AMETBASE")        # base directory of AMET
dbase           <- Sys.getenv("AMET_DATABASE")      # AMET database
ametR           <- paste(ametbase,"/R_analysis_code",sep="")      # R directory
ametRinput      <- Sys.getenv("AMETRINPUT")  # input file for this script
ametptype       <- Sys.getenv("AMET_PTYPE")   # Prefered output type
## Check for output directory via namelist and AMET_OUT env var, if not specified in namelist
## and not specified via AMET_OUT, then set figdir to the current directory
if(!exists("figdir") )                         { figdir <- Sys.getenv("AMET_OUT")       }
if( length(unlist(strsplit(figdir,""))) == 0 ) { figdir <- "./"                 }

## source some configuration files, AMET libs, and input
source(paste(ametbase,"/configure/amet-config.R",sep=""))
source(paste(ametR,"/AQ_Misc_Functions.R",sep=""))     # Miscellanous AMET R-functions file
source(ametRinput)                                     # Anaysis configuration/input file

## Load Required Libraries 
if(!require(RMySQL)){stop("Required Package RMySQL was not loaded")}

mysql <- list(login=amet_login, passwd=amet_pass, server=mysql_server, dbase=dbase, maxrec=maxrec)

### Retrieve units label from database table ###
network <- network_names[1]
units_qs <- paste("SELECT ",species," from project_units where proj_code = '",run_name1,"' and network = '",network,"'", sep="")
units <- db_Query(units_qs,mysql)
################################################

### Set file names and titles ###
filename_pdf <- paste(run_name1,species,pid,"boxplot_MDA8.pdf",sep="_")
filename_png <- paste(run_name1,species,pid,"boxplot_MDA8.png",sep="_")

## Create a full path to file
filename_pdf <- paste(figdir,filename_pdf,sep="/")
filename_png <- paste(figdir,filename_png,sep="/")

if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1,"MDA8 Ozone for",dates,sep="") }
   else { title <- custom_title }
}

label <- "MDA8 Ozone (ppb)"
#################################

criteria <- paste(" WHERE d.",species,"_ob is not NULL and d.network='",network,"' ",query,sep="")          # Set part of the MYSQL query
qs <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,d.ob_dates,d.ob_datee,d.ob_hour,d.month,d.",species,"_ob,d.",species,"_mod from ",run_name1," as d, site_metadata as s",criteria," ORDER BY stat_id,ob_dates,ob_hour",sep="")	# Set the rest of the MYSQL query
aqdat.df<-db_Query(qs,mysql)	# Query the database and store in aqdat.df dataframe

indic.nonzero <- aqdat.df[,9] >= 0						# Determine the missing obs 
aqdat.df <- aqdat.df[indic.nonzero,]						# Remove missing obs/mod pairs from dataframe
indic.nonzero <- aqdat.df[,10] >= 0
aqdat.df <- aqdat.df[indic.nonzero,]

hr_avg_ob   <- NULL
hr_avg_mod  <- NULL
max_hour    <- NULL
max_avg_ob  <- NULL
max_avg_mod <- NULL
hour <- NULL
day  <- NULL
stat_id <- NULL

split_sites <- split(aqdat.df,aqdat.df$stat_id)
for (s in 1:length(split_sites)) {
   sub.df <- split_sites[[s]]
   for (i in 1:(length(sub.df$stat_id)-7)) {
      hr_avg_ob2 <- mean(c(sub.df[i,9],sub.df[(i+1),9],sub.df[(i+2),9],sub.df[(i+3),9],sub.df[(i+4),9],sub.df[(i+5),9],sub.df[(i+6),9],sub.df[(i+7),9]))
      hr_avg_ob <- c(hr_avg_ob,hr_avg_ob2) 
      hr_avg_mod2 <- mean(c(sub.df[i,10],sub.df[(i+1),10],sub.df[(i+2),10],sub.df[(i+3),10],sub.df[(i+4),10],sub.df[(i+5),10],sub.df[(i+6),10],sub.df[(i+7),10]))
      hr_avg_mod <- c(hr_avg_mod,hr_avg_mod2)
      hour <- c(hour,sub.df$ob_hour[i])
      day <- c(day,sub.df$ob_dates[i])
      stat_id <- c(stat_id,sub.df$stat_id[i])
   }
}

aqdat2.df <- data.frame(ob_val=hr_avg_ob,mod_val=hr_avg_mod,hour=hour,day=day,stat_id=stat_id)

#######################

### Find q1, median, q2 for each group of both species ###
q1.spec1 <- tapply(aqdat2.df$ob_val, aqdat2.df$hour, quantile, 0.25, na.rm=T)    # Compute ob 25% quartile
q1.spec2 <- tapply(aqdat2.df$mod_val, aqdat2.df$hour, quantile, 0.25, na.rm=T)   # Compute model 25% quartile
median.spec1 <- tapply(aqdat2.df$ob_val, aqdat2.df$hour, median, na.rm=T)                # Compute ob median value
median.spec2 <- tapply(aqdat2.df$mod_val, aqdat2.df$hour, median, na.rm=T)       # Compute model median value
q3.spec1 <- tapply(aqdat2.df$ob_val, aqdat2.df$hour, quantile, 0.75, na.rm=T)    # Compute ob 75% quartile
q3.spec2 <- tapply(aqdat2.df$mod_val, aqdat2.df$hour, quantile, 0.75, na.rm=T)   # Compute model 75% quartile
################################################

### Set up axes so that they will be big enough for both data species  that will be added ###
num.groups <- length(unique(aqdat2.df$hour))					# Count the number of sites used in each month
y.axis.min <- min(c(0,0))							# Set y-axis minimum values
y.axis.max.value <- max(c(q3.spec1, q3.spec2))					# Determine y-axis maximum value
y.axis.max <- c(sum((y.axis.max.value * 0.3),y.axis.max.value))			# Add 30% of the y-axis maximum value to the y-axis maximum value
#############################################################################################

########## MAKE PRIOR BOXPLOT ALL U.S. ##########
### To get a new graphics window (linux systems), use X11() ###
pdf(filename_pdf, width=8, height=8)						# Set output device with options

par(mai=c(1,1,0.5,0.5), lab=c(12,10,10), mar=c(5,4,4,5))								# Set plot margins
boxplot(split(aqdat2.df$ob_val, aqdat2.df$hour), range=0, border="transparent", col="transparent", ylim=c(y.axis.min, y.axis.max), xlab="Hour LST", ylab=label, cex.axis=1.3, cex.lab=1.3)	# Create boxplot

## Do the same thing for model values.  Use a different color for the background.
boxplot(split(aqdat2.df$mod_val,aqdat2.df$hour), range=0, border="transparent", col="transparent", boxwex=0.5, add=T, cex.axis=1.3, cex.lab=1.3)	# Plot model values on existing plot

### Put title at top of boxplot ###
title(main=title)
###################################

### Place points, connected by lines, to denote where the medians are ###
x.loc <- 1:num.groups								# Set number of median points to plot
points(x.loc, median.spec1,pch=plot_symbols[1],col=plot_colors[1])						# Plot median points
lines(x.loc, median.spec1,col=plot_colors[1])							# Connect median points with a line

### Second species ###								# As above, except for model values
x.loc <- 1:num.groups
points(x.loc, median.spec2, pch=plot_symbols[2], col=plot_colors[2])
lines(x.loc, median.spec2, lty=2, col=plot_colors[2])
#########################################################################

### Put legend on the plot ###
legend("topleft", c(network_label[1], "CMAQ"), pch=plot_symbols, fill =plot_colors, lty=c(1,2), col=plot_colors, merge=F,cex=1.2)
##############################

### Count number of samples per hour ###
nsamples.table <- table(aqdat2.df$hour)
#########################################

### Put text on plot ###
text(x=18,y=y.axis.max,paste("RPO: ",rpo,sep=""),cex=1.2,adj=c(0,0))
text(x=18,y=y.axis.max*0.95,paste("PCA: ",pca,sep=""),cex=1.2,adj=c(0,0))
if (state != "All") {
   text(x=18,y=y.axis.max*0.85,paste("State: ",state,sep=""),cex=1.2,adj=c(0,0))
}
text(x=18,y=y.axis.max*0.90,paste("Site: ",site,sep=""),cex=1.2,adj=c(0,0))
########################

### Put number of samples above each hour ###
text(x=1:24,y=y.axis.min,labels=nsamples.table,cex=.75,srt=90)

### Convert pdf to png ###
if ((ametptype == "png") || (ametptype == "both")) {   
   convert_command<-paste("convert -flatten -density 150x150 ",filename_pdf," png:",filename_png,sep="")
   dev.off()
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_pdf,sep="")
      system(remove_command)
   }
}

##########################
