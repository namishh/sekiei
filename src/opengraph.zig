const std = @import("std");

const c = @cImport({
    @cInclude("cairo/cairo.h");
});

const WIDTH = 1200;
const HEIGHT = 630;

const BackgroundDirection = enum { LeftToRight, RightToLeft, TopToBottom, BottomToTop };

pub const OpenGraph = struct {
    const Self = @This();
    bg_added: bool = false,

    surface: *c.cairo_surface_t,
    cr: *c.cairo_t,

    pub fn init() Self {
        const surface = c.cairo_image_surface_create(
            c.CAIRO_FORMAT_ARGB32,
            WIDTH,
            HEIGHT,
        );

        const cr = c.cairo_create(surface).?;

        c.cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
        c.cairo_paint(cr);

        return .{
            .surface = surface.?,
            .cr = cr,
        };
    }

    pub fn deinit(self: *const Self) void {
        c.cairo_destroy(self.cr);
        c.cairo_surface_destroy(self.surface);
    }

    pub fn background_image(self: *const Self, path: [:0]const u8) *const Self {
        const image = c.cairo_image_surface_create_from_png(path).?;
        const original_width = c.cairo_image_surface_get_width(image);
        const original_height = c.cairo_image_surface_get_height(image);

        const scale_x = @as(f64, @floatFromInt(WIDTH)) / @as(f64, @floatFromInt(original_width));
        const scale_y = @as(f64, @floatFromInt(HEIGHT)) / @as(f64, @floatFromInt(original_height));

        c.cairo_save(self.cr);
        defer c.cairo_restore(self.cr);
        c.cairo_scale(self.cr, scale_x, scale_y);
        c.cairo_set_source_surface(self.cr, image, 0, 0);

        c.cairo_paint(self.cr);

        return self;
    }

    pub fn save(self: *const Self, path: [:0]const u8) !*const Self {
        if (c.cairo_surface_write_to_png(self.surface, path.ptr) != c.CAIRO_STATUS_SUCCESS) {
            return error.WriteFailed;
        }

        return self;
    }
};
