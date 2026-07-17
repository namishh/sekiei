const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub const c = @cImport({
    @cInclude("cairo/cairo.h");
});

pub fn main() !void {
    var o = OpenGraph.init();
    defer o.deinit();
    try o.save("out.png");
}
