# Licenses and credits

## Copyright, licenses and credits

- Resident Doom's port, adapters and setup code are distributed under **GPL-3.0-only**; see [LICENSE](../LICENSE). This choice follows the project's adaptations of GPLv3 RE1 decomp code, rather than assuming that merely running on GZDoom makes every mod GPL.
- RE1 source reference: **[ecruells/resident-evil-pc-decomp](https://github.com/ecruells/resident-evil-pc-decomp)** and its contributors. Setup downloads a pinned revision locally; original notices and license remain with it. Generated RE1 graphics, sound, music, geometry, animation and data tables are **not** covered by this project's GPL grant.
- Runtime: **GZDoom**, its team and contributors, licensed separately under GPLv3 or later and bundled third-party terms. No GZDoom binary or source is included here.
- Historical optional extraction (removed from current setup): **innoextract**, Daniel Scharrer and contributors, zlib/libpng license and its distribution's library notices. It is no longer downloaded by current setup; no extractor binary is included here.
- Local Python dependencies: **NumPy** (BSD-3-Clause), **Pillow** (HPND-style/Pillow license and bundled component notices). NumPy and Pillow are installed locally, not bundled in the repository. Historical ISO support used pycdlib (LGPLv2.1); the current setup no longer installs or uses it.

See [third-party notices](../THIRD_PARTY.md) and [publication audit](../ASSET_AUDIT.md). **Do not upload or redistribute your generated PK3, copied IWAD or imported game data.** Owning a game does not automatically authorize redistributing its content.

**Resident Evil and its characters, code, assets and trademarks belong to Capcom. Doom and its assets/trademarks belong to their respective rights holders, including id Software/Bethesda. This is an unofficial fan project, not affiliated with or endorsed by Capcom, id Software, Bethesda or their affiliates.**

The upstream decomp expressly describes its game logic as reverse-engineered from Capcom's executable and relies on lawful reverse engineering/fair-use reasoning; its GPL license cannot grant Capcom's rights. That underlying provenance is a legal uncertainty, not a legal guarantee from this project.
