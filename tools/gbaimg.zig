const std = @import("std");

const zigimg = @import("zigimg");

const GBAColor = packed struct {
    r: u5 = 0,
    g: u5 = 0,
    b: u5 = 0,
    _: u1 = 0,
};

const Color = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
};

const Tile = [8]u32;

fn isColorTransparent(color: zigimg.color.Rgba32) bool {
    return color.r == 255 and color.g == 0 and color.b == 255;
}

fn colorToGBA(color: zigimg.color.Rgba32) GBAColor {
    const r = std.math.mulWide(u8, color.r, 31) / 255;
    const g = std.math.mulWide(u8, color.g, 31) / 255;
    const b = std.math.mulWide(u8, color.b, 31) / 255;
    return .{ .r = @intCast(r), .g = @intCast(g), .b = @intCast(b) };
}

fn paletteFind(palette: []GBAColor, color: GBAColor) ?usize {
    for (palette[1..], 1..) |p, i| {
        if (p.r == color.r and p.g == color.g and p.b == color.b) {
            return i;
        }
    } else {
        return null;
    }
}

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.c_allocator);

    if (args.len != 4) {
        std.debug.print("wrong number of arguments.\n", .{});
        std.process.exit(1);
    }

    const path = args[1];
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var stream_source = std.io.StreamSource{
        .file = file,
    };
    var img = try zigimg.formats.png.PNG.readImage(std.heap.c_allocator, &stream_source);
    defer img.deinit(std.heap.c_allocator);
    if (@mod(img.height, 8) != 0 or @mod(img.width, 8) != 0) {
        std.debug.print("Image dimensions aren't valid.\n", .{});
        std.process.exit(1);
    }

    try img.convert(std.heap.c_allocator, .rgba32);

    var palette: [16]GBAColor = undefined;
    palette[0] = .{
        .r = 0,
        .g = 0,
        .b = 0,
    };
    var i: usize = 1;
    for (img.pixels.rgba32) |c| {
        if (isColorTransparent(c)) {
            continue;
        }
        const gba_pixel = colorToGBA(c);
        if (paletteFind(palette[0 .. i + 1], gba_pixel) == null) {
            palette[i] = gba_pixel;
            i += 1;
        }
    }
    while (i < 16) : (i += 1) {
        palette[i] = .{
            .r = 0,
            .g = 0,
            .b = 0,
        };
    }

    const sprite_size = try std.fmt.parseInt(u8, args[3], 10);
    if (sprite_size != 8 and sprite_size != 16 and sprite_size != 32 and sprite_size != 64) {
        std.debug.print("Invalid sprite_size", .{});
        std.process.exit(1);
    }

    var tiles = std.ArrayList(Tile).init(std.heap.c_allocator);
    defer tiles.deinit();
    for (0..img.height / sprite_size) |iy_sprite| {
        for (0..img.width / sprite_size) |ix_sprite| {
            for (0..sprite_size / 8) |iy_tile| {
                for (0..sprite_size / 8) |ix_tile| {
                    var tmp: Tile = undefined;
                    for (0..8) |iy_pixel| {
                        var row: u32 = 0;
                        for (0..8) |ix_pixel| {
                            const y = iy_sprite * sprite_size + iy_tile * 8 + iy_pixel;
                            const x = ix_sprite * sprite_size + ix_tile * 8 + (7 - ix_pixel);
                            const idx = y * img.width + x;
                            const color = img.pixels.rgba32[idx];
                            const palette_idx = blk: {
                                if (isColorTransparent(color)) {
                                    break :blk 0;
                                }
                                const gba_color = colorToGBA(color);
                                break :blk paletteFind(&palette, gba_color) orelse 0;
                            };
                            row <<= 4;
                            row += @intCast(palette_idx);
                        }
                        tmp[iy_pixel] = row;
                    }
                    try tiles.append(tmp);
                }
            }
        }
    }

    var output_file = try std.fs.cwd().createFile(args[2], .{});
    defer output_file.close();

    try output_file.writeAll(
        \\const gba = @import("root").gba;
        \\
        \\pub const palette = gba.Palette{
        \\
    );
    for (palette) |p| {
        try output_file.writer().print("    .{{.r = {d}, .g = {d}, .b = {d}}},\n", .{ p.r, p.g, p.b });
    }
    try output_file.writeAll(
        \\};
        \\
        \\pub const tiles = [_]gba.Tile{
        \\
    );
    for (tiles.items) |tile| {
        try output_file.writer().print("    gba.Tile{{{d},{d},{d},{d},{d},{d},{d},{d}}},\n", .{
            tile[0],
            tile[1],
            tile[2],
            tile[3],
            tile[4],
            tile[5],
            tile[6],
            tile[7],
        });
    }
    try output_file.writeAll("};");
}
