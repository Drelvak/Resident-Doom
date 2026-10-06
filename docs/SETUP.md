# Detailed setup and troubleshooting

## Before you start

Download the project ZIP and extract it into a writable folder. You need your own registered Doom / Ultimate Doom, the **original classic USA Resident Evil 1 PC** game, the complete **GZDoom 4.14.2** distribution, and **Python 3.12+** with pip/venv support. Windows users should install the Python launcher if offered. The RE1 HD Remaster and other-language/console editions are not supported.

First setup needs internet access. It downloads a checksum-pinned source reference and installs NumPy/Pillow into a virtual environment inside this project. It does not install software system-wide.

## The three drop folders

- **`dependencies/doom/doom.wad`**: your registered Doom / Ultimate Doom IWAD, named exactly `doom.wad` (lowercase on Linux). Doom II, shareware and Freedoom are not supported. The original IWAD is never edited.
- **`dependencies/re1/`**: install Resident Evil 1 normally, then copy or drag the installed game files here. The game folder can contain `USA/`, or you can copy the contents of `USA/`; a copied install folder containing those files is also recognized. Filenames are matched case-insensitively.
- **`dependencies/gzdoom/`**: unpack the complete GZDoom distribution here. Keep its support files, including `gzdoom.pk3`, beside `gzdoom.exe` on Windows or `gzdoom` on Linux. On Linux, GZDoom's usual runtime libraries must be available.

Setup inspects **only the RE1 drop folder** and does not follow links outside it. It does not search your system, registry, Steam/GOG installations or accounts. Keep one complete installed game copy in that folder. Installers, ISOs and packed disc files are not accepted by the current setup.

Setup imports only the [53 required files](../tools/required-assets.json), then builds the local playable package. No original game content is included in the download.

## Run

**Windows:** double-click `play.bat`.

**Linux:** open a terminal in the project folder and run `sh play.sh`.

On first launch, Play checks the three input folders, runs local setup/build, and then starts the game. If `build/doom-re1.pk3` already exists, it launches immediately without inspecting RE1 files or reinstalling dependencies. The internal `setup.py` and setup wrappers are retained for rebuilding/troubleshooting, but are not required for normal use.

## If something is missing

- **Missing Doom file:** place your IWAD at `dependencies/doom/doom.wad`.
- **Missing GZDoom:** put the executable and the rest of its distribution inside `dependencies/gzdoom/`, rather than an extra enclosing folder.
- **Missing RE1 file:** copy the entire installed classic PC game folder into `dependencies/re1/`, keeping its subfolders. The error names a required file. An installer, ISO or HD Remaster does not contain the supported installed layout.
- **Multiple complete RE1 datasets:** keep just one installed copy in the input folder.
- **Python missing:** install Python 3.12+ with pip/venv support, then run Play again.
- **Download or dependency error:** check your connection and run Play again. Local generated files are ignored by Git.
- **Game launch error:** see `logs/launch.log`. Config, logs and saves stay inside the project.

Windows launchers have been reviewed but native Windows setup/gameplay has not been tested. Do not redistribute the generated PK3 or imported game data. See [technical information](TECHNICAL.md) and [licenses/credits](LICENSES.md).
