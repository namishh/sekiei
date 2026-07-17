const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub fn main() !void {
    const o = try OpenGraph
        .init()
        .background_image("biscuit.png")
        .blur(10)
        .overlay(.{ 0.0, 0.0, 0.0, 0.5 })
        .save("out.png");
    defer o.deinit();
}
