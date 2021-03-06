################## MODEL TO OBS SCATTERPLOT #################### 
### AMET CODE: R_Scatterplot.r 
###
### This script is part of the AMET-AQ system.  This script creates
### a single model-to-obs scatterplot. This script will plot a
### single species from up to three networks on a single plot.  
### Additionally, summary statistics are also included on the plot.  
### The script will also allow a second run to plotted on top of the
### first run. 
###
### Last Updated by Wyat Appel: April, 2017
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
if(!require(stats)){stop("Required Package stats was not loaded")}
if(!require(plotrix)){stop("Required Package plotrix was not loaded")}

mysql <- list(login=amet_login, passwd=amet_pass, server=mysql_server, dbase=dbase, maxrec=maxrec)

network <- network_names[1]

### Set file names and titles ###
filename_ecdf_pdf 	<- paste(run_name1,species,pid,"ecdf.pdf",sep="_")				# Set PDF filename
filename_ecdf_png 	<- paste(run_name1,species,pid,"ecdf.png",sep="_") 				# Set PNG filename
filename_qq_pdf 	<- paste(run_name1,species,pid,"qq.pdf",sep="_")                          # Set PDF filename
filename_qq_png 	<- paste(run_name1,species,pid,"qq.png",sep="_")                          # Set PNG filename
filename_taylor_pdf 	<- paste(run_name1,species,pid,"taylor.pdf",sep="_")                          # Set PDF filename
filename_taylor_png 	<- paste(run_name1,species,pid,"taylor.png",sep="_")                          # Set PNG filename
filename_spectral_pdf 	<- paste(run_name1,species,pid,"periodogram.pdf",sep="_")                          # Set PDF filename
filename_spectral_png 	<- paste(run_name1,species,pid,"periodogram.png",sep="_")                          # Set PNG filename

## Create a full path to file
filename_ecdf_pdf       <- paste(figdir,filename_ecdf_pdf,sep="/")                              # Set PDF filename
filename_ecdf_png       <- paste(figdir,filename_ecdf_png,sep="/")                              # Set PNG filename
filename_qq_pdf         <- paste(figdir,filename_qq_pdf,sep="/")                          # Set PDF filename
filename_qq_png         <- paste(figdir,filename_qq_png,sep="/")                          # Set PNG filename
filename_taylor_pdf     <- paste(figdir,filename_taylor_pdf,sep="/")                          # Set PDF filename
filename_taylor_png     <- paste(figdir,filename_taylor_png,sep="/")                          # Set PNG filename
filename_spectral_pdf   <- paste(figdir,filename_spectral_pdf,sep="/")                          # Set PDF filename
filename_spectral_png   <- paste(figdir,filename_spectral_png,sep="/")                          # Set PNG filename

if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1," ",species," for ",dates,sep="") }
   else { title <- custom_title }
}

#################################

axis.max     <- NULL
qq.axis.max  <- NULL
num_obs      <- NULL
sinfo        <- NULL
sinfo2	     <- NULL
avg_text     <- ""
legend_names <- NULL
legend_cols  <- NULL
legend_chars <- NULL
point_char   <- NULL
point_color  <- NULL

### Retrieve units and model labels from database table ###
units_qs <- paste("SELECT ",species," from project_units where proj_code = '",run_name1,"' and network = '",network,"'", sep="")
units <- db_Query(units_qs,mysql)
model_name_qs <- paste("SELECT model from aq_project_log where proj_code ='",run_name1,"'", sep="")
model_name <- db_Query(model_name_qs,mysql)
model_name <- model_name[[1]]
################################################

run_count <- 1
num_runs <- 1									# Set number of runs to 1
run_names <- run_name1
if ((exists("run_name2")) && (nchar(run_name2) > 0)) {
   num_runs <- 2
   run_names <- c(run_names,run_name2)						# If so, set number of runs to 2
}
if ((exists("run_name3")) && (nchar(run_name3) > 0)) {
   num_runs <- 3                                                                # If so, set number of runs to 2
   run_names <- c(run_names,run_name3)
}
run_name <- run_name1

