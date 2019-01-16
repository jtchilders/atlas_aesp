#!/bin/bash
#COBALT -n 2
#COBALT -t 60
#COBALT -q debug-flat-quad
#COBALT -A datascience
#COBALT --jobname atlas_aesp_test

#########
## This runs one instance of the run_athena_command.py script per Theta node
#################
PROJPATH=/projects/atlas_aesp
INSTPATH=$(git rev-parse --show-toplevel)/athena_on_theta

# Which container to use
# have a look in this directory for other options
CONTAINER_DIR=/projects/atlas_aesp/singularity_containers
# this container has all the 21.0.x x86_64-slc6-gcc49 releases and was created on 2018-05-30 at 19:20.
CONTAINER=$CONTAINER_DIR/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc62.r21.0.x.201805310122.sqsh

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
   aprun -n 1 -N 1 $INSTPATH/run_athena_command.py --command rec --athenamp 10 --release 21.0.20 --package AtlasOffline --cmtconfig x86_64-slc6-gcc62-opt --workarea here --container $CONTAINER -B $INSTPATH:$INSTPATH:rw --conditionsTag=default:OFLCOND-MC16-SDR-16 --geometryVersion=default:ATLAS-R2-2016-01-00-01 --inputHITSFile=$PROJPATH/atlasworf_HITS.root --outputRDOFile=atlasworf_RDO.root  --postInclude default:RecJobTransforms/UseFrontier.py --preExec 'RAWtoESD:from RecExConfig.RecFlags import rec;rec.doForwardDet=False;rec.doInDet=False;rec.doMuon=False;rec.doCalo=True;rec.doTrigger=False;include ("RecExCommon/RecExCommon_topOptions.py")'  --maxEvents 10 --skipEvents 0 --autoConfiguration everything --runNumber 1 --digiSeedOffset1 9 --digiSeedOffset2 9 --digiSteeringConf StandardSignalOnlyTruth --jobNumber 1 --DBRelease current --athenaMPMergeTargetSize ALL:0 --ignorePatterns "regFcn: could not bind handle" --ignorePatterns "Callback registration failed" --ignorePatterns "sectorType = 0 out of range" > runlog.txt 2>&1 &
   # retreat one directory up
   cd ../
done

# wait for all subprocesses to finish
wait
