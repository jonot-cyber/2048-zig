const bios = @import("bios.zig");
const std = @import("std");

/// Controls the display settings
pub const reg_dispcnt: *volatile DispCnt = @ptrFromInt(0x04000000);
/// Controls for the zeroth background
pub const reg_bg0cnt: *volatile BgCnt = @ptrFromInt(0x04000008);
/// Controls for the first background
pub const reg_bg1cnt: *volatile BgCnt = @ptrFromInt(0x0400000a);
/// Controls for the second background
pub const reg_bg2cnt: *volatile BgCnt = @ptrFromInt(0x0400000c);
/// Controls for the third background
pub const reg_bg3cnt: *volatile BgCnt = @ptrFromInt(0x0400000e);
/// What vertical line is being drawn
pub const reg_vcount: *volatile u16 = @ptrFromInt(0x04000006);
/// The key inputs (pressed=false)
pub const reg_keyinput: *volatile Keys = @ptrFromInt(0x04000130);
/// Controls special effects
pub const reg_bldcnt: *volatile BldCnt = @ptrFromInt(0x04000050);
/// Controls alpha blending
pub const reg_bldalpha: *volatile BldAlpha = @ptrFromInt(0x04000052);
/// Controls access to the game pak
pub const reg_waitcnt: *volatile WaitCnt = @ptrFromInt(0x04000204);

// DMA
pub const reg_dma0sad: *volatile *const u8 = @ptrFromInt(0x040000b0);
pub const reg_dma1sad: *volatile *const u8 = @ptrFromInt(0x040000bc);
pub const reg_dma2sad: *volatile *const u8 = @ptrFromInt(0x040000c8);
pub const reg_dma3sad: *volatile *const u8 = @ptrFromInt(0x040000d4);

pub const reg_dma0dad: *volatile *u8 = @ptrFromInt(0x040000b4);
pub const reg_dma1dad: *volatile *u8 = @ptrFromInt(0x040000c0);
pub const reg_dma2dad: *volatile *u8 = @ptrFromInt(0x040000cc);
pub const reg_dma3dad: *volatile *u8 = @ptrFromInt(0x040000d8);

// Word count
pub const reg_dma0cnt_l: *volatile usize = @ptrFromInt(0x040000b8);
pub const reg_dma1cnt_l: *volatile usize = @ptrFromInt(0x040000c4);
pub const reg_dma2cnt_l: *volatile usize = @ptrFromInt(0x040000d0);
pub const reg_dma3cnt_l: *volatile usize = @ptrFromInt(0x040000dc);

pub const reg_dma0cnt_h: *volatile DmaCnt = @ptrFromInt(0x040000ba);
pub const reg_dma1cnt_h: *volatile DmaCnt = @ptrFromInt(0x040000c6);
pub const reg_dma2cnt_h: *volatile DmaCnt = @ptrFromInt(0x040000d2);
pub const reg_dma3cnt_h: *volatile DmaCnt = @ptrFromInt(0x040000de);

const DestAddrControl = enum(u2) {
    increment = 0,
    decrement = 1,
    fixed = 2,
    increment_reload = 3,
};

const SourceAddrControl = enum(u2) {
    increment = 0,
    decrement = 1,
    fixed = 2,
    prohibited = 3,
};

const DmaStartTiming = enum(u2) {
    immediate = 0,
    v_blank = 1,
    h_blank = 2,
    special = 3,
};

const WaitCntCycles = enum(u2) {
    cycle_4 = 0,
    cycle_3 = 1,
    cycle_2 = 2,
    cycle_8 = 3,
};

const WaitCntCycles2 = enum(u1) {
    cycle_2 = 0,
    cycle_1 = 1,
};

const WaitCntCycles3 = enum(u1) {
    cycle_4 = 0,
    cycle_1 = 1,
};

const WaitCntCycles4 = enum(u1) {
    cycle_8 = 0,
    cycle_1 = 1,
};

const PhiTerminalOutput = enum(u2) {
    disable = 0,
    mhz_4_19 = 1,
    mhz_8_38 = 2,
    mhz_16_78 = 3,
};

