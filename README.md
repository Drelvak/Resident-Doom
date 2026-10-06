# Resident Doom

**Resident Evil 1 × Doom/GZDoom**, an experimental fan project made by **Drelvak**.
Jill Valentine, fixed cameras, tank controls, original RE1 inventory and resource management meet Doom's **E1M1: Hangar**.

**[Watch the original YouTube video →](https://youtu.be/yGkjS0gFxnY)**

This download contains source and local setup tools, **not the original games or a ready-to-play PK3**. Setup builds the prototype using your own game data. No Git or programming knowledge is needed.

## Before setup: three fixed drop folders

Both Windows and Linux use the same locations. Doom and GZDoom use the exact paths below. Setup inspects **only `dependencies/re1/`** to recognize the RE1 source you put there; it never scans other folders, the registry, Steam/GOG stores or runtime locations.

```text
Resident-Doom/
  dependencies/
    doom/
      doom.wad                 <- your registered Doom / Ultimate Doom IWAD
    re1/
      USA/                     <- your legally owned USA RE1 PC data folder
        Data/ ...
        Enemy/ ...
        Players/ ...
        Item_m2/ ...
        Stage1/ ...
        Sound/ ...
    gzdoom/
      gzdoom.exe               <- Windows: unpack the complete GZDoom download here
      gzdoom                   <- Linux: unpack the complete GZDoom download here
      gzdoom.pk3 ...            <- keep all runtime support files beside the executable
```

**No game data or GZDoom executable is included.** Name the Doom file exactly **`doom.wad`** (lowercase on Linux). Doom II, shareware and Freedoom are not supported by this E1M1 slice. The original IWAD is never modified.

For RE1, put **one legally owned source** inside **`dependencies/re1/`**. Installed/copied data is preferred; no store account or installation discovery is used.

| RE1 source | Current support |
| --- | --- |
| Copied/installed classic USA PC game folder | Supported: `USA/`, its contents, or a copied install folder containing that layout; case-insensitive file recognition |
| Copied original PC CD contents | Supported **when they contain unpacked classic USA PC data**; discs containing only packed retail installers are not supported |
| GOG offline installer `.exe` and companion `.bin` files | Supported using innoextract; keep original filenames and files together. The tested version is `setup_resident_evil_1.0_hotfix2_(74654).exe` plus `setup_resident_evil_1.0_hotfix2_(74654)-1.bin` |
| Standard `.iso` disc image | Supported for ISO9660/Joliet images containing the same unpacked USA data; read locally without mounting. Tested with a generated test image, not a physical retail-disc image |
| Steam-copied files | Supported **only if they contain the classic USA PC data layout above**; no Steam detection, login or account access |
| RE1 HD Remaster, other-language/console editions, raw BIN/CUE, encrypted images, packed retail CD installers | Unsupported; no conversion/reverse engineering or DRM bypass is attempted |

Setup imports only the 53 needed game files listed in [tools/required-assets.json](tools/required-assets.json). For an ISO, place one `.iso` here. For GOG, place one installer and its companion `.bin` files here. If several complete game datasets or several installers/images are present, setup reports a short error asking you to keep one source.

## Prerequisites

- Your legally owned **USA Resident Evil 1 PC** data (1997 USA / tested GOG release above).
- Your own registered **Doom / The Ultimate Doom `doom.wad`**.
- **[GZDoom](https://zdoom.org/downloads)**: **4.14.2** is the tested version. Unpack its complete distribution into `dependencies/gzdoom/`, not just the executable. On Linux its usual runtime libraries must be available.
- **[Python 3.12+](https://www.python.org/downloads/)** with pip/venv support; install the Python launcher on Windows if offered.
- First-setup internet access for a checksum-pinned GPL reference source, NumPy/Pillow in a **project-local virtual environment**, and the official open-source extractor if you use the GOG installer. pycdlib provides local ISO reading. Setup does not install software system-wide.

Use a writable folder, not Windows `Program Files`.

## Windows

1. Download **Code → Download ZIP** and extract the whole project.
2. Fill the three drop folders above with your own Doom/RE1 files and the complete GZDoom distribution.
3. Double-click **`setup.bat`** and wait for **Setup complete**.
4. Double-click **`play.bat`**.

Setup reports a short error naming a missing expected input. Game errors are in `logs/launch.log`. **Windows launchers have been reviewed but not executed on Windows.**

## Linux

1. Download/extract the whole project ZIP.
2. Fill the same three drop folders with your own Doom/RE1 files and the complete GZDoom distribution.
3. Open a terminal in the project folder, run **`sh setup.sh`**, and wait for **Setup complete**.
4. Run **`sh play.sh`**.

No path questions or system/store discovery are used. Source recognition is confined to the RE1 drop folder. Automatic GOG extraction supports x86/x86-64 Linux; on other architectures provide the installed/copied data folder. Config, saves, logs, dependencies and all generated game content stay inside this project folder.

## Controls

| Action | Keys |
| --- | --- |
| Walk / turn | Arrow keys or WASD; tank controls |
| Run / menu cancel | V or Shift |
| Aim | Hold X |
| Interact / fire / confirm | C, Space or Enter; hold Aim to fire |
| RE inventory/status | Escape, Z, Tab or I |
| Load a saved game | F9 |

Use the RE title menu for New Game; save at a typewriter with an ink ribbon. The normal GZDoom Escape menu is replaced by the RE status screen. Close the game window to quit.

## Prototype limitations

Only **E1M1** is supported. Native RE1 PC layout and gameplay logic guide the port, but GZDoom collision, timing, rendering, camera transitions and Doom monster behavior have documented technical differences. Some fixed-camera views and the original-background storage/typewriter billboards remain experimental. Existing development gameplay tests do not establish Windows compatibility. New GZDoom versions and alternate game editions are untested.

## Copyright, licenses and credits

- Resident Doom's port, adapters and setup code are distributed under **GPL-3.0-only**; see [LICENSE](LICENSE). This choice follows the project's adaptations of GPLv3 RE1 decomp code, rather than assuming that merely running on GZDoom makes every mod GPL.
- RE1 source reference: **[ecruells/resident-evil-pc-decomp](https://github.com/ecruells/resident-evil-pc-decomp)** and its contributors. Setup downloads a pinned revision locally; original notices and license remain with it. Generated RE1 graphics, sound, music, geometry, animation and data tables are **not** covered by this project's GPL grant.
- Runtime: **GZDoom**, its team and contributors, licensed separately under GPLv3 or later and bundled third-party terms. No GZDoom binary or source is included here.
- Local extraction: **innoextract**, Daniel Scharrer and contributors, zlib/libpng license and its distribution's library notices. It is downloaded separately; no extractor binary is included here.
- Local Python dependencies: **NumPy** (BSD-3-Clause), **Pillow** (HPND-style/Pillow license and bundled component notices), and **pycdlib** (LGPLv2.1). These are installed locally, not bundled in the repository.

See [THIRD_PARTY.md](THIRD_PARTY.md) and [ASSET_AUDIT.md](ASSET_AUDIT.md). **Do not upload or redistribute your generated PK3, copied IWAD or imported game data.** Owning a game does not automatically authorize redistributing its content.

**Resident Evil and its characters, code, assets and trademarks belong to Capcom. Doom and its assets/trademarks belong to their respective rights holders, including id Software/Bethesda. This is an unofficial fan project, not affiliated with or endorsed by Capcom, id Software, Bethesda or their affiliates.**

The upstream decomp expressly describes its game logic as reverse-engineered from Capcom's executable and relies on lawful reverse engineering/fair-use reasoning; its GPL license cannot grant Capcom's rights. That underlying provenance is a legal uncertainty, not a legal guarantee from this project.
