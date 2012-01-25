
#------------------------------------------------------------
# This file defines various libraries to be used
# during compilation. Defaults are usually ok.
#------------------------------------------------------------

##############################################
# DEFINE DIRECTORIES
##############################################

DEFDIR  = $(HOME)
FEMDIR  = ..
DIRLIB  = $(FEMDIR)/femlib

LIBX = -L/usr/X11R6/lib -L/usr/X11/lib -L/usr/lib/X11  -lX11

##############################################
# Parameters
##############################################
#
# Here you should set all your application 
# specific parameters. The ones below are
# usually the only ones you have to bother.
# However, if you have special needs you can
# also set all the other parameters. Please see
# param.h for more details.
#
##############################################

export MBWDIM = 300
export NGRDIM = 12

#-----------------------

#export NKNDIM = 11000
#export NELDIM = 22000
#export NLVDIM = 33

# asi-zec
#export NKNDIM = 17000
#export NELDIM = 30000
#export NLVDIM = 1
#export NLVDIM = 52
#export NGRDIM = 12

# curonian
#export NKNDIM = 13000
#export NELDIM = 26000
#export NLVDIM = 1

# curonian petras
#export NKNDIM = 12900
#export NELDIM = 22900
#export NLVDIM = 20
#export MBWDIM = 173
#export NGRDIM = 11

# ginevra
#export NKNDIM = 1100
#export NELDIM = 2200
#export NLVDIM = 200

# kassandra
#export NKNDIM = 81000
#export NELDIM = 145000
#export NLVDIM = 1
#export NGRDIM = 15
#export MBWDIM = 300

# adriatico_DEFB_nolag
export NKNDIM = 24000
export NELDIM = 44000
export NLVDIM = 27
export NGRDIM = 12
export MBWDIM = 295

# isabella
#export NKNDIM = 14000
#export NELDIM = 26000
#export NLVDIM = 16
#export MBWDIM = 200
#export NGRDIM = 10

# skadar
#export NKNDIM = 12000
#export NELDIM = 24000
#export NLVDIM = 20

# Skadar new
#export NKNDIM = 20610
#export NELDIM = 39170
#export NLVDIM = 10
#export NGRDIM = 15
#export MBWDIM = 220
#export NBCDIM = 50

# trieste
#export NKNDIM = 26000
#export NELDIM = 51000
#export NLVDIM = 17

# Venice
#export NKNDIM = 5000
#export NELDIM = 8000
#export NLVDIM = 1
#export MBWDIM = 70

# Marano-Grado
#export NKNDIM = 12000
#export NELDIM = 22000
#export NLVDIM = 1
#export MBWDIM = 300

# Black-Sea
#export NKNDIM = 12000
#export NELDIM = 22000
#export NLVDIM = 30
#export MBWDIM = 240

# trieste small
#export NKNDIM = 3000
#export NELDIM = 6000
#export NLVDIM = 22

# Cabras
#export NKNDIM = 4000
#export NELDIM = 8000
#export NLVDIM = 1
#export MBWDIM = 50
#export NGRDIM = 10

# Mar Menor
#export NKNDIM = 9000
#export NELDIM = 17000
#export NLVDIM = 1
#export MBWDIM = 180
#export NGRDIM = 10
#export NBDYDIM = 200000

##############################################
# Compiler
##############################################
#
# Please choose a compiler. Compiler options are
# usually correct. You might check below.
#
##############################################

#COMPILER = GNU_G77
#COMPILER = GNU_GFORTRAN
COMPILER = INTEL
#COMPILER = PORTLAND

##############################################
# Parallel compilation
##############################################
#
# For the Intel compiler you can specify
# parallel execution of some parts of the
# code. This can be specified here. Please
# switch back to serial execution if you are
# in doubt of the results.
#
##############################################

#PARALLEL=false
PARALLEL=true

##############################################
# Solver for matrix solution
##############################################
#
# Here you have to specify what solver you want
# to use for the solution of the system matrix.
# You have a choice between Gaussian elimination,
# iterative solution (Sparskit) and the Pardiso
# solver. The gaussian elimination is the most
# robust. Sparskit is very fast on big matrices.
# To use the Pardiso solver you must have the 
# libraries installed. It is generally faster
# then the default method. Please note that
# in order to use Pardiso you must also use
# the INTEL compiler.
#
##############################################

#SOLVER=GAUSS
#SOLVER=PARDISO
SOLVER=SPARSKIT

