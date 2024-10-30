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

const x_offset = gba.screen_width / 2 - 32 * 2;
const y_offset = gba.screen_height / 2 - 32 * 2;

var rng = std.rand.DefaultPrng.init(0);
var rand = rng.random();

var last_input: gba.Keys = .{};

fn indexToCoordinates(index: usize) struct { x: usize, y: usize } {
    return .{
        .x = index % 4,
        .y = index / 4,
    };
}

const animation_speed = 6;
fn animateTiles(work_tiles: *const [16]?tile.WorkTile) void {
    const AnimateTile = struct {
        i: usize,
        value: usize,
        x: isize,
        y: isize,
        speed_x: isize,
        speed_y: isize,
    };
    var animate_tiles: [16]?AnimateTile = [1]?AnimateTile{null} ** 16;
    var obj_i: usize = 0;
    for (work_tiles, 0..) |work_tile_maybe, i| {
        if (work_tile_maybe) |work_tile| {
            const from_coords = indexToCoordinates(work_tile.from);
            const to_coords = indexToCoordinates(i);
            const from_x: isize = @intCast(from_coords.x * 32 + x_offset);
            const from_y: isize = @intCast(from_coords.y * 32 + y_offset);
            const to_x: isize = @intCast(to_coords.x * 32 + x_offset);
            const to_y: isize = @intCast(to_coords.y * 32 + y_offset);

            const x_speed = @divFloor(to_x - from_x, animation_speed);
            const y_speed = @divFloor(to_y - from_y, animation_speed);

            animate_tiles[i] = .{
                .i = obj_i,
                .value = work_tile.value,
                .x = from_x,
                .y = from_y,
                .speed_x = x_speed,
                .speed_y = y_speed,
            };
            obj_i += 1;
        }
    }

    for (obj_i..128) |i| {
        gba.objs[i].set(gba.OBJ{
            .hidden = true,
        });
    }
    for (0..animation_speed) |_| {
        gba.hBlankWait();
        for (&animate_tiles) |*animate_tile_maybe| {
            if (animate_tile_maybe.*) |*animate_tile| {
                gba.objs[animate_tile.i].set(gba.OBJ{
                    .x = @intCast(animate_tile.x),
                    .y = @intCast(animate_tile.y),
                    .size = .size32,
                    .tile_number = @intCast(animate_tile.value * 16),
                });
                animate_tile.x += animate_tile.speed_x;
                animate_tile.y += animate_tile.speed_y;
            }
        }
    }
}

fn renderTiles(tiles: [16]?u32) void {
    var idx: usize = 0;
    for (tiles, 0..) |t, i| {
        if (t) |til| {
            const coords = indexToCoordinates(i);
            gba.objs[idx].set(gba.OBJ{
                .size = .size32,
                .tile_number = @intCast(til * 16),
                .x = @intCast(coords.x * 32 + x_offset),
                .y = @intCast(coords.y * 32 + y_offset),
            });
            idx += 1;
        }
    }
    for (idx..128) |i| {
        gba.objs[i].set(gba.OBJ{
            .hidden = true,
        });
    }
}

fn tilesFromWorkTiles(work_tiles: *const [16]?tile.WorkTile) [16]?u32 {
    var ret: [16]?u32 = undefined;
    for (work_tiles, 0..) |work_tile_maybe, i| {
        ret[i] = if (work_tile_maybe) |work_tile| work_tile.value else null;
    }
    return ret;
}

fn setupBackground() void {
    gba.reg_bg0cnt.* = .{
        .tile_data = 0,
        .map_data = 1,
        .screen_size = .size256x256,
    };
    const base_idx = 7 + 32 * 2;
    for (0..4) |y| {
        for (0..4) |x| {
            gba.bg_map[1][base_idx + 0 + 4 * x + 32 * 4 * y].tile_number = 1;
            gba.bg_map[1][base_idx + 1 + 4 * x + 32 * 4 * y].tile_number = 2;
            gba.bg_map[1][base_idx + 2 + 4 * x + 32 * 4 * y].tile_number = 2;
            gba.bg_map[1][base_idx + 3 + 4 * x + 32 * 4 * y].tile_number = 1;
            gba.bg_map[1][base_idx + 3 + 4 * x + 32 * 4 * y].hflip = true;

            gba.bg_map[1][base_idx + 32 + 4 * x + 32 * 4 * y].tile_number = 3;
            gba.bg_map[1][base_idx + 33 + 4 * x + 32 * 4 * y].tile_number = 4;
            gba.bg_map[1][base_idx + 34 + 4 * x + 32 * 4 * y].tile_number = 4;
            gba.bg_map[1][base_idx + 35 + 4 * x + 32 * 4 * y].tile_number = 3;
            gba.bg_map[1][base_idx + 35 + 4 * x + 32 * 4 * y].hflip = true;

            gba.bg_map[1][base_idx + 64 + 4 * x + 32 * 4 * y].tile_number = 3;
            gba.bg_map[1][base_idx + 65 + 4 * x + 32 * 4 * y].tile_number = 4;
            gba.bg_map[1][base_idx + 66 + 4 * x + 32 * 4 * y].tile_number = 4;
            gba.bg_map[1][base_idx + 67 + 4 * x + 32 * 4 * y].tile_number = 3;
            gba.bg_map[1][base_idx + 67 + 4 * x + 32 * 4 * y].hflip = true;

            gba.bg_map[1][base_idx + 96 + 4 * x + 32 * 4 * y].tile_number = 1;
            gba.bg_map[1][base_idx + 96 + 4 * x + 32 * 4 * y].vflip = true;
            gba.bg_map[1][base_idx + 97 + 4 * x + 32 * 4 * y].tile_number = 2;
            gba.bg_map[1][base_idx + 97 + 4 * x + 32 * 4 * y].vflip = true;
            gba.bg_map[1][base_idx + 98 + 4 * x + 32 * 4 * y].tile_number = 2;
            gba.bg_map[1][base_idx + 98 + 4 * x + 32 * 4 * y].vflip = true;
            gba.bg_map[1][base_idx + 99 + 4 * x + 32 * 4 * y].tile_number = 1;
            gba.bg_map[1][base_idx + 99 + 4 * x + 32 * 4 * y].vflip = true;
            gba.bg_map[1][base_idx + 99 + 4 * x + 32 * 4 * y].hflip = true;
        }
    }
}

export fn main() noreturn {
    gba.copyPalette(tiles_img.palette, &gba.obj_palettes[0]);
    gba.copyTiles(tiles_img.tiles[0..], gba.obj_tiles[0..]);

    gba.copyPalette(bg_img.palette, &gba.bg_palettes[0]);
    gba.copyTiles(bg_img.tiles[0..], gba.bg_tiles[0..]);
    gba.reg_dispcnt.* = .{
        .character1d = true,
        .display_obj = true,
        .display_bg0 = true,
    };
    setupBackground();

    var tiles: [16]?u32 = [1]?u32{null} ** 16;
    tile.addTile(&tiles, rand);
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
            const res = if (!just_pressed.right)
                tile.slideRight(&tiles)
            else if (!just_pressed.left)
                tile.slideLeft(&tiles)
            else if (!just_pressed.down)
                tile.slideDown(&tiles)
            else if (!just_pressed.up)
                tile.slideUp(&tiles)
            else
                null;
            if (res) |v| {
                // Movement
                if (v[0]) {
                    animateTiles(&v[1]);
                    tiles = tilesFromWorkTiles(&v[1]);
                    tile.addTile(&tiles, rand);
                    renderTiles(tiles);
                }
            }
        }
    }
}
