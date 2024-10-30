const std = @import("std");
const builtin = @import("builtin");
pub const gba = @import("gba.zig");
const alphabet = @import("alphabet.zig");
const bios = @import("bios.zig");
const compress = @import("compress.zig");

const tile = @import("tile.zig");

const tiles_img = @import("tiles");
const bg_img = @import("bg");

const _alphabet_letters = alphabet.processLetters(alphabet.letters);
const alphabet_letters_compressed align(4) = compress.rlCompress(@ptrCast(&_alphabet_letters), @sizeOf(@TypeOf(_alphabet_letters)));

const Console = struct {
    iy: u32 = 0,
    ix: u32 = 0,

    const Writer = std.io.Writer(*@This(), error{EndOfBuffer}, appendWrite);

    pub fn init() @This() {
        gba.reg_dispcnt.display_bg0 = true;
        gba.copyPalette(.{
            .{},
            .{ .r = 31, .g = 31, .b = 31 },
        } ++ [1]gba.Color{.{}} ** 14, &gba.bg_palettes[0]);
        var alphabet_letters: [@sizeOf(@TypeOf(_alphabet_letters))]u8 = undefined;
        bios.rlUncompReadNormalWrite8Bit(@ptrCast(&alphabet_letters_compressed), @ptrCast(&alphabet_letters));
        bios.bitUnpack(@ptrCast(&alphabet_letters), @ptrCast(gba.bg_tiles[0..]), &.{
            .zero_data = false,
            .data_offset = 0,
            .source_length = @sizeOf(@TypeOf(_alphabet_letters)),
            .source_unit_width = 1,
            .destination_unit_width = 4,
        });
        gba.reg_bg0cnt.map_data = 2;
        return .{
            .ix = 0,
            .iy = 0,
        };
    }

    fn appendWrite(self: *@This(), data: []const u8) error{EndOfBuffer}!usize {
        const i = self.iy * gba.screen_width + self.ix;
        if (i + data.len > gba.screen_width * gba.screen_height / 64) {
            return error.EndOfBuffer;
        }
        for (data) |d| {
            gba.bg_map[2][self.iy * 32 + self.ix].tile_number = d;
            self.ix += 1;
            if (self.ix >= gba.screen_width / 8) {
                self.ix = 0;
                self.iy += 1;
            }
        }
        return data.len;
    }

    pub fn clear(self: *@This()) void {
        for (0..gba.screen_height / 8) |y| {
            for (0..gba.screen_width / 8) |x| {
                gba.bg_map[2][y * 32 + x].tile_number = 0;
            }
        }
        self.ix = 0;
        self.iy = 0;
    }

    pub fn writer(self: *@This()) @This().Writer {
        return .{ .context = self };
    }
};

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, size: ?usize) noreturn {
    @setCold(true);
    if (builtin.mode == .ReleaseSmall or builtin.mode == .ReleaseFast) {
        while (true) {}
    }

    var w = Console.init();
    _ = w.writer().print("PANIC: {s}\\", .{msg}) catch unreachable;

    var it = std.debug.StackIterator.init(@returnAddress(), null);
    while (it.next()) |return_address| {
        _ = w.writer().print("T: {x}\\", .{return_address}) catch unreachable;
    }
    _ = error_return_trace;
    _ = size;
    while (true) {}
}

const x_offset = 0;
const y_offset = 0;
const animate_frames = 8;

var rng = std.rand.DefaultPrng.init(0);
var rand = rng.random();

var last_input: gba.Keys = .{};

fn indexToCoordinates(index: usize) struct { x: usize, y: usize } {
    return .{
        .x = index % 4,
        .y = index / 4,
    };
}

fn renderTiles(tiles: [16]?u32) void {
    for (0..128) |i| {
        gba.objs[i].set(gba.OBJ{
            .hidden = true,
        });
    }
    var idx: usize = 0;
    for (tiles, 0..) |t, i| {
        if (t) |til| {
            const coords = indexToCoordinates(i);
            gba.objs[idx].set(gba.OBJ{
                .size = .size32,
                .tile_number = @intCast(til * 16),
                .x = @intCast(coords.x * 32),
                .y = @intCast(coords.y * 32),
            });
            idx += 1;
        }
    }
}

export fn main() noreturn {
    gba.copyPalette(tiles_img.palette, &gba.obj_palettes[0]);
    gba.copyTiles(tiles_img.tiles[0..], gba.obj_tiles[0..]);
    gba.reg_dispcnt.* = .{
        .character1d = true,
        .display_obj = true,
    };

    var tiles: [16]?u32 = [1]?u32{null} ** 16;
    tiles[0] = 0;
    renderTiles(tiles);

    var animate: ?u32 = null;
    while (true) {
        gba.hBlankWait();
        if (animate) |i| {
            if (i == 0) {}
            animate = if (i == 0) null else i - 1;
        } else {
            const input = gba.reg_keyinput.*;
            const just_pressed = input.justPressed(last_input);
            last_input = input;
            if (!just_pressed.right) {
                const work_tiles = tile.slideRight(tiles);
                for (0..16) |tile_i| {
                    if (work_tiles[tile_i]) |work_tile| {
                        tiles[tile_i] = work_tile.value;
                    } else {
                        tiles[tile_i] = null;
                    }
                }
                tile.addTile(&tiles, rand);
                renderTiles(tiles);
            } else if (!just_pressed.left) {
                const work_tiles = tile.slideLeft(tiles);
                for (0..16) |tile_i| {
                    if (work_tiles[tile_i]) |work_tile| {
                        tiles[tile_i] = work_tile.value;
                    } else {
                        tiles[tile_i] = null;
                    }
                }
                tile.addTile(&tiles, rand);
                renderTiles(tiles);
            } else if (!just_pressed.down) {
                const work_tiles = tile.slideDown(tiles);
                for (0..16) |tile_i| {
                    if (work_tiles[tile_i]) |work_tile| {
                        tiles[tile_i] = work_tile.value;
                    } else {
                        tiles[tile_i] = null;
                    }
                }
                tile.addTile(&tiles, rand);
                renderTiles(tiles);
            } else if (!just_pressed.up) {
                const work_tiles = tile.slideUp(tiles);
                for (0..16) |tile_i| {
                    if (work_tiles[tile_i]) |work_tile| {
                        tiles[tile_i] = work_tile.value;
                    } else {
                        tiles[tile_i] = null;
                    }
                }
                tile.addTile(&tiles, rand);
                renderTiles(tiles);
            }
        }
    }
}
