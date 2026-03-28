const std = @import("std");
const zigimg = @import("zigimg");

const texture = @import("./texture.zig");
const options = @import("./options.zig");

fn compareColorTest(color_format: options.ColorFormat, palette_format: options.ColorFormat, sample_file: []const u8, test_file: []const u8) !void {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;
    var image = try zigimg.Image.fromFilePath(std.testing.allocator, sample_file, read_buffer[0..]);
    defer image.deinit(std.testing.allocator);

    var file = try tmp.dir.createFile("test.bin", .{ .read = true });
    defer file.close();

    var write_buffer: [1024]u8 = undefined;
    var writer = file.writer(&write_buffer);

    try texture.writeTexture(
        std.testing.allocator,
        &writer,
        &image,
        .clamp,
        .trilinear,
        color_format,
        palette_format,
        0,
        0,
    );

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

const main_sample = "./testdata/sample.png";
const alpha_sample = "./testdata/alpha.png";
const palette33_sample = "./testdata/palette33.png";
const palette16_sample = "./testdata/palette16.png";

test "PNG encodes in I4 correctly" {
    try compareColorTest(
        .I4,
        .RGB5A3,
        main_sample,
        "./testdata/sample.i4.bin",
    );
}

test "PNG encodes in I8 correctly" {
    try compareColorTest(
        .I8,
        .RGB5A3,
        main_sample,
        "./testdata/sample.i8.bin",
    );
}

test "PNG (no alpha) encodes in RGBA8 correctly" {
    try compareColorTest(
        .RGBA8,
        .RGB5A3,
        main_sample,
        "./testdata/sample.rgba8.bin",
    );
}

test "PNG (alpha test) encodes in RGBA8 correctly" {
    try compareColorTest(
        .RGBA8,
        .RGB5A3,
        alpha_sample,
        "./testdata/alpha.rgba8.bin",
    );
}

test "PNG encodes in RGB565 correctly" {
    try compareColorTest(
        .RGB565,
        .RGB5A3,
        main_sample,
        "./testdata/sample.rgb565.bin",
    );
}

test "PNG (no alpha) encodes in RGB5A3 correctly" {
    try compareColorTest(
        .RGB5A3,
        .RGB5A3,
        main_sample,
        "./testdata/sample.rgb5a3.bin",
    );
}

test "PNG (alpha test) encodes in RGB5A3 correctly" {
    try compareColorTest(
        .RGB5A3,
        .RGB5A3,
        alpha_sample,
        "./testdata/alpha.rgb5a3.bin",
    );
}

test "PNG (alpha test) encodes in IA4 correctly" {
    try compareColorTest(
        .IA4,
        .RGB5A3,
        alpha_sample,
        "./testdata/alpha.ia4.bin",
    );
}

test "PNG (alpha test) encodes in IA8 correctly" {
    try compareColorTest(
        .IA8,
        .RGB5A3,
        alpha_sample,
        "./testdata/alpha.ia8.bin",
    );
}

test "PNG (alpha test) encodes in A8 correctly" {
    try compareColorTest(
        .A8,
        .RGB5A3,
        alpha_sample,
        "./testdata/alpha.a8.bin",
    );
}

test "PNG (palette33) encodes in CI8/IA8 correctly" {
    try compareColorTest(
        .CI8,
        .IA8,
        palette33_sample,
        "./testdata/palette33.ci8.ia8.bin",
    );
}

test "PNG (palette33) encodes in CI8/RGB5A3 correctly" {
    try compareColorTest(
        .CI8,
        .RGB5A3,
        palette33_sample,
        "./testdata/palette33.ci8.rgb5a3.bin",
    );
}

test "PNG (palette16) encodes in CI4/RGB5A3 correctly" {
    try compareColorTest(
        .CI4,
        .RGB5A3,
        palette16_sample,
        "./testdata/palette16.ci4.rgb5a3.bin",
    );
}
