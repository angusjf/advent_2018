const std = @import("std");

fn solve1(gpa: std.mem.Allocator, input: []const u8) !usize {
    var str: std.ArrayList(u8) = .fromOwnedSlice(try gpa.dupe(u8, std.mem.trimEnd(u8, input, "\n")));
    defer str.deinit(gpa);
    return try lengthReduced(&str);
}

fn solve2(gpa: std.mem.Allocator, input: []const u8) !usize {
    var min: ?usize = null;

    const trimmed = std.mem.trimEnd(u8, input, "\n");
    for (std.ascii.lowercase, std.ascii.uppercase) |c_lower, c_upper| {
        var str: std.ArrayList(u8) = .fromOwnedSlice(try gpa.dupe(u8, std.mem.trimEnd(u8, trimmed, "\n")));
        defer str.deinit(gpa);

        var sortedIndexes: std.ArrayList(usize) = .empty;
        defer sortedIndexes.deinit(gpa);

        for (0..str.items.len) |i| {
            if (str.items[i] == c_lower or str.items[i] == c_upper) {
                try sortedIndexes.append(gpa, i);
            }
        }

        str.orderedRemoveMany(sortedIndexes.items);

        const len = try lengthReduced(&str);

        min = if (min) |m| @min(m, len) else len;
    }

    return min.?;
}

fn lengthReduced(str: *std.ArrayList(u8)) !usize {
    while (true) {
        var reacted = false;

        for (str.items[0 .. str.items.len - 1], str.items[1..], 0..) |a, b, i| {
            if ((std.ascii.isUpper(a) and std.ascii.toLower(a) == b) or
                (std.ascii.isUpper(b) and std.ascii.toLower(b) == a))
            {
                str.orderedRemoveMany(&[_]usize{ i, i + 1 });
                reacted = true;

                break;
            }
        }

        if (!reacted) return str.items.len;
    }
}

test {
    try std.testing.expectEqual(10, try solve1(std.testing.allocator, "dabAcCaCBAcCcaDA"));
}

test {
    try std.testing.expectEqual(4, try solve2(std.testing.allocator, "dabAcCaCBAcCcaDA"));
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

    const gpa = debug_allocator.allocator();
    std.debug.print("{d}\n", .{try solve2(gpa, @embedFile("input05.txt"))});
}
