##################################################################
## Filename: amet-config.R                                      ##
##                                                              ##
## This file is required by the various AMET R scripts.		##
##                                                              ##
## This file provides necessary MYSQL information to the file   ##
## above so that data from Site Compare can be added to the     ##
## systems MYSQL database.					## 
##################################################################

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
## Directory Paths
amet_base         <-  "/project/amet_aq/AMET_Code/Release_Code_v13/AMET_v13";   		# The AMET base directory where AMET is installed

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
## MySQL Configuration
mysql_server	<- "darwin.rtpnc.epa.gov"	## Name of MYSQL server
amet_login	<- "wyat"			## AMET Root login for MYSQL server
amet_pass	<- "283ButterFish!"		## AMET Root password for MYSQL server
maxrec		<- -1				## Set MySQL maximum records for queries (-1 for no maximum)

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
## Misc Executables 
#Bldoverlay_exe    <- paste(amet_base,"/src/bldoverlay/bldoverlay.exe",sep="")	## Path to boundary overlay executable
#EXEC_sitex_daily  <-  paste(amet_base,"/src/sitecmp_dailyo3/sitecmp_dailyo3.exe,sep="")        # full path to site compare daily executable
#EXEC_sitex        <-  paste(amet_base,"/src/sitecmp/sitecmp.exe",sep="")                       # full path to site compare executable
Bldoverlay_exe	  <- "/home/appel/bin/bldoverlay.exe"	## Path to boundary overlay executable
EXEC_sitex_daily  <-  paste(amet_base,"/bin/sitecmp_daily_newheader_poc.exe",sep="")	# full path to site compare daily executable
EXEC_sitex        <-  paste(amet_base,"/bin/sitecmp_newheader_poc.exe",sep="")          # full path to site compare executable
