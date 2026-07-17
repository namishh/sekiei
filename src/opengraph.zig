const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;

const c = @import("main.zig").c;

const BackgroundDirection = enum { LeftToRight, RightToLeft, TopToBottom, BottomToTop };

pub const OpenGraph = struct {
    const Self = @This();
    svg_buf: Buffer,
    defs_buf: Buffer,
    bg_added: bool = false,

    pub fn init(allocator: std.mem.Allocator) !Self {
        var svg_buf = try Buffer.init(allocator, 100);
        var defs_buf = try Buffer.init(allocator, 100);

        const svg =
            \\<svg width="1200" height="630" xmlns="http://www.w3.org/2000/svg">
        ;

        const defs = "<defs>";

        try svg_buf.write(svg);
        try defs_buf.write(defs);
        return .{ .svg_buf = svg_buf, .defs_buf = defs_buf };
    }

    pub fn deinit(self: *Self) void {
        self.svg_buf.deinit();
        self.defs_buf.deinit();
    }

    pub fn get_string(self: *Self) []const u8 {
        return self.svg_buf.string();
    }

    pub fn background_linear_gradient(self: *Self, direction: BackgroundDirection, c1: []const u8, c2: []const u8) !void {
        if (self.bg_added) {
            return error.BgAlreadyAdded;
        }
        self.bg_added = true;

        const xy: [4]u32 = switch (direction) {
            .LeftToRight => .{ 0, 0, 100, 0 },
            .RightToLeft => .{ 100, 0, 0, 0 },
            .TopToBottom => .{ 0, 0, 0, 100 },
            .BottomToTop => .{ 0, 100, 0, 0 },
        };

        var buf: [256]u8 = undefined;
        const s = try std.fmt.bufPrint(&buf, "<linearGradient id=\"background\" x1=\"{d}%\" y1=\"{d}%\" x2=\"{d}%\" y2=\"{d}%\">", .{ xy[0], xy[1], xy[2], xy[3] });
        try self.defs_buf.write(s);

        var color_buf: [256]u8 = undefined;
        const colostr =
            \\ <stop offset="0%" stop-color="{s}" />
            \\ <stop offset="70%" stop-color="{s}" />
        ;
        const co = try std.fmt.bufPrint(&color_buf, colostr, .{ c1, c2 });
        try self.defs_buf.write(co);

        try self.defs_buf.write("</linearGradient>");
    }

    pub fn background_image(self: *Self, src: []const u8) !void {
        if (self.bg_added) {
            return error.BgAlreadyAdded;
        }
        self.bg_added = true;

        var buf: [256]u8 = undefined;
        const s = try std.fmt.bufPrint(&buf, "  <image href=\"{s}\" x=\"0\" y=\"0\" height=\"630\" width=\"1200\" />", .{src});
        try self.svg_buf.write(s);
    }

    pub fn end(self: *Self) !void {
        try self.defs_buf.write("</defs>");
        try self.svg_buf.write(self.defs_buf.string());

        // save other things
        try self.svg_buf.write("<rect width=\"100%\" height=\"100%\" fill=\"url(#background)\" />");

        try self.svg_buf.write("</svg>");
    }

    pub fn save_as(self: *Self, path: []const u8) !void {
        try self.end();
        std.debug.print("{s}", .{self.svg_buf.string()});
        var err: ?*c.GError = null;

        const handle = c.rsvg_handle_new_from_data(self.svg_buf.string().ptr, self.svg_buf.string().len, &err);
        defer c.g_object_unref(handle);

        // cairo
        const csurf = c.cairo_image_surface_create(c.CAIRO_FORMAT_ARGB32, 1230, 630);
        defer c.cairo_surface_destroy(csurf);

        const cr = c.cairo_create(csurf);
        defer c.cairo_destroy(cr);

        const vp = c.RsvgRectangle{ .x = 0, .y = 0, .width = 1230, .height = 630 };

        if (c.rsvg_handle_render_document(handle, cr, &vp, &err) == 0) {
            return error.RenderFailed;
        }

        if (c.cairo_surface_write_to_png(csurf, path.ptr) != c.CAIRO_STATUS_SUCCESS) {
            return error.WriteFailed;
        }
    }
};
