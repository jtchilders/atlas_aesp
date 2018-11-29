#!/bin/bash

STARTING_PATH=$(pwd -LP)
echo [$SECONDS] start directory $STARTING_PATH

# run in RAM disk
SSD=/local/scratch/$BALSAM_JOB_ID
mkdir -p $SSD

echo [$SECONDS] running in $PWD

FILE=run_rawDataHits.sh

INPUTFILE=$(python -c "import glob;l=glob.glob('*_RDO.root');print(l)")
echo [$SECONDS] INPUTFILE  = $INPUTFILE
OUTPUTFILE=rawdatahits.root
echo [$SECONDS] OUTPUTFILE = $OUTPUTFILE
LOGFILE=runRawDataHits.stdouterr
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
RELEASE=21.0.20
PACKAGE=AtlasOffline
CMTCONFIG=x86_64-slc6-gcc62-opt
echo [\$SECONDS] RELEASE=\$RELEASE
echo [\$SECONDS] PACKAGE=\$PACKAGE
echo [\$SECONDS] CMTCONFIG=\$CMTCONFIG

LOCAL_WORKAREA=/home/parton/git/btaggingML
echo [\$SECONDS] WORKAREA=\$LOCAL_WORKAREA

source \$AtlasSetup/scripts/asetup.sh --cmtconfig=\$CMTCONFIG --makeflags=\"\$MAKEFLAGS\" --cmtextratags=ATLAS,useDBRelease --workarea=\$LOCAL_WORKAREA  \$RELEASE,\$PACKAGE,notest

echo [\$SECONDS] Setup package
source /gpfs/mira-home/parton/git/btaggingML/build/x86_64-centos6-gcc62-opt/setup.sh

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


echo [\$SECONDS] Starting command
athena --command "filelist=$INPUTFILE;rootFilename='$OUTPUTFILE';evtmax=-1" /gpfs/mira-home/parton/git/btaggingML/src/RawData/share/runRawDataHits.py
EXIT_CODE=\$?
echo [\$SECONDS] Transform exited with return code: \$EXIT_CODE
echo [\$SECONDS] Exiting
exit \$EXIT_CODE

EOM

chmod a+x $FILE

# make directory on SSD
cp $FILE $SSD

for file in *_RDO.root; do
   echo copying $file to $SSD
   cp $file $SSD
done

cd $SSD
echo [$SECONDS] ls in SSD
ls

singularity exec -B $SSD:$SSD:rw -B /lus/theta-fs0/projects/datascience/parton:/lus/theta-fs0/projects/datascience/parton:rw -B /lus/theta-fs0/projects/AtlasADSP:/lus/theta-fs0/projects/AtlasADSP:rw -B /gpfs/mira-home/parton:/gpfs/mira-home/parton:rw /lus/theta-fs0/projects/AtlasADSP/atlas/singularity_images/stripped/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc62.r21.0.x.201805310122.sqsh $SSD/$FILE $SSD > $STARTING_PATH/$LOGFILE 2>&1

EXIT_CODE=$?
echo [$SECONDS] exited with code $EXIT_CODE
cp $OUTPUTFILE $STARTING_PATH/

cd $STARTING_PATH

echo [$SECONDS] exiting
exit $EXIT_CODE

