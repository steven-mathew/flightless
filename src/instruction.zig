const std = @import("std");

/// List of all CPU official operations.
///
/// # References
///
/// - [6502 Opcodes](http://wiki.nesdev.com/w/index.php/6502_instructions)
pub const Operation = enum(u8) {
    // zig fmt: off
    ADC, AND, ASL, BCC, BCS, BEQ, BIT, BMI, BNE, BPL, BRK, BVC, BVS, CLC, CLD,
    CLI, CLV, CMP, CPX, CPY, DEC, DEX, DEY, EOR, INC, INX, INY, JMP, JSR, LDA,
    LDX, LDY, LSR, NOP, ORA, PHA, PHP, PLA, PLP, ROL, ROR, RTI, RTS, SBC, SEC,
    SED, SEI, STA, STX, STY, TAX, TAY, TSX, TXA, TXS, TYA,

    SKB, IGN, ISB, DCP, AXS, LAS, LAX, AHX, SAX, XAA, SXA, RRA, TAS, SYA, ARR,
    SRE, ALR, RLA, ANC, SLO,

    XXX,
    // zig fmt: on
};

/// CPU Addressing mode
pub const AddrMode = enum(u8) {
    // zig fmt: off
    IMM,
    ZP0, ZPX, ZPY,
    ABS, ABX, ABY,
    IND, IDX, IDY,
    REL, ACC, IMP,
    XXX
    // zig fmt: on
};

/// (Addressing Mode, Operation, cycles taken)
pub const Instruction = struct { AddrMode, Operation, usize };
pub const XXXInstruction: Instruction = .{ .XXX, .XXX, 0 };

