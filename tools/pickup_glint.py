"""Original RE1 type 0x0b item glint: CORE00.ESP + esp001.TIM.
CmdFunctions::cmd_item_set 0x461220 (ROOM1000 sword flags 0x8700 => depth28),
EffectSystem::effect_behavior_fire_phases 0x4101d0, Effect_AnimateSprite 0x47ce10.
"""
from pathlib import Path
import struct,json,zlib,hashlib
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1]
b=(R/'assets/reference/USA/Data/CORE00.ESP').read_bytes();slot=list(b[:8]).index(11)
p=struct.unpack_from('<I',b,len(b)-4-slot*4)[0];n=b[p+2];nu=b[p]
frames=[list(b[p+8+i*4:p+12+i*4]) for i in range(n)]
uv=[list(b[p+8+n*4+i*4:p+12+n*4+i*4]) for i in range(nu)]
a=p+8+(n+nu)*4;q=a+b[a+4]*4
assert struct.unpack_from('<2I',b,q)==(1,1)
header=list(b[q+8:q+32]);assert header[0]==56 and header[5:7]==[11,10]
t=(R/'assets/reference/USA/Effspr/esp001.tim').read_bytes();cs=struct.unpack_from('<I',t,8)[0];pal=np.frombuffer(t,dtype='<u2',count=256,offset=20);ip=8+cs;w,h=struct.unpack_from('<2H',t,ip+8);ix=np.frombuffer(t,dtype=np.uint8,count=w*2*h,offset=ip+12).reshape(h,w*2)
# Type0xb occupies page1 V123..147; palette row0 and tint record7 identity.
for i,(u,v,cx,cy) in enumerate(uv):
 c=pal[ix[v+123:v+147,u:u+24]];rgb=np.stack(((c&31)*255//31,((c>>5)&31)*255//31,((c>>10)&31)*255//31,np.where(c==0,0,255)),-1).astype('uint8')
 dest=R/f'mod/sprites/RGLT{chr(65+i)}0.png';Image.fromarray(rgb).save(dest)
 data=dest.read_bytes();chunk=b'grAb'+struct.pack('>2i',128-cx,128-cy)
 dest.write_bytes(data[:33]+struct.pack('>I',8)+chunk+struct.pack('>I',zlib.crc32(chunk))+data[33:])
(R/'assets/pickup-glint-manifest.json').write_text(json.dumps(dict(source_animation='USA/Data/CORE00.ESP',source_art='USA/Effspr/esp001.tim',type=11,depth=28,record=p,header=header,frames=frames,uv=uv,band_y=123,active_ticks=11,hidden_ticks=[100,110,120,130,140],light_factor=10,host_note='Source additive billboard, 30.303 Hz; scaled .5 for readable Doom world presentation, no dynamic light'),indent=2)+'\n')
p=R/'assets/extraction-manifest.json';m=json.loads(p.read_text());m['files']=[dict(path=str(f.relative_to(R)),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()) for f in sorted((R/'assets/reference').rglob('*')) if f.is_file()];p.write_text(json.dumps(m,indent=2)+'\n')
