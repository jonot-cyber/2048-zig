let
  pkgs = import <nixpkgs> { config = {}; overlays = []; };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    zig
    zls
    gdb
    mgba
    qt5.qtwayland
    git
    nanoboyadvance
  ];
}
