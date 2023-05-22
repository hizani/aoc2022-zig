const std = @import("std");
const io = std.io;

const TOP_SIZE = 3;

fn insert(top: []u32, calories: u32) void {
    if (top[0] > calories) return;
    top[0] = calories;
    var i: usize = 0;
    while (i < top.len - 1) : (i += 1) {
        if (top[i] > top[i + 1]) {
            std.mem.swap(u32, &top[i], &top[i + 1]);
            continue;
        }
        return;
    }
}

pub fn main() !void {
    var top: [TOP_SIZE]u32 = .{0} ** TOP_SIZE;
    const stdin = io.getStdIn().reader();
    const stdout = io.getStdOut().writer();
    var current: u32 = 0;
    var buf: [10]u8 = undefined;

    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            insert(&top, current);
            current = 0;
            continue;
        }
        current += try std.fmt.parseInt(u32, line, 10);
    }

    var acc: u32 = 0;
    for (top) |num| acc += num;
    try stdout.print("part 1:\t{}\n", .{top[TOP_SIZE - 1]});
    try stdout.print("part 2:\t{}\n", .{acc});
}
