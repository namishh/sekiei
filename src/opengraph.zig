const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;

const c = @import("main.zig").c;

pub const OpenGraph = struct {
    const Self = @This();
    buf: Buffer,

    pub fn init(allocator: std.mem.Allocator) !Self {
        var buf = try Buffer.init(allocator, 100);

        const svg =
            \\<svg width="300" height="170" xmlns="http://www.w3.org/2000/svg">
            \\ <rect width="150" height="150" x="10" y="10" rx="20" ry="20" style="fill:red;stroke:black;stroke-width:5;opacity:0.5" />
            \\</svg>
        ;
        try buf.write(svg);
        return .{ .buf = buf };
    }

    pub fn deinit(self: *Self) void {
        self.buf.deinit();
    }

    pub fn getString(self: *Self) []const u8 {
        return self.buf.string();
    }

    pub fn save_as(self: *Self, wand: *c.MagickWand, path: []const u8) !void {
        if (c.MagickReadImageBlob(wand, self.buf.string().ptr, self.buf.string().len) == c.MagickFalse) {
            return error.FailedToRead;
        }

        if (c.MagickWriteImage(wand, path.ptr) == c.MagickFalse) {
            return error.FailedExport;
        }
    }
};
