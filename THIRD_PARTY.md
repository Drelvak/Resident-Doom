# Third-party provenance and notices

## Resident Evil PC decomp — GPLv3

Source: https://github.com/ecruells/resident-evil-pc-decomp
Pinned setup reference: `15004914527567a2b9cecf34997abe8c252bcbf9`.

The gameplay/menu/effect port in `mod/main.zs`, `mod/save_loop.zs`, `mod/death.zs`, `mod/casing.zs`, `mod/joint_runtime.zs`, and mathematical/table adapters under `tools/` adapts or traces this source. Changes translate its logic into GZDoom ZScript/Python, map coordinates and host APIs; source address/function comments retain traceability. Copyright in upstream contributions remains with their respective authors. Project-specific adapters, cameras, resource placement, setup and launchers are Drelvak's project contributions.

GPLv3 applies to these code adaptations. The downloaded upstream source preserves its own LICENSE, README, copyright notices and contributor history reference; it is not included in the published file set. The repository retains the complete GPLv3 license and source for the port/adapters. The GPL grant covers code contributions, **not** Capcom game content. Upstream expressly does not claim rights over Capcom's original code/assets and relies on lawful reverse engineering/fair-use reasoning. Public release needs consideration of that unresolved provenance.

## GZDoom — external runtime

https://github.com/ZDoom/gzdoom
GPLv3-or-later for the runtime, plus its third-party component licenses. No engine binary or copied engine source is distributed here. The ZScript adapters invoke GZDoom public APIs and extend native classes. GPL licensing of this port is driven by its RE1-source adaptations; using the runtime alone is not asserted to impose GPL on all mod assets.

## innoextract — historical optional local download

https://constexpr.org/innoextract/
Daniel Scharrer and contributors; zlib/libpng license. Earlier setup revisions downloaded official 1.9 packages with SHA-256 checks; current installed-files-only setup does not download or use the extractor. Their accompanying license/library notices stay in `.local/innoextract/`. Neither binary nor library code is included in the release source archive.

## NumPy and Pillow — local Python dependencies

https://numpy.org/doc/stable/license.html — BSD-3-Clause.
https://github.com/python-pillow/Pillow/blob/main/LICENSE — Pillow/HPND-style license and listed components.
Installed into `.local/venv/`; not distributed with this source release. Their installed license metadata is retained.

## Doom shareware evaluation

No Doom IWAD or original shareware package is bundled. The historic shareware license permits non-paid copying; a published 1999 Carmack clarification states that the shareware WAD is distributable. That is not a GPL or blanket game-asset license:
https://raw.githubusercontent.com/redox-os/freedoom/master/LICENSE-DOOM1

Independently, stock GZDoom 4.14.2 rejects `-file` mods with shareware:
https://github.com/ZDoom/gzdoom/blob/g4.14.2/src/d_main.cpp#L3528-L3530

This release does not modify a shareware IWAD, spoof its identity or bypass that restriction. The release intentionally requires the user's registered Doom IWAD, supplied at dependencies/doom/doom.wad. Shareware was evaluated and is not part of this release.

## pycdlib — historical ISO reader

https://github.com/clalancette/pycdlib
Chris Lalancette and contributors; LGPLv2.1 (see upstream COPYING and installed package notices). Earlier revisions used it as a separately installed Python dependency. Current setup does not install or use it. No proprietary image or disc content is distributed.
