const std = @import("std");

pub fn pkg(comptime freetype: anytype) std.build.Pkg {
    return .{
        .name = "fontconfig",
        .source = .{ .path = comptime thisDir() ++ "/src/main.zig" },
        .dependencies = comptime &.{freetype.pkg},
    };
}

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep) void {
    linkExpat(step);

    step.defineCMacro("FLEXIBLE_ARRAY_MEMBER", ""); // We target C99 so always have FAMs
    step.defineCMacro("HAVE_CONFIG_H", "1");

    defineHaveMacros(step) catch unreachable;
    defineSizesAligns(b, step) catch unreachable;
    defineConfigMacros(step) catch unreachable;

    step.addCSourceFiles(sources, cflags);
    step.addIncludePath(comptime thisDir() ++ "/generated");
    step.addIncludePath(comptime thisDir() ++ "/generated/src");
    step.addIncludePath(comptime thisDir() ++ "/fontconfig");
}

fn linkExpat(lib: *std.build.LibExeObjStep) void {
    if (lib.target.getOsTag() != .windows) {
        lib.defineCMacro("XML_DEV_URANDOM", "1");
    }

    lib.addCSourceFiles(expat_sources, cflags);
    lib.addIncludePath(comptime thisDir() ++ "/libexpat/expat/lib");
}

const fc_root = thisDir() ++ "/fontconfig";
const expat_root = thisDir() ++ "/libexpat";

const sources = &[_][]const u8{
    fc_root ++ "/src/fcatomic.c",
    fc_root ++ "/src/fccache.c",
    fc_root ++ "/src/fccfg.c",
    fc_root ++ "/src/fccharset.c",
    fc_root ++ "/src/fccompat.c",
    fc_root ++ "/src/fcdbg.c",
    fc_root ++ "/src/fcdefault.c",
    fc_root ++ "/src/fcdir.c",
    fc_root ++ "/src/fcformat.c",
    fc_root ++ "/src/fcfreetype.c",
    fc_root ++ "/src/fcfs.c",
    fc_root ++ "/src/fchash.c",
    fc_root ++ "/src/fcinit.c",
    fc_root ++ "/src/fclang.c",
    fc_root ++ "/src/fclist.c",
    fc_root ++ "/src/fcmatch.c",
    fc_root ++ "/src/fcmatrix.c",
    fc_root ++ "/src/fcname.c",
    fc_root ++ "/src/fcobjs.c",
    fc_root ++ "/src/fcpat.c",
    fc_root ++ "/src/fcptrlist.c",
    fc_root ++ "/src/fcrange.c",
    fc_root ++ "/src/fcserialize.c",
    fc_root ++ "/src/fcstat.c",
    fc_root ++ "/src/fcstr.c",
    fc_root ++ "/src/fcweight.c",
    fc_root ++ "/src/fcxml.c",
    fc_root ++ "/src/ftglue.c",
};

const expat_sources = &[_][]const u8{
    expat_root ++ "/expat/lib/xmlparse.c",
    expat_root ++ "/expat/lib/xmlrole.c",
    expat_root ++ "/expat/lib/xmltok.c",
    expat_root ++ "/expat/lib/xmltok_impl.c",
    expat_root ++ "/expat/lib/xmltok_ns.c",
};

// There are two issues that mean we need to use these flags. Firstly, there's some UB
// somewhere in fontconfig that I haven't tracked down, so ubsan sometimes hits an
// illegal instruction - but with LTO, we can't disable ubsan just for these comp units,
// so we need to disable LTO. Also, there's currently a bug in mingw-w64 which causes
// rand_s to not be exposed in LTO builds (a patch has been submitted to upstream).
const cflags = &[_][]const u8{
    "-fno-lto",
    "-fno-sanitize=undefined",
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
    "<dir>/usr/share/fonts</dir>" ++
    "<dir>/usr/local/share/fonts</dir>";

const macos_default_fonts: []const u8 =
    "<dir>/System/Library/Fonts</dir>" ++
    "<dir>/Library/Fonts</dir>" ++
    "<dir>~/Library/Fonts</dir>" ++
    "<dir>/System/Library/Assets/com_apple_MobileAsset_Font3</dir>" ++
    "<dir>/System/Library/Assets/com_apple_MobileAsset_Font4</dir>";

const windows_default_fonts: []const u8 =
    "<dir>WINDOWSFONTDIR</dir>" ++
    "<dir>WINDOWSUSERFONTDIR</dir>";

fn defineConfigMacros(lib: *std.build.LibExeObjStep) !void {
    lib.defineCMacro("FC_GPERF_SIZE_T", "size_t");
    lib.defineCMacro("FC_FONTPATH", "");
    lib.defineCMacro("_GNU_SOURCE", "");
    lib.defineCMacro("GETTEXT_PACKAGE", "\"fontconfig\"");

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

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
