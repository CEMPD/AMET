#!/bin/csh -f
# --------------------------------
# Scatterplot
# -----------------------------------------------------------------------
# Purpose:
#
# This is an example c-shell script to run the R-script that generates
# a box plot without whiskers.  The script is designed to create a box
# plot with on monthly boxes.  Individual observation/model pairs are
# provided through a MYSQL query, from which the script computes the
# 25% and 75% quartiles, as well as the median values for both obs and
# model values.  The script then plots these values as a box plot.
# While the script is designed to be used with an entire year of data,
# it can be used with a shorter time period.  However, no less than
# three months should be used, since any period of time shorter than
# that can cause elements of the plot (text) to be misplaced on the
# plot area. Designed for one species and one network.
#
# Initial version:  Alexis Zubrow IE UNC - Nov, 2007
#
# Revised version:  Wyat Appel - Dec, 2012
# -----------------------------------------------------------------------

  
  #--------------------------------------------------------------------------
  # These are the main controlling variables for the R script
  
  #  Top of AMET directory
  setenv AMETBASE  /project/amet_aq/AMET_Code/Release_Code_v13/AMET_v13
 
  #  AMET database
  setenv AMET_DATABASE Test_AMETv13
 
  #  AMET project id or simulation id
  setenv AMET_PROJECT	aqExample	
  
  #  Directory where figures and text output will be directed
  setenv AMET_OUT       $AMETBASE/output/$AMET_PROJECT/boxplot
  
  #  Start and End Dates of plot (YYYYMMDD) -- must match available dates in db
  setenv AMET_SDATE "20110701"             
  setenv AMET_EDATE "20110731"             

  # Process ID. This can be set to anything. It will be added to the file output name. Default is 1.
  # The PID is particularly important if using the AMET web interface and is determined there through
  # a random number generator.
  setenv AMET_PID 1

  #  Custom title (if not set will autogenerate title based on variables 
  #  and plot type)
  setenv AMET_TITLE "Boxplot $AMET_PROJECT $AMET_SDATE - $AMET_EDATE"


  #  Plot Type, options are "pdf" or "png"
  setenv AMET_PTYPE pdf


  ### Species to Plot ###
  ### Acceptable Species Names: SO4,NO3,NH4,HNO3,TNO3,PM_TOT,PM25_TOT,PM_FRM,PM25_FRM,EC,OC,TC,O3,O3_1hrmax,O3_8hrmax
  ### SO2,CO,NO,SO4_dep,SO4_conc,NO3_dep,NO3_conc,NH4_dep,NH4_conc,precip,NOy 
  ### AE6 (CMAQv5.0) Species
  ### Na,Cl,Al,Si,Ti,Ca,Mg,K,Mn,Soil,Other,Ca_dep,Ca_conc,Mg_dep,Mg_conc,K_dep,K_conc

  setenv AMET_AQSPECIES PM_TOT

  ### Observation Network to plot -- One only
  ###  set to 'y' to turn on, default is off
  ###  NOTE: species are not available in every network
#  setenv AMET_CSN y
#  setenv AMET_IMPROVE y
#  setenv AMET_CASTNET y
#  setenv AMET_CASTNET_Hourly y
#  setenv AMET_CASTNET_Drydep y
#  setenv AMET_NADP y
#  setenv AMET_AIRMON y
#  setenv AMET_AQS_Hourly y
#  setenv AMET_AQS_Daily_O3 y
  setenv AMET_AQS_Daily y
#  setenv AMET_SEARCH y
#  setenv AMET_SEARCH_Daily y
#  setenv AMET_CAPMON y
#  setenv AMET_NAPS_Hourly y

### Europe Networks ###

#  setenv AMET_AirBase_Hourly y
#  setenv AMET_AirBase_Daily y
#  setenv AMET_AURN_Hourly y
#  setenv AMET_AURN_Daily y
#  setenv AMET_EMEP_Hourly y
#  setenv AMET_EMEP_Daily y
#  setenv AMET_AGANET y
#  setenv AMET_ADMN y
#  setenv AMET_NAMN y

  # Log File for R script
  setenv AMET_LOG boxplot.log

##--------------------------------------------------------------------------##
##                Most users will not need to change below here
##--------------------------------------------------------------------------##

  ## Set the input file for this R script
  setenv AMETRINPUT $AMETBASE/scripts_analysis/$AMET_PROJECT/input_files/boxplot.input  
  setenv AMET_NET_INPUT $AMETBASE/scripts_analysis/$AMET_PROJECT/input_files/Network.input
  
  # Check for plot and text output directory, create if not present
  if (! -d $AMET_OUT) then
     mkdir -p $AMET_OUT
  endif

  # R-script execution command
  R CMD BATCH --no-save --slave $AMETBASE/R_analysis_code/AQ_Boxplot.R $AMET_LOG 
  setenv AMET_R_STATUS $status
  
  if($AMET_R_STATUS == 0) then		
  echo
		echo "Statistics information"
		echo "-----------------------------------------------------------------------------------------"
		echo "Plot   ---------->" $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_boxplot.$AMET_PTYPE
                echo "Plot   ---------->" $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_boxplot_bias.$AMET_PTYPE
                echo "Plot   ---------->" $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_boxplot_norm_bias.$AMET_PTYPE
		echo "-----------------------------------------------------------------------------------------"
		exit(0)
  else
     echo "The AMET R script did not produce any output, please check the LOGFILE $AMET_LOG for more details on the error."
     echo "Often, this indicates no data matched the specified criteria (e.g., wrong dates for project). Please check and re-run!"
  		exit(1)
  endif
  
  
  
  
