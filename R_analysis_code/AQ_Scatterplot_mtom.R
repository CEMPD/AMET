################## MODEL TO MODEL SCATTERPLOT ################## 
### AMET CODE: R_Scatterplot_MtoM.r 
###
### This script is part of the AMET-AQ system.  This script creates
### a single model-to-model scatterplot.  However, the model points
### correspond to network observation sites, and does not use all the 
### model grid points (only what is in the database).  Two model runs
### must be provided.  The script attempts to match all points in one
### run to all points in the other run.  
###
### Last Updated by Wyat Appel; April, 2017
################################################################

## get some environmental variables and setup some directories
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
network <- network_names[1] 														# Use first network to set units
units_qs <- paste("SELECT ",species," from project_units where proj_code = '",run_name1,"' and network = '",network,"'", sep="")	# Query to be used 
units <- db_Query(units_qs,mysql) 													# Query the database for units
################################################

### Set file names and titles ###
if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1," vs ",run_name2," ",species," for ",dates,sep="") }
   else { title <- custom_title }
}

filename_pdf <- paste(run_name1,species,pid,"scatterplot_mtom.pdf",sep="_")   # Set filename for pdf format file
filename_png <- paste(run_name1,species,pid,"scatterplot_mtom.png",sep="_")   # Set filename for png format file

## Create a full path to file
filename_pdf <- paste(figdir,filename_pdf,sep="/")                          # Set PDF filename
filename_png <- paste(figdir,filename_png,sep="/")                          # Set PNG filenam

#################################

axis.max <- NULL
sinfo    <- NULL
avg_text <- ""

