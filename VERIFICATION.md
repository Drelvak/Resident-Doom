# Release preparation checks

- Linux: ordinary setup created its own virtual environment, installed dependencies locally, imported all 53 required classic USA assets, and built the full PK3.
- GOG: the supported original offline installer pair was extracted without running the game installer; the generated build completed.
- Copied/installed data: nested wrapper folder and lowercase USA layout imported successfully. Copied CD contents use this same data-layout path; no physical retail CD was tested.
- ISO: a locally generated standard ISO/Joliet test image containing user-owned input files was read without mounting; all 53 extracted file hashes matched. No actual retail ISO or unusual edition was tested.
- Scope: input-folder symlinks pointing outside the folder were ignored; root-folder links are rejected. No registry/store/system discovery exists.
- Linux runtime: the independent generated package passed GZDoom 4.14.2 script compilation, and the release launcher reached E1M1 in an offscreen smoke check. The Doom IWAD remained byte-identical. No full playthrough/visual/audio regression was performed for release preparation.
- Windows: Python source compiles and launcher/path handling was inspected; neither complete Windows setup nor native Windows gameplay was tested.
- Publication: only source/text, instructions, notices and filename/hash-based dependency metadata are intended for Git. The generated PK3 and all proprietary/converted data are excluded.

Current simplification: setup accepts installed files only. Earlier GOG/ISO checks above are historical evidence, not supported current input paths. Those formats and their extra dependencies were removed from the normal flow.

One-step Play flow: tested on Linux using a separate disposable source copy and real owned-data conversion/build, with a test runtime marker for launch ordering. First Play built the PK3 and launched once; repeat Play skipped setup even after the fixture's RE1 inputs were removed; missing first-time inputs stopped with a clear error and no runtime launch. Native Windows execution remains untested.
