#!/bin/bash

STARTING_PATH=$(pwd -LP)
echo [$SECONDS] start directory $STARTING_PATH

# uncomment to run athena in RAM disk
# SSD=/local/scratch/$BALSAM_JOB_ID
# mkdir -p $SSD

echo [$SECONDS] running in $STARTING_PATH

FILE=run_reconstruct.sh

INPUTFILE=$(python -c "import glob;l=glob.glob('*_HITS.root');print(l[0])")
echo [$SECONDS] INPUTFILE  = $INPUTFILE
OUTPUTFILE_ESD=atlasworf_ESD.root
echo [$SECONDS] OUTPUTFILE_ESD = $OUTPUTFILE_ESD
OUTPUTFILE_RDO=atlasworf_RDO.root
echo [$SECONDS] OUTPUTFILE_RDO = $OUTPUTFILE_RDO
LOGFILE=reconstruct.stdouterr
echo [$SECONDS] LOGFILE    = $LOGFILE

/bin/cat << EOM > $FILE
#!/bin/bash
echo [\$SECONDS] Start inside Singularity
echo [\$SECONDS] DATE=\$(date)
WORKDIR=\$1
echo [\$SECONDS] WORKDIR=\$WORKDIR
USE_MP=true

cd \$WORKDIR

echo [\$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source \$ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [\$SECONDS] Setting up Atlas Software
RELEASE=21.0.20
PACKAGE=AtlasOffline
CMTCONFIG=x86_64-slc6-gcc62-opt
echo [\$SECONDS] RELEASE=\$RELEASE
echo [\$SECONDS] PACKAGE=\$PACKAGE
echo [\$SECONDS] CMTCONFIG=\$CMTCONFIG

LOCAL_WORKAREA=here
echo [\$SECONDS] WORKAREA=\$LOCAL_WORKAREA

source \$AtlasSetup/scripts/asetup.sh --cmtconfig=\$CMTCONFIG --makeflags=\"\$MAKEFLAGS\" --cmtextratags=ATLAS,useDBRelease --workarea=\$LOCAL_WORKAREA  \$RELEASE,\$PACKAGE,notest

echo [\$SECONDS] Setting up database for local copy: ATLAS_DB_AREA=\$ATLAS_DB_AREA
DBBASEPATH=\$ATLAS_DB_AREA/DBRelease/current
export CORAL_DBLOOKUP_PATH=\$DBBASEPATH/XMLConfig
export CORAL_AUTH_PATH=\$DBBASEPATH/XMLConfig
export DATAPATH=\$DBBASEPATH:\$DATAPATH
mkdir poolcond
export DBREL_LOCATION=\$ATLAS_DB_AREA/DBRelease
cp \$DBREL_LOCATION/current/poolcond/*.xml poolcond
export DATAPATH=\$PWD:\$DATAPATH

echo [\$SECONDS] Setting up Frontier
export http_proxy=http://10.236.1.194:3128
export HTTP_PROXY=http://10.236.1.194:3128
export FRONTIER_SERVER=\$FRONTIER_SERVER\(proxyurl=\$HTTP_PROXY\)
export FRONTIER_LOG_LEVEL=info

echo [\$SECONDS] PYTHON Version:       \$(python --version)
echo [\$SECONDS] PYTHONPATH:           \$PYTHONPATH
echo [\$SECONDS] LD_LIBRARY_PATH:      \$LD_LIBRARY_PATH
env | sort > env_dump.txt

if [ "\$USE_MP" = "TRUE" ] || [ "\$USE_MP" = "true" ] || [ "\$USE_MP" = "True" ]; then
   export ATHENA_PROC_NUMBER=128
   echo [\$SECONDS] ATHENA_PROC_NUMBER:   \$ATHENA_PROC_NUMBER
fi


echo [\$SECONDS] Starting command
Reco_tf.py --conditionsTag default:OFLCOND-MC16-SDR-16 --geometryVersion default:ATLAS-R2-2016-01-00-01 --inputHITSFile $INPUTFILE --outputESDFile $OUTPUTFILE_ESD --outputRDOFile $OUTPUTFILE_RDO --postInclude default:RecJobTransforms/UseFrontier.py --preExec 'RAWtoESD:from RecExConfig.RecFlags import rec;rec.doForwardDet=False;rec.doInDet=False;rec.doMuon=False;rec.doCalo=True;rec.doTrigger=False;include ("RecExCommon/RecExCommon_topOptions.py")' --postExec 'all:CfgMgr.MessageSvc().setError+=["HepMcParticleLink"]' --maxEvents -1 --skipEvents 0 --autoConfiguration everything --runNumber 1 --digiSeedOffset1 9 --digiSeedOffset2 9 --digiSteeringConf StandardSignalOnlyTruth --jobNumber 1 --DBRelease current --athenaMPMergeTargetSize ALL:0 --ignorePatterns "regFcn: could not bind handle" "Callback registration failed" "sectorType = 0 out of range"
EXIT_CODE=\$?
echo [\$SECONDS] Transform exited with return code: \$EXIT_CODE
echo [\$SECONDS] Exiting
exit \$EXIT_CODE

EOM

chmod a+x $FILE

# make directory on SSD
cp $FILE $SSD
cp $INPUTFILE $SSD
cd $SSD
echo [$SECONDS] ls in SSD
ls

echo [$SECONDS] run command
singularity exec -B $SSD:$SSD:rw -B /lus/theta-fs0/projects/datascience/parton:/lus/theta-fs0/projects/datascience/parton:rw -B /lus/theta-fs0/projects/AtlasADSP:/lus/theta-fs0/projects/AtlasADSP:rw -B /gpfs/mira-home/parton:/gpfs/mira-home/parton:rw /lus/theta-fs0/projects/AtlasADSP/atlas/singularity_images/stripped/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc62.r21.0.x.201805310122.sqsh $SSD/$FILE $SSD > $STARTING_PATH/$LOGFILE 2>&1
EXIT_CODE=$?
echo [$SECONDS] exit code $EXIT_CODE

echo [$SECONDS] ls -lh 
ls -lh

cp $OUTPUTFILE_ESD $STARTING_PATH/
cp $OUTPUTFILE_RDO $STARTING_PATH/
cp log.HITtoRDO $STARTING_PATH/
cp log.RAWtoESD $STARTING_PATH/

for file in ./athenaMP-workers-HITtoRDO-h2r/worker_*/${OUTPUTFILE_RDO}_*; do
   WORKER_NUM=$(python -c "x='$file';s=x.find('worker_')+len('worker_');e=x.find('/',s);print(x[s:e])")
   DEST_FILE=$STARTING_PATH/$(basename $file)_${WORKER_NUM}_RDO.root
   echo copying $file to $DEST_FILE
   cp $file $DEST_FILE
done

for file in ./athenaMP-workers-RAWtoESD-r2e/worker_*/${OUTPUTFILE_ESD}_*; do
   WORKER_NUM=$(python -c "x='$file';s=x.find('worker_')+len('worker_');e=x.find('/',s);print(x[s:e])")
   DEST_FILE=$STARTING_PATH/$(basename $file)_${WORKER_NUM}_ESD.root
   echo copying $file to $DEST_FILE
   cp $file $DEST_FILE
done

cd $STARTING_PATH

echo [$SECONDS] exiting
exit $EXIT_CODE