for (j in 1:length(network_names)) {						# Loop through for each network
   network   <- network_names[[j]]						# Set network name
   criteria <- paste(" WHERE d.",species,"_mod is not NULL and d.network='",network,"' ",query,sep="")          # Set part of the MYSQL query
   check_POCode        <- paste("select * from information_schema.COLUMNS where TABLE_NAME = '",run_name1,"' and COLUMN_NAME = 'POCode';",sep="")
   query_table_info.df <-db_Query(check_POCode,mysql)
   {
      if (length(query_table_info.df$COLUMN_NAME)==0) {
         qs1	<- paste("SELECT d.network,d.stat_id,d.lat,d.lon,DATE_FORMAT(d.ob_dates,'%Y%m%d'),DATE_FORMAT(d.ob_datee,'%Y%m%d'),d.ob_hour,d.month,d.",species,"_mod,precip_ob,precip_mod from ",run_name1," as d, site_metadata as s",criteria," ORDER BY stat_id,ob_dates",sep="")                                           # Secord part of MYSQL query for run name 1
         aqdat1.df        <- db_Query(qs1,mysql)     # query database for 1st run
         aqdat1.df$POCode <- 1
      }
      else {
         qs1	<- paste("SELECT d.network,d.stat_id,d.lat,d.lon,DATE_FORMAT(d.ob_dates,'%Y%m%d'),DATE_FORMAT(d.ob_datee,'%Y%m%d'),d.ob_hour,d.month,d.",species,"_mod,precip_ob,precip_mod,d.POCode from ",run_name1," as d, site_metadata as s",criteria," ORDER BY stat_id,ob_dates",sep="")                                           # Secord part of MYSQL query for run name 1
         aqdat1.df        <- db_Query(qs1,mysql)     # query database for 1st run
      }
   }
   {
      check_POCode        <- paste("select * from information_schema.COLUMNS where TABLE_NAME = '",run_name2,"' and COLUMN_NAME = 'POCode';",sep="")
      query_table_info.df <-db_Query(check_POCode,mysql)
      if (length(query_table_info.df$COLUMN_NAME)==0) { 
         qs2       <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,DATE_FORMAT(d.ob_dates,'%Y%m%d'),DATE_FORMAT(d.ob_datee,'%Y%m%d'),d.ob_hour,d.month,d.",species,"_mod,precip_ob,precip_mod from ",run_name2," as d, site_metadata as s",criteria," ORDER BY stat_id,ob_dates",sep="")                                           # Second par of MYSQL query for run name 2
         aqdat2.df        <- db_Query(qs2,mysql)     # query database for 1st run
         aqdat2.df$POCode <- 1
      }
      else {
         qs2       <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,DATE_FORMAT(d.ob_dates,'%Y%m%d'),DATE_FORMAT(d.ob_datee,'%Y%m%d'),d.ob_hour,d.month,d.",species,"_mod,precip_ob,precip_mod,d.POCode from ",run_name2," as d, site_metadata as s",criteria," ORDER BY stat_id,ob_dates",sep="") 						# Second par of MYSQL query for run name 2
         aqdat2.df <- db_Query(qs2,mysql)     # query database for 2nd run
      }
   }

   aqdat1.df$ob_dates <- aqdat1.df[,5]		# remove hour,minute,second values from start date (should always be 000000 anyway, but could change)
   aqdat2.df$ob_dates <- aqdat2.df[,5]		# remove hour,minute,second values from start date (should always be 000000 anyway, but could change)

   ### Match the points between each of the runs.  This is necessary if the data from each query do not match exactly ###
   aqdat1.df$statdate<-paste(aqdat1.df$stat_id,aqdat1.df$ob_dates,aqdat1.df$ob_hour,sep="")	# Create unique column that combines the site name with the ob start date for run 1
   aqdat2.df$statdate<-paste(aqdat2.df$stat_id,aqdat2.df$ob_dates,aqdat2.df$ob_hour,sep="")	# Create unique column that combines the site name with the ob start date for run 2
   {
      if (length(aqdat1.df$statdate) <= length(aqdat2.df$statdate)) {				# If more obs in run 1 than run 2
         match.ind<-match(aqdat1.df$statdate,aqdat2.df$statdate)					# Match the unique column (statdate) between the two runs
         aqdat.df<-data.frame(network=aqdat1.df$network, stat_id=aqdat1.df$stat_id, lat=aqdat1.df$lat, lon=aqdat1.df$lon, ob_dates=aqdat1.df$ob_dates, aqdat1.df[,9], aqdat2.df[match.ind,9], month=aqdat1.df$month, precip_ob=aqdat1.df$precip_ob, precip_mod=aqdat1.df$precip_mod)	# eliminate points that are not common between the two runs
      }
      else { match.ind<-match(aqdat2.df$statdate,aqdat1.df$statdate) 				# If more obs in run 2 than run 1
         aqdat.df<-data.frame(network=aqdat2.df$network, stat_id=aqdat2.df$stat_id, lat=aqdat2.df$lat, lon=aqdat2.df$lon, ob_dates=aqdat2.df$ob_dates, aqdat1.df[match.ind,9], aqdat2.df[,9], month=aqdat2.df$month, precip_ob=aqdat2.df$precip_ob, precip_mod=aqdat2.df$precip_mod)	# eliminate points that are not common between the two runs
      }
   }
   #######################################################################################################################

   aqdat.df <- data.frame(Network=aqdat.df$network,Stat_ID=aqdat.df$stat_id,lat=aqdat.df$lat,lon=aqdat.df$lon,Obs_Value=aqdat.df[,7],Mod_Value=aqdat.df[,6],Start_Date=aqdat.df$ob_dates,Month=aqdat.df$month,precip_ob=aqdat.df$precip_ob,precip_mod=aqdat.df$precip_mod)

   indic.na <- is.na(aqdat.df$Obs_Value)        # Indentify NA records
   aqdat.df <- aqdat.df[!indic.na,]             # Remove NA records
   indic.na <- is.na(aqdat.df$Mod_Value)        # Indentify NA records
   aqdat.df <- aqdat.df[!indic.na,]             # Remove NA records
   
   {
      if (averaging != "n") {                                               # Average observations to a monthly average if requested
         if (use_avg_stats == "y") {
            aqdat.df <- Average(aqdat.df)
            aqdat_stats.df <- aqdat.df                               # Call Monthly_Average function in Misc_Functions.R
         }
         else {
            aqdat_stats.df <- aqdat.df
            aqdat.df <- Average(aqdat.df)
         }
      }
      else {
         aqdat_stats.df <- aqdat.df
      }
      indic.na <- is.na(aqdat.df$Obs_Value)        # Indentify NA records
      aqdat.df <- aqdat.df[!indic.na,]             # Remove NA records
      indic.na <- is.na(aqdat.df$Mod_Value)        # Indentify NA records
      aqdat.df <- aqdat.df[!indic.na,]             # Remove NA records
   }

   #### Calculate statistics for each requested network ####
   bias <- NULL
   rmse <- NULL
   nmb <- NULL

   indic.nonzero <- aqdat_stats.df$Obs_Value >= 0	# Identify missing values (there should be none sinces it is modeled data)
   aqdat_stats.df <- aqdat_stats.df[indic.nonzero,]	# Remove missing values (again, there should be none)
   indic.nonzero <- aqdat_stats.df$Mod_Value >= 0       # Identify missing values (there should be none sinces it is modeled data)
   aqdat_stats.df <- aqdat_stats.df[indic.nonzero,]     # Remove missing values (again, there should be none)
   
   num_obs <- length(aqdat_stats.df$Obs_Value)									# Count number of obs
   bias <- round(c(bias,sum(aqdat_stats.df$Mod_Value-aqdat_stats.df$Obs_Value)/num_obs),2)				# Compute the bias
   rmse <- round(sqrt(c(rmse, sum((aqdat_stats.df$Mod_Value - aqdat_stats.df$Obs_Value)^2)/num_obs)),2)			# Compute the RMSE
   nmb <- round(c(nmb, (sum(aqdat_stats.df$Mod_Value-aqdat_stats.df$Obs_Value)/(sum(aqdat_stats.df$Obs_Value)))*100),2)		# Compute the NMB
   max_diff <- round(max(aqdat_stats.df$Mod_Value-aqdat_stats.df$Obs_Value),2)
   min_diff <- round(min(aqdat_stats.df$Mod_Value-aqdat_stats.df$Obs_Value),2)
   sinfo[[j]]<-list(plotval_obs=aqdat.df$Obs_Value,plotval_mod=aqdat.df$Mod_Value,BIAS=bias,NMB=nmb,RMSE=rmse,MaxDiff=max_diff,MinDiff=min_diff)	# Store plot values in a list

   count <- sum(is.na(aqdat.df$Obs_Value))    								# Count number of NAs in column
   len   <- length(aqdat.df$Obs_Value)									# Determine the total length of the column
   if (count != len) {  										# test to see if data is available, if so, compute axis.max		
      axis.max <- max(c(axis.max,aqdat.df$Obs_Value,aqdat.df$Mod_Value))
      axis.min <- axis.max * .033
   }
}
### If user sets axis maximum, compute axis minimum ###
if ((length(y_axis_max) > 0) || (length(x_axis_max) > 0)) {
   axis.max <- max(y_axis_max,x_axis_max)
   axis.min <- axis.max * 0.033
}
if ((length(y_axis_min) > 0) || (length(x_axis_min) > 0)) {
   axis.min <- max(y_axis_max,x_axis_max)
}
#######################################################

