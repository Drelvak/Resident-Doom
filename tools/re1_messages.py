#!/usr/bin/env python3
"""Compile the slice's original STR message streams using PrintText.h encoding."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]
PUNCT={' ':0,'!':26,'"':25,',':24,'.':121,':':22,';':23,'?':27,"'":58,'(':55,')':57,'-':59,'/':56,'\\':56}
def glyph(ch):
 if 'A'<=ch<='Z':return ord(ch)-65+29
 if 'a'<=ch<='z':return ord(ch)-97+61
 if '0'<=ch<='9':return ord(ch)-48+12
 return PUNCT.get(ch,27)
def encode(text):
 out=[];i=0
 while i<len(text):
  ch=text[i];i+=1
  if ch=='\\':
   code=text[i];i+=1
   if code=='i':out.extend([5,1,6,0,5,0]);continue
   if code=='x':out.append(int(text[i:i+2],16));i+=2;continue
   out.append({'n':2,'p':3,'c':8,'q':10}[code]);continue
  out.append(glyph(ch))
 return out+[1,0]
def generate():
 src=(ROOT/'resident-evil-pc-decomp-main/src/Globals.cpp').read_text()
 ids=[0,2,3,7,30,31,53];starts=[];lengths=[];data=[];manifest=[]
 for n in ids:
  raw=re.search(r's_gm%02d = STR\("(.*?)"\);'%n,src)[1]
  text=json.loads('"'+raw+'"');stream=encode(text);starts.append(len(data));lengths.append(len(stream));data.extend(stream)
  manifest.append(dict(global_message=n+192,source='s_gm%02d'%n,bytes=stream))
 zs='// Generated from original Globals.cpp STR messages; PrintText.h encoding.\nclass REMessages : Object {\n'
 zs+='const Count=%d;\n'%len(ids)
 for name,values in [('IDs',ids),('Starts',starts),('Lengths',lengths),('Bytes',data)]:zs+='static const int '+name+'[]={'+','.join(map(str,values))+'};\n'
 zs+='static int Glyph(int c) { if(c>=65&&c<=90)return c-65+29;if(c>=97&&c<=122)return c-97+61;if(c>=48&&c<=57)return c-48+12;'
 for ch,value in PUNCT.items():zs+='if(c==%d)return %d;'%(ord(ch),value)
 zs+='return 27; }\n}\n'
 (ROOT/'mod/messages.zs').write_text(zs);(ROOT/'assets/message-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':generate()
