const std = @import("std");
const ArrayList = std.ArrayList;

const Map = struct {
    trees: []u8,
    rows: usize,
    cols: usize,

    inline fn getTreeScore(self: *const Map, tree_row: usize, tree_col: usize) u64 {
        const tree = self.trees[tree_col + self.cols * tree_row];
        var result = @Vector(4, u64){ 0, 0, 0, 0 };

        var check_row: usize = tree_row - 1;
        result[0] = outer: {
            var counter: u64 = 1;
            while (check_row > 0) : (check_row -= 1) {
                if (self.trees[tree_col + self.cols * check_row] >= tree)
                    break :outer counter;
                counter += 1;
            }
            break :outer counter;
        };
        check_row = tree_row + 1;
        result[1] = outer: {
            var counter: u64 = 1;
            while (check_row < self.rows) : (check_row += 1) {
                if (self.trees[tree_col + self.cols * check_row] >= tree)
                    break :outer counter;
                counter += 1;
            }
            break :outer counter;
        };

        var check_col: usize = tree_col - 1;
        result[2] = outer: {
            var counter: u64 = 1;
            while (check_col > 0) : (check_col -= 1) {
                if (self.trees[check_col + self.cols * tree_row] >= tree)
                    break :outer counter + 1;
                counter += 1;
            }
            break :outer counter;
        };
        check_col = tree_col + 1;
        result[3] = outer: {
            var counter: u64 = 0;
            while (check_col < self.cols) : (check_col += 1) {
                if (self.trees[check_col + self.cols * tree_row] >= tree)
                    break :outer counter + 1;
                counter += 1;
            }
            break :outer counter;
        };
        return @reduce(.Mul, result);
    }

    inline fn isVisible(self: *const Map, tree_row: usize, tree_col: usize) bool {
        const tree = self.trees[tree_col + self.cols * tree_row];

        var check_row: usize = 0;
        outer: {
            while (check_row < self.rows - (self.rows - tree_row)) : (check_row += 1)
                if (self.trees[tree_col + self.cols * check_row] >= tree) break :outer;
            return true;
        }
        check_row = tree_row + 1;
        outer: {
            while (check_row < self.rows) : (check_row += 1)
                if (self.trees[tree_col + self.cols * check_row] >= tree) break :outer;
            return true;
        }

        var check_col: usize = 0;
        outer: {
            while (check_col < self.cols - (self.cols - tree_col)) : (check_col += 1)
                if (self.trees[check_col + self.cols * tree_row] >= tree) break :outer;
            return true;
        }
        check_col = tree_col + 1;
        outer: {
            while (check_col < self.cols) : (check_col += 1)
                if (self.trees[check_col + self.cols * tree_row] >= tree) break :outer;
            return true;
        }
        return false;
    }

    fn findMaxScore(self: *const Map) u64 {
        var max_score: u64 = 0;
        var row: usize = 1;
        while (row < self.rows - 1) : (row += 1) {
            var col: usize = 1;
            while (col < self.cols - 1) : (col += 1) {
                const score = self.getTreeScore(row, col);
                if (max_score < score) max_score = score;
            }
        }
        return max_score;
    }

    fn countVisibleTrees(self: *const Map) u64 {
        var result: u64 = self.cols * 2 + (self.rows - 2) * 2;
        var row: usize = 1;
        while (row < self.rows - 1) : (row += 1) {
            var col: usize = 1;
            while (col < self.cols - 1) : (col += 1)
                result += @boolToInt(self.isVisible(row, col));
        }
        return result;
    }
};
pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var trees = try ArrayList(u8).initCapacity(allocator, 99 * 99);

    var buf: [1024]u8 = undefined;
    const cols = blk: {
        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 0) return error.BadInput;
            try trees.appendSlice(line);
            break :blk line.len;
        } else return error.BadInput;
        unreachable;
    };
    var rows: usize = 1;
    while (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (cols != line.len) return error.BadInput;
        rows += 1;
        try trees.appendSlice(line);
    }
    const map = Map{ .trees = trees.items, .rows = rows, .cols = cols };

    //try stdout.print("part1:\t{d}\n", .{map.countVisibleTrees()});
    try stdout.print("part2:\t{d}\n", .{map.findMaxScore()});
}
