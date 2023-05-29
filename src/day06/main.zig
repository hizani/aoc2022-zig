const std = @import("std");

fn isStart(buf: []?u8) bool {
    if (buf[0] == null) return false;
    for (buf) |byte, i| {
        var j = i;
        while (j > 0) {
            j -= 1;
            if (byte == buf[j]) return false;
        }
    }
    return true;
}

fn pushNext(comptime T: type, dest: []T, value: T) void {
    var idx: usize = 1;
    for (dest[1..]) |v| {
        dest[idx - 1] = v;
        idx += 1;
    }
    dest[dest.len - 1] = value;
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf = [_]?u8{null} ** 14;
    var part1: ?usize = null;
    var part2: ?usize = null;

    var counter: usize = 0;
    while (stdin.readByte()) |byte| {
        counter += 1;
        pushNext(?u8, &buf, byte);
        if (isStart(buf[buf.len - 4 ..]) and part1 == null) {
            part1 = counter;
            if (part2 != null) break;
        }
        if (isStart(&buf) and part2 == null) {
            part2 = counter;
            if (part1 != null) break;
        }
    } else |err| {
        return err;
    }
    try stdout.print("part1: {d}\n", .{part1.?});
    try stdout.print("part2: {d}\n", .{part2.?});
}
