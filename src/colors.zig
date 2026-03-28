const std = @import("std");
const zigimg = @import("zigimg");

pub fn writeRGBA8(writer: *std.Io.Writer, image: *zigimg.Image) !void {
    var it = TileIterator.make(image, 4, 4);
    while (it.next()) |point| {
        var block: [64]u8 = undefined;
        for (0..16) |index| {
            const x = (point.x * 4) + (index % 4);
            const y = (point.y * 4) + (index / 4);

            const pixel = image.pixels.rgba32[x + image.width * y];
            block[index * 2] = pixel.a;
            block[index * 2 + 1] = pixel.r;
            block[32 + index * 2] = pixel.g;
            block[32 + index * 2 + 1] = pixel.b;
        }
        _ = try writer.write(&block);
    }
}

const TileIterator = struct {
    const Self = @This();

    current: usize,
    limit: usize,
    rows: usize,

    pub fn make(image: *zigimg.Image, tile_width: u8, tile_height: u8) Self {
        const rows = image.height / tile_height;
        const cols = image.width / tile_width;

        return .{
            .current = 0,
            .limit = rows * cols,
            .rows = rows,
        };
    }

    pub fn next(self: *Self) ?struct { x: usize, y: usize } {
        defer self.current += 1;
        if (self.current >= self.limit) {
            return null;
        }
        return .{
            .x = (self.current % self.rows),
            .y = (self.current / self.rows),
        };
    }
};
