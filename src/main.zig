const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub fn main() !void {
    const img = try OpenGraph
        .init()
        .bg_image("biscuit.png")
        .blur(10)
        .overlay("#000000aa")
        .title("writing my own static site generator because i love fixing stuff that already works", "#ffffffff")
        .subtitle("i wrote this in zig (btw)", "#ffffffff")
        .bottom("/blog", "#ffffffff")
        .pfp("static/images/pfp.png")
        .save("out.png");
    defer img.deinit();

    const simple = try OpenGraph
        .init()
        .bg_linear_gradient("#0f0f0fff", "#222222ff", .LeftToRight)
        .grid(40.0, 0.5, "#323232ff")
        .title("showcasing a simple linear gradient background", "#ffffffff")
        .subtitle("some text below it", "#ffffffff")
        .pfp("static/images/temp.png")
        .save("simple.png");
    defer simple.deinit();

    const lg = try OpenGraph
        .init()
        .bg_linear_gradient("#77b6edff", "#8be8a7ff", .LeftToRight)
        .save("simple2.png");
    defer lg.deinit();

    const x = try OpenGraph.init()
        .bg_image("bg2.png")
        .overlay("#000000aa")
        .save("outter.png");
    defer x.deinit();
}
