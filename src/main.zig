const std = @import("std");
const freetype = @import("freetype");

const c = @cImport({
    @cInclude("fontconfig/fontconfig.h");
});

pub const FontConfig = opaque {
    fn make(config: *c.FcConfig) *FontConfig {
        return @ptrCast(*FontConfig, config);
    }

    fn ptr(config: *FontConfig) *c.FcConfig {
        return @ptrCast(*c.FcConfig, @alignCast(@alignOf(c.FcConfig), config));
    }

    pub fn init() !*FontConfig {
        return if (c.FcInitLoadConfigAndFonts()) |config|
            FontConfig.make(config)
        else
            error.ConfigInitError;
    }

    pub fn fontMatch(config: *FontConfig, pattern: *Pattern) !*Pattern {
        var result: c.FcResult = undefined;
        const font = c.FcFontMatch(config.ptr(), pattern.ptr(), &result);
        switch (result) {
            c.FcResultMatch => return Pattern.make(font),
            c.FcResultNoMatch => return error.NoMatch,
            c.FcResultOutOfMemory => return error.OutOfMemory,
            else => unreachable,
        }
    }

    pub fn fontList(config: *FontConfig, pattern: *Pattern, obj_set: *ObjectSet) !*FontSet {
        return if (c.FcFontList(config.ptr(), pattern.ptr(), obj_set.ptr())) |font_set|
            FontSet.make(font_set)
        else
            error.FontListError;
    }
};

pub const Range = struct {
    min: f64,
    max: f64,

    pub fn single(val: f64) Range {
        return .{ .min = val, .max = val };
    }

    fn fromFcRange(range: *const c.FcRange) Range {
        var res: Range = undefined;
        std.debug.assert(c.FcRangeGetDouble(range, &res.min, &res.max) != 0);
        return res;
    }

    fn toFcRange(range: Range) !*c.FcRange {
        return c.FcRangeCreateDouble(range.min, range.max) orelse error.RangeInitError;
    }
};

pub const Matrix = struct {
    xx: f64,
    xy: f64,
    yx: f64,
    yy: f64,

    fn fromFcMatrix(mat: c.FcMatrix) Matrix {
        return .{
            .xx = mat.xx,
            .xy = mat.xy,
            .yx = mat.yx,
            .yy = mat.yy,
        };
    }

    fn toFcMatrix(mat: Matrix) c.FcMatrix {
        return .{
            .xx = mat.xx,
            .xy = mat.xy,
            .yx = mat.yx,
            .yy = mat.yy,
        };
    }
};

