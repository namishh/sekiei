const std = @import("std");

const c = @cImport({
    @cInclude("cairo/cairo.h");
    @cInclude("pango/pangocairo.h");
    @cInclude("glib-object.h");
    @cInclude("fontconfig/fontconfig.h");
});

const WIDTH = 1200;
const HEIGHT = 630;

const BackgroundDirection = enum { LeftToRight, RightToLeft, TopToBottom, BottomToTop };

const MaxRadius = 32;
var blur_buffer: [WIDTH * HEIGHT]u32 = undefined;
var title_bottom: f64 = 0;

const bayer4x4 = [4][4]u8{
    .{ 0, 8, 2, 10 },
    .{ 12, 4, 14, 6 },
    .{ 3, 11, 1, 9 },
    .{ 15, 7, 13, 5 },
};

pub fn hex_string_to_rgb(hex: []const u8) [4]f64 {
    const cleaned = if (hex[0] == '#') hex[1..] else hex;

    const r_int = std.fmt.parseInt(u8, cleaned[0..2], 16) catch 0;
    const g_int = std.fmt.parseInt(u8, cleaned[2..4], 16) catch 0;
    const b_int = std.fmt.parseInt(u8, cleaned[4..6], 16) catch 0;
    const a_int = std.fmt.parseInt(u8, cleaned[6..8], 16) catch 255;

    return .{
        @as(f64, @floatFromInt(r_int)) / 255.0,
        @as(f64, @floatFromInt(g_int)) / 255.0,
        @as(f64, @floatFromInt(b_int)) / 255.0,
        @as(f64, @floatFromInt(a_int)) / 255.0,
    };
}

