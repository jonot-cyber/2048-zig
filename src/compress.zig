fn rlCompressSize(comptime data: [*]const u8, comptime size: usize) comptime_int {
    @setEvalBranchQuota(size * 20);
    var ret = 0;
    var block_size = 0;
    var i: usize = 0;
    while (i < size) {
        // Look for a block of three
        if (i + 2 < size and data[i] == data[i + 1] and data[i] == data[i + 2]) {
            // Deal with the last block
            if (block_size > 0)
                ret += block_size + 1;
            // Figure out how long the block lasts
            const start_char = data[i];
            var j = i + 3;
            while (j < size and data[j] == start_char) : (j += 1) {}
            block_size = j - i;
            block_size = @min(block_size, 130);
            ret += 2;
            i += block_size;
            block_size = 0;
        } else {
            if (block_size == 128) {
                ret += block_size + 1;
                block_size = 0;
            }
            // No block of three
            block_size += 1;
            i += 1;
        }
    }
    if (block_size != 0)
        ret += block_size + 1;
    while (ret % 4 != 0) : (ret += 1) {}
    return ret;
}

pub fn rlCompress(comptime data: [*]const u8, comptime size: usize) [rlCompressSize(data, size) + 4]u8 {
    const RlHeader = packed struct {
        _reserved: u4 = 0,
        compressed_type: u4 = 3,
        size: u24,
    };
    var ret: [rlCompressSize(data, size) + 4]u8 = undefined;
    @setEvalBranchQuota(ret.len * 20);
    const header: RlHeader = .{
        .size = size,
    };
    const src: [*]const u8 = @ptrCast(&header);
    @memcpy(ret[0..4], src);

    var i = 0;
    var block_size = 0;
    var block_start = 0;
    var j = 4;
    while (i < size) {
        if (i + 2 < size and data[i] == data[i + 1] and data[i] == data[i + 2]) {
            if (block_size > 0) {
                ret[j] = block_size - 1;
                for (0..block_size) |k| {
                    ret[j + k + 1] = data[block_start + k];
                }
                j += block_size + 1;
            }
            const start_char = data[i];
            var k = i + 3;
            while (k < size and data[k] == start_char) : (k += 1) {}
            block_size = k - i;
            block_size = @min(k - i, 130);
            ret[j] = 0x80 | (block_size - 3);
            ret[j + 1] = start_char;
            j += 2;
            i += block_size;
            block_start = i;
            block_size = 0;
        } else {
            if (block_size == 128) {
                ret[j] = block_size - 1;
                for (0..block_size) |k| {
                    ret[j + k + 1] = data[block_start + k];
                }
                j += block_size + 1;
                block_start = i;
                block_size = 0;
            }
            block_size += 1;
            i += 1;
        }
    }

    if (block_size != 0) {
        ret[j] = block_size - 1;
        for (0..block_size) |k| {
            ret[j + k + 1] = data[block_start + k];
        }
    }

    return ret;
}
