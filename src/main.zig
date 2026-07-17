const std = @import("std");
const OpenGraph = @import("opengraph.zig").OpenGraph;

pub fn main() !void {
    const img = try OpenGraph
        .init()
        .bg_image("biscuit.png")
        .blur(10)
        .overlay("#000000aa")
        .title("This is some very long text i am writing isnt this fun.")
        .save("out.png");
    defer img.deinit();

    const simple = try OpenGraph
        .init()
        .bg_linear_gradient("#0f0f0fff", "#222222ff", .LeftToRight)
        .grid(40.0, 0.5, "#323232ff")
        .save("simple.png");
    defer simple.deinit();
}
