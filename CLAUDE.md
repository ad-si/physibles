# Physibles

3D-printable objects, one directory per object. Models are mostly
LuaCAD scripts (`.lua`), built with the `luacad` CLI
(`luacad info`, `luacad render`, `luacad convert`).

## Annotated PDF screenshots

Model changes are requested by dropping a PDF into the model's directory,
named like `2026-08-27t1054_iphone_mount.pdf`: a LuaCAD studio
screenshot of the model with a marker (usually red) drawn on the part
in question and a short written instruction.

- The header lists the source file and the camera angles
  (azimuth/elevation), which help reproduce the view with
  `luacad render --camera`.
- Apply the instruction to the named `.lua` file and verify with
  `luacad info` and a `luacad render` from a similar camera angle.
