# Technical information

## Prototype limitations

Only **E1M1** is supported. Native RE1 PC layout and gameplay logic guide the port, but GZDoom collision, timing, rendering, camera transitions and Doom monster behavior have documented technical differences. Some fixed-camera views and the original-background storage/typewriter billboards remain experimental. Existing development gameplay tests do not establish Windows compatibility. New GZDoom versions and alternate game editions are untested.


The runtime is GZDoom; the only supported map is E1M1. The GPL source reference is checksum-pinned and downloaded locally, and original game art/audio/models/UI and the modified playable map are generated locally from user-supplied data. The commercial IWAD remains unchanged. Generated game content must not be redistributed.

- [Publication audit](../ASSET_AUDIT.md)
- [Release verification and platform limitations](../VERIFICATION.md)
- [Source reference and dependency licenses](../THIRD_PARTY.md)

Earlier setup revisions recognized GOG installers and standard ISO images. Current setup intentionally accepts installed files only; historical testing and third-party attribution remain documented in the linked verification and license notes.

Normal gameplay disables internal diagnostics and native Doom obituaries. Explicit launch options `+re_debug true`, `+re_case_trace true`, or `+re_debug_audio true` enable the corresponding diagnostics for developers. Their defaults are off; ordinary launches reset them off. Player-facing RE prompts/messages remain enabled.
