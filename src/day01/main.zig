const std = @import("std");
const io = std.io;

const Elf = struct {
    number: u32 = 0,
    calories: u32 = 0,
};

fn parseU32FromString(buf: []const u8) !u32 {
    var result: u32 = 0;

    for (buf) |c| {
        const digit = switch (c) {
            '0'...'9' => c - '0',
            else => return error.InvalidChar,
        };

        if (@mulWithOverflow(u32, result, 10, &result))
            return error.Overflow;

        if (@addWithOverflow(u32, result, digit, &result))
            return error.Overflow;
    }

    return result;
}

fn insertTopElf(top_elfs: []Elf, candidate: Elf, position: usize) void {
    if (position != 0)
        insertTopElf(top_elfs, top_elfs[position], position - 1);
    top_elfs[position] = candidate;
}

fn insertIfTopElf(top_elfs: []Elf, candidate: Elf) void {
    for (top_elfs) |member, i| {
        if (candidate.calories > member.calories) {
            if (i != top_elfs.len - 1)
                continue;

            insertTopElf(top_elfs, candidate, i);
            return;
        }

        if (i != 0) {
            insertTopElf(top_elfs, candidate, i - 1);
        }
        return;
    }
}

const TOP_ELFS_NUM = 3;

pub fn main() !void {
    var top_elfs: [TOP_ELFS_NUM]Elf = .{Elf{}} ** TOP_ELFS_NUM;

    var stdio_reader = io.getStdIn().reader();
    var buf: [10]u8 = undefined;

    var current_elf = Elf{};
    while (try stdio_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            insertIfTopElf(top_elfs[0..], current_elf);
            current_elf.number += 1;
            current_elf.calories = 0;
            continue;
        }
        current_elf.calories += try parseU32FromString(line);
    }

    var most_calories_acc: u32 = 0;
    for (top_elfs) |num| {
        std.debug.print("{d}, {d}\n", .{ num.number, num.calories });
        most_calories_acc += num.calories;
    }

    std.debug.print("part 1: the most amount of calories: {d}\n", .{top_elfs[TOP_ELFS_NUM - 1].calories});
    std.debug.print("part 2: sum of the most 3 amounts of calories: {d}\n", .{most_calories_acc});
}
