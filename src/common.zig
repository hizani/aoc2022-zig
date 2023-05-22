pub fn parseNumber(comptime T: type, buf: []const u8) !T {
    var result: T = 0;
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
