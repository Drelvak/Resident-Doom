# Publication audit

The development copy is preserved. This separate source-only release uses an explicit file selection rather than packaging the development directory.

| Classification | Development material | Publication treatment |
| --- | --- | --- |
| Project-specific work | E1M1 camera/placement code, ZScript host adapters, Python converters/setup, launchers, shaders, controls, mod metadata | Source only; GPL-3.0-only with RE1 derivation attribution |
| RE1 decomp adaptations | Input/movement, aim/fire, menus/inventory/storage/save/death/effects, joint math and source-table adapters | Adapted code with source references and GPL notice; upstream source fetched locally, not bundled |
| GZDoom/open-source material | Bundled runtime, debug copies of engine classes, innoextract packages | All binaries and debug source copies excluded; users supply runtime, historical optional extraction dependencies no longer used by current setup |
| Capcom proprietary data | GOG installer, extracted TIM/PIX/IVM/EMD/EMW/ESP/RDT/PAK/WAV, converted PNG/MD3/audio/music, original UI/glyphs, animation/joint/message tables | Excluded, including generated equivalents; 53 filenames only are listed for local import |
| id Software proprietary data | Commercial IWADs, Doom art/logo/sprites/audio, copied E1M1 map geometry/objects and compiled map/package | Excluded; map is generated locally from the user-provided IWAD; original IWAD is never edited |
| Other material | Python dependency wheels, reference footage/screenshots, logs, saves, caches, installers, archives | Excluded; dependencies are installed/downloaded locally with notices retained |
| Private/development material | Absolute machine paths, GUI drivers, test/debug files, credentials/config and personal data | Not selected; local settings/config ignored; final committed file scan required |

No image, model, audio, WAD, executable, dependency archive, screenshot or generated game-content table is intentionally published. The generated playable PK3 remains private local output, not a GitHub release asset. The original Doom IWAD is copied read-only as input and never patched.

The decomp's GPL notice does not resolve the underlying Capcom reverse-engineering provenance. No claim of legally guaranteed safety is made. Doom shareware is not bundled and does not currently work with stock GZDoom's mod-loading restrictions.
