const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub fn main() !void {
    const img = try OpenGraph
        .init()
        .bg_image("biscuit.png")
        .blur(10)
        .overlay(.{ 0.0, 0.0, 0.0, 0.5 })
        .save("out.png");
    defer img.deinit();

    const simple = try OpenGraph
        .init()
        .bg_linear_gradient(.{ 1.0, 0.0, 0.0 }, .{ 0.0, 1.0, 1.0 }, .LeftToRight)
        .save("simple.png");

    defer simple.deinit();
}
