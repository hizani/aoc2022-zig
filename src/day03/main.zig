const std = @import("std");

fn calclulatePriority(char: u8) !u8 {
    return switch (char) {
        'a'...'z' => char - 'a' + 1,
        'A'...'Z' => char - 'A' + 27,
        else => error.NotChar,
    };
}

fn findIntersection(comptime T: type, args: anytype) ?T {
    const ArgsType = @TypeOf(args);
    const args_type_info = @typeInfo(ArgsType);

    const SIZE = std.math.maxInt(T);
    const count_array = switch (args_type_info) {
        .Struct => blk: {
            const fields_info = args_type_info.Struct.fields;
            if (fields_info.len < 2) {
                @compileError("two or more fields expected, found " ++ fields_info.len);
            }
            var count_array = [_][SIZE]u16{[_]u16{0} ** SIZE} ** fields_info.len;
            inline for (fields_info) |field, i| {
                const arg_type_info = @typeInfo(field.field_type);
                if (arg_type_info != .Array) {
                    if (arg_type_info != .Pointer or arg_type_info.Pointer.size != std.builtin.Type.Pointer.Size.Slice) {
                        @compileError("expected tuple, struct or 2d array of iteratable elements, found " ++ @typeName(ArgsType));
                    }
                }
                for (@field(args, field.name)) |value| {
                    count_array[i][value] += 1;
                }
            }
            break :blk count_array;
        },
        .Array => blk: {
            if (args.len < 2) {
                @compileError("two or more elements expected, found " ++ args.len);
            }
            const arg_type_info = @typeInfo((@TypeOf(args[0])));
            if (arg_type_info != .Array) {
                if (arg_type_info != .Pointer or arg_type_info.Pointer.size != std.builtin.Type.Pointer.Size.Slice) {
                    @compileError("expected tuple, struct or 2d array of iteratable elements, found " ++ @typeName(ArgsType));
                }
            }

            var count_array = [_][SIZE]u16{[_]u16{0} ** SIZE} ** args.len;
            inline for (args) |arg, i| {
                for (arg) |value| {
                    count_array[i][value] += 1;
                }
            }
            break :blk count_array;
        },
        else => @compileError("expected tuple, struct or 2d array of iteratable elements, found " ++ @typeName(ArgsType)),
    };
    comptime var element_idx: T = 0;
    inline while (element_idx < SIZE) : (element_idx += 1) {
        var min: u16 = std.math.maxInt(u16);
        for (count_array) |_, set_idx|
            min = @min(min, count_array[set_idx][element_idx]);
        if (min > 0) return element_idx;
    }
    return null;
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var buf: [50]u8 = undefined;

    const GROUP_SIZE = 3;
    var elfGroupBuf: [GROUP_SIZE][50]u8 = undefined;
    var elfGroup: [GROUP_SIZE][]u8 = undefined;
    var group_member: u8 = 0;
    var priority1: u32 = 0;
    var priority2: u32 = 0;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) return error.BadInput;
        //part1
        const mid = line.len / 2;
        var char = findIntersection(u8, .{ line[0..mid], line[mid..] }) orelse 0;
        priority1 += try calclulatePriority(char);
        //part2
        std.mem.copy(u8, &elfGroupBuf[group_member], line[0..]);
        elfGroup[group_member] = elfGroupBuf[group_member][0..line.len];
        group_member += 1;
        if (group_member > GROUP_SIZE - 1) {
            char = findIntersection(u8, elfGroup) orelse 0;
            priority2 += try calclulatePriority(char);
            group_member = 0;
        }
    }

    try stdout.print("part1: {d}\n", .{priority1});
    try stdout.print("part2: {d}\n", .{priority2});
}