pub const WaitCnt = packed struct {
    sram_wait_control: WaitCntCycles,
    wait_state_0_first_access: WaitCntCycles,
    wait_state_0_second_access: WaitCntCycles2,
    wait_state_1_first_access: WaitCntCycles,
    wait_state_1_second_access: WaitCntCycles3,
    wait_state_2_first_access: WaitCntCycles,
    wait_state_2_second_access: WaitCntCycles4,
    phi_terminal_output: PhiTerminalOutput,
    _unused: u1 = 0,
    prefetch_buffer: bool,
    game_boy: bool = false,
};

pub const DmaCnt = packed struct {
    _unused: u5 = 0,
    dest_addr_control: DestAddrControl,
    source_addr_control: SourceAddrControl,
    repeat: bool,
    transfer_32bit: bool,
    game_pak_drq: bool,
    dma_start_timing: DmaStartTiming,
    irq: bool,
    enable: bool,
};

const SpecialEffect = enum(u2) {
    none = 0,
    alpha = 1,
    brightness_increase = 2,
    brightness_decrease = 3,
};

pub const BldCnt = packed struct {
    first_bg0: bool = false,
    first_bg1: bool = false,
    first_bg2: bool = false,
    first_bg3: bool = false,
    first_obj: bool = false,
    first_bd: bool = false,
    special_effect: SpecialEffect,
    second_bg0: bool = false,
    second_bg1: bool = false,
    second_bg2: bool = false,
    second_bg3: bool = false,
    second_obj: bool = false,
    second_bd: bool = false,
    _: u2 = 0,
};

pub const BldAlpha = packed struct {
    first_coefficient: u5 = 0,
    _: u3 = 0,
    second_coefficient: u5 = 0,
    _2: u3 = 0,
};

/// A 15-bit color value in a GBA format
pub const Color = packed struct {
    r: u5 = 0,
    g: u5 = 0,
    b: u5 = 0,
    _: u1 = 0,
};

/// A palette
pub const Palette = [16]Color;

/// A tile
pub const Tile = [8]u32;

/// A tile in the screen block
pub const ScreenBlockTile = packed struct {
    /// The tile number
    tile_number: u10 = 0,
    /// Horizontal flip
    hflip: bool = false,
    /// Vertical flip
    vflip: bool = false,
    /// Palette number. Unused in 256 color mode.
    palette: u4 = 0,
};

/// A screen-block
pub const ScreenBlock = [1024]ScreenBlockTile;

/// The mode of an object
const ObjMode = enum(u2) {
    normal = 0,
    semi_transparent = 1,
    window = 2,
    prohibited = 3,
};

/// The shape of the sprite
const ObjShape = enum(u2) {
    square = 0,
    horizontal = 1,
    vertical = 2,
    prohibited = 3,
};

/// The size of a sprite
const ObjSize = enum(u2) {
    size8 = 0,
    size16 = 1,
    size32 = 2,
    size64 = 3,
};

/// How the color palette should work
const ColorMode = enum(u1) {
    color16 = 0,
    color256 = 1,
};

/// Sprite data, in memory.
/// Seperate because 8 bit sized data transfers don't work to VRAM
pub const OBJ = packed struct {
    y: u8 = 0,
    rot_scale: bool = false,
    hidden: bool = false,
    mode: ObjMode = .normal,
    mosaic: bool = false,
    color_mode: ColorMode = .color16,
    shape: ObjShape = .square,

    x: u9 = 0,
    _unused: u3 = undefined,
    h_flip: bool = false,
    v_flip: bool = false,
    size: ObjSize = .size8,

    tile_number: u10 = 0,
    priority: u2 = 0,
    palette_number: u4 = 0,
    _empty: u16 = undefined,
};

