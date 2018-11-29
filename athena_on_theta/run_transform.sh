#!/bin/bash
echo [$SECONDS] Start AthenaMP transform inside Singularity
echo [$SECONDS] DATE=$(date)

WORKDIR=$1
TRANSFORM=$2
JOBPARS=$3
USE_MP=$4
WORKAREA=$5
RELEASE=$6
PACKAGE=$7
CMTCONFIG=$8

echo [$SECONDS] WORKDIR=$WORKDIR
echo [$SECONDS] TRANSFORM=$TRANSFORM
echo [$SECONDS] JOBPARS=$JOBPARS
echo [$SECONDS] USE_MP=$USE_MP
echo [$SECONDS] WORKAREA=$WORKAREA
echo [$SECONDS] RELEASE=$RELEASE
echo [$SECONDS] PACKAGE=$PACKAGE
echo [$SECONDS] CMTCONFIG=$CMTCONFIG

SQUID_PROXY_IP=http://10.236.1.194:3128
GEN_TARBALL=/gpfs/mira-home/parton/git/atlasworf/generate/MC15JobOpts-00-04-24_v0.tar.gz

cd $WORKDIR

if [ "$USE_MP" = "TRUE" ] || [ "$USE_MP" = "true" ] || [ "$USE_MP" = "True" ]; then
   export ATHENA_PROC_NUMBER=128
   echo [$SECONDS] ATHENA_PROC_NUMBER:   $ATHENA_PROC_NUMBER
fi

echo [$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
echo [$SECONDS] ATLAS_LOCAL_ROOT_BASE=$ATLAS_LOCAL_ROOT_BASE
source $ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [$SECONDS] Setting up Atlas Software

source $AtlasSetup/scripts/asetup.sh --cmtconfig=$CMTCONFIG --makeflags=\"$MAKEFLAGS\" --cmtextratags=ATLAS,useDBRelease --workarea=$WORKAREA  $RELEASE,$PACKAGE,notest


if [ "$TRANSFORM" = "Sim_tf.py" ]; then
   echo [$SECONDS] Setting up database for local copy: ATLAS_DB_AREA=$ATLAS_DB_AREA
   DBBASEPATH=$ATLAS_DB_AREA/DBRelease/current
   export CORAL_DBLOOKUP_PATH=$DBBASEPATH/XMLConfig
   export CORAL_AUTH_PATH=$DBBASEPATH/XMLConfig
   export DATAPATH=$DBBASEPATH:$DATAPATH
   mkdir poolcond
   export DBREL_LOCATION=$ATLAS_DB_AREA/DBRelease
   cp $DBREL_LOCATION/current/poolcond/*.xml poolcond
   export DATAPATH=$PWD:$DATAPATH
   unset FRONTIER_SERVER

   # tell transform to skip file validation
   export G4ATLAS_SKIPFILEPEEK=1
else
   echo [$SECONDS] Setting up database for local copy: ATLAS_DB_AREA=$ATLAS_DB_AREA
   DBBASEPATH=$ATLAS_DB_AREA/DBRelease/current
   export CORAL_DBLOOKUP_PATH=$DBBASEPATH/XMLConfig
   export CORAL_AUTH_PATH=$DBBASEPATH/XMLConfig
   export DATAPATH=$DBBASEPATH:$DATAPATH
   mkdir poolcond
   export DBREL_LOCATION=$ATLAS_DB_AREA/DBRelease
   cp $DBREL_LOCATION/current/poolcond/*.xml poolcond
   export DATAPATH=$PWD:$DATAPATH

   echo [$SECONDS] Setting up Frontier
   export http_proxy=$SQUID_PROXY_IP
   export HTTP_PROXY=$SQUID_PROXY_IP
   export FRONTIER_SERVER=$FRONTIER_SERVER\(proxyurl=$HTTP_PROXY\)
   export FRONTIER_LOG_LEVEL=info
fi

# setup for Generate_tf.py
if [ "$TRANSFORM" = "Generate_tf.py" ]; then
   # copy tarball
   echo [$SECONDS] copying tarball from $GEN_TARBALL
   cp $GEN_TARBALL ./
   echo [$SECONDS] setting up LHAPDF
   export LHAPATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPATH
   export LHAPDF_DATA_PATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPDF_DATA_PATH
fi


echo [$SECONDS] PYTHON Version:       $(python --version)
echo [$SECONDS] PYTHONPATH:           $PYTHONPATH
echo [$SECONDS] LD_LIBRARY_PATH:      $LD_LIBRARY_PATH
env | sort > env_dump.txt

echo [$SECONDS] Starting command
$TRANSFORM $JOBPARS
EXIT_CODE=$?
echo [$SECONDS] Transform exited with return code: $EXIT_CODE
echo [$SECONDS] ls of directory
ls
echo [$SECONDS] Exiting
exit $EXIT_CODE