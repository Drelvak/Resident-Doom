#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""One launcher for the locally built, asset-free-at-distribution prototype."""
from pathlib import Path
import json,os,subprocess,sys
ROOT=Path(__file__).resolve().parent
try:
 exe=ROOT/'dependencies/gzdoom'/('gzdoom.exe' if os.name=='nt' else 'gzdoom')
 if not exe.is_file():raise RuntimeError('Missing GZDoom; unpack its distribution into dependencies/gzdoom/')
 package=ROOT/'build/doom-re1.pk3';iwad=ROOT/'dependencies/doom/doom.wad'
 if not package.is_file() or not iwad.is_file():raise RuntimeError('Local game data/build is missing; run setup first')
 for name in ['logs','saves','build/config','build/cache','build/data']:(ROOT/name).mkdir(parents=True,exist_ok=True)
 env=os.environ.copy()
 if os.name!='nt':env['LD_LIBRARY_PATH']=str(exe.parent)+(':'+env['LD_LIBRARY_PATH'] if env.get('LD_LIBRARY_PATH') else '')
 for name,folder in [('CONFIG','config'),('CACHE','cache'),('DATA','data')]:env['XDG_'+name+'_HOME']=str(ROOT/'build'/folder)
 command=[str(exe),'-iwad',str(iwad),'-file',str(package),'-config',str(ROOT/'build/gzdoom.ini'),'-savedir',str(ROOT/'saves'),'-noautoload','-stdout','-logfile',str(ROOT/'logs/gzdoom.log'),'+exec',str(ROOT/'controls.cfg'),'+map','E1M1','+re_joint_render','true','+re_start_title','true',*sys.argv[1:]]
 with (ROOT/'logs/launch.log').open('w') as log:result=subprocess.run(command,cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT)
 if result.returncode:raise RuntimeError('GZDoom exited with an error; see logs/launch.log')
except Exception as e:print('Resident Doom:',e,file=sys.stderr);sys.exit(1)
