const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub const c = @cImport({
    @cInclude("librsvg/rsvg.h");
    @cInclude("cairo/cairo.h");
});

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var o = try OpenGraph.init(allocator);
    defer o.deinit();
    try o.background_linear_gradient(.BottomToTop, "#fff", "#000");
    // try o.background_image("file:///Users/nam/Documents/code/zog/biscuit.jpg");
    try o.save_as("out.png");
}
