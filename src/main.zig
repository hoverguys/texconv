const std = @import("std");
const cli = @import("cli");

const options = @import("./options.zig");

var config = struct {
    endianess: []const u8 = "big",
    wrap: []const u8 = "clamp",
    filter: []const u8 = "trilinear",
    color_format: []const u8 = "RGBA8",
    palette_format: []const u8 = "RGB5A3",
    mipmap_min: u8 = 0,
    mipmap_max: u8 = 0,
    in: []const u8 = "-",
    out: []const u8 = "-",
}{};

fn cli_convert() !void {
    const endianess = try options.Endianess.parse(config.endianess);
    const wrap = try options.WrapStrategy.parse(config.wrap);
    const filter = try options.Filter.parse(config.filter);
    const color_format = (try options.ColorFormat.parse(config.color_format)).colorId();
    const palette_format = try (try options.ColorFormat.parse(config.palette_format)).paletteId();

    _ = endianess;
    _ = wrap;
    _ = filter;
    _ = color_format;
    _ = palette_format;
}

pub fn main() !void {
    var r = try cli.AppRunner.init(std.heap.page_allocator);

    const app = cli.App{
        .command = cli.Command{
            .name = "texconv",
            .target = cli.CommandTarget{
                .action = cli.CommandAction{ .exec = cli_convert },
            },
            .options = try r.allocOptions(&.{
                .{
                    .long_name = "endianess",
                    .help = "Endianess of values (valid values: big, small)",
                    .value_ref = r.mkRef(&config.endianess),
                },
                .{
                    .long_name = "wrap",
                    .help = "Wrapping strategy (valid values: clamp, repeat, mirror)",
                    .value_ref = r.mkRef(&config.wrap),
                },
                .{
                    .long_name = "filter",
                    .help = "Filter (valid values: near, bilinear, trilinear)",
                    .value_ref = r.mkRef(&config.filter),
                },
                .{
                    .long_name = "color-format",
                    .help = "Output color format (see README for list)",
                    .value_ref = r.mkRef(&config.color_format),
                },
                .{
                    .long_name = "palette-format",
                    .help = "Palette color format (see README for list)",
                    .value_ref = r.mkRef(&config.palette_format),
                },
                .{
                    .long_name = "mipmap-min",
                    .help = "Minimum mipmap level (0-10)",
                    .value_ref = r.mkRef(&config.mipmap_min),
                },
                .{
                    .long_name = "mipmap-max",
                    .help = "Maximum mipmap level (0-10)",
                    .value_ref = r.mkRef(&config.mipmap_max),
                },
                .{
                    .long_name = "in",
                    .help = "Image file to convert (- for STDIN)",
                    .value_ref = r.mkRef(&config.in),
                },
                .{
                    .long_name = "out",
                    .help = "Output file (- for STDOUT)",
                    .value_ref = r.mkRef(&config.out),
                },
            }),
        },
    };

    return r.run(&app);
}
