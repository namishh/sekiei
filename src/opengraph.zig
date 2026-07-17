const std = @import("std");

const c = @import("main.zig").c;

const BackgroundDirection = enum { LeftToRight, RightToLeft, TopToBottom, BottomToTop };

pub const OpenGraph = struct {
    const Self = @This();
    bg_added: bool = false,

    surface: *c.cairo_surface_t,
    cr: *c.cairo_t,

    pub fn init() Self {
        const surface = c.cairo_image_surface_create(
            c.CAIRO_FORMAT_ARGB32,
            1200,
            630,
        );

        const cr = c.cairo_create(surface).?;

        return .{
            .surface = surface.?,
            .cr = cr,
        };
    }

    pub fn deinit(self: *Self) void {
        c.cairo_destroy(self.cr);
        c.cairo_surface_destroy(self.surface);
    }

    pub fn save(self: *Self, path: [:0]const u8) !void {
        c.cairo_set_source_rgba(self.cr, 0.0, 0.0, 0.0, 0.0);
        c.cairo_paint(self.cr);

        c.cairo_set_source_rgba(self.cr, 1.0, 0.0, 0.0, 0.8);
        c.cairo_rectangle(self.cr, 10, 10, 100, 100);
        c.cairo_fill(self.cr);
        if (c.cairo_surface_write_to_png(self.surface, path.ptr) != c.CAIRO_STATUS_SUCCESS) {
            return error.WriteFailed;
        }
    }
};
