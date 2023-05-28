const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Action = [3]u32;

const Stacks = struct {
    stacks: ArrayList(ArrayList(u8)),

    fn doAction1(self: *Stacks, action: Action) !void {
        const count = action[0];
        var counter: u32 = 0;
        while (counter < count) : (counter += 1) {
            const crate = self.stacks.items[action[1] - 1]
                .popOrNull() orelse return error.NotEnoughToMove;
            try self.stacks.items[action[2] - 1].append(crate);
        }
    }

    fn doAction2(self: *Stacks, action: Action) !void {
        const count = action[0];
        const from_slice = self.stacks.items[action[1] - 1].items;
        if (from_slice.len < count) return error.NotEnoughToMove;
        try self.stacks.items[action[2] - 1].appendSlice(from_slice[from_slice.len - count ..]);
        self.stacks.items[action[1] - 1]
            .shrinkRetainingCapacity(self.stacks.items[action[1] - 1].items.len - count);
    }

    fn writeTop(self: *Stacks, writer: anytype) !void {
        for (self.stacks.items) |stack| {
            if (stack.items.len == 0) continue;
            const crate = stack.items[stack.items.len - 1];
            try writer.writeByte(crate);
        }
    }

    fn clone(self: *Stacks) Allocator.Error!Stacks {
        var stacks = try ArrayList(ArrayList(u8))
            .initCapacity(self.stacks.allocator, self.stacks.items.len);
        for (self.stacks.items) |stack| {
            var old_stack = stack;
            var cloned_stack = try old_stack.clone();
            try stacks.append(cloned_stack);
        }
        return Stacks{ .stacks = stacks };
    }
};

fn parseStacks(allocator: Allocator, reader: anytype) !Stacks {
    var buf: [1024]u8 = undefined;
    var stacks = try ArrayList(ArrayList(u8)).initCapacity(allocator, 9);
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) return error.BadInput;
        if (!std.mem.containsAtLeast(u8, line, 1, "[")) break;

        var i: usize = 0;
        while (i < line.len) : (i += 4) {
            if (line[i + 1] == ' ') continue;
            const stack_idx = i / 4;
            while (stacks.items.len < stack_idx + 1) {
                try stacks.append(try ArrayList(u8).initCapacity(allocator, stacks.items.len + 8));
            }
            try stacks.items[stack_idx].append(line[i + 1]);
        }
    }
    for (stacks.items) |stack| {
        std.mem.reverse(u8, stack.items);
    }
    return Stacks{ .stacks = stacks };
}

fn parseAction(line: []const u8) !Action {
    var input = line;
    var action: Action = undefined;

    _ = std.mem.indexOf(u8, input, "move ") orelse return error.NoMove;
    input = input[5..];
    const count_end = std.mem.indexOf(u8, input, " from ") orelse return error.NoFrom;
    const count_string = input[0..count_end];
    input = input[count_end + 6 ..];
    const from_end = std.mem.indexOf(u8, input, " to ") orelse return error.NoTo;
    const from_string = input[0..from_end];
    const to_string = input[from_end + 4 ..];

    action[0] = try std.fmt.parseInt(u32, count_string, 10);
    action[1] = try std.fmt.parseInt(u32, from_string, 10);
    action[2] = try std.fmt.parseInt(u32, to_string, 10);
    return action;
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [1024]u8 = undefined;

    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();
    var stacks1 = try parseStacks(alloc.allocator(), stdin);
    var stacks2 = try stacks1.clone();
    _ = try stdin.readUntilDelimiterOrEof(&buf, '\n');

    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) return error.BadInput;
        const action = try parseAction(line);
        try stacks1.doAction1(action);
        try stacks2.doAction2(action);
    }

    _ = try stdout.write("part1: ");
    try stacks1.writeTop(stdout);
    _ = try stdout.write("\n");

    _ = try stdout.write("part2: ");
    try stacks2.writeTop(stdout);
    _ = try stdout.write("\n");
}
