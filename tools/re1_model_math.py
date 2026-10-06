import math
import numpy as np
# Exact integer operations from GteMatrix.cpp 0x004406a0/0x00409df0.
sin=[max(-16383,min(16383,int(math.sin(i*0.0015339807880859375)*16384))) for i in range(4096)]
cos=[max(-16383,min(16383,int(math.cos(i*0.0015339807880859375)*16384))) for i in range(4096)]
def trunc(n,d):return int(n/d)
def mul(a,b):return trunc(a*b,16384)
def rotation(v):
 x,y,z=(-v[0])&4095,v[1]&4095,(-v[2])&4095;sx,sy,sz=sin[x],sin[y],sin[z];cx_,cy_,cz=cos[x],cos[y],cos[z]
 r=[mul(cz,cy_),-mul(cy_,sz),sy,mul(mul(sx,sy),cz)+mul(cx_,sz),mul(cx_,cz)-mul(mul(sx,sz),sy),-mul(sx,cy_),mul(sx,sz)-mul(mul(cx_,sy),cz),mul(mul(sz,sy),cx_)+mul(sx,cz),mul(cx_,cy_)]
 return np.array([trunc(n,4) for n in r],dtype=np.int64).reshape(3,3)

D=np.diag([1,-1,1])
def matrix_product(a,b):
 # MulMatrix0 truncates each product, not the completed dot product.
 return np.trunc(a[:,:,None]*b[None,:,:]/4096).astype(np.int64).sum(axis=1)
def apply_lv(r,v):
 # ApplyMatrixLV performs Y-negated I/O and per-product truncation.
 return D @ np.trunc(r*(D@v)[None,:]/4096).astype(np.int64).sum(axis=1)
def apply_vertices(r,v):
 # ApplyMatrixSV renderer coordinate convention; final MD3 quantization follows.
 return (v @ D @ r.T) @ D /4096
