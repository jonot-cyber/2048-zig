const std = @import("std");
const builtin = @import("builtin");
pub const gba = @import("gba.zig");
const alphabet = @import("alphabet.zig");
const bios = @import("bios.zig");
const compress = @import("compress.zig");

const tiles_img = @import("tiles");
const bg_img = @import("bg");

const _alphabet_letters = alphabet.processLetters(alphabet.letters);
const alphabet_letters_compressed align(4) = compress.rlCompress(@ptrCast(&_alphabet_letters), @sizeOf(@TypeOf(_alphabet_letters)));
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, size: ?usize) noreturn {
    @setCold(true);
    if (builtin.mode == .ReleaseSmall or builtin.mode == .ReleaseFast) {
        while (true) {}
    }

    gba.reg_dispcnt.* = .{
        .video_mode = 0,
        .display_bg0 = true,
    };
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
    const PanicWriter = struct {
        iy: u32 = 0,
        ix: u32 = 0,

        const Writer = std.io.Writer(
            *@This(),
            error{EndOfBuffer},
            appendWrite,
        );

        fn appendWrite(
            self: *@This(),
            data: []const u8,
        ) error{EndOfBuffer}!usize {
            const i = self.iy * gba.screen_width + self.ix;
            if (i + data.len > gba.screen_width * gba.screen_height / 64) {
                return error.EndOfBuffer;
            }
            for (data) |d| {
                gba.bg_map[2][self.iy * 32 + self.ix] = d;
                self.ix += 1;
                if (self.ix >= gba.screen_width / 8) {
                    self.ix = 0;
                    self.iy += 1;
                }
            }
            return data.len;
        }

        fn writer(self: *@This()) @This().Writer {
            return .{ .context = self };
        }
    };
    var pw = PanicWriter{};
    _ = pw.writer().print("PANIC: {s}\\", .{msg}) catch unreachable;

    var it = std.debug.StackIterator.init(@returnAddress(), null);
    while (it.next()) |return_address| {
        _ = pw.writer().print("T: {x}\\", .{return_address}) catch unreachable;
    }
    _ = error_return_trace;
    _ = size;
    while (true) {}
}

const Tile = struct {
    number: u4 = 0,
    obj_i: u7 = 0,
};

var last_input: gba.Keys = .{};
var just_pressed: gba.Keys = undefined;
var just_released: gba.Keys = undefined;

var rng = std.rand.DefaultPrng.init(0);
var rand = rng.random();

var used_objects: [128]bool = [1]bool{false} ** 128;

fn updateTiles(tiles: [16]?Tile) void {
    for (0..128) |i| {
        gba.objs[i].set(gba.OBJ{
            .hidden = true,
        });
    }
    for (tiles, 0..) |maybe_tile, i| {
        if (maybe_tile) |tile| {
            const x: u9 = @intCast(32 * @mod(i, 4));
            const y: u8 = @intCast(32 * @divFloor(i, 4));
            gba.objs[tile.obj_i].set(gba.OBJ{
                .x = x,
                .y = y,
                .tile_number = @as(u10, tile.number) * 16,
                .size = .size32,
            });
        }
    }
}

fn moveTile(tiles: *[16]?Tile, x: usize, y: usize, first_x: usize, first_y: usize) void {
    if (first_x == x and first_y == y) {
        return;
    }
    if (tiles[first_y * 4 + first_x] == null) {
        tiles[first_y * 4 + first_x] = tiles[y * 4 + x];
    } else {
        tiles[first_y * 4 + first_x].?.number += 1;
        used_objects[tiles[y * 4 + x].?.obj_i] = false;
    }
    tiles[y * 4 + x] = null;
}

const AddTileError = error{
    NoSpaceAvailable,
};

fn addTile(tiles: *[16]?Tile) AddTileError!void {
    const pos = blk: while (true) {
        const pos = rand.int(u4);
        if (tiles[pos] != null) {
            continue;
        }
        break :blk pos;
    };
    const first_free_obj = blk: for (0..128) |i| {
        if (!used_objects[i]) {
            used_objects[i] = true;
            break :blk i;
        }
    } else return error.NoSpaceAvailable;
    tiles[pos] = Tile{
        .obj_i = @intCast(first_free_obj),
        .number = if (rand.int(u2) == 0) 1 else 0,
    };
}

fn handleLeft(tiles: *[16]?Tile, just_moved_to: *[16]bool) bool {
    var moved = false;
    for (1..4) |x| {
        for (0..4) |y| {
            const tile = tiles[y * 4 + x];
            if (tile == null) {
                continue;
            }
            var ix: i5 = @intCast(x - 1);
            var first: u4 = @intCast(x);
            while (ix >= 0) : (ix -= 1) {
                const nix: u4 = @intCast(ix);
                if (tiles[y * 4 + nix]) |i_tile| {
                    if (i_tile.number == tile.?.number and !just_moved_to[y * 4 + nix]) {
                        just_moved_to[y * 4 + nix] = true;
                        first = nix;
                        break;
                    } else {
                        first = nix + 1;
                        break;
                    }
                }
            } else {
                first = 0;
            }
            if (first != x) {
                moved = true;
                moveTile(tiles, x, y, first, y);
            }
        }
    }
    return moved;
}

