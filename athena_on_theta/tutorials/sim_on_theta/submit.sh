#!/bin/bash
#COBALT -n 2
#COBALT -t 60
#COBALT -q debug-flat-quad
#COBALT -A datascience
#COBALT --jobname atlas_aesp_test

#########
## This runs one instance of the run_athena_command.py script per Theta node
#################

INSTPATH=$(git rev-parse --show-toplevel)/athena_on_theta

# Which container to use
# have a look in this directory for other options
CONTAINER_DIR=/projects/atlas_aesp/singularity_containers
# this container has all the 21.0.x x86_64-slc6-gcc49 releases and was created on 2018-05-30 at 19:20.
CONTAINER=$CONTAINER_DIR/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc49.r21.0.x.201805301920.sqsh

# athena args can be appended to the command line of the python script and they will be passed along


# First create a job working directory and enter it
mkdir $COBALT_JOBID
cd $COBALT_JOBID

# loop over the number of nodes
for i in $(seq -f "%05g" 1 $COBALT_PARTSIZE); do
   # create a node working directory and enter it
   mkdir $i
   cd $i
   # launch the athena application, pipe stdout/stderr to runlog.txt
   aprun -n 1 -N 1 $INSTPATH/run_athena_command.py --command sim --athenamp 10 --release 21.0.15 --package AtlasOffline --cmtconfig x86_64-slc6-gcc49-opt --workarea here --container $CONTAINER -B $INSTPATH:$INSTPATH:rw --conditionsTag=default:OFLCOND-MC16-SDR-14 --geometryVersion=ATLAS-R2-2016-01-00-01_VALIDATION --inputEVNTFile=$INSTPATH/atlasworf_EVNT.root --outputHITSFile=atlasworf_HITS.root --preInclude="EVNTtoHITS:SimulationJobOptions/preInclude.BeamPipeKill.py,SimulationJobOptions/preInclude.FrozenShowersFCalOnly.py" --DBRelease=all:current --preExec="EVNTtoHITS:simFlags.SimBarcodeOffset.set_Value_and_Lock(200000);simFlags.TRTRangeCut=30.0;simFlags.TightMuonStepping=True" --fileValidation=FALSE --physicsList=FTFP_BERT_ATL_VALIDATION --DataRunNumber=2010304 --simulator=FullG4 --truthStrategy=MC15aPlus --maxEvents 10 > runlog.txt 2>&1 &
   # retreat one directory up
   cd ../
done

# wait for all subprocesses to finish
wait
