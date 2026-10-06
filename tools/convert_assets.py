#!/usr/bin/env python3
"""Extract the six original inventory icons. Model conversion is separate."""
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
REF=ROOT/'assets/reference/USA'
# Extract only inventory icons actually used; rows derived from g_ItemImageLookupTable.
import re
from re1_item_tables import read_tables
src=(ROOT/'resident-evil-pc-decomp-main/src/Globals.cpp').read_text()
m=re.search(r'g_ItemImageLookupTable\s*\[.*?\]\s*=\s*\{(.*?)\};',src,re.S)
nums=[int(x,16) for x in re.findall(r'0x([0-9A-Fa-f]+)', re.sub(r'//[^\n]*','',m[1]))]
s=(REF/'Data/STATUS.TIM').read_bytes();pal=np.frombuffer(s,dtype='<u2',count=256,offset=20+2*256*2)
pix=(REF/'Data/ITEM_ALL.PIX').read_bytes();out=ROOT/'mod/graphics';out.mkdir(exist_ok=True)
tables=read_tables();mixed=(REF/'Data/ITEM_MIX.PIX').read_bytes()
for item,name in [(2,'handgun'),(3,'shotgun'),(47,'ribbon'),(11,'ammo'),(12,'shells'),(0x44,'herb'),(0x33,'key'),(0x47,'herb2'),(0x4a,'herb3')]:
 row=nums[item*4]-1; source=pix
 if item in (0x47,0x4a):
  row=tables['image_types'][nums[item*4+1]]-1;source=mixed
 arr=np.frombuffer(source,dtype=np.uint8,count=1200,offset=row*1200).reshape(30,40);v=pal[arr]
 rgba=np.stack(((v&31)*255//31,((v>>5)&31)*255//31,((v>>10)&31)*255//31,np.where(arr==0,0,255)),axis=-1).astype('uint8');Image.fromarray(rgba).save(out/(name+'.png'))
print('Extracted six original 40x30 inventory icons.')
