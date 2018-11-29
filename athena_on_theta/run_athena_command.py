#!/usr/bin/env python
import argparse,logging,subprocess,os
logger = logging.getLogger(__name__)


def main():
   logging_format = '%(asctime)s|%(levelname)s|%(name)s|%(message)s'
   logging_datefmt = '%Y-%m-%d %H:%M:%S'
   logging_filename = None  # 'run_transform.log'
   logging.basicConfig(level=logging.INFO,
                       format=logging_format,
                       datefmt=logging_datefmt,
                       filename=logging_filename)
   logger.info('Start run_transform: %s',__file__)

   # parse command line
   oparser = argparse.ArgumentParser()

   KNOWN_COMMANDS = {'rec':'Reco_tf.py','sim':'Sim_tf.py','gen':'Generate_tf.py','athena':'athena'}
   oparser.add_argument('--command', dest='command', help='Select which command to run: %s' % ','.join(str(x) for x in KNOWN_COMMANDS.keys()),required=True)

   oparser.add_argument('--athenamp',dest='use_athenamp',default=-1,type=int,help='Specify the number of AthenaMP workers to run. If not set, AthenaMP will not be run.')
   oparser.add_argument('--release',dest='athena_release',help='Athena release to setup. Example: 21.0.15',required=True)
   oparser.add_argument('--package',dest='athena_package',help='Athena package to setup. Example: AtlasOffline',required=True)
   oparser.add_argument('--cmtconfig',dest='athena_cmtconfig',help='Athena cmtconfig to setup. Example: x86_64-slc6-gcc62-opt',required=True)
   oparser.add_argument('--workarea',dest='athena_workarea',default='',help='Path passed to asetup in "--workarea" setting to use custom local compiled software.')
   oparser.add_argument('--pkg-setup',dest='package_setup_script',default='',help='Path to the setup script for custom built athena packages. This script is run after "asetup" but before the transform or athena command.')


   oparser.add_argument('--gcclocation',dest='gcclocation',default='',help='Sometimes "asetup" needs help finding the gcc libs so set this if you find problems. Example: "--gcclocation=/cvmfs/atlas.cern.ch/path/to/gcc/for/your/release"')
   oparser.add_argument('--run-script-fn',dest='run_script_filename',default='runscript.sh',help='This is the name of the bash script that will run the athena application inside the container.')

   oparser.add_argument('-B','--bind-mount',dest='bind_mounts',help='The paths past to this argument will be passed to the Singularity command line for mounting local folders. This command can be repeated in a similar way.',action='append',nargs='*')
   oparser.add_argument('-c','--container',dest='contianer',help='Full path to the singularity container to run inside.',required=True)

   oparser.add_argument('--ssd',dest='use_ssd',help='Run Athena container on SSD. If used, need to specify a list of files to copy back to working directory.',action='store_true',default=False)
   oparser.add_argument('--ssd-in',dest='ssd_in',help='This can be a comma separated list of globs to grab files in the current directory and copy to the SSD if running in the SSD. The list should be in double quotations or bash will evaluate the globs before runtime.',default='')
   oparser.add_argument('--ssd-out',dest='ssd_out',help='This can be a comma separated list of globs to grab files in the SSD directory and copy back to the working after athena exits. The list should be in double quotations or bash will evaluate the globs before runtime.',default='')


   args, unknown_args = oparser.parse_known_args()

   if args.command not in KNOWN_COMMANDS.keys():
      raise Exception('"--command" option must be one of the following %s, but %s was passed' % (KNOWN_COMMANDS.keys(),args.command))

   athena_args = parse_unknowns(unknown_args)

   logger.info('command:               %s',args.command)
   logger.info('use_ssd:               %s',args.use_ssd)
   logger.info('use_athenamp:          %s',args.use_athenamp)
   logger.info('athena_release:        %s',args.athena_release)
   logger.info('athena_package:        %s',args.athena_package)
   logger.info('athena_cmtconfig:      %s',args.athena_cmtconfig)
   logger.info('athena_workarea:       %s',args.athena_workarea)
   logger.info('package_setup_script:  %s',args.package_setup_script)
   logger.info('gcclocation:           %s',args.gcclocation)
   logger.info('run_script_filename:   %s',args.run_script_filename)
   logger.info('bind_mounts:           %s',args.bind_mounts)
   logger.info('container:             %s',args.container)
   logger.info('ssd_in:                %s',args.ssd_in)
   logger.info('ssd_out:               %s',args.ssd_out)


   ssd_path = ''
   if args.use_ssd:
      # mkdir custom directory on SSD
      ssd_path = '/local/scratch'
      if 'BALSAM_JOB_ID' in os.environ:
         ssd_path += '/' + os.environ['BALSAM_JOB_ID']
      if not os.path.exists(ssd_path):
         os.makedirs(ssd_path)

      # copy input files to SSD
      # ...



   use_athenamp = False
   if args.use_athenamp > 0:
      use_athenamp = True

   use_workarea = False
   if len(args.athena_workarea) > 0:
      use_workarea = True

   use_package_setup_script = False
   if len(args.package_setup_script) > 0:
      use_package_setup_script = True

   run_script = athena_template.format(
      use_athenamp = use_athenamp,
      use_workarea = use_workarea,
      use_package_setup_script = use_package_setup_script,
      use_ssd = args.use_ssd,
      ssd_path = ssd_path,
      athena_release = args.athena_release,
      athena_package = args.athena_package,
      athena_cmtconfig = args.athena_cmtconfig,
      athena_workarea = args.athena_workarea,
      gcclocation = args.gcclocation,
      package_setup_script = args.package_setup_script,
      athena_proc_number = args.use_athenamp,
      command = KNOWN_COMMANDS[args.command],
      command_args = ' '.join("%s %s" % (key,athena_args[key]) for key in athena_args.keys())
      )

   with open(args.run_script_filename,'w') as f:
      f.write(run_script)


   # construct singularity command
   singularity_cmd = 'singularity exec'
   for x in args.bind_mounts:
      for y in args.bind_mounts:
         singularity_cmd += ' -B ' + y

   singularity_cmd += ' ' + args.container

   singularity_cmd += ' ' + args.run_script_filename

   if args.use_ssd:
      p = subprocess.Popen(singularity_cmd,cwd=ssd_path)
   else:
      p = subprocess.Popen(singularity_cmd)


   stdout,stderr = p.communicate()

   # copy out from SSD
   if args.use_ssd:
      pass





   



