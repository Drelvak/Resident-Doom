"""Append an unreachable black rendering sector for RE1's separate menu scene.
Original playable geometry/things remain byte-identical prefixes. No IWAD writes.
"""
import struct

def append_menu_scene(entries):
 data=dict(entries);vbase=len(data[b'VERTEXES'])//4;sbase=len(data[b'SIDEDEFS'])//30;sector=len(data[b'SECTORS'])//26
 points=[(11904,11904),(11904,20096),(20096,20096),(20096,11904)]
 data[b'VERTEXES']+=b''.join(struct.pack('<2h',*p) for p in points)
 data[b'SECTORS']+=struct.pack('<2h8s8s3h',0,30000,b'REMBLK',b'REMBLK',255,0,0)
 for i in range(4):
  data[b'SIDEDEFS']+=struct.pack('<2h8s8s8sh',0,0,b'-',b'-',b'REMBLK',sector)
  data[b'LINEDEFS']+=struct.pack('<7H',vbase+i,vbase+(i+1)%4,1,0,0,sbase+i,65535)
 # GZDoom builds nodes/blockmap for the extended map; stale acceleration data
 # must not point to the old sector set. These are derived, not source geometry.
 for name in (b'SEGS',b'SSECTORS',b'NODES',b'REJECT',b'BLOCKMAP'):data[name]=b''
 return [(name,data[name]) for name,_ in entries]