####################################
#### Define Stats box placement ####
####################################
axis.length <- axis.max - axis.min
right  <- axis.max                                        # define box rightside
left   <- axis.max - (axis.length * 0.540)
bottom <- axis.min
top    <- axis.max - (axis.length * 0.790)
x6 <- axis.max - (axis.length * 0.140)		# define right justification for NMB
x5 <- axis.max - (axis.length * 0.060)		# define right justification for Max_Diff
x4 <- axis.max - (axis.length * 0.150)		# define right justification for NMB
x3 <- axis.max - (axis.length * 0.240)		# define right justification for MB
x2 <- axis.max - (axis.length * 0.320)		# define right justification for RMSE	
x1 <- axis.max - (axis.length * 0.440)          # define right justification for Network
y1 <- axis.max - (axis.length * 0.860)          # define y for labels
y2 <- axis.max - (axis.length * 0.820)          # define y for run name
y3 <- axis.max - (axis.length * 0.890)          # define y for network 1
y4 <- axis.max - (axis.length * 0.920)          # define y for network 2
y5 <- axis.max - (axis.length * 0.950)          # define y for network 3
y6 <- axis.max - (axis.length * 0.980)          # define y for network 4
y7 <- axis.max - (axis.length * 0.700)          # define y for species text
y8 <- axis.max - (axis.length * 0.660)          # define y for timescale (averaging)