##############################################
# NetCDF library
##############################################
#
# If you want output in NetCDF format and have
# the library installed, then you can specify
# it here. The directory where the netcdf files
# reside must also be indicated.
#
##############################################

NETCDF=false
#NETCDF=true
NETCDFDIR = /usr/local/netcdf
NETCDFDIR = /usr

##############################################
# GOTM library
##############################################
#
# This software comes with a version of the
# GOTM turbulence model. It is needed if you
# want to run the model in 3D mode, unless you
# uses constant vertical viscosity and diffusivity.
# If you have problems compiling the GOTM
# library, you can set GOTM to false. This will use
# an older version of the program without the
# need of the external library.
#
##############################################

#GOTM=false
GOTM=true

##############################################
# Ecological models
##############################################
#
# The model also comes with code for some
# ecological models. You can activiate this
# code here. Choices are between EUTRO
# ERSEM and AQUABC. These choices have to be 
# integrated explicitly.
# This feature is still experimental.
#
##############################################

ECOLOGICAL = NONE
#ECOLOGICAL = EUTRO
#ECOLOGICAL = ERSEM
#ECOLOGICAL = AQUABC

#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------
# Normally it should not be necessary to change anything beyond here.
#------------------------------------------------------------
#------------------------------------------------------------
#------------------------------------------------------------

ifeq ($(COMPILER),GNU_G77)
  GOTM=false	# g77 cannot compile fortran 90
endif

#------------------------------------------------------------

##############################################
# COMPILER OPTIONS
##############################################

##############################################
#
# GNU compiler (g77, f77 or gfortran)
#
##############################################
#
# -Wall			warnings
# -pedantic		a lot of warnings
# -fautomatic		forget local variables
# -static		save local variables
# -no-automatic		save local variables
# -O			optimization
# -g			debug code
# -r8			double precision for old compiler
# -fdefault-real-8	double precision for new compiler
# -p			use profiling
#
# problems with stacksize (segmentation fault)
#	ulimit -a
#	ulimit -s 32000		(32MB)
#	ulimit -s unlimited
#
##############################################

#FGNU_PROFILE = -p
FGNU_PROFILE = 
# FGNU_NOOPT = -g -Wall -pedantic
FGNU_NOOPT = -g
# FGNU_NOOPT = 
#FGNU_OPT   = -O
FGNU_OPT   = -O3
FGNU_OMP   =

ifeq ($(COMPILER),GNU_G77)
  FGNU	 = g77
  FGNU95   = g95
endif

ifeq ($(COMPILER),GNU_G77)
  F77		= $(FGNU)
  F95		= $(FGNU95)
  LINKER	= $(F77)
  FFLAGS	= $(FGNU_OPT) $(FGNU_PROFILE) $(FGNU_NOOPT) $(FGNU_OMP)
  LFLAGS	= $(FGNU_OPT) $(FGNU_PROFILE) $(FGNU_OMP)
endif

ifeq ($(COMPILER),GNU_GFORTRAN)
  FGNU   = gfortran
  FGNU95 = gfortran

  ifeq ($(PARALLEL),true)
    FGNU_OMP   =  -fopenmp
  endif
endif

ifeq ($(COMPILER),GNU_GFORTRAN)
  F77		= $(FGNU)
  F95		= $(FGNU95)
  LINKER	= $(F77)
  FFLAGS	= $(FGNU_OPT) $(FGNU_PROFILE) $(FGNU_NOOPT) $(FGNU_OMP)
  LFLAGS	= $(FGNU_OPT) $(FGNU_PROFILE) $(FGNU_OMP)
endif

##############################################
#
# Portland compiler
#
##############################################

FPG    = pgf90
FPG95	= pgf90

FPG_PROFILE = 
#FPG_PROFILE = -Mprof=func

FPG_NOOPT = -g
# FPG_NOOPT = 

#FPG_OPT   = -O
FPG_OPT   = -O3

FPG_OMP   =

ifeq ($(COMPILER),PORTLAND)
  F77		= $(FPG)
  F95		= $(FPG95)
  LINKER	= $(F77)
  FFLAGS	= $(FPG_OPT) $(FPG_PROFILE) $(FPG_NOOPT) $(FPG_OMP)
  LFLAGS	= $(FPG_OPT) $(FPG_PROFILE) $(FPG_OMP)
endif

