# make file to build sitecmp_daily program

PROGRAM = bldoverlay.exe

IOAPI = $(IOAPI_DIR)/lib
NETCDF = $(NETCDF_DIR)/lib

FC = ${myFC}
FC_FLAGS = ${myFFLAGS} -I${IOAPI} -I. $(INCLUDES)

#   Libraries
 LIBRARIES = -L${IOAPI} -lioapi -L${NETCDF} -lnetcdf ${extra_lib}



OBJS=   \
 module_sites.o \
 parser.o \
 getTZ.o \
 bldoverlay.o

$(PROGRAM):  $(OBJS)
	$(FC) $(myLINK_FLAG) $(OBJS) $(LIBRARIES) -o $(PROGRAM)

.F.o:
	$(FC) -c $(FC_FLAGS) $<

.f.o:
	$(FC) -c $(FC_FLAGS) $<

clean:
	rm -f $(OBJS) *.mod

