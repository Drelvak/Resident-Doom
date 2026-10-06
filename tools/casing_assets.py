"""Extract original type5 casing sprites and both native animation chains."""
from pathlib import Path
import struct,json,zlib,hashlib
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1];b=(R/'assets/reference/USA/Data/CORE00.ESP').read_bytes();slot=list(b[:8]).index(5);p=struct.unpack_from('<I',b,len(b)-4-slot*4)[0];n=b[p+2];nu=b[p];a=p+8+(n+nu)*4
frames=[list(b[p+8+i*4:p+12+i*4]) for i in range(n)];uv=[list(b[p+8+n*4+i*4:p+12+n*4+i*4]) for i in range(nu)]
phases=[]
for d in [0,1]:
 q=a+b[a+d]*4;assert struct.unpack_from('<I',b,q)[0]==1;q+=4;np_=struct.unpack_from('<I',b,q)[0];q+=4;phases.append([list(b[q+k*24:q+(k+1)*24]) for k in range(np_)])
t=(R/'assets/reference/USA/Effspr/esp000.tim').read_bytes();cs=struct.unpack_from('<I',t,8)[0];pal=np.frombuffer(t,dtype='<u2',count=256,offset=20);ip=8+cs;w,h=struct.unpack_from('<2H',t,ip+8);ix=np.frombuffer(t,dtype=np.uint8,count=w*2*h,offset=ip+12).reshape(h,w*2)
for i,(u,v,cx,cy) in enumerate(uv[:16]):
 c=pal[ix[v:v+16,u:u+16]];rgb=np.stack(((c&31)*255//31,((c>>5)&31)*255//31,((c>>10)&31)*255//31,np.where(c==0,0,255)),-1).astype('uint8');dest=R/f'mod/sprites/RCAS{chr(65+i)}0.png';Image.fromarray(rgb).save(dest);data=dest.read_bytes();chunk=b'grAb'+struct.pack('>2i',128-cx,128-cy);dest.write_bytes(data[:33]+struct.pack('>I',8)+chunk+struct.pack('>I',zlib.crc32(chunk))+data[33:])
def arr(name,v):return 'static const int '+name+'[]={'+','.join(map(str,v))+'};\n'
zs='// CORE00.ESP bytes; native type5 depth0 handgun / depth9 shotgun.\nclass RECasingData : Object {\n'
zs+=arr('Headers',[v for gun in phases for phase in gun for v in phase]);zs+=arr('Frames',[v for f in frames for v in f]);zs+='}\n';(R/'mod/casing_data.zs').write_text(zs)
(R/'assets/casing-manifest.json').write_text(json.dumps(dict(source_animation='USA/Data/CORE00.ESP',source_art='USA/Effspr/esp000.tim',type=5,depths=[0,9],fire_frames=[3,25],body_offsets=[[370,-2570,-220],[360,-2050,-440]],phases=phases,frames=frames,uv=uv[:16],source='Globals.cpp g_weaponMuzzleFlash 0x4c0e68; PlayerAnimations.cpp autoaim_fire 0x4580f0; EffectSystem behaviors11/8/10/9, AnimateSprite'),indent=2)+'\n')
p=R/'assets/extraction-manifest.json';m=json.loads(p.read_text());m['files']=[dict(path=str(f.relative_to(R)),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()) for f in sorted((R/'assets/reference').rglob('*')) if f.is_file()];p.write_text(json.dumps(m,indent=2)+'\n')
