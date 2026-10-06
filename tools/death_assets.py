#!/usr/bin/env python3
"""Convert original RE1 PC death/title pixels. Crops are source descriptors."""
from pathlib import Path
import struct,json,hashlib,shutil
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[1];D=R/'assets/reference/USA/Data';O=R/'mod/graphics/redeath';O.mkdir(parents=True,exist_ok=True)
def rgba(v):
 return np.stack(((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,np.where(v==0,0,255)),axis=-1).astype('uint8')
def tim(file):
 b=(D/file).read_bytes();cs=struct.unpack_from('<I',b,8)[0];cw,ch=struct.unpack_from('<2H',b,16);p=8+cs;w,h=struct.unpack_from('<2H',b,p+8)
 pal=np.frombuffer(b,dtype='<u2',count=cw,offset=20);ix=np.frombuffer(b,dtype=np.uint8,count=w*2*h,offset=p+12).reshape(h,w*2)
 if struct.unpack_from("<I",b,4)[0]&3==0:
  packed=ix;ix=np.empty((h,w*4),dtype=np.uint8);ix[:,::2]=packed&15;ix[:,1::2]=packed>>4
 return Image.fromarray(rgba(pal[ix]))
im=tim('DIED.TIM');im.save(O/'atlas.png')
quad=im.crop((0,64,160,184))
for i in range(4):
 q=quad
 if i&1:q=q.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
 if i&2:q=q.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 q.save(O/f'quad{i}.png')
for i in range(256):im.crop((i,0,i+1,64)).save(O/f'column{i}.png')
# LoadShadowMaskTexture 0x46ccd0 original coverage conversion, and
# AddFadePoly's death tint (0xffff50 -> bytes 80,255,255 -> 80/256,1/256,1/256).
b=(D/'KAGE.TIM').read_bytes();pal=np.frombuffer(b,dtype='<u2',count=256,offset=20);p=8+struct.unpack_from('<I',b,8)[0];w,h=struct.unpack_from('<2H',b,p+8)
ix=np.frombuffer(b,dtype=np.uint8,count=w*2*h,offset=p+12).reshape(h,w*2)
r=(pal[ix]&31).astype('int32');alpha=(((255-r*8)*2)&255);coverage=((255-alpha)*16//31).astype('uint8')
a=np.empty((h,w*2,4),dtype='uint8');a[:,:,:3]=(79,0,0);a[:,:,3]=coverage
Image.fromarray(a).save(R/'mod/sprites/RBLDA0.png')
v=np.frombuffer((D/'TITLE.PIX').read_bytes(),dtype='<u2').reshape(240,320);a=rgba(v);a[:,:,3]=255;Image.fromarray(a).save(O/'title.png')
# Cover EVIL with a crop of the original title's unlettered background, not a black matte.
branded=a.copy();region=branded[76:160,216:320];background=a[156:240,216:320]
# Replace only the red EVIL lettering; preserve the surrounding original eye
# pixels so the original transparent Doom patch has no rectangular matte seam.
mask=(region[:,:,0].astype(int)>region[:,:,2].astype(int)*2)&(region[:,:,0]>32)
region[mask]=background[mask];Image.fromarray(branded).save(O/'title-branded.png')
t=tim('t_press.tim')
for i,(y,h) in enumerate([(0,54),(83,70),(175,70)]):t.crop((0,y,256,y+h)).save(O/f'title-option{i}.png')
for key,file in [('death','jill04'),('body-thud','taore_st'),('title','evil01')]:
 shutil.copyfile(R/f'assets/reference/USA/Sound/{file}.wav',R/f'mod/sounds/re1/{key}.wav')
s=R/'mod/SNDINFO';text=s.read_text()
for key in ['death','body-thud','title']:
 if f're1/{key} sounds/' not in text:text+=f're1/{key} sounds/re1/{key}.wav\n'
s.write_text(text)
(R/'assets/death-manifest.json').write_text(json.dumps(dict(images={'atlas/quad/column':'USA/Data/DIED.TIM','title':'USA/Data/TITLE.PIX','title-option':'USA/Data/t_press.tim','blood-mask':'USA/Data/KAGE.TIM'},sounds={'death':'USA/Sound/jill04.wav','body-thud':'USA/Sound/taore_st.wav','title':'USA/Sound/evil01.wav'},body_animation='USA/Player/CHAR11.EMD, motion4 (existing original body bank)',layout='DeathScreen.cpp s_dieScreenPieces/image_update; TitleScreen.cpp g_titleTextPosTableUsa'),indent=2)+'\n')
p=R/'assets/extraction-manifest.json';m=json.loads(p.read_text());m['files']=[dict(path=str(f.relative_to(R)),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()) for f in sorted((R/'assets/reference').rglob('*')) if f.is_file()];p.write_text(json.dumps(m,indent=2)+'\n')
