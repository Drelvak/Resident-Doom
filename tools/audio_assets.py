#!/usr/bin/env python3
"""Extract only original RE1 sounds used by the E1M1 slice."""
from pathlib import Path
import subprocess,shutil,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
mapping={'cursor':'cursor','cancel':'cancel','decide':'decide','handgun':'gun01','reload':'gun02','magazine':'gun04','shotgun':'shot01','pump':'shot03','box-open':'item02','box-scroll':'item01','step-a':'ft_lina','step-b':'ft_linb','type-a':'type01','type-b':'type02','case-land':'gun03','shell-land':'shot02','shell-reload':'shot04'}
names=list(mapping.values())+['bgm_00','bgm_13']
out=ROOT/'mod/sounds/re1';out.mkdir(parents=True,exist_ok=True)
for key,name in mapping.items():shutil.copyfile(ROOT/'assets/reference/USA/Sound'/f'{name}.wav',out/f'{key}.wav')
(ROOT/'mod/music').mkdir(exist_ok=True)
for name,track in [('bgm_00','REMANS'),('bgm_13','REHALL')]:shutil.copyfile(ROOT/'assets/reference/USA/Sound'/f'{name}.wav',ROOT/'mod/music'/f'{track}.wav')
(ROOT/'assets/audio-manifest.json').write_text(json.dumps({'effects':{k:'USA/Sound/'+v+'.wav' for k,v in mapping.items()},'music':{'REMANS':'USA/Sound/bgm_00.wav','REHALL':'USA/Sound/bgm_13.wav'},'source':'SoundSystem.cpp Jill bank slots4/5/6; SoundApi.cpp handgun/shotgun bank; SoundTables.cpp room0/18 box slot32 item02, slot33 item01, floor footsteps45/46; BgmRoomData stage0 corridors group0 Bgm_00, main hall group11 Bgm_13'},indent=2)+'\n')
p=ROOT/'assets/extraction-manifest.json';m=json.loads(p.read_text());m['files']=[{'path':str(f.relative_to(ROOT)),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()} for f in sorted((ROOT/'assets/reference').rglob('*')) if f.is_file()];p.write_text(json.dumps(m,indent=2)+'\n')
