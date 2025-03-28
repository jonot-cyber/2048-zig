# 2048
This is a version of the game [2048](2048.org) written for the Nintendo Game Boy Advance. It is written in zig, which is a cool programming language.

## Download
[DOWNLOAD HERE](https://github.com/jonot-cyber/2048-zig/releases)

## Features
- Core gameplay
- Animation
- Win/Loss Screens
- High score tracking

## Compatability
Tested as working on mGBA 0.10.3. Might not work on real hardware.

## Building
If you don't want to [download](https://github.com/jonot-cyber/2048-zig/releases) it, or you would like to make changes, you can build it from source. Download the repository, and run:
```
zig build
```
To make a debug build, or
```
zig build --release=safe
```
for a release build. You will need to have installed zig on your computer. This was written with zig 0.14.0, so if the latest verison doesn't work, try that one.