pub const Property = enum {
    family,
    style,
    slant,
    weight,
    size,
    aspect,
    pixel_size,
    spacing,
    foundry,
    antialias,
    hinting,
    hint_style,
    vertical_layout,
    autohint,
    width,
    file,
    index,
    ft_face,
    outline,
    scalable,
    color,
    variable,
    symbol,
    dpi,
    rgba,
    minspace,
    charset,
    lang,
    fontversion,
    fullname,
    familylang,
    stylelang,
    fullnamelang,
    capability,
    fontformat,
    embolden,
    embedded_bitmap,
    decorative,
    lcd_filter,
    font_features,
    font_variations,
    namelang,
    prgname,
    postscript_name,
    font_has_hint,
    order,
    char_width,
    char_height,
    matrix,

    pub fn Type(comptime p: Property) type {
        return switch (p) {
            .family => []const u8,
            .style => []const u8,
            .slant => c_int,
            .weight => Range,
            .size => Range,
            .aspect => f64,
            .pixel_size => f64,
            .spacing => c_int,
            .foundry => []const u8,
            .antialias => bool,
            .hinting => bool,
            .hint_style => c_int,
            .vertical_layout => bool,
            .autohint => bool,
            .width => Range,
            .file => []const u8,
            .index => c_int,
            .ft_face => freetype.Face,
            .outline => bool,
            .scalable => bool,
            .color => bool,
            .variable => bool,
            .symbol => bool,
            .dpi => f64,
            .rgba => c_int,
            .minspace => bool,
            .charset => c_int, // TODO: CharSet
            .lang => c_int, // TODO: LangSet
            .fontversion => c_int,
            .fullname => []const u8,
            .familylang => []const u8,
            .stylelang => []const u8,
            .fullnamelang => []const u8,
            .capability => []const u8,
            .fontformat => []const u8,
            .embolden => bool,
            .embedded_bitmap => bool,
            .decorative => bool,
            .lcd_filter => c_int,
            .font_features => []const u8,
            .font_variations => []const u8,
            .namelang => []const u8,
            .prgname => []const u8,
            .postscript_name => []const u8,
            .font_has_hint => bool,
            .order => c_int,
            .char_width => c_int,
            .char_height => c_int,
            .matrix => Matrix,
        };
    }

    fn name(prop: Property) [*:0]const u8 {
        return switch (prop) {
            .family => c.FC_FAMILY,
            .style => c.FC_STYLE,
            .slant => c.FC_SLANT,
            .weight => c.FC_WEIGHT,
            .size => c.FC_SIZE,
            .aspect => c.FC_ASPECT,
            .pixel_size => c.FC_PIXEL_SIZE,
            .spacing => c.FC_SPACING,
            .foundry => c.FC_FOUNDRY,
            .antialias => c.FC_ANTIALIAS,
            .hinting => c.FC_HINTING,
            .hint_style => c.FC_HINT_STYLE,
            .vertical_layout => c.FC_VERTICAL_LAYOUT,
            .autohint => c.FC_AUTOHINT,
            .width => c.FC_WIDTH,
            .file => c.FC_FILE,
            .index => c.FC_INDEX,
            .ft_face => c.FC_FT_FACE,
            .outline => c.FC_OUTLINE,
            .scalable => c.FC_SCALABLE,
            .color => c.FC_COLOR,
            .variable => c.FC_VARIABLE,
            .symbol => c.FC_SCALE,
            .dpi => c.FC_DPI,
            .rgba => c.FC_RGBA,
            .minspace => c.FC_MINSPACE,
            .charset => c.FC_CHARSET,
            .lang => c.FC_LANG,
            .fontversion => c.FC_FONTVERSION,
            .fullname => c.FC_FULLNAME,
            .familylang => c.FC_FAMILYLANG,
            .stylelang => c.FC_STYLELANG,
            .fullnamelang => c.FC_FULLNAMELANG,
            .capability => c.FC_CAPABILITY,
            .fontformat => c.FC_FONTFORMAT,
            .embolden => c.FC_EMBOLDEN,
            .embedded_bitmap => c.FC_EMBEDDED_BITMAP,
            .decorative => c.FC_DECORATIVE,
            .lcd_filter => c.FC_LCD_FILTER,
            .font_features => c.FC_FONT_FEATURES,
            .font_variations => c.FC_FONT_VARIATIONS,
            .namelang => c.FC_NAMELANG,
            .prgname => c.FC_PRGNAME,
            .postscript_name => c.FC_POSTSCRIPT_NAME,
            .font_has_hint => c.FC_FONT_HAS_HINT,
            .order => c.FC_ORDER,
            .char_width => c.FC_CHAR_WIDTH,
            .char_height => c.FC_CHAR_HEIGHT,
            .matrix => c.FC_MATRIX,
        };
    }
};

