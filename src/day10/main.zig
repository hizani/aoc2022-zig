const std = @import("std");

fn VDevice(comptime Writer: type, comptime sig_checkpoints: anytype, comptime row_len: usize) type {
    const checkpoints_type = @TypeOf(sig_checkpoints);
    const checkpoints_info = @typeInfo(checkpoints_type);
    if (checkpoints_info != .Array)
        @compileError("expected Array, found " ++ @typeName(checkpoints_type));

    const array_info = checkpoints_info.Array;
    if (array_info.len < 1) @compileError("expected at least 1 checkpoint, found 0");
    const T = array_info.child;
    if (@typeInfo(T) != .Int) @compileError("expected checkpoint to be int, found " ++ @typeName(T));
    comptime var checkpoints: [array_info.len]T = undefined;
    comptime var last: T = std.math.minInt(T);
    for (sig_checkpoints) |value, i| {
        if (last >= value) @compileError("checkpoints must be ordered and unique");
        checkpoints[i] = value;
        last = value;
    }

    return struct {
        const Self = @This();
        const WriteError = std.os.WriteError;
        const DoCycleFunc = *const fn (self: *Self) WriteError!isize;

        x_reg: isize = 1,
        cycle_counter: usize = 1,
        writer: Writer = undefined,
        sig_checkpoints: [array_info.len]T = checkpoints,
        checkpoints_slice: []const T = &sig_checkpoints,
        sprite: [row_len + 10]u8 = [3]u8{ '#', '#', '#' } ++ [_]u8{'.'} ** (row_len + 7),
        do_cycle: DoCycleFunc = Self.doCycleWithCheckpoints,

        pub fn init(writer: Writer) Self {
            return Self{ .writer = writer };
        }

        pub fn doCmd(self: *Self, line: []u8) !isize {
            var result = try self.do_cycle(self);
            if (std.mem.eql(u8, line[0..4], "noop")) {
                self.cycle_counter += 1;
                return result;
            }
            if (std.mem.eql(u8, line[0..4], "addx")) {
                if (line.len < 6) return error.BadInput;
                self.cycle_counter += 1;
                result += try self.do_cycle(self);
                const value = try std.fmt.parseInt(i32, line[5..], 10);
                self.x_reg += value;
                self.cycle_counter += 1;
                self.rewriteSprite();
                return result;
            }
            return error.BadInput;
        }

        fn rewriteSprite(self: *Self) void {
            var i: usize = 0;
            var delta: isize = 0;
            if (self.x_reg < 1) delta = 1 + self.x_reg;
            while (i < self.x_reg - (1 - delta)) : (i += 1) self.sprite[i] = '.';
            while (i < self.x_reg + (2 - delta)) : (i += 1) self.sprite[i] = '#';
            while (i < self.sprite.len) : (i += 1) self.sprite[i] = '.';
        }

        fn doCycleWithCheckpoints(self: *Self) WriteError!isize {
            try self.write();
            if (self.isOnCheckpoint()) {
                if (self.checkpoints_slice[0] == self.sig_checkpoints[self.sig_checkpoints.len - 1]) {
                    self.do_cycle = Self.doCycle;
                    return self.x_reg * @intCast(isize, self.cycle_counter);
                }
                self.checkpoints_slice = self.checkpoints_slice[1..];
                return self.x_reg * @intCast(isize, self.cycle_counter);
            }
            return 0;
        }

        fn doCycle(self: *Self) WriteError!isize {
            try self.write();
            return 0;
        }

        fn write(self: *Self) WriteError!void {
            const pos = (self.cycle_counter - 1) % row_len;
            if (pos == 0) try self.writer.writeByte('\n');
            const char = self.sprite[pos];
            try self.writer.writeByte(char);
        }

        fn isOnCheckpoint(self: *Self) bool {
            return self.cycle_counter == self.checkpoints_slice[0];
        }
    };
}

pub fn main() !void {
    var stdin = std.io.getStdIn().reader();
    var stdout = std.io.getStdOut().writer();
    const checkpoints = [_]u16{ 20, 60, 100, 140, 180, 220 };
    var vd = VDevice(@TypeOf(stdout), checkpoints, 40).init(stdout);

    var sig_strength_sum: isize = 0;
    var buf: [14]u8 = undefined;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        sig_strength_sum += try vd.doCmd(line);
    }

    try stdout.print("\npart1:\t{d}\n", .{sig_strength_sum});
    try stdout.print("part2:\t{s}\n", .{"above"});
}
