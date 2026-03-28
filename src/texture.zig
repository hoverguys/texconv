const std = @import("std");
const zigimg = @import("zigimg");

const options = @import("./options.zig");
const colors = @import("./colors.zig");

const Header = extern struct {
    width: u16,
    height: u16,
    color_format: u8,
    palette_format: u8,
    mipmap: u8,
    filter: u8,
    data_offset: u32,
    palette_offset: u32,
    palette_entries: u16,
};

pub fn writeTexture(
    allocator: std.mem.Allocator,
    writer: *std.fs.File.Writer,
    image: *zigimg.Image,
    wrap: options.WrapStrategy,
    filter: options.Filter,
    color_format: options.ColorFormat,
    palette_format: options.ColorFormat,
    mipmap_min: u8,
    mipmap_max: u8,
) !void {

    // Skip header for now (we need to write data first)
    try writer.seekTo(32);

    switch (color_format) {
        .RGBA8 => {
            try image.convert(allocator, .rgba32);
            try colors.writeRGBA8(&writer.interface, image);
        },
        else => return error.unsupportedColorFormat,
    }

    // Make header
    const wrap_bits = @as(u8, wrap.value());
    const filter_bits = filter.value();
    const header = Header{
        .width = @truncate(image.width),
        .height = @truncate(image.height),
        .color_format = color_format.colorId(),
        .palette_format = try palette_format.paletteId(),
        .mipmap = mipmap_min | (mipmap_max << 4),
        .filter = filter_bits | (wrap_bits << 2) | (wrap_bits << 5),
        .data_offset = 32,
        .palette_offset = 0,
        .palette_entries = 0,
    };

    try writer.interface.flush();
    try writer.seekTo(0);
    try writer.interface.writeStruct(header, .big);
    try writer.interface.flush();
}