/// The VRAM structure of a sprite.
pub const VramOBJ = packed struct {
    attr0: u16,
    attr1: u16,
    attr2: u16,
    _empty: u16,

    /// Sets a VRAM sprite to an in memory sprite
    pub noinline fn set(self: *VramOBJ, obj: OBJ) void {
        const tmp: VramOBJ = @bitCast(obj);
        self.attr0 = tmp.attr0;
        self.attr1 = tmp.attr1;
        self.attr2 = tmp.attr2;
    }

    /// Hides a sprite without needing a transfer
    pub fn hide(self: *VramOBJ) void {
        self.attr0 &= ~@as(u16, 0x0200);
    }
};

/// The palettes in the background
pub const bg_palettes: [*]Palette = @ptrFromInt(0x05000000);

/// The palettes in the object
pub const obj_palettes: [*]Palette = @ptrFromInt(0x05000200);

/// The tiles of the background
pub const bg_tiles: [*]Tile = @ptrFromInt(0x06000000);

/// BG Color in a bitmap mode
pub const bg_colors: [*]Color = @ptrFromInt(0x06000000);

/// The tiles of sprites
pub const obj_tiles: [*]Tile = @ptrFromInt(0x06010000);

/// A map for a background. Overlaps with the tiles, watch out
pub const bg_map: [*]ScreenBlock = @ptrFromInt(0x06000000);

/// Where the sprites are in memory. 128 total
pub const objs: [*]VramOBJ = @ptrFromInt(0x07000000);

/// The height of a gba screen
pub const screen_height = 160;

/// The width of a gba screen
pub const screen_width = 240;

/// Copy a palette from memory to VRAM.
pub fn copyPalette(src: Palette, dst: *Palette) void {
    for (src, 0..) |c, i| {
        dst[i] = c;
    }
}

/// Copy tiles from memory to VRAM.
pub fn copyTiles(src: []const Tile, dst: [*]Tile) void {
    const source = std.mem.sliceAsBytes(src);
    bios.cpuSet(source, @ptrCast(dst));
}

/// Set the screen size of a background
const BgScreenSize = enum(u2) {
    size256x256 = 0,
    size512x256 = 1,
    size256x512 = 2,
    size512x512 = 3,
};

/// Background control structure
pub const BgCnt = packed struct {
    priority: u2 = 0,
    tile_data: u2 = 0,
    _reserved: u2 = 0,
    mosaic: bool = false,
    color_mode: ColorMode = .color16,
    map_data: u5 = 0,
    overflow: bool = false,
    screen_size: BgScreenSize = .size256x256,
};

/// Display control structure
pub const DispCnt = packed struct {
    video_mode: u3 = 0,
    _reserved: bool = false,
    frame: u1 = 0,
    hblank_interval_free: bool = false,
    character1d: bool = false,
    forced_blank: bool = false,
    display_bg0: bool = false,
    display_bg1: bool = false,
    display_bg2: bool = false,
    display_bg3: bool = false,
    display_obj: bool = false,
    window0: bool = false,
    window1: bool = false,
    obj_window: bool = false,
};

/// Wait for a frame to be displayed
pub fn hBlankWait() void {
    while (reg_vcount.* >= 160) {}
    while (reg_vcount.* < 160) {}
}

/// A key structure. false=pressed
pub const Keys = packed struct {
    a: bool = true,
    b: bool = true,
    select: bool = true,
    start: bool = true,
    right: bool = true,
    left: bool = true,
    up: bool = true,
    down: bool = true,
    r: bool = true,
    l: bool = true,
    _: u6 = undefined,

    /// Gives you the just pressed keys
    pub fn justPressed(self: *const Keys, last: Keys) Keys {
        const self_as_uint: u16 = @bitCast(self.*);
        const last_as_uint: u16 = @bitCast(last);

        const res = ~(self_as_uint ^ last_as_uint) | self_as_uint;
        return @bitCast(res);
    }

    /// Gives you the just released keys
    pub fn justReleased(self: *const Keys, last: Keys) Keys {
        const self_as_uint: u16 = @bitCast(self.*);
        const last_as_uint: u16 = @bitCast(last);

        const res = ~((self_as_uint ^ last_as_uint) & self_as_uint);
        return @bitCast(res);
    }
};
