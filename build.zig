const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const days = 25;
    var paths: [days][18]u8 = undefined;
    var day_names: [days][5]u8 = undefined;
    var descriptions: [days][9]u8 = undefined;

    comptime for (paths) |_, idx| {
        var day = idx + 1;
        const day_name = std.fmt.comptimePrint("day{d}{d}", .{ day / 10, day % 10 });
        const path = std.fmt.comptimePrint("src/{s}/main.zig", .{day_name});
        const description = std.fmt.comptimePrint("Run {s}", .{day_name});

        day_names[idx] = day_name.*;
        paths[idx] = path.*;
        descriptions[idx] = description.*;
    };

    for (paths) |path, idx| {
        const exe = b.addExecutable(&day_names[idx], &path);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.addPackagePath("common", "src/common.zig");
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(&day_names[idx], &descriptions[idx]);
        run_step.dependOn(&run_cmd.step);
    }
}
