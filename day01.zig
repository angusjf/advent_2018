const std = @import("std");

fn solve1(input: []const u8) !i32 {
    var lines = std.mem.tokenizeAny(u8, input, "\n ,");

    var f: i32 = 0;

    while (lines.next()) |line| {
        const df = try std.fmt.parseInt(i32, line, 10);

        f += df;
    }

    return f;
}

test solve1 {
    try std.testing.expectEqual(3, try solve1("+1, +1, +1"));
    try std.testing.expectEqual(0, try solve1("+1, +1, -2"));
    try std.testing.expectEqual(-6, try solve1("-1, -2, -3"));
}

fn solve2(gpa: std.mem.Allocator, input: []const u8) !i32 {
    var f: i32 = 0;

    var seen: std.AutoHashMapUnmanaged(i32, void) = .empty;
    defer seen.deinit(gpa);

    try seen.put(gpa, 0, {});

    while (true) {
        var lines = std.mem.tokenizeAny(u8, input, "\n ,");

        while (lines.next()) |line| {
            const df = try std.fmt.parseInt(i32, line, 10);

            f += df;

            const gop = try seen.getOrPut(gpa, f);
            if (gop.found_existing) return f;
        }
    }
}

test solve2 {
    try std.testing.expectEqual(0, try solve2(std.testing.allocator, "+1, -1"));
    try std.testing.expectEqual(10, try solve2(std.testing.allocator, "+3, +3, +4, -2, -4"));
    try std.testing.expectEqual(5, try solve2(std.testing.allocator, "-6, +3, +8, +5, -6"));
    try std.testing.expectEqual(14, try solve2(std.testing.allocator, "+7, +7, -2, -7, -4"));
}

pub fn main() !void {
    const stdout = std.fs.File.stdout();

    var buf: [10]u8 = undefined;

    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

    const gpa = debug_allocator.allocator();

    const len = std.fmt.printInt(&buf, try solve2(gpa, @embedFile("input01.txt")), 10, .lower, .{});

    try stdout.writeAll(buf[0..len]);
}
