const std = @import("std");

fn solve(gpa: std.mem.Allocator, input: []const u8, output: []u8) !usize {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var requirements: std.AutoArrayHashMapUnmanaged(u8, std.ArrayList(u8)) = .empty;
    defer requirements.deinit(gpa);
    defer {
        for (requirements.values()) |*req| {
            req.deinit(gpa);
        }
    }
    var to_complete: std.AutoArrayHashMapUnmanaged(u8, void) = .empty;
    defer to_complete.deinit(gpa);

    while (lines.next()) |line| {
        var words = std.mem.tokenizeScalar(u8, line, ' ');

        _ = words.next().?; // Step
        const dependency = words.next().?[0];
        _ = words.next().?; // must
        _ = words.next().?; // be
        _ = words.next().?; // finished
        _ = words.next().?; // before
        _ = words.next().?; // step
        const step = words.next().?[0];

        const gop = try requirements.getOrPut(gpa, step);
        if (!gop.found_existing) gop.value_ptr.* = .empty;
        try gop.value_ptr.*.append(gpa, dependency);

        try to_complete.put(gpa, step, {});
        try to_complete.put(gpa, dependency, {});
    }

    const SortContext = struct {
        keys: []const u8,
        pub fn lessThan(ctx: @This(), a_index: usize, b_index: usize) bool {
            return ctx.keys[a_index] < ctx.keys[b_index];
        }
    };

    to_complete.sort(SortContext{ .keys = to_complete.keys() });

    var order: std.ArrayList(u8) = .initBuffer(output);

    while (true) {
        loop: for (to_complete.keys()) |key| {
            var requirements_met: bool = true;
            if (requirements.get(key)) |reqs| {
                for (reqs.items) |req| {
                    if (to_complete.contains(req)) {
                        requirements_met = false;
                        continue :loop;
                    }
                }
            }
            if (requirements_met) {
                std.debug.assert(to_complete.orderedRemove(key));
                order.appendAssumeCapacity(key);
                break :loop;
            }
        } else return order.items.len;
    }
}

test {
    const input =
        \\Step C must be finished before step A can begin.
        \\Step C must be finished before step F can begin.
        \\Step A must be finished before step B can begin.
        \\Step A must be finished before step D can begin.
        \\Step B must be finished before step E can begin.
        \\Step D must be finished before step E can begin.
        \\Step F must be finished before step E can begin.
    ;

    var buffer: [100]u8 = undefined;

    const len = try solve(std.testing.allocator, input, &buffer);

    try std.testing.expectEqualStrings("CABDFE", buffer[0..len]);
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const gpa = debug_allocator.allocator();

    var buffer: [100]u8 = undefined;

    const len = try solve(gpa, @embedFile("input07.txt"), &buffer);

    std.debug.print("{s}\n", .{buffer[0..len]});
}
