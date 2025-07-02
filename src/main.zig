const std = @import("std");
const print = std.debug.print;
const ThreadPool = std.Thread.Pool;
const DictHashMap = @import("./dictionary.zig");

pub fn main() !void {
    var srtTime = try std.time.Timer.start();
    const dictFile = @embedFile("./cs50/dictionaries/large");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const noOfWorkers: u32 = 2;

    var threadPool: ThreadPool = undefined;
    try threadPool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = noOfWorkers });
    defer threadPool.deinit();

    // const dict = WordDictionary;
    // try dict.openFileAndReturnsHashTableOfAllTheWords("./cs50/dictionaries/large", allocator, &threadPool, noOfWorkers);
    // defer dict.HashMap.deinit(allocator);
    //
    var hashMap = std.StringHashMap(bool).init(allocator);
    try hashMap.ensureTotalCapacity(100);
    try hashMap.put("monish", true);
    print("\n put the word monish in the hash_map now let's retrieve it \n", .{});
    const res = hashMap.get("monish");
    if (res) |a| {
        print("the value monish is in the hashMap and res is {any}", .{a});
    } else {
        print("the value monish is not there in it even though I put it in ;) \n\n", .{});
    }
    hashMap.deinit();

    const DictType = DictHashMap.getDictionary(bool);
    var dict = DictType.init(allocator);
    // try dict.hashMap.ensureTotalCapacity(195_000);
    defer dict.deinit();
    dict.openFileAndReturnsHashTableOfAllTheWords("./cs50/dictionaries/large", &threadPool, noOfWorkers) catch |e| {
        print("\n\n there is a error in the dict.openFileAndReturnsHashTableOfAllTheWords func and it is ->{any} \n", .{e});
        return e;
    };

    const nanoseconds = srtTime.read();

    const a: f64 = @floatFromInt(nanoseconds);

    const timeInMs: f64 = a / 1_000_000.0;

    std.debug.print("the file lenght is {d} and the frst [0..50]m content is ->{s} ------\n time passed since the start is {d:.10} ms \n ", .{ dictFile.len, dictFile[0..10], timeInMs });
}

test "are we able to get the words from the hash_map" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const dictFile = @embedFile("./cs50/dictionaries/large");

    const noOfWorkers: u32 = 2;

    var threadPool: ThreadPool = undefined;
    try threadPool.init(std.Thread.Pool.Options{ .allocator = allocator, .n_jobs = noOfWorkers });
    defer threadPool.deinit();

    const DictType = DictHashMap.getDictionary(bool);
    var dict = DictType.init(allocator);
    try dict.hashMap.ensureTotalCapacity(195_000);
    defer dict.deinit();
    dict.openFileAndReturnsHashTableOfAllTheWords("./cs50/dictionaries/large", &threadPool, noOfWorkers) catch |e| {
        print("\n\n there is a error in the dict.openFileAndReturnsHashTableOfAllTheWords func and it is ->{any} \n", .{e});
        return e;
    };

    // const a = 8;
    // const lastLineBreak = dict.getDistributedWorkLocation(dictFile, a)[a - 1];
    const a: u32 = 18;
    // --- Change starts here ---
    const lastLineBreak = DictType.getDistributedWorkLocation(dictFile, a)[a - 1];
    // --- Change ends here ---
    std.debug.print("--++----++----\n\n\n", .{});

    var iterator = std.mem.tokenizeScalar(u8, dictFile[lastLineBreak .. dictFile.len - 1], '\n');
    while (iterator.next()) |word| {
        const r = dict.getValueForKey(word);
        if (r) |v| {
            print("the word from the iterator is {s} and is it in the dict ->{any}\n", .{ word, v });
            continue;
        }
        print("the word from the iterator is {s} and is it in the dict ->{any}\n", .{ word, false });
        const isKeyThere = dict.hashMap.getKey(word);
        if (isKeyThere) |y| {
            print("searched the hashMap for the key:{s}  and it is there as the return value is {s} \n", .{ word, y });
        } else {
            print("searched the hashMap for the key:{s}  and it is **NOT** there \n", .{word});
        }
    }
}
