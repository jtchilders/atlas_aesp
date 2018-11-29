#!/bin/bash

STARTING_PATH=$(pwd -LP)
echo [$SECONDS] start directory $STARTING_PATH

# run in RAM disk
SSD=/local/scratch/$BALSAM_JOB_ID
mkdir -p $SSD

echo [$SECONDS] running in $STARTING_PATH

FILE=run_simulate.sh

INPUTFILE=$(python -c "import glob;l=glob.glob('*.root');print(l[0])")
echo [$SECONDS] INPUTFILE  = $INPUTFILE
OUTPUTFILE=atlasworf_HITS.root
echo [$SECONDS] OUTPUTFILE = $OUTPUTFILE
LOGFILE=simulate.stdouterr
echo [$SECONDS] LOGFILE    = $LOGFILE

/bin/cat << EOM > $FILE
#!/bin/bash
echo [\$SECONDS] Start inside Singularity
echo [\$SECONDS] DATE=\$(date)
WORKDIR=\$1
echo [\$SECONDS] WORKDIR=\$WORKDIR

cd \$WORKDIR


echo [\$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source \$ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [\$SECONDS] Setting up Atlas Software
RELEASE=21.0.15
PACKAGE=AtlasOffline
CMTCONFIG=x86_64-slc6-gcc49-opt
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
unset FRONTIER_SERVER

# tell transform to skip file validation
export G4ATLAS_SKIPFILEPEEK=1

echo [\$SECONDS] PYTHON Version:       \$(python --version)
echo [\$SECONDS] PYTHONPATH:           \$PYTHONPATH
echo [\$SECONDS] LD_LIBRARY_PATH:      \$LD_LIBRARY_PATH
env | sort > env_dump.txt


export ATHENA_PROC_NUMBER=128
echo [\$SECONDS] ATHENA_PROC_NUMBER:   \$ATHENA_PROC_NUMBER

echo [\$SECONDS] Starting command
Sim_tf.py --conditionsTag=default:OFLCOND-MC16-SDR-14 --geometryVersion=ATLAS-R2-2016-01-00-01_VALIDATION --inputEVNTFile=$INPUTFILE --outputHITSFile=$OUTPUTFILE --preInclude="EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py,SimulationJobOptions/preInclude.FrozenShowersFCalOnly.py" --DBRelease=all:current --preExec="EVNTtoHITS:simFlags.SimBarcodeOffset.set_Value_and_Lock(200000);simFlags.TRTRangeCut=30.0;simFlags.TightMuonStepping=True" --fileValidation=FALSE --physicsList=FTFP_BERT_ATL_VALIDATION --DataRunNumber=2010304 --simulator=FullG4 --truthStrategy=MC15aPlus --maxEvents -1
EXIT_CODE=\$?
echo [\$SECONDS] Transform exited with return code: \$EXIT_CODE
echo [\$SECONDS] Exiting
exit \$EXIT_CODE

EOM


chmod a+x $FILE

# make directory on SSD
cp $FILE $SSD
cp $INPUTFILE $SSD

echo [$SECONDS] ls in SSD
cd $SSD
ls

echo [$SECONDS] launch container
singularity exec -B $SSD:$SSD:rw -B /lus/theta-fs0/projects/datascience/parton:/lus/theta-fs0/projects/datascience/parton:rw -B /lus/theta-fs0/projects/AtlasADSP:/lus/theta-fs0/projects/AtlasADSP:rw -B /gpfs/mira-home/parton:/gpfs/mira-home/parton:rw /lus/theta-fs0/projects/AtlasADSP/atlas/singularity_images/stripped/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc49.r21.0.x.201805301920.sqsh $SSD/$FILE $SSD > $STARTING_PATH/$LOGFILE 2>&1
EXIT_CODE=$?
echo [$SECONDS] exit code $EXIT_CODE
tar cf simulate.tar athenaMP-workers*/*/AthenaMP.log
cp simulate.tar $STARTING_PATH/
cp $OUTPUTFILE $STARTING_PATH/
cp $LOGFILE $STARTING_PATH/
cp log.EVNTtoHITS $STARTING_PATH/

echo [$SECONDS] ls directory $PWD
ls 

cd $STARTING_PATH

echo [$SECONDS] exiting
exit $EXIT_CODE

