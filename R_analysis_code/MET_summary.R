#########################################################################
#-----------------------------------------------------------------------#
#                                                                       #
#                AMET (Atmospheric Model Evaluation Tool)               #
#                                                                       #
#                     Summary Statistics Plots                          #
#                         MET_summary.R                                 #
#                                                                       #
#                                                                       #
#         Version: 	1.3                                             #
#         Date:		May 15, 2017                                    #
#         Contributors:	Robert Gilliam                                  #
#                                                                       #
#         Developed by the US Environmental Protection Agency           #
#-----------------------------------------------------------------------#
#########################################################################
#-----------------------------------------------------------------------#
#                                                                       #
#       Modified for MET/AQ combined setup --                           #
#                   Alexis Zubrow (IE UNC), Oct 2007                    #
#                                                                       #
#-----------------------------------------------------------------------#
# Version 1.2, May 8, 2013, Rob Gilliam                                 #
# Updates: - Pulled some configurable options out of MET_plot_prof.R    #
#            and placed into the plot_prof.input file                   #
#          - Extensive cleaning of R script, R input and .csh files     #
#                                                                       #
#  Version 1.3, May 15, 2017, Rob Gilliam                               # 
#  Updates: - Removed old amet-config.R configuration option that       #
#             defined MySQL server, database and password (unsecure).   #
#           - Added a read password and MySQL config though wrapper     #
#             and setenv statements.                                    # 
#           - Removed some deprecated variables and cleaned/formatted   #
#             script for better readability. Also changed dir names     #
#             to reflect the update (i.e., R_analysis_code instead of R)#      
#-----------------------------------------------------------------------#
#                                                                       #
#########################################################################

#########################################################################
#:::::::::::::::::::::::::::::::::::::::::::::
#	Load required modules
  if(!require(RMySQL)){stop("Required Package RMySQL was not loaded")}
  if(!require(maps)){stop("Required Package maps was not loaded")}

########################################################
#    Initialize AMET Diractory Structure Via Env. Vars
#    AND Load required function and conf. files
##############################################################################################

 ## Get environmental variables and setup main AMET directories and files
 ametbase         <-Sys.getenv("AMETBASE")
 ametR            <-paste(ametbase,"/R_analysis_code",sep="")
 ametRinput       <- Sys.getenv("AMETRINPUT")
 mysqlloginconfig <-Sys.getenv("MYSQL_CONFIG")

 # Check for output directory via namelist and AMET_OUT env var, if not specified in namelist
 # and not specified via AMET_OUT, then set figdir to the current directory
 if(!exists("figdir") )                         { figdir <- Sys.getenv("AMET_OUT")	}
 if( length(unlist(strsplit(figdir,""))) == 0 ) { figdir <- "./"			}

 ## source some configuration files, AMET libs, and input
 source (paste(ametR,"/MET_amet.misc-lib.R",sep=""))
 source (paste(ametR,"/MET_amet.plot-lib.R",sep=""))
 source (paste(ametR,"/MET_amet.stats-lib.R",sep=""))
 source (mysqlloginconfig)
 source (ametRinput)
 
 ametdbase      <- Sys.getenv("AMET_DATABASE")
 mysqlserver    <- Sys.getenv("MYSQL_SERVER")
 mysql          <-list(server=mysqlserver,dbase=ametdbase,login=mysqllogin,
                       passwd=mysqlpasswd,maxrec=maxrec)

