{
  stdenv,
  lib,
  zig,
}:
let
  fs = lib.fileset;
  sourceFiles = ./.;
in

fs.trace sourceFiles

stdenv.mkDerivation {
  name = "gba2048";
  src = ./.;

  nativeBuildInputs = [ zig.hook ];
}
