################## MODEL SKILL SCATTER PLOT #################### 
### AMET CODE: R_Scatterplot_skill.R 
###
### This script is part of the AMET-AQ system.  This script creates
### a scatter plot for a single network that includes more statistics 
### than the multiple network scatter plot.  Although limited to a
### single network, multiple runs may be used.
###
### Last Updated by Wyat Appel: March, 2017
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

### Set file names and titles ###
if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1," ",species," for ",dates,sep="") }
   else { title <- custom_title }
}

filename_pdf <- paste(run_name1,species,pid,"scatterplot_percentiles.pdf",sep="_")             # Set PDF filename
filename_png <- paste(run_name1,species,pid,"scatterplot_percentiles.png",sep="_")             # Set PNG filename
filename_txt <- paste(run_name1,species,pid,"scatterplot_percentiles.csv",sep="_")       # Set output file name


## Create a full path to file
filename_pdf <- paste(figdir,filename_pdf,sep="/")      # Set PDF filename
filename_png <- paste(figdir,filename_png,sep="/")      # Set PNG filenam
filename_txt <- paste(figdir,filename_txt,sep="/")      # Set output file name

#################################

run_name	<- NULL
axis.max	<- NULL
num_obs		<- NULL
sinfo		<- NULL
avg_text	<- ""
legend_names	<- NULL
legend_cols	<- NULL
legend_chars	<- NULL
point_char	<- NULL
point_color	<- NULL

################################
### Define percentile arrays ###
################################
percentile_5_ob		<- NULL
percentile_5_mod	<- NULL
percentile_25_ob	<- NULL
percentile_25_mod	<- NULL
percentile_50_ob	<- NULL
percentile_50_mod	<- NULL
percentile_75_ob	<- NULL
percentile_75_mod	<- NULL
percentile_95_ob	<- NULL
percentile_95_mod	<- NULL
###############################

### Retrieve units and model labels from database table ###
network <- network_names[1]
units_qs <- paste("SELECT ",species," from project_units where proj_code = '",run_name1,"' and network = '",network,"'", sep="")
units <- db_Query(units_qs,mysql)
model_name_qs <- paste("SELECT model from aq_project_log where proj_code ='",run_name1,"'", sep="")
model_name <- db_Query(model_name_qs,mysql)
################################################

run_name[1] <- run_name1
criteria <- paste(" WHERE d.",species,"_ob is not NULL and d.network='",network,"' ",query,sep="")           # Set part of the MYSQL query
check_POCode        <- paste("select * from information_schema.COLUMNS where TABLE_NAME = '",run_name1,"' and COLUMN_NAME = 'POCode';",sep="")
query_table_info.df <-db_Query(check_POCode,mysql)
{
   if (length(query_table_info.df$COLUMN_NAME)==0) {
      qs <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,d.ob_dates,d.ob_datee,d.ob_hour,d.month,d.",species,"_ob,d.",species,"_mod, precip_ob, precip_mod from ",run_name," as d, site_metadata as s",criteria," ORDER BY network,stat_id",sep="")      # Set the rest of the MYSQL query
      aqdat.df        <- db_Query(qs,mysql)
      aqdat.df$POCode <- 1
   }
   else {
      qs <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,d.ob_dates,d.ob_datee,d.ob_hour,d.month,d.",species,"_ob,d.",species,"_mod, precip_ob, precip_mod,d.POCode from ",run_name," as d, site_metadata as s",criteria," ORDER BY network,stat_id",sep="")        # Set the rest of the MYSQL query
      aqdat.df<-db_Query(qs,mysql)
   }
}

####################### 
if (remove_negatives == "y") {
   indic.nonzero <- aqdat.df[,9] >= 0                                                  # determine which obs are missing (less than 0); 
   aqdat.df <- aqdat.df[indic.nonzero,]                                                        # remove missing obs from dataframe
   indic.nonzero <- aqdat.df[,10] >= 0
   aqdat.df <- aqdat.df[indic.nonzero,]
}
######################

################################################
### Calculate percentiles based on each site ###
################################################
temp <- split(aqdat.df,aqdat.df$stat_id)
for (i in 1:length(temp)) { 
   sub.df <- temp[[i]]
   percentile_5_ob <- c(percentile_5_ob, quantile(sub.df[,9],.05))
   percentile_5_mod <- c(percentile_5_mod, quantile(sub.df[,10],.05))
   percentile_25_ob <- c(percentile_25_ob, quantile(sub.df[,9],.25))
   percentile_25_mod <- c(percentile_25_mod, quantile(sub.df[,10],.25))
   percentile_50_ob <- c(percentile_50_ob, quantile(sub.df[,9],.50))
   percentile_50_mod <- c(percentile_50_mod, quantile(sub.df[,10],.50))
   percentile_75_ob <- c(percentile_75_ob, quantile(sub.df[,9],.75))
   percentile_75_mod <- c(percentile_75_mod, quantile(sub.df[,10],.75))
   percentile_95_ob <- c(percentile_95_ob, quantile(sub.df[,9],.95))
   percentile_95_mod <- c(percentile_95_mod, quantile(sub.df[,10],.95))
}
#################################################

