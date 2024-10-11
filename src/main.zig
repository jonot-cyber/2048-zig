const std = @import("std");
const builtin = @import("builtin");
pub const gba = @import("gba.zig");
const alphabet = @import("alphabet.zig");

const test_img = @import("test");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, size: ?usize) noreturn {
    @setCold(true);
    if (builtin.mode == .ReleaseSmall) {
        while (true) {}
    }

    gba.reg_dispcnt.* = .{
        .video_mode = 0,
        .display_bg0 = true,
    };
    gba.copyPalette(.{
        .{},
        .{ .r = 31, .g = 31, .b = 31 },
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
    }, &gba.bg_palettes[0]);
    var ascii_tiles: [128]gba.Tile = undefined;
    for (alphabet.letters, 0..) |l, i| {
        ascii_tiles[i] = alphabet.letterToTile(l);
    }
    gba.copyTiles(ascii_tiles[0..], gba.bg_tiles[0..]);
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

export fn main() noreturn {
    gba.copyPalette(test_img.palette, &gba.obj_palettes[0]);
    gba.copyTiles(&test_img.tiles, gba.obj_tiles[0..]);
    while (true) {}
}