network <- network_names[[1]]
   for (j in 1:length(run_names)) {
      run_name <- run_names[j]						# Set network
      criteria <- paste(" WHERE d.",species,"_ob is not NULL and d.network='",network,"' ",query,sep="")		# Set part of the MYSQL query
      check_POCode        <- paste("select * from information_schema.COLUMNS where TABLE_NAME = '",run_name,"' and COLUMN_NAME = 'POCode';",sep="")
      query_table_info.df <-db_Query(check_POCode,mysql)
      {
         if (length(query_table_info.df$COLUMN_NAME)==0) {
            qs <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,d.ob_dates,d.ob_datee,d.ob_hour,d.month,d.",species,"_ob,d.",species,"_mod, precip_ob, precip_mod from ",run_name," as d, site_metadata as s",criteria," ORDER BY network,stat_id",sep="")	# Set the rest of the MYSQL query
            aqdat_query.df        <- db_Query(qs,mysql)
            aqdat_query.df$POCode <- 1
         }
         else {
            qs <- paste("SELECT d.network,d.stat_id,d.lat,d.lon,d.ob_dates,d.ob_datee,d.ob_hour,d.month,d.",species,"_ob,d.",species,"_mod, precip_ob, precip_mod,d.POCode from ",run_name," as d, site_metadata as s",criteria," ORDER BY network,stat_id",sep="")        # Set the rest of the MYSQL query
            aqdat_query.df <- db_Query(qs,mysql)
         }
      }

      if (averaging != "n") {
         aqdat.df <- data.frame(Network=aqdat_query.df$network,Stat_ID=aqdat_query.df$stat_id,lat=aqdat_query.df$lat,lon=aqdat_query.df$lon,Obs_Value=round(aqdat_query.df[,9],5),Mod_Value=round(aqdat_query.df[,10],5),Hour=aqdat_query.df$ob_hour,Start_Date=aqdat_query.df$ob_dates,Month=aqdat_query.df$month,precip_ob=aqdat_query.df$precip_ob,precip_mod=aqdat_query.df$precip_mod)
         {
            if (use_avg_stats == "y") {
               aqdat.df <- Average(aqdat.df)
               aqdat_stats.df <- aqdat.df                               # Call Monthly_Average function in Misc_Functions.R
            }
            else {
               aqdat_stats.df <- aqdat.df
               aqdat.df <- Average(aqdat.df)
            }
         }
      }
      else { 
         aqdat.df <- aqdat_query.df
      ### if plotting all obs, remove missing obs and zero precip obs if requested ###
         ####################### 
         if (remove_negatives == "y") {
            indic.nonzero <- aqdat.df[,9] >= 0		# determine which obs are missing (less than 0); 
            aqdat.df <- aqdat.df[indic.nonzero,]	# remove missing obs from dataframe
            indic.nonzero <- aqdat.df[,10] >= 0          # determine which obs are missing (less than 0); 
            aqdat.df <- aqdat.df[indic.nonzero,]        # remove missing obs from dataframe
         }
         ######################
         aqdat.df <- data.frame(Network=aqdat.df$network,Stat_ID=aqdat.df$stat_id,lat=aqdat.df$lat,lon=aqdat.df$lon,Obs_Value=round(aqdat.df[,9],5),Mod_Value=round(aqdat.df[,10],5),Month=aqdat.df$month,precip_ob=aqdat.df$precip_ob)      # Create dataframe of network values to be used to create a list
         aqdat_stats.df <- aqdat.df
      }
      axis.max <- max(c(axis.max,aqdat.df$Obs_Value,aqdat.df$Mod_Value)) 

         sinfo[[j]]<-list(plotval_obs=aqdat.df$Obs_Value,plotval_mod=aqdat.df$Mod_Value)        # create of list of plot values and corresponding statistics
   }				# End for loop for networks
#######################################################

### Set Plotting Defaults ###
plot_cols <- plot_colors 
leg_names <- network_label[1]
#############################

###########################################
### Create Cumulative Distribution Plot ###
###########################################
pdf(file=filename_ecdf_pdf,width=8,height=8)
Fn_obs <- ecdf(sinfo[[1]]$plotval_obs)  	# Compute CDF information for observations
xmax <- max(sinfo[[1]]$plotval_obs,sinfo[[1]]$plotval_mod)
plot(Fn_obs, col='black', xlab=paste('value (', units,')',sep=""),xlim=c(0,xmax),main=paste("CDF for",run_name1,"/",network_label[1],species,"for",dates,sep=" "),cex.main=1)	# Plot CDF for Observations
for (i in 1:num_runs) {		# For each model simulation
   Fn_mod <- ecdf(sinfo[[i]]$plotval_mod)
   plot(Fn_mod, col=plot_cols[i], add=T)
   leg_names <- c(leg_names, run_names[i])
}
legend("bottomright", leg_names, pch=1, col=plot_colors,bty='n',cex=1,inset=c(0,0.03))	# Plot legend

if (run_info_text == "y") {
   if (rpo != "None") {
      text(x=xmax,y=.4, paste("RPO = ",rpo,sep=""),cex=1,adj=c(1,0.5))           # add RPO region to plot
   }
   if (pca != "None") {
      text(x=xmax,y=.37, paste("PCA = ",pca,sep=""),cex=1,adj=c(1.0,0.5))
   }
   if (state != "All") {
      text(x=xmax,y=.34, paste("State = ",state,sep=""),cex=1,adj=c(1,.5))       # add State abbreviation to plot
   }
   if (site != "All") {
      text(x=xmax,y=.31, paste("Site = ",site,sep=""),cex=1,adj=c(1,0.5))                     # add Site name to plot
   }
}

