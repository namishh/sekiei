const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub fn main() !void {
    const img = try OpenGraph
        .init()
        .bg_image("biscuit.png")
        .blur(10)
        .overlay("#000000aa")
        .title("writing my own static site because i love fixing fixed stuff", "#ffffffff")
        .subtitle("i wrote this in zig", "#ffffffff")
        .bottom("/blog", "#ffffffff")
        .pfp("static/images/pfp.png")
        .save("out.png");
    defer img.deinit();

    const simple = try OpenGraph
        .init()
        .bg_linear_gradient("#0f0f0fff", "#222222ff", .LeftToRight)
        .grid(40.0, 0.5, "#323232ff")
        .title("this should be the new blog post that i will never release ", "#ffffffff")
        .subtitle("but well i will never release it", "#ffffffff")
        .pfp("static/images/pfp.png")
        .save("simple.png");
    defer simple.deinit();
}
