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
