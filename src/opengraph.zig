const std = @import("std");

const c = @cImport({
    @cInclude("cairo/cairo.h");
});

const WIDTH = 1200;
const HEIGHT = 630;

const BackgroundDirection = enum { LeftToRight, RightToLeft, TopToBottom, BottomToTop };

const MaxRadius = 32;
const KernelSize = MaxRadius * 2 + 1;

var blur_buffer: [WIDTH * HEIGHT]u32 = undefined;

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
        defer c.cairo_surface_destroy(image);
        const original_width = c.cairo_image_surface_get_width(image);
        const original_height = c.cairo_image_surface_get_height(image);

        const scale_x = @as(f64, @floatFromInt(WIDTH)) / @as(f64, @floatFromInt(original_width));
        const scale_y = @as(f64, @floatFromInt(HEIGHT)) / @as(f64, @floatFromInt(original_height));

        const scale = @max(scale_x, scale_y);

        c.cairo_save(self.cr);
        defer c.cairo_restore(self.cr);
        c.cairo_scale(self.cr, scale, scale);
        c.cairo_set_source_surface(self.cr, image, 0, 0);

        c.cairo_paint(self.cr);

        return self;
    }

    pub fn overlay(self: *const Self, rgba: [4]f64) *const Self {
        c.cairo_set_source_rgba(self.cr, rgba[0], rgba[1], rgba[2], rgba[3]);
        c.cairo_rectangle(self.cr, 0, 0, WIDTH, HEIGHT);
        c.cairo_fill(self.cr);
        return self;
    }

    pub fn gaussian(self: *const Self, radius: u8) *const Self {
        std.debug.assert(radius <= MaxRadius);
        return self;
    }

    pub fn save(self: *const Self, path: [:0]const u8) !*const Self {
        if (c.cairo_surface_write_to_png(self.surface, path.ptr) != c.CAIRO_STATUS_SUCCESS) {
            return error.WriteFailed;
        }

        return self;
    }
};
