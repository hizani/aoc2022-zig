const std = @import("std");

fn parseRanges(line: []u8, ranges: *[4]u8) !void {
    var start: usize = 0;
    var range_idx: usize = 0;
    for (line) |char, i| {
        if (char == ',') {
            ranges[range_idx] = try std.fmt.parseInt(u8, line[start..i], 10);
            range_idx += 1;
            start = i + 1;
            continue;
        }
        if (char == '-') {
            ranges[range_idx] = try std.fmt.parseInt(u8, line[start..i], 10);
            range_idx += 1;
            start = i + 1;
        }
        if (range_idx == ranges.len - 1) {
            ranges[range_idx] = try std.fmt.parseInt(u8, line[start..], 10);
            return;
        }
    }
}
fn isSubset(range1: []u8, range2: []u8) bool {
    if (range1[0] <= range2[0] and range1[1] >= range2[1]) return true;
    if (range1[0] >= range2[0] and range1[1] <= range2[1]) return true;
    return false;
}

fn isOverlap(range1: []u8, range2: []u8) bool {
    return !(range1[1] < range2[0] or range1[0] > range2[1]);
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [32]u8 = undefined;

    var ranges = [_]u8{ 0, 0, 0, 0 };
    var sum1: u32 = 0;
    var sum2: u32 = 0;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) return error.BadInput;
        try parseRanges(line, &ranges);
        if (isSubset(ranges[0..2], ranges[2..])) sum1 += 1;
        if (isOverlap(ranges[0..2], ranges[2..])) sum2 += 1;
    }

    try stdout.print("part1: {d}\n", .{sum1});
    try stdout.print("part2: {d}\n", .{sum2});
}
