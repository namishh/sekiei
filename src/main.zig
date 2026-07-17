const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub fn main() !void {
    const o = try OpenGraph
        .init()
        .background_image("biscuit.png")
        .save("out.png");
    defer o.deinit();
}
