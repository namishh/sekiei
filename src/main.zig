const std = @import("std");

const c = @cImport({
    @cInclude("MagickWand/MagickWand.h");
});

pub fn main() !void {
    const wand = c.NewMagickWand();
    if (wand == null) {
        return error.MagicWandCreationFailed;
    }
    defer _ = c.DestroyMagickWand(wand);
    const svg =
        \\<svg width="300" height="170" xmlns="http://www.w3.org/2000/svg">
        \\  <rect width="150" height="150" x="10" y="10" style="fill:blue;stroke:pink;stroke-width:5;fill-opacity:0.5;stroke-opacity:0.9" />
        \\</svg>
    ;

    if (c.MagickReadImageBlob(wand, svg, svg.len) == c.MagickFalse) {
        return error.FailedToRead;
    }

    if (c.MagickWriteImage(wand, "output.png") == c.MagickFalse) {
        return error.FailedExport;
    }

    std.debug.print("Wrote output.png\n", .{});
}
