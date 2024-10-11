// SPDX-License-Identifier: CC0-1.0
//
// SPDX-FileContributor: Antonio Niño Díaz, 2022

    .section    .gba_crt0, "ax"
    .global     entrypoint
    .global _start
    .cpu        arm7tdmi
    .extern main

    .arm

_start:
entrypoint:
    b       header_end

    .fill   156, 1, 0   // Nintendo Logo
    .fill   12, 1, 0    // Game Title
    .fill   4, 1, 0     // Game Code
    .byte   0x30, 0x30  // Maker Code ("00")
    .byte   0x96        // Fixed Value (must be 0x96)
    .byte   0x00        // Main unit code
    .byte   0x00        // Device Type
    .fill   7, 1, 0     // Reserved Area
    .byte   0x00        // Software version
    .byte   0x00        // Complement check (header checksum)
    .byte   0x00, 0x00  // Reserved Area

header_end:
    b       start_vector

    // Multiboot Header Entries
    .byte   0           // Boot mode
    .byte   0           // Slave ID Number
    .fill   26, 1, 0    // Not used
    .word   0           // JOYBUS entrypoint

    .align

start_vector:

    // Disable interrupts
    mov     r0, #0x4000000
    mov     r1, #0
    str     r1, [r0, #0x208] // IME

    // Setup IRQ mode stack
    mov     r0, #0x12
    msr     cpsr, r0
    ldr     sp, =__STACK_IRQ_END__

    // Setup system mode stack
    mov     r0, #0x1F
    msr     cpsr, r0
    ldr     sp, =__STACK_USR_END__
    // Clear IWRAM
    mov     r0, #0x3000000
    mov     r1, #(32 * 1024)
    bl      mem_zero

    // Copy data section from ROM to RAM
    ldr     r0, =__DATA_LMA__
    ldr     r1, =__DATA_START__
    ldr     r2, =__DATA_SIZE__
    bl      mem_copy

    // Copy IWRAM data from ROM to RAM
    ldr     r0, =__IWRAM_LMA__
    ldr     r1, =__IWRAM_START__
    ldr     r2, =__IWRAM_SIZE__
    bl      mem_copy

    // Clear EWRAM
    mov     r0, #0x2000000
    mov     r1, #(256 * 1024)
    bl      mem_zero

    // Copy EWRAM data from ROM to RAM
    ldr     r0, =__EWRAM_LMA__
    ldr     r1, =__EWRAM_START__
    ldr     r2, =__EWRAM_SIZE__
    bl      mem_copy

    // Call main()
    ldr     r0, =main
    bx r0

    // If main() returns, reboot the GBA using SoftReset
    swi     #0x00

// r0 = Base address
// r1 = Size
mem_zero:
    mov r3, #0
    bic r1, r1, #3
    add r1, r0, r1
.mem_zero1:
    cmp r0, r1
    bxeq lr
    str r3, [r0], #4
    b .mem_zero1

// r0 = Source address
// r1 = Destination address
// r2 = Size
mem_copy:
    bic r2, r2, #3
    sub r1, r1, #4
    add r2, r0, r2
.mem_copy1:
    cmp r0, r2
    bxeq lr
    ldr r3, [r0], #4
    str r3, [r1, #4]!
    b .mem_copy1
//mem_copy:
//    add r2, r0, r2
//.mem_copy1:
//    cmp r0, r2
//    bxeq lr
//    ldrb r3, [r0], #1
//    strb r3, [r1], #1
//    b .mem_copy1
