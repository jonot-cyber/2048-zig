const std = @import("std");

const Tiles = [16]?u32;

/// Convert a tile number to it's value
pub fn tileToValue(tile: u32) !u32 {
    return std.math.powi(u32, 2, tile + 1);
}

/// Convert a value to a tile number
pub fn valueToTile(value: u32) !u32 {
    return std.math.log2_int(u32, value) - 1;
}

pub fn addTile(tiles: *[16]?u32, rand: std.rand.Random) void {
    const free_idx = blk: while (true) {
        const idx = rand.uintLessThan(usize, tiles.len);
        if (tiles[idx] == null)
            break :blk idx;
    };
    const four_tile = try valueToTile(4);
    const two_tile = try valueToTile(2);
    tiles[free_idx] = if (rand.int(u2) == 0) four_tile else two_tile;
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

fn slide(row: *const [4]?u32, from: *const [4]usize) struct { bool, [4]?WorkTile } {
    var moved = false;
    var out: [4]?WorkTile = .{ null, null, null, null };
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
            if (v != 0) moved = true;
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
    return .{ moved, out };
}

pub fn slideDir(tiles: *const [16]?u32, indexes: *const [16]usize) struct { bool, [16]?WorkTile } {
    var moved = false;
    var a: [16]?u32 = undefined;
    for (0..16) |i| {
        a[i] = tiles[indexes[i]];
    }

    var work_tiles: [4][4]?WorkTile = undefined;
    var res = slide(a[0..4], indexes[0..4]);
    if (res[0]) moved = true;
    work_tiles[0] = res[1];
    res = slide(a[4..8], indexes[4..8]);
    if (res[0]) moved = true;
    work_tiles[1] = res[1];
    res = slide(a[8..12], indexes[8..12]);
    if (res[0]) moved = true;
    work_tiles[2] = res[1];
    res = slide(a[12..16], indexes[12..16]);
    if (res[0]) moved = true;
    work_tiles[3] = res[1];

    var out: [16]?WorkTile = undefined;
    for (0..4) |b| {
        for (0..4) |c| {
            out[indexes[b * 4 + c]] = work_tiles[b][c];
        }
    }
    return .{ moved, out };
}

pub fn slideRight(tiles: *const [16]?u32) struct { bool, [16]?WorkTile } {
    return slideDir(tiles, &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 });
}

pub fn slideLeft(tiles: *const [16]?u32) struct { bool, [16]?WorkTile } {
    return slideDir(tiles, &.{ 3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12 });
}

pub fn slideDown(tiles: *const [16]?u32) struct { bool, [16]?WorkTile } {
    return slideDir(tiles, &.{ 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15 });
}

pub fn slideUp(tiles: *const [16]?u32) struct { bool, [16]?WorkTile } {
    return slideDir(tiles, &.{ 12, 8, 4, 0, 13, 9, 5, 1, 14, 10, 6, 2, 15, 11, 7, 3 });
}

/// Returns if the board is full, and no moves can be made
pub fn detectLoss(tiles: *const [16]?u32) bool {
    // If there are any empty spaces, return false.
    for (tiles) |tile| {
        if (tile == null) {
            return false;
        }
    }
    for (0..4) |iy| {
        for (0..4) |ix| {
            const idx = iy * 4 + ix;
            // Check to the right
            if (ix != 3) {
                if (tiles[idx] == tiles[idx + 1]) {
                    return false;
                }
            }

            // Check below
            if (iy != 3) {
                if (tiles[idx] == tiles[idx + 4]) {
                    return false;
                }
            }
        }
    }
    return true;
}

/// Detect if a game has been won
pub fn detectWin(tiles: *const [16]?u32) !bool {
    const winning_tile = try valueToTile(2048);
    for (tiles) |maybe_tile| {
        if (maybe_tile) |tile| {
            if (tile == winning_tile)
                return true;
        }
    }
    return false;
}
