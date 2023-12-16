const std = @import("std");
const intrinzic = @import("intrinzic");
const SIDD = intrinzic.sse4_2.SIDD;

// Here is the actual string compare but it only compares 128 bits (16 bytes) at a time. Here's the C code:
pub fn asm_sse42_strcmp(str1: [*]const u8, str2: [*]const u8, length: u32, ptr_cursor: usize) bool {
    const a = intrinzic._mm_loadu_si128(str1 + ptr_cursor);
    const b = intrinzic._mm_loadu_si128(str2 + ptr_cursor);
    return !intrinzic._mm_cmpestrc(a, length, b, length, SIDD.CMP_EQUAL_EACH | SIDD.NEGATIVE_POLARITY);
}

// This is the function you'd wnat to use which compares strings with any length.
pub fn sse42_strcmp(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;

    const previous_mul_16 = @as(usize, @intFromFloat(@floor(@as(f64, @floatFromInt(a.len / 16))) * 16));
    const remained = a.len - previous_mul_16;

    var prt_cursor: usize = 0;
    while (prt_cursor < previous_mul_16 and previous_mul_16 != 0) {
        if (!asm_sse42_strcmp(a.ptr, b.ptr, 16, prt_cursor)) {
            return false;
        }

        prt_cursor += 16;
    }

    if (remained > 0) {
        if (!asm_sse42_strcmp(a.ptr, b.ptr, @truncate(remained), prt_cursor)) {
            return false;
        }
    }

    return true;
}

pub fn main() !void {
    const string_1 = "abcdefgabcdefgababcdefgabcdefgababcdefgabcdefgab";
    const string_2 = "abcdefgabcdefgababcdefgabcdefgababcdefgabcdefgab";
    const string_3 = "abcdefgabcdefgababcdefgabcdefgababcdefgabcdefgac";
    std.debug.print("{}\n{}\n", .{ sse42_strcmp(string_1, string_2), sse42_strcmp(string_1, string_3) });
}
