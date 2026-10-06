# Resident Doom

Drelvak’s Resident Evil 1 × Doom experiment: play as Jill inside Doom, with exact mechanics ported over directly from source code taken from [RE1 Decomp](https://github.com/ecruells/resident-evil-pc-decomp). Limited saves, typewriters, storage boxes, inventory, it's all there.

**[Watch the original video](https://youtu.be/yGkjS0gFxnY)**






<img width="800" height="450" alt="redoom_800_30fps" src="https://github.com/user-attachments/assets/414e96f8-f0b1-441c-b19c-f22dcfa19cf7" />






## What you need

- Doom
- Resident Evil 1 PC (tested using GoG version, other PC versions untested but probably works)
- [GZDoom](https://zdoom.org/downloads)

## Setup

Download and extract this project, then:

1. Put your **`doom.wad`** in **`dependencies/doom/`**.
2. **Install Resident Evil 1 normally, then drag the installed game files into `dependencies/re1/`.**
3. Put the complete GZDoom download in **`dependencies/gzdoom/`**.

**Windows:** Double-click `play.bat`.

**Linux:** Run `sh play.sh`.

The first launch prepares the game automatically. Later launches start immediately.

## Controls

Controls are the same as RE1 PC.

**Arrows/WASD:** move and turn · **V/Shift:** run/cancel · **X:** aim · **C/Space:** interact/fire/confirm · **Escape/TAB:** inventory

## Limitations

One experimental map: E1M1. Windows gameplay is not yet tested, developed on Arch Linux. Original game files are required and are not included. You must provide your own legally obtained copies.
The rest of the levels, at least the entire shareware episode, may be finished in the future. Currently a proof of concept prototype.

[Setup & troubleshooting](docs/SETUP.md) · [Technical information](docs/TECHNICAL.md) · [Licenses & credits](docs/LICENSES.md) · [Contributing](CONTRIBUTING.md)