pub const OpenGraph = struct {
    const Self = @This();

    surface: *c.cairo_surface_t,
    cr: *c.cairo_t,

    pub fn init() Self {
        const surface = c.cairo_image_surface_create(
            c.CAIRO_FORMAT_ARGB32,
            WIDTH,
            HEIGHT,
        );

        _ = c.FcConfigAppFontAddFile(c.FcConfigGetCurrent(), "static/_priv/geist.ttf");
        const cr = c.cairo_create(surface).?;

        c.cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
        c.cairo_paint(cr);

        return .{ .surface = surface.?, .cr = cr };
    }

    pub fn deinit(self: *const Self) void {
        c.cairo_destroy(self.cr);
        c.cairo_surface_destroy(self.surface);
    }

    pub fn bg_linear_gradient(self: *const Self, c_t: []const u8, c_f: []const u8, dir: BackgroundDirection) *const Self {
        const floatHeight = @as(f64, @floatFromInt(HEIGHT));
        const floatWidth = @as(f64, @floatFromInt(WIDTH));
        const pattern: *c.cairo_pattern_t = switch (dir) {
            .BottomToTop => c.cairo_pattern_create_linear(0.0, floatHeight, 0.0, 0.0).?,
            .LeftToRight => c.cairo_pattern_create_linear(0.0, 0.0, floatWidth, 0.0).?,
            .RightToLeft => c.cairo_pattern_create_linear(floatWidth, 0.0, 0.0, 0.0).?,
            .TopToBottom => c.cairo_pattern_create_linear(0.0, 0.0, 0.0, floatHeight).?,
        };

        defer c.cairo_pattern_destroy(pattern);

        const color_to = hex_string_to_rgb(c_t);
        const color_from = hex_string_to_rgb(c_f);

        c.cairo_pattern_add_color_stop_rgba(pattern, 0.0, color_to[0], color_to[1], color_to[2], color_to[3]);
        c.cairo_pattern_add_color_stop_rgba(pattern, 1.0, color_from[0], color_from[1], color_from[2], color_from[3]);
        c.cairo_set_source(self.cr, pattern);
        c.cairo_rectangle(self.cr, 0, 0, WIDTH, HEIGHT);
        c.cairo_fill(self.cr);
        return self;
    }

    pub fn grid(self: *const Self, grid_size: f64, line_width: f64, color: []const u8) *const Self {
        const co = hex_string_to_rgb(color);
        c.cairo_set_source_rgba(self.cr, co[0], co[1], co[2], co[3]);
        c.cairo_set_line_width(self.cr, line_width);

        var x: f64 = 0;
        while (x <= WIDTH) : (x += grid_size) {
            c.cairo_move_to(self.cr, x, 0);
            c.cairo_line_to(self.cr, x, HEIGHT);
        }

        var y: f64 = 0;
        while (y <= HEIGHT) : (y += grid_size) {
            c.cairo_move_to(self.cr, 0, y);
            c.cairo_line_to(self.cr, WIDTH, y);
        }

        c.cairo_stroke(self.cr);

        return self;
    }

    pub fn overlay(self: *const Self, color: []const u8) *const Self {
        const rgba = hex_string_to_rgb(color);
        c.cairo_set_source_rgba(self.cr, rgba[0], rgba[1], rgba[2], rgba[3]);
        c.cairo_rectangle(self.cr, 0, 0, WIDTH, HEIGHT);
        c.cairo_fill(self.cr);
        return self;
    }

    pub fn bg_color(self: *const Self, color: []const u8) *const Self {
        const rgba = hex_string_to_rgb(color);
        c.cairo_set_source_rgba(self.cr, rgba[0], rgba[1], rgba[2], rgba[3]);
        c.cairo_rectangle(self.cr, 0, 0, WIDTH, HEIGHT);
        c.cairo_fill(self.cr);
        return self;
    }

    pub fn bg_image(self: *const Self, path: [:0]const u8) *const Self {
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

    pub fn pfp(self: *const Self, path: [:0]const u8) *const Self {
        const image = c.cairo_image_surface_create_from_png(path).?;
        defer c.cairo_surface_destroy(image);

        const size: f64 = 80;
        const x: f64 = WIDTH - 40 - size;
        const y: f64 = HEIGHT - 40 - size;

        const width: f64 = @floatFromInt(c.cairo_image_surface_get_width(image));
        const height: f64 = @floatFromInt(c.cairo_image_surface_get_height(image));

        c.cairo_save(self.cr);
        defer c.cairo_restore(self.cr);

        c.cairo_arc(
            self.cr,
            x + size / 2,
            y + size / 2,
            size / 2,
            0,
            2 * std.math.pi,
        );
        c.cairo_clip(self.cr);

        c.cairo_translate(self.cr, x, y);
        c.cairo_scale(self.cr, size / width, size / height);

        c.cairo_set_source_surface(self.cr, image, 0, 0);
        c.cairo_paint(self.cr);

        return self;
    }

    pub fn blur(self: *const Self, radius: u8) *const Self {
        std.debug.assert(radius <= MaxRadius);
        c.cairo_surface_flush(self.surface);
        const stride: usize = @intCast(c.cairo_image_surface_get_stride(self.surface));
        const ptr = c.cairo_image_surface_get_data(self.surface);
        const pixels: [*]u32 = @ptrCast(@alignCast(ptr));
        const window = @as(u32, radius) * 2 + 1;

        for (0..HEIGHT) |y| {
            const row: [*]const u32 =
                @ptrCast(@alignCast(@as([*]const u8, @ptrCast(pixels)) + y * stride));
            for (0..WIDTH) |x| {
                var a: u32 = 0;
                var r: u32 = 0;
                var g: u32 = 0;
                var b: u32 = 0;
                var i: i32 = -@as(i32, radius);
                while (i <= radius) : (i += 1) {
                    const xx: usize = @intCast(std.math.clamp(
                        @as(i32, @intCast(x)) + i,
                        0,
                        WIDTH - 1,
                    ));
                    const p = row[xx];
                    a += (p >> 24) & 0xff;
                    r += (p >> 16) & 0xff;
                    g += (p >> 8) & 0xff;
                    b += p & 0xff;
                }
                blur_buffer[y * WIDTH + x] =
                    ((a / window) << 24) |
                    ((r / window) << 16) |
                    ((g / window) << 8) |
                    (b / window);
            }
        }

        for (0..HEIGHT) |y| {
            const row: [*]u32 =
                @ptrCast(@alignCast(@as([*]u8, @ptrCast(pixels)) + y * stride));
            for (0..WIDTH) |x| {
                var a: u32 = 0;
                var r: u32 = 0;
                var g: u32 = 0;
                var b: u32 = 0;
                var i: i32 = -@as(i32, radius);
                while (i <= radius) : (i += 1) {
                    const yy: usize = @intCast(std.math.clamp(
                        @as(i32, @intCast(y)) + i,
                        0,
                        HEIGHT - 1,
                    ));
                    const p = blur_buffer[yy * WIDTH + x];
                    a += (p >> 24) & 0xff;
                    r += (p >> 16) & 0xff;
                    g += (p >> 8) & 0xff;
                    b += p & 0xff;
                }
                row[x] = ((a / window) << 24) | ((r / window) << 16) | ((g / window) << 8) | (b / window);
            }
        }

        c.cairo_surface_mark_dirty(self.surface);
        return self;
    }

    pub fn dither(self: *const Self, strength: u8) *const Self {
        c.cairo_surface_flush(self.surface);
        const stride: usize = @intCast(c.cairo_image_surface_get_stride(self.surface));
        const ptr = c.cairo_image_surface_get_data(self.surface);
        const pixels: [*]u32 = @ptrCast(@alignCast(ptr));

        const dot_size: usize = 3;

        for (0..HEIGHT) |y| {
            const row: [*]u32 = @ptrCast(@alignCast(@as([*]u8, @ptrCast(pixels)) + y * stride));

            for (0..WIDTH) |x| {
                const p = row[x];
                const a = (p >> 24) & 0xff;
                var r: i32 = @intCast((p >> 16) & 0xff);
                var g: i32 = @intCast((p >> 8) & 0xff);
                var b: i32 = @intCast(p & 0xff);

                const threshold = bayer4x4[(y / dot_size) % 4][(x / dot_size) % 4];

                const offset: i32 = @divTrunc((@as(i32, threshold) - 7) * @as(i32, strength), 4);

                r = std.math.clamp(r + offset, 0, 255);
                g = std.math.clamp(g + offset, 0, 255);
                b = std.math.clamp(b + offset, 0, 255);

                row[x] = (a << 24) | (@as(u32, @intCast(r)) << 16) | (@as(u32, @intCast(g)) << 8) | @as(u32, @intCast(b));
            }
        }

        c.cairo_surface_mark_dirty(self.surface);
        return self;
    }

    fn drawText(self: *const Self, text: [:0]const u8, color: [:0]const u8, font: [:0]const u8, x: f64, y: f64) struct { width: c_int, height: c_int } {
        const layout = c.pango_cairo_create_layout(self.cr).?;
        defer c.g_object_unref(layout);

        const font_desc = c.pango_font_description_from_string(font.ptr).?;
        defer c.pango_font_description_free(font_desc);

        const rgba = hex_string_to_rgb(color);
        c.cairo_set_source_rgba(self.cr, rgba[0], rgba[1], rgba[2], rgba[3]);

        c.pango_layout_set_font_description(layout, font_desc);
        c.pango_layout_set_text(layout, text.ptr, @intCast(text.len));
        c.pango_layout_set_width(layout, (WIDTH - 80) * c.PANGO_SCALE);
        c.pango_layout_set_wrap(layout, c.PANGO_WRAP_WORD_CHAR);

        c.cairo_move_to(self.cr, x, y);
        c.pango_cairo_show_layout(self.cr, layout);

        var width: c_int = 0;
        var height: c_int = 0;
        c.pango_layout_get_pixel_size(layout, &width, &height);

        return .{
            .width = width,
            .height = height,
        };
    }

    pub fn title(self: *const Self, text: [:0]const u8, color: [:0]const u8) *const Self {
        const size = self.drawText(text, color, "Geist Bold 48", 40, 80);
        title_bottom = 80.0 + @as(f64, @floatFromInt(size.height));
        return self;
    }

    pub fn subtitle(self: *const Self, text: [:0]const u8, color: [:0]const u8) *const Self {
        _ = self.drawText(text, color, "Geist 24", 40, title_bottom + 10);
        return self;
    }

    pub fn bottom(self: *const Self, text: [:0]const u8, color: [:0]const u8) *const Self {
        _ = self.drawText(text, color, "Geist 18", 40, HEIGHT - 80);
        return self;
    }

    pub fn save(self: *const Self, path: [:0]const u8) !*const Self {
        if (c.cairo_surface_write_to_png(self.surface, path.ptr) != c.CAIRO_STATUS_SUCCESS) {
            return error.WriteFailed;
        }

        return self;
    }
};
