const std = @import("std");

pub fn main() !void {
    const input = @embedFile("input03.txt");
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const gpa = debug_allocator.allocator();

    std.debug.print("{d}\n", .{try solve(gpa, input)});
}

const Claim = struct { x: u16, y: u16, w: u16, h: u16 };

fn calc_overlap(a: Claim, b: Claim) u32 {
    return a.x + b.h;
}

fn solve(gpa: std.mem.Allocator, input: []const u8) !u32 {
    var claims: std.ArrayList(Claim) = .empty;
    defer claims.deinit(gpa);

    try parseClaims(gpa, input, &claims);

    var map: std.AutoHashMapUnmanaged(struct { u16, u16 }, u32) = .empty;
    defer map.deinit(gpa);

    for (claims.items) |claim| {
        for (0..claim.w) |dx| {
            for (0..claim.h) |dy| {
                const pos = .{ claim.x + @as(u16, @intCast(dx)), claim.y + @as(u16, @intCast(dy)) };
                const n = try map.getOrPut(gpa, pos);
                if (!n.found_existing) n.value_ptr.* = 0;
                n.value_ptr.* += 1;
            }
        }
    }

    claims_loop: for (1.., claims.items) |i, claim| {
        for (0..claim.w) |dx| {
            for (0..claim.h) |dy| {
                const pos = .{ claim.x + @as(u16, @intCast(dx)), claim.y + @as(u16, @intCast(dy)) };
                if (map.get(pos).? > 1) continue :claims_loop;
            }
        }
        return @intCast(i);
    }

    unreachable;
}

fn parseClaims(gpa: std.mem.Allocator, input: []const u8, claims: *std.ArrayList(Claim)) !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeAny(u8, line, " ,:@x");
        _ = parts.next().?;

        try claims.append(gpa, Claim{
            .x = try std.fmt.parseInt(u16, parts.next().?, 10),
            .y = try std.fmt.parseInt(u16, parts.next().?, 10),
            .w = try std.fmt.parseInt(u16, parts.next().?, 10),
            .h = try std.fmt.parseInt(u16, parts.next().?, 10),
        });
    }
}

test {
    const input =
        \\#1 @ 1,3: 4x4
        \\#2 @ 3,1: 4x4
        \\#3 @ 5,5: 2x2
    ;

    const result = try solve(std.testing.allocator, input);

    try std.testing.expectEqual(3, result);
}
