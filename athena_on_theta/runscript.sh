#!/bin/bash
echo [$SECONDS] Start inside Singularity
echo [$SECONDS] DATE=$(date)
USE_MP=True
USE_WORKAREA=True
USE_PKG_SCRIPT=False
USE_SSD=False
RELEASE=21.0.15
PACKAGE=AtlasOffline
CMTCONFIG=x86_64-slc6-gcc49-opt
echo [$SECONDS] USE_MP=          $USE_MP
echo [$SECONDS] USE_WORKAREA=    $USE_WORKAREA
echo [$SECONDS] USE_PKG_SCRIPT=  $USE_PKG_SCRIPT
echo [$SECONDS] USE_SSD=         $USE_SSD
echo [$SECONDS] RELEASE=         $RELEASE
echo [$SECONDS] PACKAGE=         $PACKAGE
echo [$SECONDS] CMTCONFIG=       $CMTCONFIG

if [ "$USE_SSD" = "TRUE" ] || [ "$USE_SSD" = "true" ] || [ "$USE_SSD" = "True" ]; then
   SSD_PATH=
   echo [$SECONDS] SSD_PATH=        $SSD_PATH
   mkdir -s $SSD_PATH
   cd $SSD_PATH
fi

echo [$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source $ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [$SECONDS] Setting up Atlas Software

if [ "$USE_WORKAREA" = "TRUE" ] || [ "$USE_WORKAREA" = "true" ] || [ "$USE_WORKAREA" = "True" ]; then
   LOCAL_WORKAREA=--workarea=here
   echo [$SECONDS] WORKAREA=        $LOCAL_WORKAREA
fi

echo [$SECONDS] AtlasSetup=      $AtlasSetup
source $AtlasSetup/scripts/asetup.sh --cmtconfig=$CMTCONFIG --makeflags="$MAKEFLAGS" --cmtextratags=ATLAS,useDBRelease $LOCAL_WORKAREA  $RELEASE,$PACKAGE,notest

if [ "$USE_PKG_SCRIPT" = "TRUE" ] || [ "$USE_PKG_SCRIPT" = "true" ] || [ "$USE_PKG_SCRIPT" = "True" ]; then
   PKG_SCRIPT=
   echo [$SECONDS] PKG_SCRIPT=      $PKG_SCRIPT
   source $PKG_SCRIPT
fi

if [ "Sim_tf.py" = "Sim_tf.py" ]; then
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

   # tell transform to skip file validation (time-saver)
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
   export http_proxy=http://10.236.1.194:3128
   export HTTP_PROXY=http://10.236.1.194:3128
   export FRONTIER_SERVER=$FRONTIER_SERVER\(proxyurl=$HTTP_PROXY\)
   export FRONTIER_LOG_LEVEL=info
fi

echo [$SECONDS] PYTHON Version:     $(python --version)
echo [$SECONDS] PYTHONPATH:         $PYTHONPATH
echo [$SECONDS] LD_LIBRARY_PATH:    $LD_LIBRARY_PATH
env | sort > env_dump.txt

if [ "$USE_MP" = "TRUE" ] || [ "$USE_MP" = "true" ] || [ "$USE_MP" = "True" ]; then
   export ATHENA_PROC_NUMBER=10
   echo [$SECONDS] ATHENA_PROC_NUMBER: $ATHENA_PROC_NUMBER
fi

# setup for Generate_tf.py
if [ "Sim_tf.py" = "Generate_tf.py" ]; then
   echo [$SECONDS] setting up LHAPDF
   export LHAPATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPATH
   export LHAPDF_DATA_PATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPDF_DATA_PATH
fi

echo [$SECONDS] Starting command
Sim_tf.py --inputEVNTFile "atlasworf_EVNT.root" --truthStrategy "MC15aPlus" --preInclude "EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py,SimulationJobOptions/preInclude.FrozenShowersFCalOnly.py" --conditionsTag "default:OFLCOND-MC16-SDR-14" --outputHITSFile "atlasworf_HITS.root" --DataRunNumber "2010304" --physicsList "FTFP_BERT_ATL_VALIDATION" --simulator "FullG4" --maxEvents "-1" --preExec "EVNTtoHITS:simFlags.SimBarcodeOffset.set_Value_and_Lock(200000);simFlags.TRTRangeCut=30.0;simFlags.TightMuonStepping=True" --DBRelease "all:current" --fileValidation "FALSE" --geometryVersion "ATLAS-R2-2016-01-00-01_VALIDATION"
EXIT_CODE=$?
echo [$SECONDS] command exited with return code: $EXIT_CODE
echo [$SECONDS] Exiting
exit $EXIT_CODE
