const std = @import("std");
const zigimg = @import("zigimg");

const texture = @import("./texture.zig");
const options = @import("./options.zig");

fn compareColorTest(color_format: options.ColorFormat, test_file: []const u8) !void {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(std.testing.allocator, "./testdata/sample.png", read_buffer[0..]);
    defer image.deinit(std.testing.allocator);

    var file = try tmp.dir.createFile("test.bin", .{ .read = true });
    defer file.close();

    var write_buffer: [1024]u8 = undefined;
    var writer = file.writer(&write_buffer);

    try texture.writeTexture(std.testing.allocator, &writer, &image, .clamp, .trilinear, color_format, .RGB5A3, 0, 0);

    // Read back file
    try file.seekTo(0);
    const generated = try file.readToEndAlloc(std.testing.allocator, 64 * 1024);
    defer std.testing.allocator.free(generated);

    // Read trusted sample
    const snapshot = try std.fs.cwd().readFileAlloc(std.testing.allocator, test_file, 64 * 1024);
    defer std.testing.allocator.free(snapshot);

    try std.testing.expectEqual(snapshot.len, generated.len);
    try std.testing.expectEqualSlices(u8, snapshot, generated);
}

test "PNG encodes in RGBA8 correctly" {
    try compareColorTest(.RGBA8, "./testdata/sample.rgba8.bin");
}

test "PNG encodes in RGB565 correctly" {
    try compareColorTest(.RGB565, "./testdata/sample.rgb565.bin");
}
