const std = @import("std");

const Directory = struct {
    size: u64 = 0,
    parent: ?*Directory,
};

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var dirs_buf: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&dirs_buf);
    const allocator = fba.allocator();
    var dirs = try std.ArrayList(Directory).initCapacity(allocator, 200);

    var buf: [1024]u8 = undefined;
    var current_dir: ?*Directory = null;
    var sum: u64 = 0;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (!std.mem.eql(u8, line[0..2], "$ ")) {
            if (std.mem.eql(u8, line[0..3], "dir")) continue;
            var split = std.mem.split(u8, line, " ");
            const size_string = split.next() orelse return error.BadFile;
            const number =
                try std.fmt.parseInt(u64, size_string, 10);
            current_dir.?.size += number;
            continue;
        }

        if (std.mem.eql(u8, line[2..4], "ls")) continue;
        if (std.mem.eql(u8, line[2..5], "cd ")) {
            const arg = line[5..7];
            if (std.mem.eql(u8, arg, "..")) {
                if (current_dir.?.size <= 100000) sum += current_dir.?.size;
                current_dir.?.parent.?.size += current_dir.?.size;
                current_dir = current_dir.?.parent.?;
                continue;
            }
            try dirs.append(Directory{ .parent = current_dir });
            current_dir = &dirs.items[dirs.items.len - 1];
            continue;
        }
        return error.BadCmd;
    }

    var parent: ?*Directory = current_dir.?.parent;
    while (parent) |p| {
        if (current_dir.?.size <= 100000) sum += current_dir.?.size;
        p.size += current_dir.?.size;
        parent = p.parent;
        current_dir = p;
    }
    var delete_size: u64 = current_dir.?.size;
    const needed_memory = 30000000 - (70000000 - delete_size);
    for (dirs.items[1..]) |dir| {
        if (dir.size >= needed_memory and dir.size < delete_size)
            delete_size = dir.size;
    }

    try stdout.print("part1:\t{d}\n", .{sum});
    try stdout.print("part2:\t{d}\n", .{delete_size});
}