### Convert pdf file to png file ###
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density 150x150 ",filename_ecdf_pdf," png:",filename_ecdf_png,sep="")
   dev.off()
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_ecdf_pdf,sep="")
      system(remove_command)
   }
}
##########################################


##########################
### Create Taylor Plot ###
##########################
i <- 1
pdf(file=filename_taylor_pdf,width=8,height=8)
taylor.diagram(sinfo[[i]]$plotval_obs, sinfo[[i]]$plotval_mod,main=paste("Taylor Diagram for",run_name1,"/",network_label[1],species,"for",dates,sep=" "),cex.main=.9)
while (i < num_runs) {
   i <- i+1
   taylor.diagram(sinfo[[i]]$plotval_ob,sinfo[[i]]$plotval_mod,add=T,col=plot_cols[i])
}
legend("bottomright",legend=leg_names,pch=1,col=plot_colors,bty='n')

### Convert pdf file to png file ###
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density 150x150 ",filename_taylor_pdf," png:",filename_taylor_png,sep="")
   dev.off()
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_taylor_pdf,sep="")
      system(remove_command)
   }
}
####################################


###############################
### Create Periodogram Plot ###
###############################
i <- 1
num_obs <- length(sinfo[[i]]$plotval_obs)
if(num_obs < 10000) {	# Do not plot the periodogram for large datasets (takes too long)
   pdf(file=filename_spectral_pdf,width=8,height=8)
   spec.pgram(sinfo[[i]]$plotval_obs,col=plot_cols[1],main="")
for (i in 1:num_runs) {
   spec.pgram(sinfo[[i]]$plotval_mod,add=T,col=plot_cols[1+i])
}
   legend("bottomleft", legend=leg_names, lty=1, col=plot_colors, cex=1, bty="n")
   title(main=paste("Periodogram for",run_name1,"/",network_label[1],species,"for",dates,sep=" "),cex.main=1)

   ### Convert pdf file to png file ###
   if ((ametptype == "png") || (ametptype == "both")) {
      convert_command<-paste("convert -flatten -density 150x150 ",filename_spectral_pdf," png:",filename_spectral_png,sep="")
      dev.off()
      system(convert_command)

      if (ametptype == "png") {
         remove_command <- paste("rm ",filename_spectral_pdf,sep="")
         system(remove_command)
      }
   }
}
####################################


#####################################
### Create Quantile-Quantile Plot ###
#####################################
i <- 1
leg_names<-run_name1
leg_colors<-plot_colors
pdf(file=filename_qq_pdf,width=8,height=8)
for (j in 1:num_runs) {
   qq.axis.max <- max(qq.axis.max,sinfo[[j]]$plotval_obs,sinfo[[j]]$plotval_mod)
}
qq_tmp <- qqplot(sinfo[[i]]$plotval_obs,sinfo[[i]]$plotval_mod, plot.it=F)
plot(qq_tmp$x,qq_tmp$y,pch=1,xlab=paste('Observed ',species,' (',units,')',sep=""), xlim=c(0,qq.axis.max),ylim=c(0,qq.axis.max),ylab=paste('Predicted ',species,' (',units,')',sep=""), col=plot_cols[1])
while (i < num_runs) {         # For each model simulation
   i <- i+1
   qq_tmp <- qqplot(sinfo[[i]]$plotval_obs,sinfo[[i]]$plotval_mod, plot.it=F)
   points(qq_tmp$x,qq_tmp$y,col=plot_cols[i])
   leg_names <- c(leg_names, run_names[i])
   leg_colors <- c(leg_colors,plot_cols[i])
}  
abline(0,1)
title(main=paste("Q-Q Plot for",network_label[1],species,"for",dates,sep=" "),cex.main=1)
legend("topleft", leg_names, pch=1, col=plot_cols,bty='n',cex=1,inset=c(0,0.03))   # Plot legend

if (run_info_text == "y") {
   if (rpo != "None") {
      text(x=qq.axis.max,y=0, paste("RPO = ",rpo,sep=""),cex=1,adj=c(1,0.5))           # add RPO region to plot
   }
   if (pca != "None") {
      text(x=qq.axis.max,y=0.06*qq.axis.max, paste("PCA = ",pca,sep=""),cex=1,adj=c(1.0,0.5))
   }
   if (state != "All") {
      text(x=qq.axis.max,y=0.12*qq.axis.max, paste("State = ",state,sep=""),cex=1,adj=c(1,0.5))       # add State abbreviation to plot
   }
   if (site != "All") {
      text(x=qq.axis.max,y=0.18*qq.axis.max, paste("Site = ",site,sep=""),cex=1,adj=c(1,0.5))                     # add Site name to plot
   }
}

### Convert pdf file to png file ###
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density 150x150 ",filename_qq_pdf," png:",filename_qq_png,sep="")
   dev.off()
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_qq_pdf,sep="")
      system(remove_command)
   }
}
#####################################