##############################
### Write Data to CSV File ###
##############################
data.df <- data.frame(perc_5_ob=percentile_5_ob,perc_5_mod=percentile_5_mod,perc_25_ob=percentile_25_ob,perc_25_mod=percentile_25_mod,perc_50_ob=percentile_50_ob,perc_50_mod=percentile_50_mod,perc_75_ob=percentile_75_ob,perc_75_mod=percentile_75_mod,perc_95_ob=percentile_95_ob,perc_95_mod=percentile_95_mod)
write.table(run_name1,file=filename_txt,append=F,col.names=F,row.names=F,sep=",")
write.table(data.df,file=filename_txt,append=T,col.names=T,row.names=F,sep=",")
###############################


##############################
### Determine axis maximum ###
##############################
axis.max <- max(percentile_95_ob,percentile_95_mod)
axis.min <- axis.max * 0.033

axis.length <- (axis.max - axis.min)
y1 <- axis.max - (axis.length * 0.750)                    # define y for species text
y2 <- axis.max - (axis.length * 0.800)                    # define y for timescale (averaging)

### If user sets axis maximum, compute axis minimum ###
if ((length(y_axis_max) > 0) || (length(x_axis_max) > 0)) {
   axis.max <- max(y_axis_max,x_axis_max)
   axis.min <- axis.max * 0.033
}
if ((length(y_axis_min) > 0) || (length(x_axis_min) > 0)) {
   axis.min <- min(y_axis_min,x_axis_min)
}
#######################################################


########################################################################################
### Set plot options and create blank plot area with correct lables and axis lengths ###
########################################################################################
plot_char <-16 
pdf(file=filename_pdf,width=8,height=8)
### Plot and draw rectangle with stats ###
par(mai=c(1,1,0.5,0.5),lab=c(8,8,7))
plot(1,1,type="n", pch=plot_char, col="red", ylim=c(axis.min, axis.max), xlim=c(axis.min, axis.max), xlab=paste("Observed ", species," (", units,")",sep=""), ylab=paste(model_name," ",species," (",units,")",sep=""), cex.axis=1.2, cex.lab=1.2)	# create plot axis and labels, but do not plot any points
text(axis.max,y1, network, cex=1, adj=c(1,0.5))
text(axis.max,y2, paste(species," (",units,")"), cex=1, adj=c(1,0.5))		# add species text
#########################################################################################

###################################
### Put title at top of boxplot ###
###################################
title(main=title,cex.main=1.1)
###################################

#######################################
### Plot points for each percentile ###
#######################################
#colors <- c("yellow","green","black","blue","red")
points(percentile_5_ob,percentile_5_mod,pch=plot_symbols[1],col=plot_colors[1],cex=.8)  # plot points for each network
points(percentile_25_ob,percentile_25_mod,pch=plot_symbols[2],col=plot_colors[2],cex=.8)  # plot points for each network
points(percentile_50_ob,percentile_50_mod,pch=plot_symbols[3],col=plot_colors[3],cex=.8)  # plot points for each network
points(percentile_75_ob,percentile_75_mod,pch=plot_symbols[4],col=plot_colors[4],cex=.8)  # plot points for each network
points(percentile_95_ob,percentile_95_mod,pch=plot_symbols[5],col=plot_colors[5],cex=.8)  # plot points for each network
legend_names <- c("5th","25th","50th","75th","95th")
legend_cols  <- plot_colors
legend_char <- plot_symbols
#######################################

##########################################
### Add descripitive text to plot area ###
##########################################
if (run_info_text == "y") {
   if (rpo != "None") {   
      text(x=axis.max,y=y[7], paste("RPO = ",rpo,sep=""),cex=1,adj=c(1,.5))		# add RPO region to plot
   }
   if (pca != "None") {
      text(x=axis.amx,y=y[7], paste("PCA = ",pca,sep=""),cex=1,adj=c(1,0.5))	# add PCA region to plot
   }
   if (state != "All") {
      text(x=axis.max,y=y[7], paste("State = ",state,sep=""),cex=1,adj=c(1,.5))	# add State abbreviation to plot
   }
   if (site != "All") {
      text(x=axis.max,y=y[7], paste("Site = ",site,sep=""),cex=1,adj=c(1,.5))			# add Site name to plot
   }
}
##########################################

#####################################################
### Put 1-to-1 lines and confidence lines on plot ###
##################################################### 
abline(0,1)                                     # create 1-to-1 line
if (conf_line=="y") {
   abline(0,(1/1.5),col="black",lty=1)              # create lower bound 2-to-1 line
   abline(0,1.5,col="black",lty=1)                # create upper bound 2-to-1 line
}
#####################################################

##############################
### Put legend on the plot ###
##############################
legend("topleft", legend_names, pch=legend_char,col=legend_cols, merge=F, cex=1.2, bty="n")
##############################

####################################
### Convert pdf file to png file ###
####################################
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density 150x150 ",filename_pdf," png:",filename_png,sep="")
   dev.off()
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_pdf,sep="")
      system(remove_command)
   }
}
####################################
