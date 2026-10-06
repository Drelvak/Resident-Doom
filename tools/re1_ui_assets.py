#!/usr/bin/env python3
"""Extract original TIM pixels and the native MainMenu draw tables; no substitute art."""
from pathlib import Path
import struct,re,json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'assets/reference/USA/Data'; OUT=ROOT/'mod/graphics/reui';OUT.mkdir(parents=True,exist_ok=True)
def tim(name,row=0):
 b=(DATA/name).read_bytes();flags=struct.unpack_from('<I',b,4)[0];size=struct.unpack_from('<I',b,8)[0];cw,ch=struct.unpack_from('<2H',b,16);p=8+size;w,h=struct.unpack_from('<2H',b,p+8)
 pal=np.frombuffer(b,dtype='<u2',count=cw,offset=20+row*cw*2);raw=np.frombuffer(b,dtype=np.uint8,count=w*2*h,offset=p+12).reshape(h,w*2)
 if flags&3==0:
  arr=np.empty((h,w*4),dtype=np.uint8);arr[:,::2]=raw&15;arr[:,1::2]=raw>>4
 else:arr=raw
 v=pal[arr];rgba=np.stack(((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,np.where(arr==0,0,255)),axis=-1).astype('uint8')
 return Image.fromarray(rgba)
def source_array(src,name):
 body=re.search(r'\b'+name+r'\s*\[.*?\]\s*=\s*\{(.*?)\};',src,re.S)[1];body=re.sub(r'//[^\n]*','',body)
 return bytes(int(x,16) for x in re.findall(r'0x([a-fA-F0-9]+)',body))
def crop(im,name,u,v,w,h):
 im.crop((u,v,u+w,v+h)).save(OUT/(name+'.png'))
status=tim('STATUS.TIM');blue=tim('BLUE.TIM');face=tim('Statface.tim');box=tim('ITEMBOXn.TIM');font=tim('fontus.tim')
for name,im in [('status',status),('font',font),('box',box)]:im.save(ROOT/'assets'/('original-'+name+'.png'))
src=(ROOT/'resident-evil-pc-decomp-main/src/game/MenuData.cpp').read_text();block=source_array(src,'g_MenuFrameDataBlock');assert len(block)==712
commands=[]
def record(b,o,im,depth,flip=0):
 x,y,w,h,u,v=struct.unpack_from('<6H',b,o);name='part%03d'%len(commands);piece=im.crop((u,v,u+w,v+h))
 if flip&0x40:piece=piece.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 if flip&0x80:piece=piece.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
 piece.save(OUT/(name+'.png'));commands.append(dict(name=name,x=x,y=y,w=w,h=h,depth=depth,u=u,v=v,flip=flip));return x,y,w,h
for o in range(252,-1,-12):record(block,o,status,21)
for lo,hi in [(312,368),(496,622)]:
 for p in range(hi,lo,-14):
  flags=struct.unpack_from('<H',block,p-2)[0];cnt=(flags>>8)&127;vertical=flags&0x8000
  x,y,w,h=record(block,p-14,status,20,flags&192)
  first=commands[-1]
  for n in range(1,cnt):commands.append(dict(first,x=x+(0 if vertical else w*n),y=y+(h*n if vertical else 0),depth=20))
# Composite only immutable frame parts. Greater depth is behind lesser depth.
frame=Image.new('RGBA',(320,240),(0,0,0,0))
for c in sorted(commands,key=lambda c:-c['depth']):frame.alpha_composite(Image.open(OUT/(c['name']+'.png')),(c['x'],c['y']))
frame.save(OUT/'frame.png')
for i,o in enumerate(range(264,312,12)):
 x,y,w,h,u,v=struct.unpack_from('<6H',block,o);crop(status,'tab%d'%i,u,v,w,h)
crop(status,'radio-disabled',0,64,48,16);crop(status,'tab-cursor',0,80,48,16)
for n,u in enumerate([128,168]):crop(status,'cursor%d'%n,u,224,40,30)
crop(blue,'empty',0,0,40,30);crop(face,'portrait',32,0,30,30)
# Original label-window opening/closing crops: counter*6 by counter*3.
for state in ('open','close'):
 for count in range(1,9):
  for action,v in enumerate([0,24,48,72]):
   u=48 if state=='open' else (16-count)*6
   vv=v+(0 if state=='open' else (8-count)*3)
   crop(status,'action-%s-%d-%d'%(state,count,action),u,vv,count*6,count*3)
# Font CLUT tint multiplication from AddTintSprite 0x0046e0a0.
for d in range(10):crop(status,'digit%d'%d,128,d*8,8,8)
for n,v in enumerate([0,24,48,72,96]):crop(status,'action%d'%n,48,v,48,24)
for v in range(0,80,8):crop(status,'condition%d'%v,96,v,32,8)
# Font mapping is STR's pft_encode_char in PrintText.h. The game-text region starts at row 28.
punctuation={' ':0,'!':26,'"':25,',':24,'.':121,':':22,';':23,'?':27,"'":58,'(':55,')':57,'-':59,'/':56,'\\':56,'_':0}
for code in range(32,127):
 ch=chr(code);idx=ord(ch)-65+29 if 'A'<=ch<='Z' else ord(ch)-97+61 if 'a'<=ch<='z' else ord(ch)-48+12 if ch.isdigit() else punctuation.get(ch,27)
 glyph=font.crop(((idx%18)*8,28+(idx//18)*14,(idx%18)*8+8,42+(idx//18)*14))
 glyph.save(OUT/('glyph%d.png'%code))
 for label,color in [('green',(0,255,0)),('gray',(204,204,204))]:
  arr=np.asarray(glyph).copy();arr[:,:,:3]=(arr[:,:,:3].astype('uint16')*np.array(color)//255).astype('uint8');Image.fromarray(arr).save(OUT/('glyph%d-%s.png'%(code,label)))
for idx in range(128):
 glyph=font.crop(((idx%18)*8,28+(idx//18)*14,(idx%18)*8+8,42+(idx//18)*14))
 glyph.save(OUT/('code%d.png'%idx))
 arr=np.asarray(glyph).copy();arr[:,:,:3]=(arr[:,:,:3].astype('uint16')*np.array((0,255,0))//255).astype('uint8');Image.fromarray(arr).save(OUT/('code%d-green.png'%idx))
crop(font,'arrow',16,28,8,14)
main=(ROOT/'resident-evil-pc-decomp-main/src/game/MainMenu.cpp').read_text();boxparts=[]
for group in ['s_itemboxFramePartsC','s_itemboxFramePartsA']:
 b=source_array(main,group)
 for o in range(len(b)-12,-1,-12):
  x,y,w,h,u,v=struct.unpack_from('<6H',b,o);name='boxpart%d'%len(boxparts);crop(box,name,u,v,w,h);boxparts.append(dict(name=name,x=x,y=y,w=w,h=h))
crop(box,'box-marker',64,56,6,1)
slots=[struct.unpack_from('<2h',block,656+i*4) for i in range(12)]
# Generate exact source polylines; rasterization is the sole line API conversion.
from PIL import ImageDraw
waves=[]
for n in range(20):
 body=re.search(r'ekg_wave_%02d\[\]\s*=\s*\{(.*?)\}'%n,src)[1];values=[int(x) for x in re.findall(r'-?\d+',body)];wave=[values[i:i+4] for i in range(0,len(values),4)];waves.append(wave)
colors=[(192,0,0),(255,127,0),(216,216,0),(0,255,0),(0,0,0)]
for n,wave in enumerate(waves):
 ys=[0]*48
 for a,b,y,slope in wave:
  for x in range(a,b+1):ys[x]=y+(x-a)*slope
 for sweep in range(22,133):
  for trail in [15,31]:
   im=Image.new('RGBA',(48,30));draw=ImageDraw.Draw(im)
   for x in range(max(84,sweep),min(131,sweep+trail)+1):
    rgb=colors[n//4] if trail==15 else tuple(max(0,c-(sweep+31-x)*(c>>5)) for c in colors[n//4]);draw.line((x-84,ys[x-84]+17,min(47,x-83),ys[min(47,x-83)]+17),fill=(*rgb,255))
   im.save(OUT/('ecg-%d-%d-%d.png'%(n,sweep,trail)))
# Preserve mask rectangles as source data, rather than inventing clipping boundaries.
mask=source_array(main,'s_itemboxMaskRects');masks=[struct.unpack_from('<4h',mask,o) for o in range(0,40,8)]
for sweep in range(84,176):
 im=Image.new('RGBA',(48,30),(0,0,0,255));draw=ImageDraw.Draw(im)
 y=max(146,sweep);count=15-max(0,146-sweep);green=255-max(0,146-sweep)*16
 for line in range(max(0,count)):
  if y+line<176:draw.line((0,y+line-146,47,y+line-146),fill=(0,max(0,green-line*16),0,255))
 im.save(OUT/('heal%d.png'%sweep))
manifest=dict(masks=masks,native=[320,240],frames=commands,slots=slots,box=boxparts,waves=waves,palette='base TIM CLUT row 0; additional STATUS CLUT mapping remains under audit')
(ROOT/'assets/ui-manifest.json').write_text(json.dumps(manifest,indent=2))
zs='// Generated from original MainMenu.cpp/MenuData.cpp byte records.\nclass REUIData : Object {\n'
ordered=sorted(commands,key=lambda c:-c['depth'])
for name,key in [('FrameX','x'),('FrameY','y'),('FrameW','w'),('FrameH','h')]:
 zs+='static const int '+name+'[] = {'+','.join(str(c[key]) for c in ordered)+'};\n'
zs+='static const int FrameTexture[] = {'+','.join(str(int(c['name'][4:])) for c in ordered)+'};\n'
for name,values in [('SlotX',[s[0] for s in slots]),('SlotY',[s[1] for s in slots]),('BoxX',[s['x'] for s in boxparts]),('BoxY',[s['y'] for s in boxparts]),('BoxW',[s['w'] for s in boxparts]),('BoxH',[s['h'] for s in boxparts])]:zs+='static const int '+name+'[] = {'+','.join(map(str,values))+'};\n'
for i,name in enumerate(('MaskX','MaskY','MaskW','MaskH')):zs+='static const int '+name+'[] = {'+','.join(str(m[i]) for m in masks)+'};\n'
zs+='}\n';(ROOT/'mod/ui_data.zs').write_text(zs)
print('Original UI: 320x240, %d frame draws, 12 cursor positions, original TIM glyphs and 20 ECG tables.'%len(commands))

raw=(DATA/'TYPE00.TIM').read_bytes();w,h=struct.unpack_from('<2H',raw,16);v=np.frombuffer(raw,dtype='<u2',count=w*h,offset=20).reshape(h,w);a=np.stack(((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,np.full_like(v,255)),-1).astype('uint8');Image.fromarray(a).save(ROOT/'assets/original-typewriter.png')

# Original menu's solid black rectangle, rendered as a generated flat patch.
Image.new('RGBA',(64,64),(0,0,0,255)).save(OUT/'black.png')
