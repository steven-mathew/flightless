//! Memory

const std = @import("std");
const rand = std.rand;
const mem = std.mem;
const math = std.math;
const fmt = std.fmt;
const testing = std.testing;

pub const Memory = struct {
    data: std.ArrayList(u8),

    /// Create a new, empty `Memory` instance.
    pub fn init(allocator: *std.mem.Allocator) Memory {
        const data = std.ArrayList.init(u8, allocator);
        return Memory{ .data = data };
    }

    /// Create a new `Memory` instance of a given size, zeroed out.
    pub fn withSize(allocator: *std.mem.Allocator, size: usize) !Memory {
        const data = std.ArrayList(u8).initCapacity(allocator, size);
        return Memory{ .data = data };
    }

    /// Create a new `Memory` instance of a given size based on `RamState`, zeroed out.
    pub fn ram(allocator: *std.mem.Allocator, state: RamState, size: usize) !Memory {
        var memory = try Memory.withSize(allocator, size);
        memory.fillRam(state);
        return memory;
    }

    /// Fills `Memory` based on `RamState`.
    pub fn fillRam(self: *Memory, state: RamState) void {
        switch (state) {
            RamState.AllZeros => mem.set(u8, self.data, 0x00),
            RamState.AllOnes => mem.set(u8, self.data, 0xFF),
            RamState.Random => {
                var rng = rand.DefaultPrng.init(@intCast(std.time.timestamp()));
                for (self.data) |*val| {
                    val.* = rng.random.intRangeLessThan(u8, 0x00, 0xFF);
                }
            },
        }
    }
};

/// RAM `Memory` in a given state on startup.
pub const RamState = enum {
    AllZeros,
    AllOnes,
    Random,
};
