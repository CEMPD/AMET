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
amet_base         <-  "/proj/ie/apps/AMET/CEMPD_AMET_v13";   		# The AMET base directory where AMET is installed

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
## MySQL Configuration
mysql_server	<- "treehug.its.unc.edu"	## Name of MYSQL server
amet_login	<- "cep-amet"	## AMET Root login for MYSQL server
amet_pass	<- "LBMVBF1"	## AMET Root password for MYSQL server
maxrec		<- -1				## Set MySQL maximum records for queries (-1 for no maximum)

##::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
## Misc Executables 
Bldoverlay_exe	<- "/proj/ie/apps/AMET/CEMPD_AMET_v13/src/bldoverlay/bldoverlay.exe"	## Path to boundary overlay executable
EXEC_sitex_daily  <-  "/proj/ie/apps/AMET/CEMPD_AMET_v13/src/sitecmp_dailyo3/sitecmp_dailyo3.exe"                      # full path to site compare daily executable
EXEC_sitex        <-  "/proj/ie/apps/AMET/CEMPD_AMET_v13/src/sitecmp/sitecmp.exe"                            # full path to site compare executable

