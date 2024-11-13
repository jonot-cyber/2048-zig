const compress = @import("compress.zig");
const std = @import("std");

/// Decompresses RLE compressed data into general memory
/// See https://problemkaputt.de/gbatek.htm#biosdecompressionfunctions for information
pub fn rlUncompReadNormalWrite8Bit(source: [*]align(4) const u8, destination: [*]u8) void {
    return asm volatile ("swi #0x14"
        :
        : [source] "{r0}" (source),
          [destination] "{r1}" (destination),
        : "r0", "r1", "r3"
    );
}

/// Decompresses RLE compressed data into video memory
/// See https://problemkaputt.de/gbatek.htm#biosdecompressionfunctions for information
pub fn rlUncompReadNormalWrite16Bit(source: [*]align(4) const u8, destination: [*]u8) void {
    return asm volatile ("swi #0x15"
        :
        : [source] "{r0}" (source),
          [destination] "{r1}" (destination),
        : "r0", "r1", "r3"
    );
}

/// Unpack bitmap data.
pub fn bitUnpack(source: [*]const u8, destination: [*]align(4) u8, info: *const compress.BitUnPackInfo) void {
    const unpacked_data_size_bits = info.source_length * info.destination_unit_width / info.source_unit_width;
    // Source data must be a multiple of 4 bytes
    std.debug.assert(unpacked_data_size_bits % 32 == 0);

    // Make sure the data is valid
    std.debug.assert(info.source_unit_width >= 1 and info.source_unit_width <= 8 and std.math.isPowerOfTwo(info.source_unit_width));
    std.debug.assert(info.destination_unit_width >= 1 and info.destination_unit_width <= 32 and std.math.isPowerOfTwo(info.destination_unit_width));

    return asm volatile ("swi #0x10"
        :
        : [source] "{r0}" (source),
          [destination] "{r1}" (destination),
          [info] "{r2}" (info),
        : "r0", "r1", "r2", "r3"
    );
}

pub fn cpuSet(source: []align(2) const u8, destination: [*]align(2) const u8) void {
    const Mode = packed struct {
        half_word_count: u21,
        _unused: u3 = 0,
        fill: bool,
        full_word: bool,
        _unused2: u6 = 0,
    };
    const mode: Mode = .{
        .half_word_count = @intCast(source.len / 2),
        .fill = false,
        .full_word = false,
    };
    return asm volatile ("swi #0x0b"
        :
        : [source] "{r0}" (source.ptr),
          [destination] "{r1}" (destination),
          [mode] "{r2}" (mode),
        : "r0", "r1", "r2", "r3"
    );
}
