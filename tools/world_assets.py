#!/usr/bin/env python3
"""Convert original IVM meshes and crop original scenery into world sprites.
No reconstructed RE object geometry or replacement textures.
"""
from pathlib import Path
import struct,json,runpy,zlib
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
md3=runpy.run_path(str(ROOT/'tools/convert_item_views.py'))['md3']
out=ROOT/'mod/models/items'
def readmesh(path,frame=64):
 b=path.read_bytes();s=struct.unpack_from('<4s64s10i',b,struct.unpack_from('<i',b,100)[0]);off=struct.unpack_from('<i',b,100)[0];nf,_,nv,nt,ot,_,ost,ox,_=s[3:]
 v=np.array([struct.unpack_from('<3hH',b,off+ox+(frame*nv+i)*8)[:3] for i in range(nv)],float)/64
 uv=[struct.unpack_from('<2f',b,off+ost+i*8) for i in range(nv)];tri=[struct.unpack_from('<3i',b,off+ot+i*12) for i in range(nt)];return v,uv,tri
# Room backgrounds use PS1 RGB555, as display_image (0x00470770) does.
# pak_view.py's RGB helper reverses R/B, so use its LZW only, not its colours.
PakDecoder=runpy.run_path(str(ROOT/'resident-evil-pc-decomp-main/tools/pak_view.py'))['PakDecoder']
def decode_background(name):
 raw=PakDecoder((ROOT/'assets/reference/USA/Stage1'/name).read_bytes()).run()
 assert struct.unpack_from('<2I',raw)==(16,2)
 w,h=struct.unpack_from('<2H',raw,16)
 pixels=np.frombuffer(raw,dtype='<u2',count=w*h,offset=20).reshape(h,w)
 rgb=np.stack(((pixels&31)*255//31,((pixels>>5)&31)*255//31,((pixels>>10)&31)*255//31),-1).astype('uint8')
 Image.fromarray(rgb).save(ROOT/'assets/background-reference'/(Path(name).stem+'.png'))
for name in ['RC1181.pak','RC1180.pak']:decode_background(name)
models=[]
world_measurements=[]
for cls,sprite,file in [('REClip','RAMM','I26V'),('REClipBox','RAMM','I26V'),('REHerb','RHER','I64V'),('REShells','RSHL','I16V'),('REShotgun','RSHG','I02V'),('REInkRibbon','RINK','I56V')]:
 v,uv,tri=readmesh(out/(file+'.md3'));v/=(3 if cls=="REShotgun" else 3.2 if cls=="REHerb" else 8 if cls=="RESwordKey" else 6);
 if cls=="REHerb":v[:,0]*=1.15
 if cls=="REInkRibbon":v=np.stack((v[:,2],v[:,1],-v[:,0]),axis=1)
 if cls.startswith("REClip"):v=np.stack((v[:,0],-v[:,2],v[:,1]),axis=1)
 v[:,2]-=v[:,2].min();v[:,2]+=2
 world_measurements.append({"actor":cls,"source":"USA/Item_m2/"+file+".IVM","dimensions":(v.max(axis=0)-v.min(axis=0)).tolist(),"floor_clearance":2})
 worldskin='world-'+file+'.png'
 (out/worldskin).write_bytes((out/(file+'.png')).read_bytes())
 md3('world-'+file,v,uv,tri,[v],'models/items/'+worldskin);models.append((cls,sprite,'world-'+file,worldskin))
# Prefer the original in-room sword-key TMD over its menu-view mesh.
b=(ROOT/'assets/reference/USA/Stage1/ROOM1000.RDT').read_bytes()
table=struct.unpack_from('<I',b,0x54)[0];base,tim=struct.unpack_from('<2I',b,table)
clen=struct.unpack_from('<I',b,tim+8)[0];pal=np.frombuffer(b,dtype='<u2',count=256,offset=tim+20)
p=tim+8+clen;ix,iy,w,h=struct.unpack_from('<4H',b,p+4)
indices=np.frombuffer(b,dtype=np.uint8,count=w*2*h,offset=p+12).reshape(h,w*2);colours=pal[indices]
rgba=np.stack(((colours&31)*255//31,((colours>>5)&31)*255//31,((colours>>10)&31)*255//31,np.where(indices==0,0,255)),-1).astype('uint8')
Image.fromarray(rgba).save(out/'world-key.png')
vp,nv,_,_,pp,nprim,_=struct.unpack_from('<7I',b,base+12)
verts=np.array([struct.unpack_from('<3h',b,base+12+vp+i*8) for i in range(nv)],float)
points=[];uv=[];tri=[];pos=base+12+pp
for k in range(nprim):
 _,length,_,mode=struct.unpack_from('<4B',b,pos);assert mode==0x34
 q=pos+4;page=struct.unpack_from('<H',b,q+6)[0];start=len(points)
 for j in range(3):
  u,v=struct.unpack_from('<2B',b,q+j*4);vi=struct.unpack_from('<H',b,q+14+j*4)[0]
  points.append(verts[vi]);uv.append(((u+(page&15)*128-ix*2+.5)/(w*2),(v+((page>>4)&1)*256-iy+.5)/h))
 tri.extend([(start,start+1,start+2),(start+2,start+1,start)]);pos+=4+length*4
# Source key is a plane. Lay that original plane on the floor, 18 units long.
v=np.array(points);v=np.stack((v[:,1],v[:,2],v[:,0]),axis=1)*(18/(v[:,1].max()-v[:,1].min()))
v[:,2]-=v[:,2].min();v[:,2]+=2
md3('world-key',v,uv,tri,[v],'models/items/world-key.png')
models.append(('RESwordKey','RKEY','world-key','world-key.png'))
world_measurements.append({'actor':'RESwordKey','source':'USA/Stage1/ROOM1000.RDT item table0x54 slot0 TMD134380 TIM236524','dimensions':(v.max(axis=0)-v.min(axis=0)).tolist(),'floor_clearance':2})
# These objects are pre-rendered artwork, not complete standalone meshes.
# Only crop and mask original pixels; never reconstruct missing geometry.
from PIL import ImageDraw
def original_sprite(source, polygon, destination):
 image=Image.open(source).convert('RGBA')
 mask=Image.new('L',image.size,0);ImageDraw.Draw(mask).polygon(polygon,fill=255)
 image.putalpha(mask)
 image=image.crop(mask.getbbox());image.save(destination)
 # Anchor the original sprite at its bottom centre on the interaction actor.
 data=destination.read_bytes();payload=struct.pack('>2i',image.width//2,image.height)
 chunk=b'grAb'+payload
 destination.write_bytes(data[:33]+struct.pack('>I',len(payload))+chunk+struct.pack('>I',zlib.crc32(chunk))+data[33:])
 return {'source':str(source.relative_to(ROOT)), 'polygon':polygon,
         'output':str(destination.relative_to(ROOT)), 'size':list(image.size)}
sprites=ROOT/'mod/sprites'
chest=original_sprite(ROOT/'assets/background-reference/RC1181.png',
 [(82,153),(92,150),(139,148),(154,151),(154,183),(144,193),(86,190),(82,184)],sprites/'RBOXA0.png')
typewriter=original_sprite(ROOT/'assets/background-reference/RC1180.png',
 [(77,134),(95,134),(95,145),(100,148),(100,153),(109,154),(109,158),(94,158),(92,178),(90,196),(97,202),(97,208),(91,213),(74,214),(69,209),(71,202),(84,197),(86,180),(85,158),(64,157),(64,153),(76,151),(76,145)],sprites/'RTYPA0.png')
Image.open(ROOT/'assets/original-typewriter.png').save(ROOT/'mod/graphics/reui/typewriter.png')
# Remove only generated replacement assets from the prior conversion.
for name in ['chest.md3','chest.png','typewriter.md3','typewriter-material.png']:
 (out/name).unlink(missing_ok=True)
defs=''
for cls,sprite,file,skin in models:defs+=f'Model {cls} {{ Path "models/items" Model 0 "{file}.md3" Skin 0 "{skin}" Scale 1 1 1 NoInterpolation FrameIndex {sprite} A 0 0 }}\n'
(ROOT/'mod/world.modeldef').write_text(defs)
(RootGL:=ROOT/'mod/GLDEFS').write_text('HardwareShader Sprite RTYPA0 { Shader \"shaders/typewriter.fp\" }\n'+''.join('HardwareShader Texture \"models/items/'+skin+'\" { Shader \"shaders/pickup.fp\" }\n' for skin in sorted({model[3] for model in models})))
(ROOT/'assets/world-model-manifest.json').write_text(json.dumps({
 'pickups':'original IVM geometry/textures; scaled and ground-normalized',
 'chest':chest,'typewriter':typewriter,
 'chest_original_file':'USA/Stage1/RC1181.pak',
 'typewriter_original_file':'USA/Stage1/RC1180.pak',
 'chest_room':'Types.h ROOM_MANSION_STOREROOM 0x18: under east wing stairs',
 'background_decode':'Rendering.cpp display_image 0x00470770: red bits0..4, green5..9, blue10..14',
 'world_measurements':world_measurements,
 'limitations':'Chest body and typewriter have no complete standalone room TMD. Original RC1181/RC1180 background pixels are masked billboards, with fixed source perspective. No replacement object geometry.',
 'models':models},indent=2)+'\n')