x <- c(x1,x2,x3,x4,x5)				# Create vector of x offset values
y <- c(y1,y2,y3,y4,y5,y6,y7,y8)			# Create vector of y offset values

######################################
########## MAKE SCATTERPLOT ##########
######################################

## NOTE: You could also save in a PostScript, JPEG, or PDF format.
pdf(file=filename_pdf,width=8,height=8)
## Plot and draw rectangle with stats ##
par(mai=c(1,1,0.5,0.5))
plot(1,1, type="n",pch=2, col="red", ylim=c(axis.min, axis.max), xlim=c(axis.min, axis.max), xlab=run_name2, ylab=run_name1, cex.axis=1.2, cex.lab=1.2)		# Create plot with no points
text(x[3],y[2], paste("vs.",run_name2,sep=" "), cex=1, adj=c(0.5,0.5))			# add run name text
text(x[2],y[7], paste(species," (",units,")"),cex=1.2,adj=0)		# add species text
text(x[2],y[8], aqdat.df$avg_text, cex=1.2, adj=0)			# add timescale text (e.g. monthly average)
text(x[2],y[1], "MB",font=3,cex=0.8)					# write NMB title
text(x[3],y[1], "NMB %",font=3,cex=0.8)					# write NME title
text(x[4],y[1], "MaxDiff", font=3,cex=0.8)				# write Max_Difference title
text(x[5],y[1], "MinDiff", font=3,cex=0.8)
plot_chars <- c(0,2,3,4,5,6,8)						# vector of plot characters

for (i in 1:length(network_names)) {
   points(sinfo[[i]]$plotval_obs,sinfo[[i]]$plotval_mod,pch=plot_chars[i],col=plot_colors[i],cex=.8)	# add points to plot for each model/model pair
   text(x[1],y[i+2], network_label[i], cex=0.9)                         				# add network text to stats box
   text(x[2],y[i+2], sinfo[[i]]$BIAS, cex=0.9)                          				# write network1 RMSE
   text(x[3],y[i+2], sinfo[[i]]$NMB, cex=0.9)                          				# write netowrk1 MB
   text(x[4],y[i+2], sinfo[[i]]$MaxDiff, cex=0.9)                           				# write network1 NMB
   text(x[5],y[i+2], sinfo[[i]]$MinDiff, cex=0.9)
}

### Put title at top of boxplot ###
title(main=title,cex.main=1)
###################################

### Put legend on the plot ###
legend("topleft", network_label, pch=plot_chars,col=plot_colors, merge=F, cex=1.2, bty="n")
##############################

### Add text to plot for various query options ###
if (run_info_text == "y") {
   if (rpo != "None") { 
      text(x=(axis.max*.58),y=(axis.max*.27), paste("RPO = ",rpo,sep=""),cex=1,adj=c(0,.5))           # add RPO region to plot
   }
   if (state != "All") {
      text(x=(axis.max*.58),y=(axis.max*.23), paste("State = ",state,sep=""),cex=1,adj=c(0,.5))       # add State abbreviation to plot
   }
   if (site != "All") {
      text(x=(axis.max*.69),y=(axis.max*.23), paste("Site = ",site,sep=""),cex=1,adj=c(0.25,0.5))                     # add Site name to plot
   }
}
##################################################

### Put 1-to-1 lines and confidence lines on plot ###
abline(0,1)                                     # create 1-to-1 line
if (conf_line=="y") {
   abline(0,(1/1.5),col="black",lty=1)              # create lower bound 2-to-1 line
   abline(0,1.5,col="black",lty=1)                # create upper bound 2-to-1 line
} 
######################################################

### Convert pdf format file to png format ###
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density 150x150 ",filename_pdf," png:",filename_png,sep="")
   dev.off()
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_pdf,sep="")
      system(remove_command)
   }
}
###############################
