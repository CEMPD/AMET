##################### SOCCER GOAL PLOT #########################
### AMET CODE: R_Soccerplot.R
###
### This script is part of the AMET-AQ system.  It plots a unique
### type of plot referred to as a "soccer goal" plot. The idea behind
### the soccer goal plot is that criteria and goal lines are plotted
### in such a way as to form a "soccer goal" on the plot area.  Two
### statistics are then plotted, Bias (NMB, FB, NMdnB) on the x-axis and
### error (NME, FE, NMdnE) on the y-axis.  The better the performance of the
### model, the closer the plotted points will fall within the "goal"
### lines.  This type of plot is used by EPA and RPOs as part of their
### assessment of model performance.
###
### Last updated by Wyat Appel; June 2017
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
   if (custom_title == "") { title <- paste("Soccergoal plot for ",run_name1," for ",dates,"; State=",state,"; Site=",site,sep="") }   
   else { title <- custom_title }
}

filename_pdf <- paste(run_name1,pid,"soccerplot.pdf",sep="_")             # Set PDF filename
filename_png <- paste(run_name1,pid,"soccerplot.png",sep="_")             # Set PNG filename
filename_txt <- paste(run_name1,pid,"soccerplot.csv",sep="_")       # Set output file name

## Create a full path to file
filename_pdf <- paste(figdir,filename_pdf,sep="/")      # Set PDF filename
filename_png <- paste(figdir,filename_png,sep="/")      # Set PNG filenam
filename_txt <- paste(figdir,filename_txt,sep="/")      # Set output file name

mysql <- list(login=root_login, passwd=root_pass, server=mysql_server, dbase=dbase, maxrec=1000000)
con             <- dbConnect(MySQL(),user=root_login,password=root_pass,dbname=dbase,host=mysql_server)
MYSQL_tables    <- dbListTables(con)
dbDisconnect(con)

### Retrieve units label from database table ###
network <- network_names[1]
#################################################

### Set initial NULL vectors ###
plot_vals <- NULL
################################
species_query <- paste("d.",species[1],"_ob, d.",species[1],"_mod",sep="")
if (length(species) > 1) {
   for (i in 2:length(species)) {
      species_query <- paste(species_query,",d.",species[i],"_ob, d.",species[i],"_mod",sep="")
   }
}

for (j in 1:length(network_names)) {	# Loop through each network
   mean_obs      <- NULL
   mean_mod      <- NULL
   nmb           <- NULL				
   nme           <- NULL
   fb            <- NULL
   fe            <- NULL
   nmdnb	 <- NULL
   nmdne	 <- NULL
   drop_names    <- NULL
   network       <- network_names[[j]]						# Set network name based on loop value
#   criteria <- paste(" WHERE d.",species[1],"_ob is not NULL and d.network='",network,"' ",query,sep="")          # Set part of the MYSQL query
   criteria <- paste(" where d.network='",network,"' ",query,sep="")          # Set part of the MYSQL query
   qs	<- paste("SELECT d.network,d.stat_id,d.lat,d.lon,d.ob_dates,d.ob_datee,d.ob_hour,d.month,",species_query,",d.precip_ob from ",run_name1," as d, site_metadata as s",criteria," ORDER BY network,stat_id",sep="")    # Set the rest of the MYSQL query 
   aqdat_all.df      <- db_Query(qs,mysql)						# Query the database for a specific species

   l <- 9
   if (network == 'AQS_Hourly') {
      cat(qs)
      cat(aqdat_all.df$network)
   }
   for (i in 1:length(species)) { 								# For each species, calculate several statistics
     data_all.df <- data.frame(network=I(aqdat_all.df$network),stat_id=I(aqdat_all.df$stat_id),lat=aqdat_all.df$lat,lon=aqdat_all.df$lon,ob_val=aqdat_all.df[,l],mod_val=aqdat_all.df[,(l+1)],precip_val=aqdat_all.df$precip_ob)	# Create properly formatted dataframe to use with DomainStats function
      good_count <- sum(!is.na(data_all.df$ob_val))		# Count the number of non-missing values
      if (good_count > 0) {					# If there are non-missing values, continue
         stats_all.df <- DomainStats(data_all.df)		# Call DomainStats function to compute stats for the entire domain
         if (!is.null(stats_all.df)) {
            mean_obs <- c(mean_obs,stats_all.df$MEAN_OBS) 
            mean_mod <- c(mean_mod,stats_all.df$MEAN_MODEL)
            nmb <- c(nmb,stats_all.df$Percent_Norm_Mean_Bias)	# Store NMB values from DomainStats in vector called nmb
            nme <- c(nme,stats_all.df$Percent_Norm_Mean_Err)	# Store NME values from DomainStats in vector called nme
            fb  <- c(fb,stats_all.df$Frac_Bias)			# Store FB values from DomainStats in vector called fb
            fe  <- c(fe,stats_all.df$Frac_Err)			# Store FE values from DomainStats in vector called fe
            nmdnb <- c(nmdnb,stats_all.df$Norm_Median_Bias)	# Store NMdnB values in vector
            nmdne <- c(nmdne,stats_all.df$Norm_Median_Error)	# Store NmdnE values in vector
         }
         else {
            mean_obs <- c(mean_obs,NA)
            mean_mod <- c(mean_mod,NA)
            nmb      <- c(nmb,NA)
            nme      <- c(nme,NA)
            fb       <- c(fb,NA)
            fe       <- c(fe,NA)
            nmdnb    <- c(nmdnb,NA)
            nmdne    <- c(nmdne,NA)
         } 
      }
      else {				# If all values are missing, set statistic value to NA
         mean_obs <- c(mean_obs,NA)
         mean_mod <- c(mean_mod,NA)
         nmb	  <- c(nmb,NA)
         nme	  <- c(nme,NA)
         fb	  <- c(fb,NA)
         fe	  <- c(fe,NA)
         nmdnb	  <- c(nmdnb,NA)
         nmdne	  <- c(nmdne,NA)
      }
      l   <- l+2								# Increment to next ob specie column
      i <- i+1
   }

   if (soccerplot_opt == 1) { 							# If user selected to use NMB/NME for plot axes	
      plot_vals[[j]] <- list(Species=species,VAL1=nmb,VAL2=nme) 		# Set plot values to be used as nmb and nme vectors
      xlabel <- "Normalized Mean Bias (%)"					# Set x-axis label as NMB
      ylabel <- "Normalized Mean Error (%)"					# Set y-axis label as NME
   }
   if (soccerplot_opt == 2) { 									# Else use FB/FE for plot axes
      plot_vals[[j]] <- list(Species=species,VAL1=fb,VAL2=fe)		# Set plot values to be used as fb and fe vectors
      xlabel <- "Fractional Bias (%)"						# Set x-axis label as FB
      ylabel <- "Fractional Error (%)"						# Set y-axis label as FE
   }
   if (soccerplot_opt == 3) {
      plot_vals[[j]] <- list(Species=species,VAL1=nmdnb,VAL2=nmdne)	# Set plot values to be used as fb and fe vectors
      xlabel <- "Normalized Median Bias (%)"					# Set x-axis label as NMdnB
      ylabel <- "Normalized Median Error (%)"					# Set y-axis label as NMdnE
   }
}

