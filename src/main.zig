const std = @import("std");
const cli = @import("cli");
const zigimg = @import("zigimg");

const options = @import("./options.zig");
const texture = @import("./texture.zig");

var config = struct {
    wrap: []const u8 = "clamp",
    filter: []const u8 = "trilinear",
    color_format: []const u8 = "RGBA8",
    palette_format: []const u8 = "RGB5A3",
    mipmap_min: u8 = 0,
    mipmap_max: u8 = 0,
    in: []const u8 = undefined,
    out: []const u8 = undefined,
    palettize: bool = false,
}{};

fn cli_convert() !void {
    const allocator = std.heap.smp_allocator;

    const wrap = try options.WrapStrategy.parse(config.wrap);
    const filter = try options.Filter.parse(config.filter);
    const color_format = try options.ColorFormat.parse(config.color_format);
    const palette_format = try options.ColorFormat.parse(config.palette_format);

    // Read image file
    var read_buffer: [zigimg.io.DEFAULT_BUFFER_SIZE]u8 = undefined;

    var image = try zigimg.Image.fromFilePath(allocator, config.in, read_buffer[0..]);
    defer image.deinit(allocator);

    std.log.debug("Detected {}x{} ({})", .{ image.width, image.height, image.pixelFormat() });

    var out = try std.fs.cwd().createFile(config.out, .{});
    defer out.close();

    var write_buffer: [1024]u8 = undefined;
    var writer = out.writer(&write_buffer);

    if ((color_format == .CI4 or color_format == .CI8) and config.palettize) {
        try image.convert(allocator, .indexed8);
    }

    try texture.writeTexture(allocator, &writer, &image, wrap, filter, color_format, palette_format, config.mipmap_min, config.mipmap_max);
}

pub fn main() !void {
    var r = try cli.AppRunner.init(std.heap.page_allocator);

    const app = cli.App{
        .command = cli.Command{
            .name = "texconv",
            .target = cli.CommandTarget{
                .action = cli.CommandAction{ .exec = cli_convert },
            },
            .options = try r.allocOptions(&.{ .{
                .long_name = "wrap",
                .help = "Wrapping strategy (valid values: clamp, repeat, mirror)",
                .value_ref = r.mkRef(&config.wrap),
            }, .{
                .long_name = "filter",
                .help = "Filter (valid values: near, bilinear, trilinear)",
                .value_ref = r.mkRef(&config.filter),
            }, .{
                .long_name = "color-format",
                .help = "Output color format (see README for list)",
                .value_ref = r.mkRef(&config.color_format),
            }, .{
                .long_name = "palette-format",
                .help = "Palette color format (see README for list)",
                .value_ref = r.mkRef(&config.palette_format),
            }, .{
                .long_name = "mipmap-min",
                .help = "Minimum mipmap level (0-10)",
                .value_ref = r.mkRef(&config.mipmap_min),
            }, .{
                .long_name = "mipmap-max",
                .help = "Maximum mipmap level (0-10)",
                .value_ref = r.mkRef(&config.mipmap_max),
            }, .{
                .long_name = "in",
                .help = "Image file to convert",
                .value_ref = r.mkRef(&config.in),
                .required = true,
            }, .{
                .long_name = "out",
                .help = "Output file",
                .value_ref = r.mkRef(&config.out),
                .required = true,
            }, .{
                .long_name = "palettize",
                .help = "Automatically create a palette if required",
                .value_ref = r.mkRef(&config.palettize),
            } }),
        },
    };

    return r.run(&app);
}
