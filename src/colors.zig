const std = @import("std");
const zigimg = @import("zigimg");

pub fn writeI4(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 8, 8);
    while (it.next()) |point| {
        var block: [32]u8 = undefined;
        var index: usize = 0;
        for (0..8) |chunk_y| {
            for (0..4) |chunk_x| {
                const x = point.x * 8 + chunk_x * 2;
                const y = point.y * 8 + chunk_y;
                const p1 = image.pixels.grayscale4[x + image.width * y];
                const p2 = image.pixels.grayscale4[x + 1 + image.width * y];
                block[index] = @as(u8, p1.value) << 4 | p2.value;
                index += 1;
            }
        }
        _ = try writer.write(&block);
    }
}

pub fn writeI8(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 8, 4);
    while (it.next()) |point| {
        var block: [32]u8 = undefined;
        var index: usize = 0;
        for (0..4) |chunk_y| {
            for (0..8) |chunk_x| {
                const x = point.x * 8 + chunk_x;
                const y = point.y * 4 + chunk_y;
                const pixel = image.pixels.grayscale8[x + image.width * y];
                block[index] = pixel.value;
                index += 1;
            }
        }
        _ = try writer.write(&block);
    }
}

pub fn writeIA4(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 8, 4);
    while (it.next()) |point| {
        var block: [32]u8 = undefined;
        var index: usize = 0;
        for (0..4) |chunk_y| {
            for (0..8) |chunk_x| {
                const x = point.x * 8 + chunk_x;
                const y = point.y * 4 + chunk_y;
                const pixel = image.pixels.grayscale8Alpha[x + image.width * y];
                block[index] = pixel.value & 0xf0 | pixel.alpha >> 4;
                index += 1;
            }
        }
        _ = try writer.write(&block);
    }
}

pub fn writeIA8(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 4, 4);
    while (it.next()) |point| {
        var block: [32]u8 = undefined;
        for (0..16) |index| {
            const x = point.x * 4 + (index % 4);
            const y = point.y * 4 + (index / 4);
            const pixel = image.pixels.grayscale8Alpha[x + image.width * y];
            block[index * 2] = pixel.value;
            block[index * 2 + 1] = pixel.alpha;
        }
        _ = try writer.write(&block);
    }
}

pub fn writeRGBA8(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 4, 4);
    while (it.next()) |point| {
        var block: [64]u8 = undefined;
        for (0..16) |index| {
            const x = point.x * 4 + (index % 4);
            const y = point.y * 4 + (index / 4);

            const pixel = image.pixels.rgba32[x + image.width * y];
            block[index * 2] = pixel.a;
            block[index * 2 + 1] = pixel.r;
            block[32 + index * 2] = pixel.g;
            block[32 + index * 2 + 1] = pixel.b;
        }
        _ = try writer.write(&block);
    }
}

pub fn writeRGB565(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 4, 4);
    while (it.next()) |point| {
        var block: [32]u8 = undefined;
        var endianWriter = std.Io.Writer.fixed(&block);
        for (0..16) |index| {
            const x = point.x * 4 + (index % 4);
            const y = point.y * 4 + (index / 4);

            const pixel = image.pixels.rgb565[x + image.width * y];
            try endianWriter.writeStruct(pixel, .big);
        }
        _ = try writer.write(&block);
    }
}

pub fn writeRGB5A3(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 4, 4);
    while (it.next()) |point| {
        var block: [32]u8 = undefined;
        var endianWriter = std.Io.Writer.fixed(&block);
        for (0..16) |index| {
            const x = point.x * 4 + (index % 4);
            const y = point.y * 4 + (index / 4);

            const pixel = image.pixels.rgba32[x + image.width * y];
            try endianWriter.writeInt(u16, getRGB5A3(pixel), .big);
        }
        _ = try writer.write(&block);
    }
}

fn getRGB5A3(color: zigimg.color.Rgba32) u16 {
    if (color.a < 0xff) {
        const r4 = color.r >> 4;
        const g4 = color.g >> 4;
        const b4 = color.b >> 4;
        const a3 = color.a >> 5;
        return b4 | @as(u16, g4) << 4 | @as(u16, r4) << 8 | @as(u16, a3) << 12;
    }

    const r5 = color.r >> 3;
    const g5 = color.g >> 3;
    const b5 = color.b >> 3;
    return b5 | @as(u16, g5) << 5 | @as(u16, r5) << 10 | 0x8000;
}

const TileIterator = struct {
    const Self = @This();

    current: usize,
    limit: usize,
    cols: usize,

    pub fn make(image: *zigimg.Image, tile_width: u8, tile_height: u8) Self {
        const rows = image.height / tile_height;
        const cols = image.width / tile_width;

        return .{
            .current = 0,
            .limit = rows * cols,
            .cols = cols,
        };
    }

    pub fn next(self: *Self) ?struct { x: usize, y: usize } {
        defer self.current += 1;
        if (self.current >= self.limit) {
            return null;
        }
        return .{
            .x = self.current % self.cols,
            .y = self.current / self.cols,
        };
    }
};
