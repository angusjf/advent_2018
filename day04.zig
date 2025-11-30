const std = @import("std");

const DateTime = struct { year: u16, month: u16, day: u16, hour: u16, min: u16 };

fn mins_elapsed(from: DateTime, to: DateTime) u32 {
    std.debug.assert(from.year == to.year);
    std.debug.assert(from.month == to.month);
    std.debug.assert(from.day == to.day);
    std.debug.assert(from.hour == to.hour);

    return to.min - from.min;
}

fn timestampLessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.order(u8, a, b) == .lt;
}

fn solve1(gpa: std.mem.Allocator, input: []const u8) !u32 {
    var guard_sleep_mins: std.AutoHashMapUnmanaged(u16, u32) = .empty;
    defer guard_sleep_mins.deinit(gpa);
    var guard_sleep: std.AutoHashMapUnmanaged(struct { u16, u16 }, u32) = .empty;
    defer guard_sleep.deinit(gpa);

    var lines_it = std.mem.tokenizeScalar(u8, input, '\n');

    var lines: std.ArrayList([]const u8) = .empty;
    defer lines.deinit(gpa);
    while (lines_it.next()) |line| {
        try lines.append(gpa, line);
    }
    std.mem.sort([]const u8, lines.items, {}, timestampLessThan);

    var on_duty: ?u16 = null;
    var slept_at: ?DateTime = null;

    for (lines.items) |line| {
        const action = line[19..];

        const curr_time = curr: {
            const year = try std.fmt.parseInt(u16, line[1..5], 10);
            const month = try std.fmt.parseInt(u16, line[6..8], 10);
            const day = try std.fmt.parseInt(u16, line[9..11], 10);
            const hour = try std.fmt.parseInt(u16, line[12..14], 10);
            const min = try std.fmt.parseInt(u16, line[15..17], 10);

            break :curr DateTime{ .year = year, .month = month, .day = day, .hour = hour, .min = min };
        };

        switch (action[0]) {
            'G' => {
                var words = std.mem.tokenizeScalar(u8, action, ' ');
                _ = words.next().?;
                const id = words.next().?;
                const n = try std.fmt.parseInt(u16, id[1..], 10);
                on_duty = n;
            },
            'f' => {
                slept_at = curr_time;
            },
            'w' => {
                {
                    const elapsed = mins_elapsed(slept_at.?, curr_time);
                    const gop = try guard_sleep_mins.getOrPut(gpa, on_duty.?);
                    gop.value_ptr.* = elapsed + (if (gop.found_existing) gop.value_ptr.* else 0);
                }

                for (slept_at.?.min..curr_time.min) |min| {
                    const gop = try guard_sleep.getOrPut(gpa, .{ on_duty.?, @intCast(min) });
                    gop.value_ptr.* = 1 + (if (gop.found_existing) gop.value_ptr.* else 0);
                }
            },
            else => unreachable,
        }
    }

    var max_key: ?u16 = null;
    var max_value: ?u32 = null;
    {
        var it = guard_sleep_mins.iterator();

        while (it.next()) |kv| {
            // std.debug.print("{d} -> {d}m\n", .{ kv.key_ptr.*, kv.value_ptr.* });
            if (max_value) |max| {
                if (kv.value_ptr.* > max) {
                    max_key = kv.key_ptr.*;
                    max_value = kv.value_ptr.*;
                }
            } else {
                max_key = kv.key_ptr.*;
                max_value = kv.value_ptr.*;
            }
        }
    }

    var max_min: ?u16 = null;
    var max_guard: ?u16 = null;
    var max_mins: ?u32 = null;

    {
        var it = guard_sleep.iterator();

        while (it.next()) |kv| {
            // std.debug.print("{d},{d} -> {d}m\n", .{ kv.key_ptr.*.@"0", kv.key_ptr.*.@"1", kv.value_ptr.* });
            if (true or kv.key_ptr.*.@"0" == max_key.?) {
                if (max_mins) |max| {
                    if (kv.value_ptr.* > max) {
                        max_guard = kv.key_ptr.*.@"0";
                        max_min = kv.key_ptr.*.@"1";
                        max_mins = kv.value_ptr.*;
                    }
                } else {
                    max_guard = kv.key_ptr.*.@"0";
                    max_min = kv.key_ptr.*.@"1";
                    max_mins = kv.value_ptr.*;
                }
            }
        }
    }

    // return @as(u32, max_key.?) * max_min.?;
    return @as(u32, max_guard.?) * max_min.?;
}

test solve1 {
    const input =
        \\[1518-11-01 00:00] Guard #10 begins shift
        \\[1518-11-01 00:05] falls asleep
        \\[1518-11-01 00:25] wakes up
        \\[1518-11-01 00:30] falls asleep
        \\[1518-11-01 00:55] wakes up
        \\[1518-11-01 23:58] Guard #99 begins shift
        \\[1518-11-02 00:40] falls asleep
        \\[1518-11-02 00:50] wakes up
        \\[1518-11-03 00:05] Guard #10 begins shift
        \\[1518-11-03 00:24] falls asleep
        \\[1518-11-03 00:29] wakes up
        \\[1518-11-04 00:02] Guard #99 begins shift
        \\[1518-11-04 00:36] falls asleep
        \\[1518-11-04 00:46] wakes up
        \\[1518-11-05 00:03] Guard #99 begins shift
        \\[1518-11-05 00:45] falls asleep
        \\[1518-11-05 00:55] wakes up
    ;

    try std.testing.expectEqual(240, try solve1(std.testing.allocator, input));
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;

    const gpa = debug_allocator.allocator();
    std.debug.print("{d}\n", .{try solve1(gpa, @embedFile("input04.txt"))});
}
