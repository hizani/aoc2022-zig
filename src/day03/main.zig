const std = @import("std");

fn charNumber(char: u8) !u8 {
    return switch (char) {
        'a'...'z' => char - 'a',
        'A'...'Z' => char - 'A' + 26,
        else => error.NotChar,
    };
}

fn findIntersection(args: anytype) !?u8 {
    const ArgsType = @TypeOf(args);
    const args_type_info = @typeInfo(ArgsType);

    const CHAR_COUNT = 54;
    const count_array = switch (args_type_info) {
        .Struct => blk: {
            const fields_info = args_type_info.Struct.fields;
            if (fields_info.len < 2) {
                @compileError("two or more fields expected, found " ++ fields_info.len);
            }
            const arg_type_info = @typeInfo(fields_info[0].field_type);
            if (arg_type_info != .Pointer and arg_type_info != .Array) {
                @compileError("expected tuple, struct or matrix, found " ++ @typeName(ArgsType));
            }
            var count_array = [_][CHAR_COUNT]u16{[_]u16{0} ** CHAR_COUNT} ** fields_info.len;
            inline for (fields_info) |field, i| {
                for (@field(args, field.name)) |value| {
                    const char = try charNumber(value);
                    count_array[i][char] += 1;
                }
            }
            break :blk count_array;
        },
        .Array => blk: {
            if (args.len < 2) {
                @compileError("two or more elements expected, found " ++ args.len);
            }
            const arg_type_info = @typeInfo((@TypeOf(args[0])));
            if (arg_type_info != .Pointer and arg_type_info != .Array) {
                @compileError("expected tuple, struct or matrix, found " ++ @typeName(ArgsType));
            }

            var count_array = [_][CHAR_COUNT]u16{[_]u16{0} ** CHAR_COUNT} ** args.len;
            inline for (args) |arg, i| {
                for (arg) |value| {
                    const char = try charNumber(value);
                    count_array[i][char] += 1;
                }
            }
            break :blk count_array;
        },
        else => @compileError("expected tuple, struct or matrix, found " ++ @typeName(ArgsType)),
    };
    comptime var char_idx: u8 = 0;
    inline while (char_idx < CHAR_COUNT) : (char_idx += 1) {
        var min: u16 = std.math.maxInt(u16);
        inline for (count_array) |_, set_idx|
            min = @min(min, count_array[set_idx][char_idx]);
        if (min > 0) return char_idx + 1;
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
        priority1 += try findIntersection(.{ line[0..mid], line[mid..] }) orelse 0;
        //part2
        std.mem.copy(u8, &elfGroupBuf[group_member], line[0..]);
        elfGroup[group_member] = elfGroupBuf[group_member][0..line.len];
        group_member += 1;
        if (group_member > GROUP_SIZE - 1) {
            priority2 += try findIntersection(elfGroup) orelse 0;
            group_member = 0;
        }
    }

    try stdout.print("part1: {d}\n", .{priority1});
    try stdout.print("part2: {d}\n", .{priority2});
}
