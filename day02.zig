const std = @import("std");

pub fn main() !void {
    const first, const second = try common(@embedFile("input02.txt"));
    std.debug.print("{s}{s}\n", .{ first, second });
}

fn checksum(input: []const u8) !u32 {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var count2: u32 = 0;
    var count3: u32 = 0;

    while (lines.next()) |line| {
        var freqs = std.mem.zeroes([26]u8);
        for (line) |c| {
            freqs[c - 'a'] += 1;
        }
        for (freqs) |f| {
            if (f == 3) {
                count3 += 1;
                break;
            }
        }
        for (freqs) |f| {
            if (f == 2) {
                count2 += 1;
                break;
            }
        }
    }

    return count2 * count3;
}

fn common(input: []const u8) !struct { []const u8, []const u8 } {
    var lines1 = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines1.next()) |line1| {
        var lines2 = std.mem.tokenizeScalar(u8, input, '\n');
        next: while (lines2.next()) |line2| {
            if (std.mem.eql(u8, line1, line2)) continue :next;

            var diffs: u32 = 0;
            var diff_at: usize = undefined;

            for (line1, line2, 0..) |a, b, i| {
                if (a != b) {
                    diff_at = i;
                    diffs += 1;

                    if (diffs >= 2) continue :next;
                }
            }

            if (diffs == 1) {
                return .{ line1[0..diff_at], line2[diff_at + 1 ..] };
            }
        }
    }

    unreachable;
}

test {
    const input =
        \\abcdef
        \\bababc
        \\abbcde
        \\abcccd
        \\aabcdd
        \\abcdee
        \\ababab
    ;

    try std.testing.expectEqual(12, try checksum(input));
}

test {
    const input =
        \\abcde
        \\fghij
        \\klmno
        \\pqrst
        \\fguij
        \\axcye
        \\wvxyz
    ;

    const first, const second = try common(input);

    const joined = try std.mem.concat(std.testing.allocator, u8, &[_][]const u8{ first, second });
    defer std.testing.allocator.free(joined);

    try std.testing.expectEqualStrings("fgij", joined);
}
