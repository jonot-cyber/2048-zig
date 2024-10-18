//! This module contains functions for compressing data. Decompression functions might be found in bios.zig

/// Get the size of data after being compressed with Run-Length encoding
fn rlCompressSize(comptime data: [*]const u8, comptime size: usize) comptime_int {
    // Allows the function to compress
    @setEvalBranchQuota(size * 20);

    // The size returned
    var ret = 0;

    // The size of the current "block"
    // This is either a span of 3 or more repeated bytes
    // Or 1 or more non-repeated bytes
    // Each of which needs a header
    var block_size = 0;

    // The current index into data
    var i: usize = 0;
    while (i < size) {
        // Look for a block of three identical bytes
        if (i + 2 < size and data[i] == data[i + 1] and data[i] == data[i + 2]) {
            // If there is a current uncompressed block, we need to add the size so it doesn't get lost.
            if (block_size > 0)
                ret += block_size + 1;

            // Figure out how long the block lasts by iterating until it is a different byte
            const start_char = data[i];
            var j = i + 3;
            while (j < size and data[j] == start_char) : (j += 1) {}
            block_size = j - i;
            // This is the maximum size of a compressed block
            block_size = @min(block_size, 130);

            // A compressed block is 2 bytes of output.
            ret += 2;
            i += block_size;
            block_size = 0;
        } else {
            // If the uncompressed block hits the maximum size, add the size now and start a new block
            if (block_size == 128) {
                ret += block_size + 1;
                block_size = 0;
            }
            // Add to the block
            block_size += 1;
            i += 1;
        }
    }
    // If we have an in-progress uncompressed block, add it now
    if (block_size != 0)
        ret += block_size + 1;
    // On the GBA, the length of compressed data for RLE needs to be a multiple of 4. This pads it out
    if (ret % 4 != 0) ret += 4 - ret % 4;
    return ret;
}

/// Creates run-length encoding compressed data, in the way that the Game Boy Advance expects.
pub fn rlCompress(comptime data: [*]const u8, comptime size: usize) [rlCompressSize(data, size) + 4]u8 {
    // Create a header for the start of the data.
    const RlHeader = packed struct {
        _reserved: u4 = 0,
        compressed_type: u4 = 3,
        size: u24,
    };
    var ret: [rlCompressSize(data, size) + 4]u8 = undefined;
    const header: RlHeader = .{
        .size = size,
    };
    const src: [*]const u8 = @ptrCast(&header);
    @memcpy(ret[0..4], src);

    // Make sure there is enough room for the function to compile;
    @setEvalBranchQuota(ret.len * 20);

    var i = 0; // Index into data
    var block_size = 0; // The size of the current block
    var block_start = 0; // The index of the start of the current block
    var j = 4; // Index into ret
    while (i < size) {
        // Check for a block
        if (i + 2 < size and data[i] == data[i + 1] and data[i] == data[i + 2]) {
            // If there is an existing uncompressed block, we need to add it in.
            if (block_size > 0) {
                // Add a header and the data
                ret[j] = block_size - 1;
                @memcpy(ret[j + 1 .. j + 1 + block_size], data[block_start .. block_start + block_size]);
                j += block_size + 1;
            }
            // Figure out how long the span is
            const start_char = data[i];
            var k = i + 3;
            while (k < size and data[k] == start_char) : (k += 1) {}
            block_size = k - i;
            block_size = @min(k - i, 130);

            // Construct the header and the data
            ret[j] = 0x80 | (block_size - 3);
            ret[j + 1] = start_char;
            j += 2;
            i += block_size;
            block_start = i;
            block_size = 0;
        } else {
            // If the block is full, send it now
            if (block_size == 128) {
                ret[j] = block_size - 1;
                @memcpy(ret[j + 1 .. j + 1 + block_size], data[block_start .. block_start + block_size]);
                j += block_size + 1;
                block_start = i;
                block_size = 0;
            }
            block_size += 1;
            i += 1;
        }
    }

    // If we have a block left over, add it.
    if (block_size != 0) {
        ret[j] = block_size - 1;
        @memcpy(ret[j + 1 .. j + block_size + 1], data[block_start..block_size]);
    }

    return ret;
}

/// Information passed to bios.bitUnPack
pub const BitUnPackInfo = packed struct {
    /// How long the source data is
    source_length: u16,
    /// How big a unit is in the source data
    source_unit_width: u8,
    /// How big a unit is in the destination data
    destination_unit_width: u8,
    /// How much to offset each unit
    data_offset: u31,
    /// Whether to offset units that equal zero
    zero_data: bool,
};
