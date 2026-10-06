#!/usr/bin/env python3
from pathlib import Path
import zipfile,json,struct,os
from re1_item_tables import generate
from re1_messages import generate as generate_messages
from menu_map import append_menu_scene
root=Path(__file__).resolve().parents[1]
(root/'build').mkdir(exist_ok=True)
build_lock=(root/'build/.build.lock').open('a')
try:
 import fcntl
 fcntl.flock(build_lock,fcntl.LOCK_EX)
except ImportError:
 import msvcrt
 build_lock.write('0');build_lock.flush();build_lock.seek(0)
 msvcrt.locking(build_lock.fileno(),msvcrt.LK_LOCK,1)
generate()
generate_messages()
(root/'build').mkdir(exist_ok=True)
manifest=json.loads((root/'assets/animation-manifest.json').read_text())
# One sprite state per baked animation frame gives deterministic poses in GZDoom.
zs='class JillPose : Actor { Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION } States {\nSpawn: TNT1 A -1; Stop;\n'
nf=sum(m['count'] for m in manifest)
md=''
for name,file in [('JillPose','jill.md3'),('JillUnarmedPose','jill-unarmed.md3'),('JillShotgunPose','jill-shotgun.md3')]:
 md+=f'Model {name} {{ Path "models/jill" Model 0 "{file}" Skin 0 "skin.png" Scale 1 1 1 NoInterpolation\n'
 for i in range(nf):
  sprite=f'J{i:03}'
  if name=='JillPose':zs+=f'Pose{i}: {sprite} A -1; Stop;\n'
  md+=f'FrameIndex {sprite} A 0 {i}\n'
 md+='}\n'
zs+='} }\nclass JillUnarmedPose : JillPose {}\nclass JillShotgunPose : JillPose {}\n'
(root/'mod/poses.zs').write_text(zs);(root/'mod/MODELDEF').write_text(md+(root/'mod/item_views.modeldef').read_text()+(root/'mod/joint_models.modeldef').read_text()+(root/'mod/world.modeldef').read_text())
arr='class REAnimations : Object {\n'
for bank,prefix in [('W12',''),('W10','Unarmed'),('BODY','Body'),('W13','Shotgun')]:
 motions=[m for m in manifest if m.get('bank','W12')==bank]
 for field,key in [('Starts','first'),('Counts','count')]:
  arr+='static const int '+prefix+field+'[] = {'+','.join(str(m[key]) for m in motions)+'};\n'
arr+='static const int Timings[] = {'+','.join(str(t) for m in manifest for t in m['timings'])+'};\n}\n'
(root/'mod/animations.zs').write_text(arr)
# Package the one selected map in GZDoom's explicit maps namespace.
# Original playable geometry and things are preserved; one disconnected
# black sector hosts the original inventory model viewer.
w=(root/'dependencies/doom/doom.wad').read_bytes(); n,o=struct.unpack_from('<2I',w,4)
d=[(*struct.unpack_from('<2I',w,o+i*16),w[o+i*16+8:o+i*16+16]) for i in range(n)]
k=next(i for i,e in enumerate(d) if e[2].rstrip(b'\0')==b'E1M1')
entries=[(name.rstrip(b'\0'),w[p:p+size]) for p,size,name in d[k:k+11]]
# Strip original Doom resources; keep starts, monsters and decorations.
resources=set(range(2001,2020))|{2022,2023,2024,2025,2026,2045,2046,2047,2048,2049,5,6,13,38,39,40}
entries=[(name,b''.join(struct.pack('<5h',*thing) for thing in struct.iter_unpack('<5h',data) if thing[3] not in resources) if name==b'THINGS' else data) for name,data in entries]
entries=append_menu_scene(entries)
mapdata=bytearray(b'PWAD'+struct.pack('<2I',len(entries),0)); directory=[]
for name,data in entries:
 directory.append((len(mapdata),len(data),name));mapdata.extend(data)
struct.pack_into('<I',mapdata,8,len(mapdata))
for p,size,name in directory:mapdata.extend(struct.pack('<2I8s',p,size,name))
(root/'mod/maps').mkdir(exist_ok=True);(root/'mod/maps/E1M1.wad').write_bytes(mapdata)
package_temp=root/'build'/('doom-re1-%d.tmp'%os.getpid())
with zipfile.ZipFile(package_temp,'w',zipfile.ZIP_DEFLATED) as z:
 for f in sorted((root/'mod').rglob('*')):
  if f.is_file(): z.write(f,f.relative_to(root/'mod'))
os.replace(package_temp,root/'build/doom-re1.pk3')
print(root/'build/doom-re1.pk3')
