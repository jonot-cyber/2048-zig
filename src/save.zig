const std = @import("std");

const gba = @import("gba.zig");

const sram_ptr: [*]volatile u8 = @ptrFromInt(0x0e000000);
pub const sram: *volatile [0x7fff]u8 = sram_ptr[0..0x7fff];

fn memcpy1(dst: []u8, src: []const u8) void {
    std.debug.assert(dst.len == src.len);
    for (0..dst.len) |i| {
        asm volatile (
            \\ldrb r4, [r1, r3]
            \\strb r4, [r0, r3]
            :
            : [src] "{r1}" (src.ptr),
              [dst] "{r0}" (dst.ptr),
              [i] "{r3}" (i),
            : "r4"
        );
    }
}

pub fn init() void {
    gba.reg_waitcnt.sram_wait_control = .cycle_8;
}

pub fn getScore() ?u32 {
    var buf: [8]u8 = undefined;
    memcpy1(&buf, @volatileCast(sram[0..8]));

    // Check for existing save data
    if (!std.mem.eql(u8, buf[0..4], "2048")) {
        return null;
    }

    return std.mem.readInt(u32, buf[4..8], .big);
}

pub fn setScore(score: u32) void {
    var buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &buf, score, .big);
    memcpy1(@volatileCast(sram[0..4]), "2048");
    memcpy1(@volatileCast(sram[4..8]), &buf);
}
