pub fn rlUncompReadNormalWrite16Bit(source: [*]const u8, destination: [*]u8) void {
    return asm volatile ("swi #0x15"
        :
        : [source] "{r0}" (source),
          [destination] "{r1}" (destination),
        : "r0", "r1", "r3"
    );
}