##############################################
#
# INTEL compiler
#
##############################################
#
# -w    warnings	no warnings
# -CU   run time exception
# -dn   level n of diagnostics
# -O    optimization (O2 O3)
# -i8   integer 8 byte (-i2 -i4 -i8)
# -r8   real 8 byte    (-r4 -r8 -r16), also -autodouble
# -check all
# -check uninit		(run time exception for uninitialized values)
# -implicitnone
# -debug
# -openmp
# -openmp-profile
# -openmp-report	(1 2)
#
# problems with stacksize (segmentation fault)
#	export KMP_STACKSIZE=32M
#
#############################################

INTEL_DIR = /opt/intel/fc/10.1.018
INTEL_BIN = $(INTEL_DIR)/bin

FINTEL     = $(INTEL_BIN)/ifort
FINTEL     = ifort

# FINTEL_PROFILE = -p
FINTEL_PROFILE = 

# ERSEM FLAGS -------------------------------------

REAL_4B = real\(4\)
DEFINES += -DREAL_4B=$(REAL_4B)
DEFINES += -DFORTRAN95 
DEFINES += -DPRODUCTION -static
#DEFINES += -DRLEN=real
#EXTRAS  = -w95

#FINTEL_ERSEM = $(DEFINES) $(EXTRAS)
FINTEL_ERSEM = $(DEFINES) 

# NETCDF FLAGS -------------------------------------
# check it if we really need  "-assume 2underscores"
# -> not needed anymore

FFNCDF =
#ifeq ($(NETCDF),true)
#  #FFNCDF   = -assume 2underscores
#endif

#-------------------------------------------------

# FINTEL_NOOPT = -g -traceback -check all
# FINTEL_NOOPT = -xP
# FINTEL_NOOPT = -w -CU -d1
# FINTEL_NOOPT = -w -CU -d5
# FINTEL_NOOPT = 
FINTEL_NOOPT = -w $(FFNCDF) -Cu -traceback

# FINTEL_OPT   = 
# FINTEL_OPT   = -O -g -Mprof=time
# FINTEL_OPT   = -O3 -g -axSSE4.2 #-mcmodel=medium -shared-intel
FINTEL_OPT   = -O -g
FINTEL_OPT   = -O -g -warn interfaces -check uninit -check bounds
FINTEL_OPT   = -O -g -warn interfaces -check uninit
FINTEL_OPT   = -O -g -check uninit
#FINTEL_OPT   = -O -g -fp-model precise -no-prec-div


FINTEL_OMP   =
ifeq ($(PARALLEL),true)
  FINTEL_OMP   = -threads -openmp
endif

ifeq ($(COMPILER),INTEL)
  F77		= $(FINTEL)
  F95     	= $(F77)
  LINKER	= $(F77)
  FFLAGS	= $(FINTEL_OPT) $(FINTEL_PROFILE) $(FINTEL_NOOPT) $(FINTEL_OMP)
  LFLAGS	= $(FINTEL_OPT) $(FINTEL_PROFILE) $(FINTEL_OMP)
endif

##############################################
#
# C compiler
#
##############################################

CC     = gcc
CFLAGS = -O -Wall -pedantic
LCFLAGS = -O 

##############################################
#
# old stuff - do not bother
#
##############################################

##############################################
#
# profiling: use -p for linking ; example for ht
#
#   f77 -p -c subany.f ... 	(compiles with profiling)
#   f77 -p -o ht ...     	(links with profiling)
#   ht                   	(creates mon.out)
#   prof ht              	(elaborates mon.out)
#   gprof ht              	(elaborates mon.out)
#	-b	brief
#	-p	flat profile
#
##############################################


##############################################
#
# lahey
#
#	help for options :
#		f77l3
#		386link
#		up l32 /help
#	remove kernel :
#		os386 /remove
#	compiler switches :
#		/R	remember local variables
#		/H	hardcopy listing
#		/S	create sold file .sld
#		/L	line-number traceback table
#		/O	output options
#
# compiler (all versions)
# 
# FLC             = f77l3
# FLFLAGS         = /nO /nS /L /nR /nH
# 
# linker lahey 3.01
# 
# LLINKER         = up l32
# LDFLAGS         = /nocommonwarn /stack:5004
# LDMAP           = nul
# LLIBS		=
# LDEXTRA		= ,$@,$(LDMAP),$(LLIBS) $(LDFLAGS);
# EXE		= exp
# 
# linker lahey 5.20
# 
# LLINKER		= 386link
# LDFLAGS		= -stack 2000000 -fullsym
# LDEXTRA		= $(LDFLAGS)
# EXE    		= exe
#
##############################################

##############################################
# Private stuff
##############################################

#MAKEGENERAL = $(FEMDIR)/general/Makefile.general

