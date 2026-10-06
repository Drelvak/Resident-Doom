#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Import user-owned data and build locally. Never runs the commercial installer."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,struct,subprocess,sys,tarfile,urllib.request,venv,zipfile
ROOT=Path(__file__).resolve().parent
LOCAL=ROOT/'.local'
LOCKS=json.loads((ROOT/'tools/download-lock.json').read_text())
sys.path.insert(0,str(ROOT/'tools'))
from re_input import index_folder,select_dataset
REQUIRED=json.loads((ROOT/'tools/required-assets.json').read_text())
def run(args):
 subprocess.run([str(a) for a in args],cwd=ROOT,check=True)
def download(entry):
 target=LOCAL/entry['filename']
 if not target.exists() or hashlib.sha256(target.read_bytes()).hexdigest()!=entry['sha256']:
  print('Downloading verified open-source setup dependency:',entry['filename'],flush=True)
  req=urllib.request.Request(entry['url'],headers={'User-Agent':'Resident-Doom-local-setup'})
  with urllib.request.urlopen(req,timeout=90) as r:blob=r.read()
  if hashlib.sha256(blob).hexdigest()!=entry['sha256']:raise RuntimeError('Download checksum mismatch; refusing to use '+entry['filename'])
  target.write_bytes(blob)
 return target
def unpack(archive,destination):
 destination.mkdir(parents=True,exist_ok=True);base=destination.resolve()
 def safe(name):
  if '\\' in name or ':' in name:raise RuntimeError('Unsafe archive member')
  p=(base/name).resolve()
  if not p.is_relative_to(base):raise RuntimeError('Archive path escapes setup directory')
 if zipfile.is_zipfile(archive):
  with zipfile.ZipFile(archive) as z:
   for m in z.infolist():
    safe(m.filename)
    if (m.external_attr>>16)&0o170000==0o120000:raise RuntimeError('Archive symlink refused')
   z.extractall(destination)
 else:
  with tarfile.open(archive) as t:
   for m in t.getmembers():
    safe(m.name)
    if m.issym() or m.islnk():raise RuntimeError('Archive links refused')
   t.extractall(destination,filter='data')
def dependency_source():
 dest=ROOT/'resident-evil-pc-decomp-main'
 if not (dest/'src/Globals.cpp').exists():
  unpack(download(LOCKS['decomp']),LOCAL/'decomp-unpack')
  src=LOCAL/'decomp-unpack'/('resident-evil-pc-decomp-'+LOCKS['decomp']['commit'])
  shutil.copytree(src,dest,dirs_exist_ok=True)
 # Upstream's license/notices remain beside its locally downloaded source.
 print('RE1 source reference pinned at',LOCKS['decomp']['commit'],flush=True)
def re_source():
 folder=ROOT/'dependencies/re1'
 if not folder.is_dir():raise RuntimeError('Missing dependencies/re1/. Put your legally owned RE1 source there.')
 if folder.is_symlink() or not folder.resolve().is_relative_to(ROOT.resolve()):raise RuntimeError('RE1 input must be a real folder inside this project, not a link to another location')
 index=index_folder(folder);dataset=select_dataset(index,REQUIRED)
 if dataset:return 'folder',dataset
 missing='Data/STATUS.TIM'
 for key in index:
  if key.endswith('data/status.tim'):
   prefix=key[:-len('data/status.tim')]
   missing=next((n.removeprefix('USA/') for n in REQUIRED if prefix+n.removeprefix('USA/').casefold() not in index),'required classic PC data')
   break
 raise RuntimeError('Missing RE1 game file: '+missing+'. Copy the installed classic Resident Evil 1 PC game folder into dependencies/re1/, not an installer or disc image.')

def import_re(source):
 ref=ROOT/'assets/reference';ref.mkdir(parents=True,exist_ok=True);_,data=source
 print('Importing installed Resident Evil 1 game files.',flush=True)
 for name,path in data.items():
  dest=ref/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,dest)
 (ROOT/'assets/extraction-manifest.json').write_text(json.dumps({'method':'installed game files, inspection restricted to dependencies/re1/','files':[]},indent=2)+'\n')
def validate_doom(path):
 b=path.read_bytes()
 if len(b)<12 or b[:4]!=b'IWAD':raise RuntimeError('Select a Doom 1 IWAD (DOOM.WAD), not Doom II or a mod')
 n,o=struct.unpack_from('<2I',b,4)
 if o+n*16>len(b):raise RuntimeError('Invalid IWAD directory')
 names={b[o+i*16+8:o+i*16+16].rstrip(b'\0') for i in range(n)}
 if b'E1M1' not in names or b'E2M1' not in names:raise RuntimeError('This prototype requires registered Doom / The Ultimate Doom DOOM.WAD, not Doom II/shareware/Freedoom')
def prepare_python(skip):
 if skip:
  import numpy,PIL
  return sys.executable
 envdir=LOCAL/'venv'
 if not envdir.exists():
  try:venv.EnvBuilder(with_pip=True).create(envdir)
  except Exception as e:raise RuntimeError('Python venv support is unavailable. Install Python with venv/pip support, then retry.') from e
 python=envdir/('Scripts/python.exe' if os.name=='nt' else 'bin/python')
 env=os.environ.copy();env.update(PIP_INDEX_URL='https://pypi.org/simple',PIP_EXTRA_INDEX_URL='',PIP_CACHE_DIR=str(LOCAL/'pip-cache'),PIP_CONFIG_FILE=os.devnull,PIP_DISABLE_PIP_VERSION_CHECK='1',PYTHONNOUSERSITE='1')
 subprocess.run([str(python),'-m','pip','install','-r',str(ROOT/'requirements.txt')],cwd=ROOT,env=env,check=True)
 return str(python)
def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--skip-install',action='store_true',help='Use already installed NumPy/Pillow (advanced/offline testing)')
 args=parser.parse_args()
 if sys.version_info<(3,12):raise RuntimeError('Python 3.12+ is required')
 LOCAL.mkdir(exist_ok=True)
 doom=ROOT/'dependencies/doom/doom.wad'
 if not doom.is_file():raise RuntimeError('Missing dependencies/doom/doom.wad. Put your registered Doom 1 IWAD there.')
 validate_doom(doom)
 gz=ROOT/'dependencies/gzdoom'/('gzdoom.exe' if os.name=='nt' else 'gzdoom')
 if not gz.is_file():raise RuntimeError('Missing '+str(gz.relative_to(ROOT))+'. Unpack the GZDoom distribution into dependencies/gzdoom/.')
 # Inspect only the RE1 input folder; installed data takes priority.
 source=re_source()
 python=prepare_python(args.skip_install)
 for n in ['assets/background-reference','mod/graphics','mod/graphics/reui','mod/sprites','mod/models','mod/models/jill','mod/models/items','mod/sounds/re1','logs','saves']:(ROOT/n).mkdir(parents=True,exist_ok=True)
 dependency_source();import_re(source)
 for name in ['convert_assets','convert_models','convert_item_views','re1_ui_assets','world_assets','audio_assets','casing_assets','pickup_glint','death_assets','build']:
  print('Generating locally:',name,flush=True);run([python,ROOT/'tools'/(name+'.py')])
 print('\nSetup complete. Run play.bat (Windows) or ./play.sh (Linux).\nKeep generated game assets private; do not upload the generated PK3.',flush=True)
if __name__=='__main__':
 try:main()
 except (Exception,KeyboardInterrupt) as e:print('\nSetup failed:',e,file=sys.stderr);sys.exit(1)
