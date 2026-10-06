# SPDX-License-Identifier: GPL-3.0-only
"""Recognize classic USA RE1 data strictly inside the user's one input folder."""
from pathlib import Path
import os

def index_folder(folder):
 base=folder.resolve();index={}
 for current,dirs,files in os.walk(base,followlinks=False):
  dirs[:]=[n for n in dirs if not (Path(current)/n).is_symlink()]
  for name in files:
   p=Path(current)/name
   if p.is_symlink():continue
   if not p.resolve().is_relative_to(base):raise RuntimeError('RE1 input contains an escaping path')
   key=str(p.relative_to(base)).replace('\\','/').casefold()
   if key in index:raise RuntimeError('RE1 input has duplicate case-insensitive filenames; keep one source copy')
   index[key]=p
 return index

def select_dataset(index,required):
 # Accept USA/ or the contents of USA/, optionally under a copied install wrapper.
 suffix='data/status.tim';roots=set()
 for key in index:
  if key.endswith('/'+suffix):roots.add(key[:-len(suffix)])
  elif key==suffix:roots.add('')
 complete=[]
 for root in sorted(roots):
  paths={n:index.get(root+n.removeprefix('USA/').casefold()) for n in required}
  if all(paths.values()):complete.append(paths)
 if len(complete)>1:raise RuntimeError('Multiple complete RE1 datasets found inside the input folder; keep one copy')
 return complete[0] if complete else None
