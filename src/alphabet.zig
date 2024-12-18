const std = @import("std");
const gba = @import("gba.zig");
const bios = @import("bios.zig");

pub const Glyph = struct {
    width: usize,
    height: usize,
    data: []const u1,
};

pub const Surface = struct {
    tiles: []gba.Tile,
    pitch: usize,

    pub fn init(tiles: []gba.Tile, pitch: usize) @This() {
        return .{ .tiles = tiles, .pitch = pitch };
    }

    pub fn drawPixel(self: @This(), y: usize, x: usize, color: u4) void {
        const tile_y: usize = @divFloor(y, 8);
        // Skip draws that are out of bounds
        if (tile_y >= @divFloor(self.tiles.len, self.pitch)) {
            return;
        }
        const tile_x: usize = @divFloor(x, 8);
        // Skip draws that are out of bounds
        if (tile_x >= self.pitch) {
            return;
        }
        const inner_y: u5 = @intCast(@mod(y, 8));
        const inner_x: u5 = @intCast(@mod(x, 8));

        const tile: *gba.Tile = &self.tiles[tile_y * self.pitch + tile_x];
        tile[inner_y] |= @as(u32, color) << (4 * inner_x);
    }

    pub fn drawGlyph(self: @This(), y: usize, x: usize, glyph: Glyph, color: u4) void {
        for (0..glyph.height) |iy| {
            for (0..glyph.width) |ix| {
                const pixel = glyph.data[iy * glyph.width + ix];
                if (pixel == 0) {
                    continue;
                }
                self.drawPixel(y + iy, x + ix, color);
            }
        }
    }
};