fn makeLookupTable() [256]Instruction {
    comptime {
        var t: [256]Instruction = .{XXXInstruction} ** 256;

        // zig fmt: off
        t[0x00] = .{ .IMP, .BRK, 7 }; t[0x01] = .{ .IDX, .ORA, 6 }; t[0x02] = .{ .IMP, .XXX, 2 }; t[0x03] = .{ .IDX, .SLO, 8 };
        t[0x04] = .{ .ZP0, .NOP, 3 }; t[0x05] = .{ .ZP0, .ORA, 3 }; t[0x06] = .{ .ZP0, .ASL, 5 }; t[0x07] = .{ .ZP0, .SLO, 5 };
        t[0x08] = .{ .IMP, .PHP, 3 }; t[0x09] = .{ .IMM, .ORA, 2 }; t[0x0A] = .{ .ACC, .ASL, 2 }; t[0x0B] = .{ .IMM, .ANC, 2 };
        t[0x0C] = .{ .ABS, .NOP, 4 }; t[0x0D] = .{ .ABS, .ORA, 4 }; t[0x0E] = .{ .ABS, .ASL, 6 }; t[0x0F] = .{ .ABS, .SLO, 6 };

        t[0x10] = .{ .REL, .BPL, 2 }; t[0x11] = .{ .IDY, .ORA, 5 }; t[0x12] = .{ .IMP, .XXX, 2 }; t[0x13] = .{ .IDY, .SLO, 8 };
        t[0x14] = .{ .ZPX, .NOP, 4 }; t[0x15] = .{ .ZPX, .ORA, 4 }; t[0x16] = .{ .ZPX, .ASL, 6 }; t[0x17] = .{ .ZPX, .SLO, 6 };
        t[0x18] = .{ .IMP, .CLC, 2 }; t[0x19] = .{ .ABY, .ORA, 4 }; t[0x1A] = .{ .IMP, .NOP, 2 }; t[0x1B] = .{ .ABY, .SLO, 7 };
        t[0x1C] = .{ .ABX, .IGN, 4 }; t[0x1D] = .{ .ABX, .ORA, 4 }; t[0x1E] = .{ .ABX, .ASL, 7 }; t[0x1F] = .{ .ABX, .SLO, 7 };

        t[0x20] = .{ .ABS, .JSR, 6 }; t[0x21] = .{ .IDX, .AND, 6 }; t[0x22] = .{ .IMP, .XXX, 2 }; t[0x23] = .{ .IDX, .RLA, 8 };
        t[0x24] = .{ .ZP0, .BIT, 3 }; t[0x25] = .{ .ZP0, .AND, 3 }; t[0x26] = .{ .ZP0, .ROL, 5 }; t[0x27] = .{ .ZP0, .RLA, 5 };
        t[0x28] = .{ .IMP, .PLP, 4 }; t[0x29] = .{ .IMM, .AND, 2 }; t[0x2A] = .{ .ACC, .ROL, 2 }; t[0x2B] = .{ .IMM, .ANC, 2 };
        t[0x2C] = .{ .ABS, .BIT, 4 }; t[0x2D] = .{ .ABS, .AND, 4 }; t[0x2E] = .{ .ABS, .ROL, 6 }; t[0x2F] = .{ .ABS, .RLA, 6 };

        t[0x30] = .{ .REL, .BMI, 2 }; t[0x31] = .{ .IDY, .AND, 5 }; t[0x32] = .{ .IMP, .XXX, 2 }; t[0x33] = .{ .IDY, .RLA, 8 };
        t[0x34] = .{ .ZPX, .NOP, 4 }; t[0x35] = .{ .ZPX, .AND, 4 }; t[0x36] = .{ .ZPX, .ROL, 6 }; t[0x37] = .{ .ZPX, .RLA, 6 };
        t[0x38] = .{ .IMP, .SEC, 2 }; t[0x39] = .{ .ABY, .AND, 4 }; t[0x3A] = .{ .IMP, .NOP, 2 }; t[0x3B] = .{ .ABY, .RLA, 7 };
        t[0x3C] = .{ .ABX, .IGN, 4 }; t[0x3D] = .{ .ABX, .AND, 4 }; t[0x3E] = .{ .ABX, .ROL, 7 }; t[0x3F] = .{ .ABX, .RLA, 7 };

        t[0x40] = .{ .IMP, .RTI, 6 }; t[0x41] = .{ .IDX, .EOR, 6 }; t[0x42] = .{ .IMP, .XXX, 2 }; t[0x43] = .{ .IDX, .SRE, 8 };
        t[0x44] = .{ .ZP0, .NOP, 3 }; t[0x45] = .{ .ZP0, .EOR, 3 }; t[0x46] = .{ .ZP0, .LSR, 5 }; t[0x47] = .{ .ZP0, .SRE, 5 };
        t[0x48] = .{ .IMP, .PHA, 3 }; t[0x49] = .{ .IMM, .EOR, 2 }; t[0x4A] = .{ .ACC, .LSR, 2 }; t[0x4B] = .{ .IMM, .ALR, 2 };
        t[0x4C] = .{ .ABS, .JMP, 3 }; t[0x4D] = .{ .ABS, .EOR, 4 }; t[0x4E] = .{ .ABS, .LSR, 6 }; t[0x4F] = .{ .ABS, .SRE, 6 };

        t[0x50] = .{ .REL, .BVC, 2 }; t[0x51] = .{ .IDY, .EOR, 5 }; t[0x52] = .{ .IMP, .XXX, 2 }; t[0x53] = .{ .IDY, .SRE, 8 };
        t[0x54] = .{ .ZPX, .NOP, 4 }; t[0x55] = .{ .ZPX, .EOR, 4 }; t[0x56] = .{ .ZPX, .LSR, 6 }; t[0x57] = .{ .ZPX, .SRE, 6 };
        t[0x58] = .{ .IMP, .CLI, 2 }; t[0x59] = .{ .ABY, .EOR, 4 }; t[0x5A] = .{ .IMP, .NOP, 2 }; t[0x5B] = .{ .ABY, .SRE, 7 };
        t[0x5C] = .{ .ABX, .IGN, 4 }; t[0x5D] = .{ .ABX, .EOR, 4 }; t[0x5E] = .{ .ABX, .LSR, 7 }; t[0x5F] = .{ .ABX, .SRE, 7 };

        t[0x60] = .{ .IMP, .RTS, 6 }; t[0x61] = .{ .IDX, .ADC, 6 }; t[0x62] = .{ .IMP, .XXX, 2 }; t[0x63] = .{ .IDX, .RRA, 8 };
        t[0x64] = .{ .ZP0, .NOP, 3 }; t[0x65] = .{ .ZP0, .ADC, 3 }; t[0x66] = .{ .ZP0, .ROR, 5 }; t[0x67] = .{ .ZP0, .RRA, 5 };
        t[0x68] = .{ .IMP, .PLA, 4 }; t[0x69] = .{ .IMM, .ADC, 2 }; t[0x6A] = .{ .ACC, .ROR, 2 }; t[0x6B] = .{ .IMM, .ARR, 2 };
        t[0x6C] = .{ .IND, .JMP, 5 }; t[0x6D] = .{ .ABS, .ADC, 4 }; t[0x6E] = .{ .ABS, .ROR, 6 }; t[0x6F] = .{ .ABS, .RRA, 6 };

        t[0x70] = .{ .REL, .BVS, 2 }; t[0x71] = .{ .IDY, .ADC, 5 }; t[0x72] = .{ .IMP, .XXX, 2 }; t[0x73] = .{ .IDY, .RRA, 8 };
        t[0x74] = .{ .ZPX, .NOP, 4 }; t[0x75] = .{ .ZPX, .ADC, 4 }; t[0x76] = .{ .ZPX, .ROR, 6 }; t[0x77] = .{ .ZPX, .RRA, 6 };
        t[0x78] = .{ .IMP, .SEI, 2 }; t[0x79] = .{ .ABY, .ADC, 4 }; t[0x7A] = .{ .IMP, .NOP, 2 }; t[0x7B] = .{ .ABY, .RRA, 7 };
        t[0x7C] = .{ .ABX, .IGN, 4 }; t[0x7D] = .{ .ABX, .ADC, 4 }; t[0x7E] = .{ .ABX, .ROR, 7 }; t[0x7F] = .{ .ABX, .RRA, 7 };

        t[0x80] = .{ .IMM, .SKB, 2 }; t[0x81] = .{ .IDX, .STA, 6 }; t[0x82] = .{ .IMM, .SKB, 2 }; t[0x83] = .{ .IDX, .SAX, 6 };
        t[0x84] = .{ .ZP0, .STY, 3 }; t[0x85] = .{ .ZP0, .STA, 3 }; t[0x86] = .{ .ZP0, .STX, 3 }; t[0x87] = .{ .ZP0, .SAX, 3 };
        t[0x88] = .{ .IMP, .DEY, 2 }; t[0x89] = .{ .IMM, .SKB, 2 }; t[0x8A] = .{ .IMP, .TXA, 2 }; t[0x8B] = .{ .IMM, .XAA, 2 };
        t[0x8C] = .{ .ABS, .STY, 4 }; t[0x8D] = .{ .ABS, .STA, 4 }; t[0x8E] = .{ .ABS, .STX, 4 }; t[0x8F] = .{ .ABS, .SAX, 4 };

        t[0x90] = .{ .REL, .BCC, 2 }; t[0x91] = .{ .IDY, .STA, 6 }; t[0x92] = .{ .IMP, .XXX, 2 }; t[0x93] = .{ .IDY, .AHX, 6 };
        t[0x94] = .{ .ZPX, .STY, 4 }; t[0x95] = .{ .ZPX, .STA, 4 }; t[0x96] = .{ .ZPY, .STX, 4 }; t[0x97] = .{ .ZPY, .SAX, 4 };
        t[0x98] = .{ .IMP, .TYA, 2 }; t[0x99] = .{ .ABY, .STA, 5 }; t[0x9A] = .{ .IMP, .TXS, 2 }; t[0x9B] = .{ .ABY, .TAS, 5 };
        t[0x9C] = .{ .ABX, .SYA, 5 }; t[0x9D] = .{ .ABX, .STA, 5 }; t[0x9E] = .{ .ABY, .SXA, 5 }; t[0x9F] = .{ .ABY, .AHX, 5 };

        t[0xA0] = .{ .IMM, .LDY, 2 }; t[0xA1] = .{ .IDX, .LDA, 6 }; t[0xA2] = .{ .IMM, .LDX, 2 }; t[0xA3] = .{ .IDX, .LAX, 6 };
        t[0xA4] = .{ .ZP0, .LDY, 3 }; t[0xA5] = .{ .ZP0, .LDA, 3 }; t[0xA6] = .{ .ZP0, .LDX, 3 }; t[0xA7] = .{ .ZP0, .LAX, 3 };
        t[0xA8] = .{ .IMP, .TAY, 2 }; t[0xA9] = .{ .IMM, .LDA, 2 }; t[0xAA] = .{ .IMP, .TAX, 2 }; t[0xAB] = .{ .IMM, .LAX, 2 };
        t[0xAC] = .{ .ABS, .LDY, 4 }; t[0xAD] = .{ .ABS, .LDA, 4 }; t[0xAE] = .{ .ABS, .LDX, 4 }; t[0xAF] = .{ .ABS, .LAX, 4 };

        t[0xB0] = .{ .REL, .BCS, 2 }; t[0xB1] = .{ .IDY, .LDA, 5 }; t[0xB2] = .{ .IMP, .XXX, 2 }; t[0xB3] = .{ .IDY, .LAX, 5 };
        t[0xB4] = .{ .ZPX, .LDY, 4 }; t[0xB5] = .{ .ZPX, .LDA, 4 }; t[0xB6] = .{ .ZPY, .LDX, 4 }; t[0xB7] = .{ .ZPY, .LAX, 4 };
        t[0xB8] = .{ .IMP, .CLV, 2 }; t[0xB9] = .{ .ABY, .LDA, 4 }; t[0xBA] = .{ .IMP, .TSX, 2 }; t[0xBB] = .{ .ABY, .LAS, 4 };
        t[0xBC] = .{ .ABX, .LDY, 4 }; t[0xBD] = .{ .ABX, .LDA, 4 }; t[0xBE] = .{ .ABY, .LDX, 4 }; t[0xBF] = .{ .ABY, .LAX, 4 };

        t[0xC0] = .{ .IMM, .CPY, 2 }; t[0xC1] = .{ .IDX, .CMP, 6 }; t[0xC2] = .{ .IMM, .SKB, 2 }; t[0xC3] = .{ .IDX, .DCP, 8 };
        t[0xC4] = .{ .ZP0, .CPY, 3 }; t[0xC5] = .{ .ZP0, .CMP, 3 }; t[0xC6] = .{ .ZP0, .DEC, 5 }; t[0xC7] = .{ .ZP0, .DCP, 5 };
        t[0xC8] = .{ .IMP, .INY, 2 }; t[0xC9] = .{ .IMM, .CMP, 2 }; t[0xCA] = .{ .IMP, .DEX, 2 }; t[0xCB] = .{ .IMM, .AXS, 2 };
        t[0xCC] = .{ .ABS, .CPY, 4 }; t[0xCD] = .{ .ABS, .CMP, 4 }; t[0xCE] = .{ .ABS, .DEC, 6 }; t[0xCF] = .{ .ABS, .DCP, 6 };

        t[0xD0] = .{ .REL, .BNE, 2 }; t[0xD1] = .{ .IDY, .CMP, 5 }; t[0xD2] = .{ .IMP, .XXX, 2 }; t[0xD3] = .{ .IDY, .DCP, 8 };
        t[0xD4] = .{ .ZPX, .NOP, 4 }; t[0xD5] = .{ .ZPX, .CMP, 4 }; t[0xD6] = .{ .ZPX, .DEC, 6 }; t[0xD7] = .{ .ZPX, .DCP, 6 };
        t[0xD8] = .{ .IMP, .CLD, 2 }; t[0xD9] = .{ .ABY, .CMP, 4 }; t[0xDA] = .{ .IMP, .NOP, 2 }; t[0xDB] = .{ .ABY, .DCP, 7 };
        t[0xDC] = .{ .ABX, .IGN, 4 }; t[0xDD] = .{ .ABX, .CMP, 4 }; t[0xDE] = .{ .ABX, .DEC, 7 }; t[0xDF] = .{ .ABX, .DCP, 7 };

        t[0xE0] = .{ .IMM, .CPX, 2 }; t[0xE1] = .{ .IDX, .SBC, 6 }; t[0xE2] = .{ .IMM, .SKB, 2 }; t[0xE3] = .{ .IDX, .ISB, 8 };
        t[0xE4] = .{ .ZP0, .CPX, 3 }; t[0xE5] = .{ .ZP0, .SBC, 3 }; t[0xE6] = .{ .ZP0, .INC, 5 }; t[0xE7] = .{ .ZP0, .ISB, 5 };
        t[0xE8] = .{ .IMP, .INX, 2 }; t[0xE9] = .{ .IMM, .SBC, 2 }; t[0xEA] = .{ .IMP, .NOP, 2 }; t[0xEB] = .{ .IMM, .SBC, 2 };
        t[0xEC] = .{ .ABS, .CPX, 4 }; t[0xED] = .{ .ABS, .SBC, 4 }; t[0xEE] = .{ .ABS, .INC, 6 }; t[0xEF] = .{ .ABS, .ISB, 6 };

        t[0xF0] = .{ .REL, .BEQ, 2 }; t[0xF1] = .{ .IDY, .SBC, 5 }; t[0xF2] = .{ .IMP, .XXX, 2 }; t[0xF3] = .{ .IDY, .ISB, 8 };
        t[0xF4] = .{ .ZPX, .NOP, 4 }; t[0xF5] = .{ .ZPX, .SBC, 4 }; t[0xF6] = .{ .ZPX, .INC, 6 }; t[0xF7] = .{ .ZPX, .ISB, 6 };
        t[0xF8] = .{ .IMP, .SED, 2 }; t[0xF9] = .{ .ABY, .SBC, 4 }; t[0xFA] = .{ .IMP, .NOP, 2 }; t[0xFB] = .{ .ABY, .ISB, 7 };
        t[0xFC] = .{ .ABX, .IGN, 4 }; t[0xFD] = .{ .ABX, .SBC, 4 }; t[0xFE] = .{ .ABX, .INC, 7 }; t[0xFF] = .{ .ABX, .ISB, 7 };
        // zig fmt: on

        return t;
    }
}

const lookup_table = makeLookupTable();

/// Decodes an instruction from its opcode
pub inline fn decodeInstruction(opcode: u8) *const Instruction {
    return &lookup_table[opcode];
}

comptime {
    std.debug.assert(lookup_table.len == 256);
    std.debug.assert(lookup_table[0xA9][0] == AddrMode.IMM);
}

const T = std.testing;
test "instruction lookup table" {
    const lda_imm = lookup_table[0xA9];
    try T.expectEqual(AddrMode.IMM, lda_imm[0]);
    try T.expectEqual(Operation.LDA, lda_imm[1]);
    try T.expectEqual(@as(u8, 2), lda_imm[2]);
}
