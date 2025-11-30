const std = @import("std");

const Point = struct { x: u32, y: u32 };

fn abs_diff(a: u32, b: u32) u32 {
    return if (a > b) a - b else b - a;
}

fn nearest(points: []Point, x: u32, y: u32) ?usize {
    var index: ?usize = null;
    var min_dist: u32 = std.math.maxInt(u32);

    for (points, 0..) |point, i| {
        const dist_x = abs_diff(point.x, x);
        const dist_y = abs_diff(point.y, y);
        const dist = dist_x + dist_y;
        if (dist < min_dist) {
            min_dist = dist;
            index = i;
        } else if (dist == min_dist) {
            index = null;
        }
    }

    return index;
}

fn solve(gpa: std.mem.Allocator, input: []const u8) !u32 {
    var points: std.ArrayList(Point) = .empty;
    defer points.deinit(gpa);

    var numbers = std.mem.tokenizeAny(u8, input, "\n, ");

    while (numbers.next()) |x| {
        const y = numbers.next().?;

        try points.append(gpa, .{
            .x = try std.fmt.parseInt(u32, x, 10),
            .y = try std.fmt.parseInt(u32, y, 10),
        });
    }

    var min_x: u32 = std.math.maxInt(u32);
    var min_y: u32 = std.math.maxInt(u32);
    var max_x: u32 = std.math.minInt(u32);
    var max_y: u32 = std.math.minInt(u32);

    for (points.items) |point| {
        min_x = @min(min_x, point.x);
        min_y = @min(min_y, point.y);
        max_x = @max(max_x, point.x);
        max_y = @max(max_y, point.y);
    }
    min_x -= 1;
    min_y -= 1;
    max_x += 1;
    max_y += 1;

    var nearest_points: std.AutoHashMapUnmanaged(usize, u32) = .empty;
    defer nearest_points.deinit(gpa);
    var infinite: std.AutoHashMapUnmanaged(usize, void) = .empty;
    defer infinite.deinit(gpa);

    for (min_y..max_y + 1) |y| {
        for (min_x..max_x + 1) |x| {
            if (nearest(points.items, @intCast(x), @intCast(y))) |n| {
                const gop = try nearest_points.getOrPut(gpa, n);
                if (!gop.found_existing) gop.value_ptr.* = 0;
                gop.value_ptr.* += 1;
                std.debug.print("{c}", .{((@as(u8, @intCast(n)) % 26) + 'a')});
                if (x == min_x or y == min_y or x == max_x or y == max_y) {
                    try infinite.put(gpa, n, {});
                }
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    var max: u32 = 0;

    var it = nearest_points.iterator();
    while (it.next()) |kv| {
        if (!infinite.contains(kv.key_ptr.*)) {
            max = @max(max, kv.value_ptr.*);
            std.debug.print("{c} -> {any}\n", .{ 'A' + @as(u8, @intCast(kv.key_ptr.*)), kv.value_ptr.* });
        }
    }

    return max;
}

test {
    const input =
        \\1, 1
        \\1, 6
        \\8, 3
        \\3, 4
        \\5, 5
        \\8, 9
    ;

    try std.testing.expectEqual(17, try solve(std.testing.allocator, input));
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const gpa = debug_allocator.allocator();
    std.debug.print("{any}", .{try solve(gpa, @embedFile("input06.txt"))});
}