const glyph_data = [_]Glyph{
    Glyph{ .width = 2, .height = 7, .data = &.{
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
        0, 0,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        1,
        1,
        1,
        1,
        1,
        0,
        1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 0, 1,
        1, 0, 1,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
    } },
    Glyph{ .width = 6, .height = 7, .data = &.{
        0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0,
        1, 1, 1, 1, 1, 1,
        0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0,
        1, 1, 1, 1, 1, 1,
        0, 1, 0, 0, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 1, 0, 1,
        1, 0, 1, 0, 0,
        0, 1, 1, 1, 0,
        0, 0, 1, 0, 1,
        1, 0, 1, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 7, .height = 7, .data = &.{
        0, 1, 0, 0, 0, 0, 1,
        1, 1, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 0, 0,
        0, 0, 0, 1, 0, 0, 0,
        0, 0, 1, 0, 0, 1, 0,
        0, 1, 0, 0, 1, 1, 1,
        1, 0, 0, 0, 0, 1, 0,
    } },
    Glyph{ .width = 6, .height = 7, .data = &.{
        0, 1, 1, 1, 0, 0,
        1, 0, 0, 0, 1, 0,
        0, 1, 0, 1, 0, 0,
        0, 0, 1, 0, 0, 0,
        0, 1, 0, 1, 0, 0,
        1, 0, 0, 0, 1, 0,
        0, 1, 1, 1, 0, 1,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        1,
        1,
        0,
        0,
        0,
        0,
        0,
    } },
    Glyph{ .width = 2, .height = 7, .data = &.{
        0, 1,
        1, 0,
        1, 0,
        1, 0,
        1, 0,
        1, 0,
        0, 1,
    } },
    Glyph{ .width = 2, .height = 7, .data = &.{
        1, 0,
        0, 1,
        0, 1,
        0, 1,
        0, 1,
        0, 1,
        1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        1, 0, 1, 0, 1,
        0, 1, 1, 1, 0,
        1, 1, 1, 1, 1,
        0, 1, 1, 1, 0,
        1, 0, 1, 0, 1,
        0, 0, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        1, 1, 1, 1, 1,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 0, 0,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        0,
        0,
        0,
        0,
        0,
        1,
        1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        1, 1, 1,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        0,
        0,
        0,
        0,
        0,
        0,
        1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 0, 1,
        0, 0, 1,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        1, 0, 0,
        1, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 1, 0,
        1, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
        0, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 1, 1,
        0, 0, 1, 0, 1,
        0, 1, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 0, 0, 0,
        0, 0, 1, 1, 0,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 1,
        0, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        0,
        0,
        1,
        0,
        1,
        0,
        0,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        0,
        0,
        1,
        0,
        1,
        1,
        0,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        0, 0, 0, 1,
        0, 0, 1, 0,
        0, 1, 0, 0,
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 0, 0,
        0, 0, 0,
        1, 1, 1,
        0, 0, 0,
        1, 1, 1,
        0, 0, 0,
        0, 0, 0,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
        0, 0, 1, 0,
        0, 1, 0, 0,
        1, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 0, 1, 1, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 0, 0,
        0, 0, 1, 0, 0,
    } },
    Glyph{ .width = 7, .height = 7, .data = &.{
        0, 1, 1, 1, 1, 1, 0,
        1, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 1, 1, 0, 1,
        1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 1, 1, 1, 1,
        1, 0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 1, 0, 0,
        0, 1, 0, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 1, 1, 0, 0,
        1, 0, 0, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 1, 0,
        1, 1, 1, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        1, 1, 1, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 1, 1, 1, 1,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 1, 1, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 1, 0, 0,
        1, 0, 0, 1, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 1, 1, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 1, 1,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        1, 1, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 1,
        1, 0, 0, 1, 0,
        1, 0, 1, 0, 0,
        1, 1, 0, 0, 0,
        1, 0, 1, 0, 0,
        1, 0, 0, 1, 0,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 0, 0, 0,
        1, 1, 1, 1,
    } },
    Glyph{ .width = 7, .height = 7, .data = &.{
        0, 1, 0, 0, 0, 1, 0,
        1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 1, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 1,
        1, 1, 0, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 0, 1, 1,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 0, 1, 0,
        0, 1, 1, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 0,
        1, 0, 1, 0, 0,
        1, 0, 0, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        0, 1, 1, 1, 0,
        0, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 1, 1, 1, 1,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        0, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
    } },
    Glyph{ .width = 7, .height = 7, .data = &.{
        1, 0, 0, 0, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 1, 0, 1, 0, 1,
        1, 0, 1, 0, 1, 0, 1,
        0, 1, 0, 0, 0, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 1, 0, 1, 0,
        0, 1, 0, 1, 0,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 1, 1, 1, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 1, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 1, 1, 1, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 1, 1,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 0, 0,
        1, 1, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 0, 0,
        1, 0, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 0, 1,
        0, 0, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 1, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        0, 0, 1,
        1, 1, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 1, 0,
        1, 0, 1,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        1, 1, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 0, 0,
        0, 1, 0,
        0, 0, 1,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
    } },
    Glyph{ .width = 6, .height = 7, .data = &.{
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 1, 1, 1, 0, 0,
        1, 0, 0, 0, 1, 0,
        1, 0, 0, 0, 1, 0,
        1, 0, 0, 0, 1, 0,
        0, 1, 1, 1, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
        0, 1, 1, 1, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 1,
        1, 0, 0, 0, 0,
        0, 1, 1, 1, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        1, 1, 1, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 1,
        0, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 1, 1, 0,
        1, 1, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        1,
        0,
        1,
        1,
        1,
        1,
        1,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 1,
        0, 0, 0, 1,
        0, 0, 0, 1,
        1, 0, 0, 1,
        0, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        1, 0, 1, 1, 0,
        1, 1, 0, 0, 0,
        1, 0, 1, 1, 0,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        1,
        1,
        1,
        1,
        1,
        1,
        1,
    } },
    Glyph{ .width = 7, .height = 7, .data = &.{
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        1, 1, 1, 0, 1, 1, 0,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 1, 1, 1, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 1,
        0, 0, 0, 0, 1,
        0, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
        1, 0, 0, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 1, 1, 1, 1,
        1, 0, 0, 0, 0,
        0, 1, 1, 1, 0,
        0, 0, 0, 0, 1,
        1, 1, 1, 1, 0,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 1, 0,
        0, 1, 0,
        1, 1, 1,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
        0, 1, 0,
    } },
    Glyph{ .width = 4, .height = 7, .data = &.{
        0, 0, 0, 0,
        0, 0, 0, 0,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        1, 0, 0, 1,
        0, 1, 1, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
    } },
    Glyph{ .width = 7, .height = 7, .data = &.{
        0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 0, 0, 1, 0, 0, 1,
        1, 1, 1, 0, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 1, 0, 1, 0,
        1, 0, 0, 0, 1,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 1,
        0, 0, 0, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        1, 1, 1, 1, 1,
        0, 0, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 1, 0, 0, 0,
        1, 1, 1, 1, 1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        0, 0, 1,
        0, 1, 0,
        0, 1, 0,
        1, 0, 0,
        0, 1, 0,
        0, 1, 0,
        0, 0, 1,
    } },
    Glyph{ .width = 1, .height = 7, .data = &.{
        1,
        1,
        1,
        1,
        1,
        1,
        1,
    } },
    Glyph{ .width = 3, .height = 7, .data = &.{
        1, 0, 0,
        0, 1, 0,
        0, 1, 0,
        0, 0, 1,
        0, 1, 0,
        0, 1, 0,
        1, 0, 0,
    } },
    Glyph{ .width = 5, .height = 7, .data = &.{
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        1, 0, 1, 0, 1,
        0, 0, 0, 1, 0,
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0,
    } },
};

pub const GlyphWriter = struct {
    surface: Surface,
    cursor_y: usize = 0,
    cursor_x: usize = 0,
    color: u4 = 1,

    const Writer = std.io.Writer(
        *GlyphWriter,
        error{EndOfBuffer},
        appendWrite,
    );

    fn appendWrite(self: *GlyphWriter, data: []const u8) error{EndOfBuffer}!usize {
        for (data) |char| {
            if (char == '\n') {
                // TODO: This assumes constant glyph height.
                self.cursor_y += glyph_data['a' - 32].height + 1;
                self.cursor_x = 0;
                continue;
            }
            if (char < 32 or char > 126) {
                continue;
            }
            const glyph = glyph_data[char - 32];
            const new_cursor_x = blk: {
                if (self.surface.pitch * 8 <= self.cursor_x + glyph.width) {
                    self.cursor_y += glyph.height + 1;
                    if (@divFloor(self.surface.tiles.len, self.surface.pitch) * 8 <= self.cursor_y + glyph.height) {
                        return error.EndOfBuffer;
                    }
                    break :blk 0;
                } else {
                    break :blk self.cursor_x + glyph.width + 1;
                }
            };
            self.surface.drawGlyph(self.cursor_y, self.cursor_x, glyph, self.color);
            self.cursor_x = new_cursor_x;
        }
        return data.len;
    }

    pub fn writer(self: *GlyphWriter) Writer {
        return .{ .context = self };
    }
};