#################################################################################################################
#	MAIN SUMMARY STATISTICS PROGRAM
#################################################################################################################
 # Create query string
 varsName	<-c("Temperature (2m)","Specific Humidity (2m)","Wind Speed (10m)","Wind Direction (deg.)")
 varid		<-c("T","Q","WS","WD")
 varxstr	<-paste("SELECT DATE_FORMAT(ob_date,'%Y%m%d'),HOUR(ob_time),d.stat_id,s.ob_network,d.T_mod,d.T_ob, 
                   d.Q_mod,d.WVMR_ob, d.U_mod,d.U_ob, d.V_mod,d.V_ob")
 query		<-paste(varxstr," FROM ",project,"_surface d, stations s WHERE  s.stat_id=d.stat_id ",querystr,sep="")
################################################################################
 for(q in 1:length(query)){
   
    #   1) Query the database for the met data
    writeLines("Query used to extract data from MySQL database:")
    writeLines(paste(query))
    data<-ametQuery(query[q],mysql)
    if (length(na.omit(data)) == 0){next;}	# stop if no data is found

    # Save dataframe into R datafile if specified
    if(wantsave){
         save(data,file=paste(savedir,"/",pid[q],".web_query.Rdata",sep=""))
    }
    
    # if text statistics are specified, open text file and write header lines
    if (textstats){   
         sfile<-file(paste(figdir,"/tmp",sep=""),"w") 
         writeLines("Model Evaluation Metrics", con =sfile)
         writeLines("--------------------------------------------------------", con =sfile)
    }

    locs<-c(1,2,3,4,5,6,9,10,11,12,7,8)
    datap<-massageTseries(data,loc=locs,qcerror=c(15,15,10),iftseries=F,addrand=FALSE)

    if (diurnal){
         ################################
         #	Temperature Stats	#
         ################################
         writeLines("Plotting diurnal Temperature.. Figure name:")
         figure<-paste(figdir,"/",project,".",pid[q],".T.diurnal",sep="")
         obs<-datap$temp[,2]
         mod<-datap$temp[,1]
         if(length(na.omit(obs)) > 0 ) {
         var<-data.frame(as.POSIXlt(datap$date, tz="GMT")$hour,mod,obs)
         labels<-list(varname="2 m Temperature",amet="NOAA/EPA AMET Product",units="K")
         try(dstats<-diurnalplot(var,statloc=dstatloc,figure,plotopts=plotopts,labels=labels))

         if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Diurnal Temperature (2 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(dstats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",col.names=dstats$id, row.names=F, quote=FALSE)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
         #######################################################################################
         ################################
         #	Wind Speed Stats	#
         ################################
         writeLines("Plotting diurnal Wind Speed.. Figure name:")
         figure<-paste(figdir,"/",project,".",pid[q],".WS.diurnal",sep="")
         obs<-datap$ws[,2]
         mod<-datap$ws[,1]
         if(length(na.omit(obs)) > 0 ) {
         var<-data.frame(as.POSIXlt(datap$date, tz="GMT")$hour,mod,obs)
         labels<-list(varname="10 m Wind Speed",amet="NOAA/EPA AMET Product",units="m/s")
         try(dstats<-diurnalplot(var,statloc=dstatloc,figure,plotopts=plotopts,labels=labels))

         if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Diurnal Wind Speed (10 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(dstats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",col.names=dstats$id,quote=FALSE, row.names=F)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
         #######################################################################################
         ################################
         #	Wind Direction Stats	#
         ################################
         writeLines("Plotting diurnal Wind Direction.. Figure name:")
         figure<-paste(figdir,"/",project,".",pid[q],".WD.diurnal",sep="")
         obs=datap$wd[,2]
         mod=datap$wd[,1]
         diff<-mod-obs
         diff<-ifelse(diff > 180 , diff-360, diff)
         diff<-ifelse(diff< -180 , diff+360, diff)
         obs<-runif(length(diff),min=0,max=0.001)
         mod<-diff
         if(length(na.omit(obs)) > 0 ) {
         var<-data.frame(as.POSIXlt(datap$date, tz="GMT")$hour,mod,obs)
         labels<-list(varname="10 m Wind Direction",amet="NOAA/EPA AMET Product",units="deg")
         try(dstats<-diurnalplot(var,statloc=dstatloc,figure,plotopts=plotopts,labels=labels))

         if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Diurnal Wind Direction (10 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(dstats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",col.names=dstats$id,quote=FALSE, row.names=F)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
         #######################################################################################
         ################################
         #	Mixing Ratio Stats	#
         ################################
         writeLines("Plotting diurnal Mixing Ratio.. Figure name:")
         figure<-paste(figdir,"/",project,".",pid[q],".Q.diurnal",sep="")
         obs<-datap$q[,2]*1000
         mod<-datap$q[,1]*1000
         if(length(na.omit(obs)) > 0 ) {
         var<-data.frame(as.POSIXlt(datap$date, tz="GMT")$hour,mod,obs)
         labels<-list(varname="2 m Mixing Ratio",amet="NOAA/EPA AMET Product",units="g/kg")
         try(dstats<-diurnalplot(var,statloc=dstatloc,figure,plotopts=plotopts,labels=labels))

         if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Diurnal Mixing Ratio (2 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(dstats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",col.names=dstats$id,quote=FALSE, row.names=F)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
         #######################################################################################

  }	## 	END OF DIURNAL PLOTS AND TABLES
  
  ###################################################################################################
  #	AMET Performance Plot Option
  ###################################################################################################
  if (ametp){
         #######################################################################################
         ################################
         #	Temperature Stats	#
         ################################
         figure<-paste(figdir,"/",project,".",pid[q],".T.ametplot",sep="")
         qdesc<-c(mysql$server,mysql$dbase,mysql$login,"pass",project,model,queryID[q],varid[1],
                  statid,obnetwork,lat,lon,elev,landuse,dates[q],datee[q],obtime,fcasthr,level,syncond,query[q],figure,1)
         obs=datap$temp[,2]
         mod=datap$temp[,1]
         if(length(na.omit(obs)) > 0 ) {
         var<-list(obs=obs,mod=mod)
         stats<-genvarstats(var,varsName[1])
         try(ametplot(obs,mod,datap$ws[,2],stats$metrics,qdesc=qdesc,pid=pid,figureid=figure,plotopts=plotopts))
          if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Collective Temperature (2 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(stats$id,stats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",quote=FALSE, row.names=F)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
         #######################################################################################
         ################################
         #	Wind Speed Stats	#
         ################################
         figure<-paste(figdir,"/",project,".",pid[q],".WS.ametplot",sep="")
         qdesc<-c(mysql$server,mysql$dbase,mysql$login,"pass",project,model,queryID[q],varid[3],statid,
                  obnetwork,lat,lon,elev,landuse,dates[q],datee[q],obtime,fcasthr,level,syncond,query[q],figure,1)
         obs=datap$ws[,2]
         mod=datap$ws[,1]
         if(length(na.omit(obs)) > 0 ) {
         var<-list(obs=obs,mod=mod)
         stats<-genvarstats(var,varsName[3])
         try(ametplot(obs,mod,datap$ws[,2],stats$metrics,qdesc=qdesc,pid=pid,figureid=figure,plotopts=plotopts))

          if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Collective Wind Speed (10 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(stats$id,stats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",quote=FALSE, row.names=F)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
        #######################################################################################
         ################################
         #	Wind Direction Stats	#
         ################################
         writeLines("Plotting summary of Wind Direction.. Figure name:")
         figure<-paste(figdir,"/",project,".",pid[q],".WD.ametplot",sep="")
         qdesc<-c(mysql$server,mysql$dbase,mysql$login,"pass",project,model,queryID[q],varid[4],statid,
                  obnetwork,lat,lon,elev,landuse,dates[q],datee[q],obtime,fcasthr,level,syncond,query[q],figure,4)
         obs=datap$wd[,2]
         mod=datap$wd[,1]
         diff<-mod-obs
         diff<-ifelse(diff > 180 , diff-360, diff)
         diff<-ifelse(diff< -180 , diff+360, diff)
         obs<-runif(length(diff),min=0,max=0.001)
         mod<-diff
         if(length(na.omit(obs)) > 0 ) {
         var<-list(obs=obs,mod=mod)
         stats<-genvarstats(var,varsName[4])
         try(ametplot(obs,mod,datap$ws[,2],stats$metrics,qdesc=qdesc,pid=pid,figureid=figure,wdflag=1,plotopts=plotopts))

          if (textstats){
   	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Collective Wind Direction (10 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(stats$id,stats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",quote=FALSE)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
        #######################################################################################
         ################################
         #	Mixing Ratio Stats	#
         ################################
         writeLines("Plotting summary of Mixing Ratio.. Figure name:")
         figure<-paste(figdir,"/",project,".",pid[q],".Q.ametplot",sep="")
         qdesc<-c(mysql$server,mysql$dbase,mysql$login,"pass",project,model,queryID[q],varid[2],
                  statid,obnetwork,lat,lon,elev,landuse,dates[q],datee[q],obtime,fcasthr,level,syncond,query[q],figure,1)
         obs=datap$q[,2]*1000
         mod=datap$q[,1]*1000
         if(length(na.omit(obs)) > 0 ) {
         var<-list(obs=obs,mod=mod)
         stats<-genvarstats(var,varsName[2])
         try(ametplot(obs,mod,datap$ws[,2],stats$metrics,qdesc=qdesc,pid=pid,figureid=figure,plotopts=plotopts))

          if (textstats){
    	      sfile<-file(paste(figdir,"/tmp",sep=""),"a") 
    	      writeLines("--------------------------------------------------------", con =sfile)
              writeLines("Collective Mixing Ratio (2 m) Statistics", con =sfile)
              close(sfile)
    
              tmp<-data.frame(stats$id,stats$metrics)
              write.table(tmp,paste(figdir,"/tmpx",sep=""),sep=",",quote=FALSE)
              system(paste("cat ",figdir,"/tmp ",figdir,"/tmpx> ",figdir,"/tmpxx",sep=""))
              system(paste("mv ",figdir,"/tmpxx ",figdir,"/tmp",sep=""))
         }
         rm(obs,mod,var,stats,tmp)
         }
        #######################################################################################

   }	## END of AMET PLOT
   # If Text statistic file is generated mv final temporary file figdir/tmp to savedir/stats.some_process_id.dat	
   if (textstats){
   	system(paste("mv ",figdir,"/tmp ",savedir,"/stats.",project,".",pid[q],".dat",sep=""))
   	system(paste("rm -f ",figdir,"/tmp* ",sep=""))
   }
 } #   END OF LOOP THROUGH Queries   	
