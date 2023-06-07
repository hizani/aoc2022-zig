const std = @import("std");

const Knot = struct {
    x: isize,
    y: isize,
};

fn Bridge(comptime size: usize) type {
    return struct {
        const Self = @This();
        grid: [size * size]u1 = [_]u1{0} ** (size * size),

        fn proceedSteps(self: *Self, knots: []Knot, direction: [2]i3, steps: usize) !void {
            var step: usize = 0;
            while (step < steps) : (step += 1) {
                knots[0].x += direction[0];
                knots[0].y += direction[1];

                for (knots[1..]) |value, i| {
                    const delta_x = value.x - knots[i].x;
                    const delta_y = value.y - knots[i].y;
                    if (try std.math.absInt(delta_x) > 1 or try std.math.absInt(delta_y) > 1) {
                        knots[i + 1].x += -(@intCast(i3, @boolToInt(delta_x > 0)) - @intCast(i3, @boolToInt(delta_x < 0)));
                        knots[i + 1].y += -(@intCast(i3, @boolToInt(delta_y > 0)) - @intCast(i3, @boolToInt(delta_y < 0)));
                    }
                }
                const tail_x = @intCast(usize, knots[knots.len - 1].x);
                const tail_y = @intCast(usize, knots[knots.len - 1].y);
                self.grid[tail_x + size * tail_y] = 1;
            }
        }

        fn countFootprints(self: *Self) usize {
            var counter: usize = 0;
            for (self.grid) |value|
                counter += value;
            return counter;
        }
    };
}

pub fn main() !void {
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();
    const N = 1024;
    var bridge1 = Bridge(N){};
    var bridge2 = Bridge(N){};
    var head_tail = [_]Knot{.{ .x = N / 2, .y = N / 2 }} ** 2;
    var head_10_tails = [_]Knot{.{ .x = N / 2, .y = N / 2 }} ** 10;

    var buf: [6]u8 = undefined;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len < 3) return error.BadInput;
        const direction: [2]i3 = blk: {
            switch (line[0]) {
                'L' => break :blk .{ -1, 0 },
                'R' => break :blk .{ 1, 0 },
                'U' => break :blk .{ 0, -1 },
                'D' => break :blk .{ 0, 1 },
                else => return error.BadInput,
            }
        };
        const steps = try std.fmt.parseInt(usize, line[2..], 10);
        try bridge1.proceedSteps(&head_tail, direction, steps);
        try bridge2.proceedSteps(&head_10_tails, direction, steps);
    }

    try stdout.print("part1:\t{d}\n", .{bridge1.countFootprints()});
    try stdout.print("part2:\t{d}\n", .{bridge2.countFootprints()});
}
