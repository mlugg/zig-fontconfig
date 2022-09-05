const std = @import("std");
const freetype = @import("mach-freetype/build.zig");

const sources = &[_][]const u8{
    "fontconfig/src/fcarch.c",
    "fontconfig/src/fcatomic.c",
    "fontconfig/src/fccache.c",
    "fontconfig/src/fccfg.c",
    "fontconfig/src/fccharset.c",
    "fontconfig/src/fccompat.c",
    "fontconfig/src/fcdbg.c",
    "fontconfig/src/fcdefault.c",
    "fontconfig/src/fcdir.c",
    "fontconfig/src/fcformat.c",
    "fontconfig/src/fcfreetype.c",
    "fontconfig/src/fcfs.c",
    "fontconfig/src/fchash.c",
    "fontconfig/src/fcinit.c",
    "fontconfig/src/fclang.c",
    "fontconfig/src/fclist.c",
    "fontconfig/src/fcmatch.c",
    "fontconfig/src/fcmatrix.c",
    "fontconfig/src/fcname.c",
    "fontconfig/src/fcobjs.c",
    "fontconfig/src/fcpat.c",
    "fontconfig/src/fcptrlist.c",
    "fontconfig/src/fcrange.c",
    "fontconfig/src/fcserialize.c",
    "fontconfig/src/fcstat.c",
    "fontconfig/src/fcstr.c",
    "fontconfig/src/fcweight.c",
    "fontconfig/src/fcxml.c",
    "fontconfig/src/ftglue.c",
};

const expat_sources = &[_][]const u8{
    "libexpat/expat/lib/xmlparse.c",
    "libexpat/expat/lib/xmlrole.c",
    "libexpat/expat/lib/xmltok.c",
    "libexpat/expat/lib/xmltok_impl.c",
    "libexpat/expat/lib/xmltok_ns.c",
};

const Platform = struct {
    linux: bool = false,
    macos: bool = false,
    windows_msvc: bool = false,
    windows_gnu: bool = false,

    const true_unix: Platform = .{
        .linux = true,
        .macos = true,
    };

    const unix: Platform = .{
        .linux = true,
        .macos = true,
        .windows_gnu = true,
    };

    const windows: Platform = .{
        .windows_msvc = true,
        .windows_gnu = true,
    };

    const all: Platform = .{
        .linux = true,
        .macos = true,
        .windows_msvc = true,
        .windows_gnu = true,
    };
};

const PlatformMacro = std.meta.Tuple(&.{ []const u8, Platform });

const have_macros = [_]PlatformMacro{
    // headers
    .{ "HAVE_DIRENT_H", Platform.unix },
    .{ "HAVE_FCNTL_H", Platform.unix },
    .{ "HAVE_STDLIB_H", Platform.all },
    .{ "HAVE_STRING_H", Platform.all },
    .{ "HAVE_UNISTD_H", Platform.unix },
    .{ "HAVE_SYS_STATVFS_H", Platform.true_unix },
    .{ "HAVE_SYS_VFS_H", .{ .linux = true } },
    .{ "HAVE_SYS_STATFS_H", .{ .linux = true } },
    .{ "HAVE_SYS_PARAM_H", Platform.unix },
    .{ "HAVE_SYS_MOUNT_H", Platform.true_unix },

    // functions
    .{ "HAVE_LINK", Platform.true_unix },
    .{ "HAVE_MKSTEMP", Platform.unix },
    .{ "HAVE_MKOSTEMP", Platform.true_unix },
    .{ "HAVE__MKTEMP_S", Platform.windows },
    .{ "HAVE_MKDTEMP", Platform.true_unix },
    .{ "HAVE_GETOPT", Platform.unix },
    .{ "HAVE_GETOPT_LONG", .{ .linux = true, .windows_gnu = true } },
    .{ "HAVE_GETPROGNAME", .{ .macos = true } },
    .{ "HAVE_GETEXECNAME", .{} },
    .{ "HAVE_RAND", Platform.all },
    .{ "HAVE_RANDOM", Platform.true_unix },
    .{ "HAVE_LRAND48", Platform.true_unix },
    .{ "HAVE_RANDOM_R", .{ .linux = true } },
    .{ "HAVE_RAND_R", Platform.true_unix },
    .{ "HAVE_READLINK", Platform.true_unix },
    .{ "HAVE_FSTATVFS", Platform.true_unix },
    .{ "HAVE_FSTATFS", .{ .linux = true } },
    .{ "HAVE_LSTAT", Platform.true_unix },
    .{ "HAVE_MMAP", Platform.true_unix },
    .{ "HAVE_VPRINTF", Platform.all },
    .{ "HAVE_POSIX_FADVISE", .{ .linux = true } },

    // freetype functions
    .{ "HAVE_FT_GET_BDF_PROPERTY", Platform.all },
    .{ "HAVE_FT_GET_PS_FONT_INFO", Platform.all },
    .{ "HAVE_FT_HAS_PS_GLYPH_NAMES", Platform.all },
    .{ "HAVE_FT_GET_X11_FONT_FORMAT", Platform.all },
    .{ "HAVE_FT_DONE_MM_VAR", Platform.all },

    // struct members
    .{ "HAVE_STRUCT_STATVFS_F_BASETYPE", .{} },
    .{ "HAVE_STRUCT_STATVFS_F_FSTYPENAME", .{} },
    .{ "HAVE_STRUCT_STATFS_F_FLAGS", .{ .linux = true } },
    .{ "HAVE_STRUCT_STATFS_F_FSTYPENAME", .{} },
    .{ "HAVE_STRUCT_DIRENT_D_TYPE", Platform.true_unix },
};