####################################

plot_chars <- seq(from=1,to=30,by=1)

###########################################################
########## MAKE SOCCERPLOT: DOMAIN / All SPECIES ##########
###########################################################

pdf(file=filename_pdf,width=10,height=8)
par(mai=c(1,1,0.5,1))									# Set margins
plot(1, 1, type="n",pch=2, col="green", ylim=c(4.8,125), xlim=c(-85, 85), xlab=xlabel, ylab=ylabel, cex.axis=1.2, cex.lab=1.4, axes=FALSE)
axis(1,at=c(-100,-75,-60,-45,-30,-15,0,15,30,45,60,75,100),cex.axis=1.4) 		# Create x-axis
axis(2,at=c(0,25,50,75,100,125),cex.axis=1.4,las=2)					# Create left side y-axis
axis(4,at=c(0,25,50,75,100,125),cex.axis=1.4,las=2)					# Create right side y-axis
mtext(ylabel,side=4,adj=0.5,line=3,cex=1.4)
lines(c(0,0),c(0,125))									# Draw center line
abline(h=125) 										# Create top border line
rect(ybottom=0,ytop=35,xright=15,xleft=-15,lty=2,lwd=1,border="grey45")			# Create rectangle for 35/15 box
rect(ybottom=0,ytop=50,xright=30,xleft=-30,lty=2,lwd=1,border="grey45")			# Create rectangle for 75/30 box
rect(ybottom=0,ytop=75,xright=60,xleft=-60,lty=2,lwd=1,border="grey45")
text(-3,35,"35",cex=1.2)								# Add text for 35% goal line
text(-3,50,"50",cex=1.2)								# Add text for 50% goal line
text(-3,75,"75",cex=1.2) 								# Add text for 75% goal line
abline(h=0)

legend_names <- species
legend_chars <- plot_chars
values <- NULL 
for (n in 1:length(network_names)) {							# For each network, plot values as points
   y <- c(120,115,110,105,100,95,90,85)							# Y offsets for network labels (used below)
   for (i in 1:length(species)) {							# Plot each available species
      points(plot_vals[[n]]$VAL1[i],plot_vals[[n]]$VAL2[i],pch=plot_chars[i],col=plot_colors[n],cex=2)            # Plot points using the appropriate character
   } 
   text(50,y[n],network_label[n],col=plot_colors[n],pos=4,cex=1.3)			# Add text for the network on the plot area
}

### Put title at top of boxplot ###
title(main=title,cex.main=1.2)
###################################

### Put legend on the plot ###
legend(-90,125, legend_names, pch=legend_chars, col="black", merge=F, cex=1.3, bty="n")
##############################

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
#############################################

