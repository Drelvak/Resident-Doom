# SPDX-License-Identifier: GPL-3.0-only
"""Read an ordinary ISO9660/Joliet data image; never mounts a disc or runs setup."""
from pathlib import Path
import sys,json
import pycdlib
from re_input import select_dataset
ROOT=Path(__file__).resolve().parents[1]
required=json.loads((ROOT/'tools/required-assets.json').read_text())
def extract(image,destination):
 iso=pycdlib.PyCdlib()
 try:
  iso.open(str(image));kind='joliet_path' if iso.has_joliet() else 'iso_path';index={}
  for directory,dirs,files in iso.walk(**{kind:'/'}):
   for name in files:
    path=directory.rstrip('/')+'/'+name
    normalized='/'.join(p.split(';',1)[0] for p in path.strip('/').split('/')).casefold()
    if normalized in index:raise RuntimeError('Disc image has duplicate normalized paths')
    index[normalized]=path
  selected=select_dataset(index,required)
  if not selected:raise RuntimeError('ISO lacks the unpacked classic USA RE1 PC data. Packed/other-edition discs are unsupported; provide installed files instead.')
  for name,path in selected.items():
   out=destination/name;out.parent.mkdir(parents=True,exist_ok=True)
   iso.get_file_from_iso(str(out),**{kind:path})
 finally:iso.close()
if __name__=='__main__':
 try:extract(Path(sys.argv[1]),Path(sys.argv[2]))
 except Exception as e:print('ISO import failed:',e,file=sys.stderr);sys.exit(1)
