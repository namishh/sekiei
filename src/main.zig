const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub const c = @cImport({
    @cInclude("MagickWand/MagickWand.h");
});

pub fn main() !void {
    const wand = c.NewMagickWand();
    if (wand == null) {
        return error.MagicWandCreationFailed;
    }
    defer _ = c.DestroyMagickWand(wand);
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var o = try OpenGraph.init(allocator);
    defer o.deinit();

    std.debug.print("{s}", .{o.getString()});
    try o.save_as(wand.?, "out.png");
}
