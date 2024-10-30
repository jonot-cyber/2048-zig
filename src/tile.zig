const std = @import("std");

const Tiles = [16]?u32;

pub fn addTile(tiles: *[16]?u32, rand: std.rand.Random) void {
    const free_idx = blk: while (true) {
        const idx = rand.uintLessThan(usize, tiles.len);
        if (tiles[idx] == null)
            break :blk idx;
    };
    tiles[free_idx] = if (rand.int(u2) == 0) 1 else 0;
}

pub const WorkTile = struct {
    value: u32,
    merged: bool,
    from: usize,
};

fn slideUnit(tile: u32, row: []const ?WorkTile) usize {
    for (row, 0..) |r, i| {
        if (r) |r2| {
            if (!r2.merged and r2.value == tile) {
                return i;
            } else {
                return i - 1;
            }
        }
    }
    return row.len - 1;
}

fn slide(row: *const [4]?u32, from: [4]usize) [4]?WorkTile {
    var out: [4]?WorkTile = [1]?WorkTile{null} ** 3 ++ [1]?WorkTile{undefined};
    if (row[3]) |r| {
        out[3] = .{
            .value = r,
            .merged = false,
            .from = from[3],
        };
    }
    for ([_]usize{ 2, 1, 0 }) |i| {
        if (row[i]) |r| {
            const v = slideUnit(r, out[i..]);
            const merged = if (out[i + v]) |o|
                o.value == r
            else
                false;
            const q = if (merged) r + 1 else r;
            out[i + v] = .{
                .value = q,
                .merged = merged,
                .from = from[i],
            };
        }
    }
    return out;
}

pub fn slideRight(tiles: [16]?u32) [16]?WorkTile {
    const wt1 = slide(tiles[0..4], .{ 0, 1, 2, 3 });
    const wt2 = slide(tiles[4..8], .{ 4, 5, 6, 7 });
    const wt3 = slide(tiles[8..12], .{ 8, 9, 10, 11 });
    const wt4 = slide(tiles[12..16], .{ 12, 13, 14, 15 });
    var out: [16]?WorkTile = undefined;
    @memcpy(out[0..4], &wt1);
    @memcpy(out[4..8], &wt2);
    @memcpy(out[8..12], &wt3);
    @memcpy(out[12..16], &wt4);
    return out;
}

pub fn slideLeft(tiles: [16]?u32) [16]?WorkTile {
    var tiles_copy = tiles;
    std.mem.reverse(?u32, tiles_copy[0..4]);
    var wt1 = slide(tiles_copy[0..4], .{ 3, 2, 1, 0 });
    std.mem.reverse(?u32, tiles_copy[4..8]);
    var wt2 = slide(tiles_copy[4..8], .{ 7, 6, 5, 4 });
    std.mem.reverse(?u32, tiles_copy[8..12]);
    var wt3 = slide(tiles_copy[8..12], .{ 11, 10, 9, 8 });
    std.mem.reverse(?u32, tiles_copy[12..16]);
    var wt4 = slide(tiles_copy[12..16], .{ 15, 14, 13, 12 });
    var out: [16]?WorkTile = undefined;
    std.mem.reverse(?WorkTile, &wt1);
    @memcpy(out[0..4], &wt1);
    std.mem.reverse(?WorkTile, &wt2);
    @memcpy(out[4..8], &wt2);
    std.mem.reverse(?WorkTile, &wt3);
    @memcpy(out[8..12], &wt3);
    std.mem.reverse(?WorkTile, &wt4);
    @memcpy(out[12..16], &wt4);
    return out;
}

pub fn slideDown(tiles: [16]?u32) [16]?WorkTile {
    const col1: [4]?u32 = .{ tiles[0], tiles[4], tiles[8], tiles[12] };
    const col2: [4]?u32 = .{ tiles[1], tiles[5], tiles[9], tiles[13] };
    const col3: [4]?u32 = .{ tiles[2], tiles[6], tiles[10], tiles[14] };
    const col4: [4]?u32 = .{ tiles[3], tiles[7], tiles[11], tiles[15] };

    const wt1 = slide(&col1, .{ 0, 4, 8, 12 });
    const wt2 = slide(&col2, .{ 1, 5, 9, 13 });
    const wt3 = slide(&col3, .{ 2, 6, 10, 14 });
    const wt4 = slide(&col4, .{ 3, 7, 11, 15 });

    var out: [16]?WorkTile = undefined;
    out[0] = wt1[0];
    out[4] = wt1[1];
    out[8] = wt1[2];
    out[12] = wt1[3];
    out[1] = wt2[0];
    out[5] = wt2[1];
    out[9] = wt2[2];
    out[13] = wt2[3];
    out[2] = wt3[0];
    out[6] = wt3[1];
    out[10] = wt3[2];
    out[14] = wt3[3];
    out[3] = wt4[0];
    out[7] = wt4[1];
    out[11] = wt4[2];
    out[15] = wt4[3];
    return out;
}

pub fn slideUp(tiles: [16]?u32) [16]?WorkTile {
    const col1: [4]?u32 = .{ tiles[12], tiles[8], tiles[4], tiles[0] };
    const col2: [4]?u32 = .{ tiles[13], tiles[9], tiles[5], tiles[1] };
    const col3: [4]?u32 = .{ tiles[14], tiles[10], tiles[6], tiles[2] };
    const col4: [4]?u32 = .{ tiles[15], tiles[11], tiles[7], tiles[3] };

    const wt1 = slide(&col1, .{ 12, 8, 4, 0 });
    const wt2 = slide(&col2, .{ 13, 9, 5, 1 });
    const wt3 = slide(&col3, .{ 14, 10, 6, 2 });
    const wt4 = slide(&col4, .{ 15, 11, 7, 3 });

    var out: [16]?WorkTile = undefined;
    out[12] = wt1[0];
    out[8] = wt1[1];
    out[4] = wt1[2];
    out[0] = wt1[3];
    out[13] = wt2[0];
    out[9] = wt2[1];
    out[5] = wt2[2];
    out[1] = wt2[3];
    out[14] = wt3[0];
    out[10] = wt3[1];
    out[6] = wt3[2];
    out[2] = wt3[3];
    out[15] = wt4[0];
    out[11] = wt4[1];
    out[7] = wt4[2];
    out[3] = wt4[3];
    return out;
}
