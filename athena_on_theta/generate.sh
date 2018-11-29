#!/bin/bash

STARTING_PATH=$PWD
echo [$SECONDS] start directory $STARTING_PATH

# run in RAM disk
SSD=/local/scratch/$BALSAM_JOB_ID
mkdir -p $SSD

FILE=run_generate.sh

INPUTFILE=$(python -c "import glob;l=glob.glob('*.lhe');print(l[0])")
echo [$SECONDS] input file = $INPUTFILE
OUTPUTFILE=atlasworf_EVNT.root
LOGFILE=generate.stdouterr

/bin/cat << EOM > $FILE
#!/bin/bash
echo [\$SECONDS] Start inside Singularity
echo [\$SECONDS] DATE=\$(date)
WORKDIR=\$1
echo [\$SECONDS] WORKDIR=\$WORKDIR
USE_MP=false

cd \$WORKDIR

echo [\$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source \$ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [\$SECONDS] Setting up Atlas Software
RELEASE=19.2.5.32.2
PACKAGE=MCProd
CMTCONFIG=x86_64-slc6-gcc47-opt
echo [\$SECONDS] RELEASE=\$RELEASE
echo [\$SECONDS] PACKAGE=\$PACKAGE
echo [\$SECONDS] CMTCONFIG=\$CMTCONFIG

LOCAL_WORKAREA=here
echo [\$SECONDS] WORKAREA=\$LOCAL_WORKAREA

source \$AtlasSetup/scripts/asetup.sh --cmtconfig=\$CMTCONFIG --makeflags=\"\$MAKEFLAGS\" --cmtextratags=ATLAS,useDBRelease --workarea=\$LOCAL_WORKAREA  \$RELEASE,\$PACKAGE,notest

# copy tarball
cp /gpfs/mira-home/parton/git/atlasworf/generate/MC15JobOpts-00-04-24_v0.tar.gz ./

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


# setup for Generate_tf.py

echo [\$SECONDS] setting up LHAPDF
export LHAPATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:\$LHAPATH
export LHAPDF_DATA_PATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:\$LHAPDF_DATA_PATH


echo [\$SECONDS] PYTHON Version:       \$(python --version)
echo [\$SECONDS] PYTHONPATH:           \$PYTHONPATH
echo [\$SECONDS] LD_LIBRARY_PATH:      \$LD_LIBRARY_PATH
env | sort > env_dump.txt


echo [\$SECONDS] Starting command
Generate_tf.py --jobConfig=/gpfs/mira-home/parton/git/atlasworf/gentf_jo.py --preExec="input_lhe_filename='$SSD/$INPUTFILE';minevents=200"  --outputEVNTFile=$SSD/$OUTPUTFILE --runNumber=1 --ecmEnergy=13000 --evgenJobOpts=MC15JobOpts-00-04-24_v0.tar.gz --firstEvent=0
EXIT_CODE=\$?
echo [\$SECONDS] Transform exited with return code: \$EXIT_CODE
echo [\$SECONDS] ls of directory
ls
echo [\$SECONDS] Exiting
exit \$EXIT_CODE

EOM

chmod a+x $FILE

# make directory in SSD
cp $FILE $SSD
cp $INPUTFILE $SSD

singularity exec -B /lus/theta-fs0/projects/AtlasADSP:/lus/theta-fs0/projects/AtlasADSP:rw -B $SSD:$SSD:rw -B /gpfs/mira-home/parton:/gpfs/mira-home/parton:rw /lus/theta-fs0/projects/AtlasADSP/atlas/singularity_images/stripped/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc47.r19.2.5.201804250920.sqsh $SSD/$FILE $SSD > $STARTING_PATH/$LOGFILE 2>&1
EXIT_CODE=$?
echo [$SECONDS] exit code $EXIT_CODE
cp $SSD/$OUTPUTFILE ./
cp $SSD/log.generate ./

echo [$SECONDS] exiting
exit $EXIT_CODE