pub const Pattern = opaque {
    fn make(pattern: *c.FcPattern) *Pattern {
        return @ptrCast(*Pattern, pattern);
    }

    fn ptr(pattern: *Pattern) *c.FcPattern {
        return @ptrCast(*c.FcPattern, @alignCast(@alignOf(c.FcPattern), pattern));
    }

    pub fn init() !*Pattern {
        return if (c.FcPatternCreate()) |pattern|
            Pattern.make(pattern)
        else
            error.PatternInitError;
    }

    pub fn parse(name: [*:0]const u8) !*Pattern {
        return if (c.FcNameParse(name)) |pattern|
            Pattern.make(pattern)
        else
            error.PatternInitError;
    }

    pub fn deinit(pattern: *Pattern) void {
        c.FcPatternDestroy(pattern.ptr());
    }

    pub fn defaultSubstitute(pattern: *Pattern) void {
        c.FcDefaultSubstitute(pattern.ptr());
    }

    pub fn configSubstitute(pattern: *Pattern, config: *FontConfig) !void {
        if (c.FcConfigSubstitute(config.ptr(), pattern.ptr(), c.FcMatchPattern) == 0) {
            return error.OutOfMemory;
        }
    }

    pub fn getProperty(pattern: *Pattern, comptime prop: Property, id: c_int) !prop.Type() {
        var val: c.FcValue = undefined;
        switch (c.FcPatternGet(pattern.ptr(), prop.name(), id, &val)) {
            c.FcResultMatch => {},
            c.FcResultNoMatch => return error.NoSuchProperty,
            c.FcResultNoId => return error.NoSuchId,
            else => unreachable,
        }

        switch (prop.Type()) {
            c_int => {
                std.debug.assert(val.type == c.FcTypeInteger);
                return val.u.i;
            },
            f64 => {
                std.debug.assert(val.type == c.FcTypeDouble);
                return val.u.d;
            },
            []const u8 => {
                std.debug.assert(val.type == c.FcTypeString);
                return std.mem.span(@ptrCast([*:0]const u8, val.u.s));
            },
            bool => {
                std.debug.assert(val.type == c.FcTypeBool);
                return val.u.b;
            },
            freetype.Face => {
                std.debug.assert(val.type == c.FcTypeFTFace);
                const FT_Face = std.meta.fields(freetype.Face)[0].field_type;
                return freetype.Face{ .handle = @ptrCast(FT_Face, val.u.f) };
            },
            Range => return switch (val.type) {
                c.FcTypeInteger => Range.single(@intToFloat(f64, val.u.i)),
                c.FcTypeDouble => Range.single(val.u.d),
                c.FcTypeRange => Range.fromFcRange(val.u.r.?),
                else => unreachable,
            },
            Matrix => {
                std.debug.assert(val.type == c.FcTypeMatrix);
                return Matrix.fromFcMatrix(val.u.m);
            },
            else => unreachable,
        }
    }
};

pub const ObjectSet = opaque {
    fn make(obj_set: *c.FcObjectSet) *ObjectSet {
        return @ptrCast(*ObjectSet, obj_set);
    }

    fn ptr(obj_set: *ObjectSet) *c.FcObjectSet {
        return @ptrCast(*c.FcObjectSet, @alignCast(@alignOf(c.FcObjectSet), obj_set));
    }

    pub fn build(comptime props: []const Property) !*ObjectSet {
        const types = [1]type{?[*:0]const u8} ** (props.len + 1);

        var tuple: std.meta.Tuple(&types) = undefined;
        inline for (props) |prop, i| {
            tuple[i] = prop.name();
        }

        tuple[props.len] = null;

        return if (@call(.{}, c.FcObjectSetBuild, tuple)) |obj_set|
            ObjectSet.make(obj_set)
        else
            error.ObjectSetInitError;
    }

    pub fn deinit(obj_set: *ObjectSet) void {
        c.FcObjectSetDestroy(obj_set.ptr());
    }
};

pub const FontSet = opaque {
    fn make(font_set: *c.FcFontSet) *FontSet {
        return @ptrCast(*FontSet, font_set);
    }

    fn ptr(font_set: *FontSet) *c.FcFontSet {
        return @ptrCast(*c.FcFontSet, @alignCast(@alignOf(c.FcFontSet), font_set));
    }

    pub fn deinit(font_set: *FontSet) void {
        c.FcFontSetDestroy(font_set.ptr());
    }

    pub fn fonts(font_set: *FontSet) []*Pattern {
        const pats: []?*c.FcPattern = font_set.ptr().fonts[0..@intCast(usize, font_set.ptr().nfont)];
        return @ptrCast([]*Pattern, pats);
    }
};
