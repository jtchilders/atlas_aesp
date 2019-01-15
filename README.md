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



