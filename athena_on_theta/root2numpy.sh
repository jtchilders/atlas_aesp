#!/bin/bash

STARTING_PATH=$(pwd -LP)
echo [$SECONDS] start directory $STARTING_PATH

# run in RAM disk
SSD=/local/scratch/$BALSAM_JOB_ID
mkdir -p $SSD

echo [$SECONDS] running in $STARTING_PATH

FILE=run_datahits.sh

INPUTFILE_HITS=rawdatahits.root
echo [$SECONDS] INPUTFILE_HITS  = $INPUTFILE_HITS
INPUTFILE_CALO=rawdatacalo.root
echo [$SECONDS] INPUTFILE_CALO  = $INPUTFILE_CALO
OUTPUTFILE="${BALSAM_JOB_ID}_nevts{ncompress}_evtid{evtnum:08d}.npz"
echo [$SECONDS] OUTPUTFILE = $OUTPUTFILE
LOGFILE=root2numpy.stdouterr
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

echo [\$SECONDS] PYTHON Version:       \$(python --version)
echo [\$SECONDS] PYTHONPATH:           \$PYTHONPATH
echo [\$SECONDS] LD_LIBRARY_PATH:      \$LD_LIBRARY_PATH
env | sort > env_dump.txt


echo [\$SECONDS] Starting command
# python /home/parton/git/btaggingML/scripts/processdata_G3DNet.py --nprocs 64  --nevent -1 --output-path output_images --batchmode  --larEt 0.05 --tileEt 0.05 --eta 0.6 --phi 0.6 --ncompress 1 --npz_filename $OUTPUTFILE --inputhits $SSD/$INPUTFILE_HITS --inputcalo $SSD/$INPUTFILE_CALO --map /projects/atlasMLbjets/parton/skimmed_map.npz 
python /home/parton/git/btaggingML/scripts/multi_processdata.py --nprocs 64  --nevent -1 --output-path output_images --batchmode  --larEt 0.05 --tileEt 0.05 --eta 3 --ncompress 10 --npz_filename $OUTPUTFILE --inputhits $SSD/$INPUTFILE_HITS --inputcalo $SSD/$INPUTFILE_CALO 
EXIT_CODE=\$?
echo [\$SECONDS] Transform exited with return code: \$EXIT_CODE
echo [\$SECONDS] Exiting
exit \$EXIT_CODE

EOM

chmod a+x $FILE

# make directory on SSD
cp $FILE $SSD
cp $INPUTFILE_HITS $SSD
cp $INPUTFILE_CALO $SSD
#cd $SSD
echo [$SECONDS] ls in SSD
ls

echo [$SECONDS] run command
singularity exec -B $SSD:$SSD:rw -B /projects/atlasMLbjets/parton/:/projects/atlasMLbjets/parton/:ro -B /lus/theta-fs0/projects/datascience/parton:/lus/theta-fs0/projects/datascience/parton:rw -B /lus/theta-fs0/projects/AtlasADSP:/lus/theta-fs0/projects/AtlasADSP:rw -B /gpfs/mira-home/parton:/gpfs/mira-home/parton:rw /lus/theta-fs0/projects/AtlasADSP/atlas/singularity_images/stripped/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc62.r21.0.x.201805310122.sqsh $SSD/$FILE $STARTING_PATH > $STARTING_PATH/$LOGFILE 2>&1
EXIT_CODE=$?
echo [$SECONDS] exited with code $EXIT_CODE
#cp $OUTPUTFILE $STARTING_PATH/

#cd $STARTING_PATH

echo [$SECONDS] exiting
exit $EXIT_CODE