def parse_unknowns(args):
   # allow users to pass arguments for Athena or transforms directly on command line
   # they should all be in the form "--option value"
   output_args = {}
   i = 0
   while i < len(args):
      option = args[i]
      if option.startswith('--'):
         # make sure we don't go past length of list
         if i + 1 < len(args):
            value = args[i + 1]
            output_args[option] = value
            i += 2
         else:
            logging.error('no value to go with option: %s',option)
            raise SyntaxError('no value to go with athena option %s in unknown_args: %s' % (option,args))
      else:
         raise SyntaxError('found entry in unknown arguments but does not start with "--". Athena arguments must always be passed in the form "--option value": %s in %s' % (option,args))

   return output_args




athena_template = '''#!/bin/bash
echo [$SECONDS] Start inside Singularity
echo [$SECONDS] DATE=$(date)
USE_MP={use_athenamp}
USE_WORKAREA={use_workarea}
USE_PKG_SCRIPT={use_package_setup_script}
USE_SSD={use_ssd}
RELEASE={athena_release}
PACKAGE={athena_package}
CMTCONFIG={athena_cmtconfig}
echo [$SECONDS] USE_MP=          $USE_MP
echo [$SECONDS] USE_WORKAREA=    $USE_WORKAREA
echo [$SECONDS] USE_PKG_SCRIPT=  $USE_PKG_SCRIPT
echo [$SECONDS] USE_SSD=         $USE_SSD
echo [$SECONDS] RELEASE=         $RELEASE
echo [$SECONDS] PACKAGE=         $PACKAGE
echo [$SECONDS] CMTCONFIG=       $CMTCONFIG

if [ "$USE_SSD" = "TRUE" ] || [ "$USE_SSD" = "true" ] || [ "$USE_SSD" = "True" ]; then
   SSD_PATH={ssd_path}
   echo [$SECONDS] SSD_PATH=        $SSD_PATH
   mkdir -s $SSD_PATH
   cd $SSD_PATH
fi

echo [$SECONDS] Setting up Atlas Local Root Base
export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source $ATLAS_LOCAL_ROOT_BASE/user/atlasLocalSetup.sh --quiet

echo [$SECONDS] Setting up Atlas Software

if [ "$USE_WORKAREA" = "TRUE" ] || [ "$USE_WORKAREA" = "true" ] || [ "$USE_WORKAREA" = "True" ]; then
   LOCAL_WORKAREA=--workarea={athena_workarea}
   echo [$SECONDS] WORKAREA=        $LOCAL_WORKAREA
fi

echo [$SECONDS] AtlasSetup=      $AtlasSetup
source $AtlasSetup/scripts/asetup.sh --cmtconfig=$CMTCONFIG --makeflags=\"$MAKEFLAGS\" --cmtextratags=ATLAS,useDBRelease $LOCAL_WORKAREA {gcclocation} $RELEASE,$PACKAGE,notest

if [ "$USE_PKG_SCRIPT" = "TRUE" ] || [ "$USE_PKG_SCRIPT" = "true" ] || [ "$USE_PKG_SCRIPT" = "True" ]; then
   PKG_SCRIPT={package_setup_script}
   echo [$SECONDS] PKG_SCRIPT=      $PKG_SCRIPT
   source $PKG_SCRIPT
fi

if [ "{command}" = "Sim_tf.py" ]; then
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

echo [$SECONDS] PYTHON Version:     $(python --version)
echo [$SECONDS] PYTHONPATH:         $PYTHONPATH
echo [$SECONDS] LD_LIBRARY_PATH:    $LD_LIBRARY_PATH
env | sort > env_dump.txt

if [ "$USE_MP" = "TRUE" ] || [ "$USE_MP" = "true" ] || [ "$USE_MP" = "True" ]; then
   export ATHENA_PROC_NUMBER={athena_proc_number}
   echo [$SECONDS] ATHENA_PROC_NUMBER: $ATHENA_PROC_NUMBER
fi

# setup for Generate_tf.py
if [ "{command}" = "Generate_tf.py" ]; then
   echo [$SECONDS] setting up LHAPDF
   export LHAPATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPATH
   export LHAPDF_DATA_PATH=/lus/theta-fs0/projects/AtlasADSP/machinelearning/bjet_prod/lhapdfsets/current:$LHAPDF_DATA_PATH
fi

echo [$SECONDS] Starting command
{command} {command_args}
EXIT_CODE=$?
echo [$SECONDS] command exited with return code: $EXIT_CODE
echo [$SECONDS] Exiting
exit $EXIT_CODE
'''


if __name__ == "__main__":
   main()
