#!/bin/bash
echo [$SECONDS] Start inside Singularity
echo [$SECONDS] DATE=$(date)
USE_MP=False
USE_WORKAREA=False
USE_PKG_SCRIPT=False
RELEASE=21.0.15
PACKAGE=AtlasOffline
CMTCONFIG=gccVersionX
echo [$SECONDS] USE_MP=          $USE_MP
echo [$SECONDS] USE_WORKAREA=    $USE_WORKAREA
echo [$SECONDS] USE_PKG_SCRIPT=  $USE_PKG_SCRIPT
echo [$SECONDS] RELEASE=         $RELEASE
echo [$SECONDS] PACKAGE=         $PACKAGE
echo [$SECONDS] CMTCONFIG=       $CMTCONFIG
cd $WORKDIR

echo [$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source $ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [$SECONDS] Setting up Atlas Software

if [ "$USE_WORKAREA" = "TRUE" ] || [ "$USE_WORKAREA" = "true" ] || [ "$USE_WORKAREA" = "True" ]; then
   LOCAL_WORKAREA=--workarea=
   echo [$SECONDS] WORKAREA=        $LOCAL_WORKAREA
fi

echo [$SECONDS] AtlasSetup=      $AtlasSetup
source $AtlasSetup/scripts/asetup.sh --cmtconfig=$CMTCONFIG --makeflags="$MAKEFLAGS" --cmtextratags=ATLAS,useDBRelease $LOCAL_WORKAREA  $RELEASE,$PACKAGE,notest

if [ "$USE_PKG_SCRIPT" = "TRUE" ] || [ "$USE_PKG_SCRIPT" = "true" ] || [ "$USE_PKG_SCRIPT" = "True" ]; then
   PKG_SCRIPT=
   echo [$SECONDS] PKG_SCRIPT=        $PKG_SCRIPT
   source $PKG_SCRIPT
fi

if [ "Reco_tf.py" = "Sim_tf.py" ]; then
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

echo [$SECONDS] PYTHON Version:       $(python --version)
echo [$SECONDS] PYTHONPATH:           $PYTHONPATH
echo [$SECONDS] LD_LIBRARY_PATH:      $LD_LIBRARY_PATH
env | sort > env_dump.txt

if [ "$USE_MP" = "TRUE" ] || [ "$USE_MP" = "true" ] || [ "$USE_MP" = "True" ]; then
   export ATHENA_PROC_NUMBER=-1
   echo [$SECONDS] ATHENA_PROC_NUMBER:   $ATHENA_PROC_NUMBER
fi

# setup for Generate_tf.py
if [ "Reco_tf.py" = "Generate_tf.py" ]; then
   echo [$SECONDS] setting up LHAPDF
   export LHAPATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPATH
   export LHAPDF_DATA_PATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPDF_DATA_PATH
fi

echo [$SECONDS] Starting command
Reco_tf.py --maxEvents -1 --ignorePatterns "regFcn: could not bind handle" "Callback registration failed" "sectorType = 0 out of range" --geometryVersion default:ATLAS-R2-2016-01-00-01 --conditionsTag default:OFLCOND-MC16-SDR-16 --runNumber 1 --postExec all:CfgMgr.MessageSvc().setError+=["HepMcParticleLink"] --digiSteeringConf StandardSignalOnlyTruth --autoConfiguration everything --inputHITSFile input_hits.root --jobNumber 1 --skipEvents 0 --postInclude default:RecJobTransforms/UseFrontier.py --outputESDFile output_esd.root --preExec RAWtoESD:from RecExConfig.RecFlags import rec;rec.doForwardDet=False;rec.doInDet=False;rec.doMuon=False;rec.doCalo=True;rec.doTrigger=False;include ("RecExCommon/RecExCommon_topOptions.py") --DBRelease current --outputRDOFile output_rdo.root --digiSeedOffset2 9 --athenaMPMergeTargetSize ALL:0 --digiSeedOffset1 9
EXIT_CODE=$?
echo [$SECONDS] command exited with return code: $EXIT_CODE
echo [$SECONDS] Exiting
exit $EXIT_CODE
