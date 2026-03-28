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
    _padding: [14]u8,
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
    comptime {
        std.debug.assert(@sizeOf(Header) == 32);
    }

    // Skip header for now (we need to write data first)
    try writer.seekTo(32);

    var palette_entries: u16 = 0;
    var palette_offset: u32 = 0;

    switch (color_format) {
        .I4 => {
            try image.convert(allocator, .grayscale4);
            try colors.writeI4(&writer.interface, image);
        },
        .I8 => {
            try image.convert(allocator, .grayscale8);
            try colors.writeI8(&writer.interface, image);
        },
        .IA4 => {
            try image.convert(allocator, .grayscale8Alpha);
            try colors.writeIA4(&writer.interface, image);
        },
        .IA8 => {
            try image.convert(allocator, .grayscale8Alpha);
            try colors.writeIA8(&writer.interface, image);
        },
        .A8 => {
            try image.convert(allocator, .grayscale8Alpha);
            try colors.writeA8(&writer.interface, image);
        },
        .RGBA8 => {
            try image.convert(allocator, .rgba32);
            try colors.writeRGBA8(&writer.interface, image);
        },
        .RGB565 => {
            try image.convert(allocator, .rgb565);
            try colors.writeRGB565(&writer.interface, image);
        },
        .RGB5A3 => {
            try image.convert(allocator, .rgba32);
            try colors.writeRGB5A3(&writer.interface, image);
        },
        .CI4 => {
            if (!image.pixels.isIndexed()) {
                return error.nonPalettedImage;
            }
            if (image.pixels.getPalette().?.len > 0x10) {
                return error.paletteTooLarge;
            }
            try colors.writeCI4(&writer.interface, image);
        },
        .CI8 => {
            if (!image.pixels.isIndexed()) {
                return error.nonPalettedImage;
            }
            if (image.pixels.getPalette().?.len > 0x100) {
                return error.paletteTooLarge;
            }
            try colors.writeCI8(&writer.interface, image);
        },
    }

    // Flush changes so we can seek/obtain position
    try writer.interface.flush();

    if (color_format == .CI4 or color_format == .CI8) {
        const palette = switch (image.pixelFormat()) {
            .indexed4 => image.pixels.indexed4.palette,
            .indexed8 => image.pixels.indexed8.palette,
            else => return error.unexpectedPixelFormat,
        };
        palette_entries = @truncate(palette.len);
        palette_offset = std.mem.alignForward(u32, @truncate(writer.pos), 32);

        try writer.seekTo(palette_offset);
        try colors.writePalette(&writer.interface, palette, palette_format);
        try writer.interface.flush();
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
        .palette_offset = palette_offset,
        .palette_entries = palette_entries,
        ._padding = @splat(0),
    };

    try writer.seekTo(0);
    try writer.interface.writeStruct(header, .big);
    try writer.interface.flush();
}