fn defineHaveMacros(lib: *std.build.LibExeObjStep) !void {
    for (have_macros) |macro| {
        const name = macro[0];
        const plat = macro[1];

        const exists = switch (lib.target.getOsTag()) {
            .linux => plat.linux,
            .macos => plat.macos,
            .windows => switch (lib.target.getAbi()) {
                .msvc => plat.windows_msvc,
                .gnu => plat.windows_gnu,
                else => return error.UnsupportedAbi,
            },
            else => return error.UnsupportedOs,
        };

        if (exists) {
            lib.defineCMacro(name, "1");
        }
    }
}

fn defineSizesAligns(b: *std.build.Builder, lib: *std.build.LibExeObjStep) !void {
    const ptr_size = @divExact(lib.target.getCpuArch().ptrBitWidth(), 8);
    const ptr_size_str = try std.fmt.allocPrint(b.allocator, "{}", .{ptr_size});
    lib.defineCMacro("SIZEOF_VOID_P", ptr_size_str);
    lib.defineCMacro("ALIGNOF_VOID_P", ptr_size_str);
    lib.defineCMacro("ALIGNOF_DOUBLE", "8"); // there's no reasonable platform that uses 32-bit double
}

const linux_default_fonts: []const u8 =
    "\\t<dir>/usr/share/fonts</dir>\\n" ++
    "\\t<dir>/usr/local/share/fonts</dir>\\n";

const macos_default_fonts: []const u8 =
    "\\t<dir>/System/Library/Fonts</dir>\\n" ++
    "\\t<dir>/Library/Fonts</dir>\\n" ++
    "\\t<dir>~/Library/Fonts</dir>\\n" ++
    "\\t<dir>/System/Library/Assets/com_apple_MobileAsset_Font3</dir>\\n" ++
    "\\t<dir>/System/Library/Assets/com_apple_MobileAsset_Font4</dir>\\n";

const windows_default_fonts: []const u8 =
    "\\t<dir>WINDOWSFONTDIR</dir>\\n" ++
    "\\t<dir>WINDOWSUSERFONTDIR</dir>\\n";

fn defineConfigMacros(lib: *std.build.LibExeObjStep) !void {
    lib.defineCMacro("FC_GPERF_SIZE_T", "size_t");
    lib.defineCMacro("FC_FONTPATH", "");

    switch (lib.target.getOsTag()) {
        .linux => {
            lib.defineCMacro("FONTCONFIG_PATH", "\"/etc/fonts\"");
            lib.defineCMacro("CONFIGDIR", "\"/etc/fonts/conf.d\"");
            lib.defineCMacro("FC_TEMPLATEDIR", "\"/usr/share/fontconfig/conf.avail\"");
            lib.defineCMacro("FC_CACHEDIR", "\"/var/cache/fontconfig\"");
            lib.defineCMacro("FC_DEFAULT_FONTS", "\"" ++ linux_default_fonts ++ "\"");
        },
        .macos => {
            lib.defineCMacro("FONTCONFIG_PATH", "\"/usr/local/etc/fonts\"");
            lib.defineCMacro("CONFIGDIR", "\"/usr/local/etc/fonts/conf.d\"");
            lib.defineCMacro("FC_TEMPLATEDIR", "\"/usr/local/share/fontconfig/conf.avail\"");
            lib.defineCMacro("FC_CACHEDIR", "\"/usr/local/var/cache/fontconfig\"");
            lib.defineCMacro("FC_DEFAULT_FONTS", "\"" ++ macos_default_fonts ++ "\"");
        },
        .windows => {
            // Because fontconfig isn't normally used on Windows, there aren't really
            // global configs around, nor a defined location to put them. We'll just
            // put them in the program's working directory for now
            lib.defineCMacro("FONTCONFIG_PATH", "\"./.fonts\"");
            lib.defineCMacro("CONFIGDIR", "\"./.fonts/conf.d\"");
            lib.defineCMacro("FC_TEMPLATEDIR", "\"./.fonts/conf.avail\"");
            lib.defineCMacro("FC_CACHEDIR", "\"LOCAL_APPDATA_FONTCONFIG_CACHE\"");
            lib.defineCMacro("FC_DEFAULT_FONTS", "\"" ++ windows_default_fonts ++ "\"");
        },
        else => return error.UnsupportedOs,
    }
}

fn linkExpat(lib: *std.build.LibExeObjStep) void {
    if (lib.target.getOsTag() != .windows) {
        lib.defineCMacro("XML_DEV_URANDOM", "1");
    }

    lib.addCSourceFiles(expat_sources, &.{});
    lib.addIncludePath("libexpat/expat/lib");
}

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    const lib = b.addStaticLibrary("zig-fontconfig", "src/main.zig");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkLibC();
    freetype.link(b, lib, .{});
    linkExpat(lib);

    lib.defineCMacro("FLEXIBLE_ARRAY_MEMBER", ""); // We target C99 so always have FAMs
    lib.defineCMacro("HAVE_CONFIG_H", "1");
    try defineHaveMacros(lib);
    try defineSizesAligns(b, lib);
    try defineConfigMacros(lib);

    lib.addCSourceFiles(sources, &.{});
    lib.addIncludePath("generated");
    lib.addIncludePath("generated/src");
    lib.addIncludePath("fontconfig");
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
