const std = @import("std");

pub const ColorFormat = enum {
    const Self = @This();

    I4,
    I8,
    IA4,
    IA8,
    RGB565,
    RGB5A3,
    RGBA8,
    A8,
    CI4,
    CI8,

    pub fn parse(str: []const u8) !Self {
        return std.meta.stringToEnum(Self, str) orelse return error.InvalidColorFormat;
    }

    pub fn colorId(self: Self) u8 {
        return switch (self) {
            .I4 => 0x0,
            .I8 => 0x1,
            .IA4 => 0x2,
            .IA8 => 0x3,
            .RGB565 => 0x4,
            .RGB5A3 => 0x5,
            .RGBA8 => 0x6,
            .A8 => 0x7,
            .CI4 => 0x8,
            .CI8 => 0x9,
        };
    }

    pub fn paletteId(self: Self) !u8 {
        return switch (self) {
            .IA8 => 0x0,
            .RGB565 => 0x1,
            .RGB5A3 => 0x2,
            else => error.InvalidColorFormat,
        };
    }
};

pub const WrapStrategy = enum {
    const Self = @This();

    clamp,
    repeat,
    mirror,

    pub fn parse(str: []const u8) !Self {
        return std.meta.stringToEnum(Self, str) orelse return error.InvalidChoice;
    }

    pub fn value(self: Self) u2 {
        return switch (self) {
            .clamp => 0,
            .repeat => 1,
            .mirror => 2,
        };
    }
};

pub const Filter = enum {
    const Self = @This();

    near,
    bilinear,
    trilinear,

    pub fn parse(str: []const u8) !Self {
        return std.meta.stringToEnum(Self, str) orelse return error.InvalidChoice;
    }

    pub fn value(self: Self) u2 {
        return switch (self) {
            .near => 0,
            .bilinear => 2,
            .trilinear => 3,
        };
    }
};
