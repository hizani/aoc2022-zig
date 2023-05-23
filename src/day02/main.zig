const std = @import("std");

// draw, win, defeat, rock, paper, scissors
const scores = [_]u32{ 3, 6, 0, 1, 2, 3 };

fn playP1(opponent: u8, player: u8) u32 {
    const o = opponent - 'A';
    const p = player - 'X' + 3;
    return scores[(p - o) % 3] + scores[p];
}

fn playP2(opponent: u8, intention: u8) u32 {
    const o = opponent - 'A';
    const i = intention - 'X';
    const p = (o + i + 2) % 3 + 3;
    return i * 3 + scores[p];
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [4]u8 = undefined;

    var score1: u32 = 0;
    var score2: u32 = 0;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len < 3) return error.BadInput;
        score1 += playP1(line[0], line[2]);
        score2 += playP2(line[0], line[2]);
    }

    try stdout.print("part1: {d}\n", .{score1});
    try stdout.print("part2: {d}\n", .{score2});
}