fn handleRight(tiles: *[16]?Tile, just_moved_to: *[16]bool) bool {
    var moved = false;
    for (1..4) |x_inv| {
        const x = 3 - x_inv;
        for (0..4) |y| {
            const tile = tiles[y * 4 + x];
            if (tile == null) {
                continue;
            }
            var ix: i5 = @intCast(x + 1);
            var first: u4 = @intCast(x);
            while (ix < 4) : (ix += 1) {
                const nix: u4 = @intCast(ix);
                if (tiles[y * 4 + nix]) |i_tile| {
                    if (i_tile.number == tile.?.number and !just_moved_to[y * 4 + nix]) {
                        just_moved_to[y * 4 + nix] = true;
                        first = nix;
                        break;
                    } else {
                        first = nix - 1;
                        break;
                    }
                }
            } else {
                first = 3;
            }
            if (first != x) {
                moved = true;
                moveTile(tiles, x, y, first, y);
            }
        }
    }
    return moved;
}

fn handleUp(tiles: *[16]?Tile, just_moved_to: *[16]bool) bool {
    var moved = false;
    for (1..4) |y| {
        for (0..4) |x| {
            const tile = tiles[y * 4 + x];
            if (tile == null) {
                continue;
            }
            var iy: i5 = @intCast(y - 1);
            var first: u4 = @intCast(y);
            while (iy >= 0) : (iy -= 1) {
                const niy: u4 = @intCast(iy);
                if (tiles[niy * 4 + x]) |i_tile| {
                    if (i_tile.number == tile.?.number and !just_moved_to[niy * 4 + x]) {
                        just_moved_to[niy * 4 + x] = true;
                        first = niy;
                        break;
                    } else {
                        first = niy + 1;
                        break;
                    }
                }
            } else {
                first = 0;
            }
            if (first != y) {
                moved = true;
                moveTile(tiles, x, y, x, first);
            }
        }
    }
    return moved;
}

fn handleDown(tiles: *[16]?Tile, just_moved_to: *[16]bool) bool {
    var moved = false;
    for (1..4) |y_inv| {
        const y = 3 - y_inv;
        for (0..4) |x| {
            const tile = tiles[y * 4 + x];
            if (tile == null) {
                continue;
            }
            var iy: i5 = @intCast(y + 1);
            var first: u4 = @intCast(y);
            while (iy < 4) : (iy += 1) {
                const niy: u4 = @intCast(iy);
                if (tiles[niy * 4 + x]) |i_tile| {
                    if (i_tile.number == tile.?.number and !just_moved_to[niy * 4 + x]) {
                        just_moved_to[niy * 4 + x] = true;
                        first = niy;
                        break;
                    } else {
                        first = niy - 1;
                        break;
                    }
                }
            } else {
                first = 3;
            }
            if (first != y) {
                moved = true;
                moveTile(tiles, x, y, x, first);
            }
        }
    }
    return moved;
}

const tiles_palette_compressed align(4) = compress.rlCompress(@ptrCast(&tiles_img.palette), @sizeOf(@TypeOf(tiles_img.palette)));
const tiles_tiles_compressed align(4) = compress.rlCompress(@ptrCast(&tiles_img.tiles), @sizeOf(@TypeOf(tiles_img.tiles)));

const bg_palette_compressed align(4) = compress.rlCompress(@ptrCast(&bg_img.palette), @sizeOf(@TypeOf(bg_img.palette)));
const bg_tiles_compressed align(4) = compress.rlCompress(@ptrCast(&bg_img.tiles), @sizeOf(@TypeOf(bg_img.tiles)));

export fn main() noreturn {
    bios.rlUncompReadNormalWrite16Bit(&tiles_palette_compressed, @ptrCast(&gba.obj_palettes[0]));
    bios.rlUncompReadNormalWrite16Bit(&tiles_tiles_compressed, @ptrCast(&gba.obj_tiles[0]));
    bios.rlUncompReadNormalWrite16Bit(&bg_palette_compressed, @ptrCast(&gba.bg_palettes[0]));
    bios.rlUncompReadNormalWrite16Bit(&bg_tiles_compressed, @ptrCast(&gba.bg_tiles[0]));
    gba.reg_dispcnt.* = .{
        .display_obj = true,
        .display_bg0 = true,
        .character1d = true,
    };
    gba.reg_bg0cnt.* = .{
        .tile_data = 0,
        .map_data = 1,
    };
    var tiles = [1]?Tile{null} ** 16;
    addTile(&tiles) catch unreachable;
    updateTiles(tiles);
    while (true) {
        gba.hBlankWait();
        const input = gba.reg_keyinput.*;
        just_pressed = input.justPressed(last_input);
        just_released = input.justReleased(last_input);
        last_input = input;
        var just_moved_to = [1]bool{false} ** 16;
        const moved = if (!just_pressed.left)
            handleLeft(&tiles, &just_moved_to)
        else if (!just_pressed.right)
            handleRight(&tiles, &just_moved_to)
        else if (!just_pressed.up)
            handleUp(&tiles, &just_moved_to)
        else if (!just_pressed.down)
            handleDown(&tiles, &just_moved_to)
        else
            false;
        if (moved) {
            addTile(&tiles) catch unreachable;
            updateTiles(tiles);
        }
        if (!just_pressed.start) {
            // Reset
            for (0..16) |i| {
                if (tiles[i]) |tile| {
                    used_objects[tile.obj_i] = false;
                    tiles[i] = null;
                }
            }
            addTile(&tiles) catch unreachable;
            updateTiles(tiles);
        }
    }
}
