# atlas_aesp
Codes for the ATLAS Aurora Early Science Project

# athena_on_theta

The `run_athena_command.py` script will run athena transforms or athena scripts on Theta using containerized releases.

The command has these options:
```
   2019-01-15 20:03:10|INFO|__main__|Start run_transform: ../../run_athena_command.py
   usage: run_athena_command.py [-h] --command COMMAND [--athenamp USE_ATHENAMP]
                                --release ATHENA_RELEASE --package ATHENA_PACKAGE
                                --cmtconfig ATHENA_CMTCONFIG
                                [--workarea ATHENA_WORKAREA]
                                [--pkg-setup PACKAGE_SETUP_SCRIPT]
                                [--gcclocation GCCLOCATION]
                                [--run-script-fn RUN_SCRIPT_FILENAME]
                                [-B [BIND_MOUNTS [BIND_MOUNTS ...]]] -c CONTAINER

   Run athena transforms or plain old athena inside a container. In order to pass
   arguments to athena or the standard transform settings, just append the
   settings at the end of this command line and they will be passed to athena.

   optional arguments:
     -h, --help            show this help message and exit
     --command COMMAND     Select which command to run: rec,gen,sim,athena
     --athenamp USE_ATHENAMP
                           Specify the number of AthenaMP workers to run. If not
                           set, AthenaMP will not be run.
     --release ATHENA_RELEASE
                           Athena release to setup. Example: 21.0.15
     --package ATHENA_PACKAGE
                           Athena package to setup. Example: AtlasOffline
     --cmtconfig ATHENA_CMTCONFIG
                           Athena cmtconfig to setup. Example:
                           x86_64-slc6-gcc62-opt
     --workarea ATHENA_WORKAREA
                           Path passed to asetup in "--workarea" setting to use
                           custom local compiled software.
     --pkg-setup PACKAGE_SETUP_SCRIPT
                           Path to the setup script for custom built athena
                           packages. This script is run after "asetup" but before
                           the transform or athena command.
     --gcclocation GCCLOCATION
                           Sometimes "asetup" needs help finding the gcc libs so
                           set this if you find problems. Example: "--gcclocation
                           =/cvmfs/atlas.cern.ch/path/to/gcc/for/your/release"
     --run-script-fn RUN_SCRIPT_FILENAME
                           This is the name of the bash script that will run the
                           athena application inside the container.
     -B [BIND_MOUNTS [BIND_MOUNTS ...]], --bind-mount [BIND_MOUNTS [BIND_MOUNTS ...]]
                           The paths past to this argument will be passed to the
                           Singularity command line for mounting local folders.
                           This command can be repeated in a similar way.
     -c CONTAINER, --container CONTAINER
                           Full path to the singularity container to run inside.
```

## Tutorials

## `sim_on_theta/submit.sh`
This script gives you an idea of how to run simulation on Theta. It should run out of the box. 
Just login to theta `ssh theta.alcf.anl.gov` make sure you can access `/projects/atlas_aesp` then clone this repo and run `qsub submit.sh`. The job will run on the debug queue and won't finish in the 60 minute limit since there are too many input events for one node.

# Development on Theta
If you want to develop, compile Athena packages on Theta, you need to run the build commands inside a singularity shell, in the container you are running. For intance, to load up release 21.0.15 you do
```bash
> singularity shell -B /projects/atlas_aesp/working/path:/projects/atlas_aesp/working/path:rw /projects/atlas_aesp/singularity_containers/centos6-cvmfs.atlas.cern.ch.x86_64-slc6-gcc49.r21.0.x.201805301920.sqsh
```
Then you can setup athena release as usual:
```bash
> export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
> source $ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh
```
## `athena_on_theta/submit.sh`
Once you have built your custom area, you can run athena this way with your custom area:

