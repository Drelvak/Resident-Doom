"""Original rigid joint meshes and integer animation inputs for Joint_move.
Uses the same source geometry, UVs and hierarchy as the reference baked model.
"""
import struct,math,json
import numpy as np
from re1_model_math import sin,cos

def export(root,body,weapon,parents,translations,roots,angles,shotgun):
 out=root/'mod/models/jill/joints';out.mkdir(exist_ok=True)
 zs='// Generated original TMD parts. Joint14 is replaced, not supplemented.\n'
 defs=''
 for j,mesh in [*enumerate(body),(15,weapon),(16,shotgun)]:
  points,norms,uv,tris=mesh
  points=np.stack((points[:,0],-points[:,2],-points[:,1]),axis=1)*56/1800
  norms=np.stack((norms[:,0],-norms[:,2],-norms[:,1]),axis=1)
  norms/=np.maximum(np.linalg.norm(norms,axis=1)[:,None],1)
  enc=((np.round(np.arccos(np.clip(norms[:,2],-1,1))*255/math.tau).astype(int)&255)<<8)|(np.round(np.arctan2(norms[:,1],norms[:,0])*255/math.tau).astype(int)&255)
  n=len(points);nt=len(tris);ot=108;os=ot+12*nt;ost=os+68;ox=ost+8*n;end=ox+8*n
  surface=bytearray(struct.pack('<4s64s10i',b'IDP3',b'original_joint',0,1,1,n,nt,ot,os,ost,ox,end))
  surface.extend(b''.join(struct.pack('<3i',*t) for t in tris));surface.extend(struct.pack('<64si',b'models/jill/skin.png',0))
  surface.extend(b''.join(struct.pack('<2f',*t) for t in uv))
  for point,normal in zip(points,enc):surface.extend(struct.pack('<3hH',*np.clip(np.round(point*64),-32768,32767).astype(int),int(normal)))
  blob=bytearray(struct.pack('<4si64s9i',b'IDP3',15,b'RE1 original joint',0,1,0,1,0,108,164,164,164+len(surface)))
  blob.extend(struct.pack('<10f16s',-128,-128,-128,128,128,128,0,0,0,222,b'local'));blob.extend(surface)
  (out/('part%d.md3'%j)).write_bytes(blob)
  cls='REJointPart%d'%j;sprite='K%03d'%j
  zs+='class '+cls+' : Actor { Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION +NOTIMEFREEZE } States { Spawn: '+sprite+' A -1; Stop; } }\n'
  defs+='Model '+cls+' { Path "models/jill/joints" Model 0 "part%d.md3" Skin 0 "models/jill/skin.png" Scale 1 1 1 UseActorPitch UseActorRoll CorrectPixelStretch NoInterpolation FrameIndex '%j+sprite+' A 0 0 }\n'
 data='// Generated from original EMD/EMW frame words and hierarchy.\nclass REJointData : Object {\n'
 for name,values in [('Parents',parents),('Translations',np.asarray(translations).reshape(-1)),('Roots',np.asarray(roots).reshape(-1)),('Angles',np.asarray(angles).reshape(-1)),('Sin',sin),('Cos',cos)]:
  data+='static const int '+name+'[]={'+','.join(str(int(v)) for v in values)+'};\n'
 data+='}\n'
 (root/'mod/joint_data.zs').write_text(data);(root/'mod/joint_models.zs').write_text(zs);(root/'mod/joint_models.modeldef').write_text(defs)
 (root/'assets/joint-renderer-inputs.json').write_text(json.dumps(dict(parents=parents,translations=np.asarray(translations).tolist(),roots=roots,angles=angles),indent=2))
 print('Exported 15 original joint parts, replacement W12 joint14 and exact source animation words.')
