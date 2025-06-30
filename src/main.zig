const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var srtTime = try std.time.Timer.start();
    const dictFile = @embedFile("./cs50/dictionaries/large");
    const nanoseconds = srtTime.read();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const dict = WordDictionary;
    try dict.openFileAndReturnsHashTableOfAllTheWords("./cs50/dictionaries/large", allocator);
    defer dict.HashMap.deinit(allocator);

    const a: f64 = @floatFromInt(nanoseconds);
    const timeInMs: f64 = a / 1_000_000.0;
    std.debug.print("the file lenght is {d} and the frst [0..50]m content is ->{s} ------\n time passed since the start is {d:.10} ms \n ", .{ dictFile.len, dictFile[0..10], timeInMs });
}

const WordDictionary = struct {
    const this = @This();
    var HashMap = std.hash_map.HashMapUnmanaged([:0]const u8, bool, std.hash_map.StringContext, 92){};

    pub fn openFileAndReturnsHashTableOfAllTheWords(comptime fileLocation: [:0]const u8, allocator: std.mem.Allocator) !void {
        const dictFile = @embedFile(fileLocation);
        std.debug.print("the file lenght is {d} and the frst [0..30]m content is ->{s} +++ \n from the struct \n", .{ dictFile.len, dictFile[0..30] });
        try HashMap.ensureTotalCapacity(allocator, 198_000);
        try putTheWordsInTheHashMap(dictFile, allocator); // const lenOfLargestWord = this.getTheLenOfLargestWordInDict(dictFile);
        //

        // since the file is too large and we can't use the for loop then let's switch to out old trusty heap
        // allocator.
        //
        //game plan -> make a array  where each index is the size of the max word , for eg the last word is zymurgy and get's its ascii value - a so we get the number of the array
        // const lastIndexForKeysArray = this.getHashTablesLastIndex(dictFile);
        // something is wrong here as 128 should not be the

        // const largestValOfHash = this.getTheHashOfLargestWord(dictFile);
        // const hashTableSize = this.getHashTableSize(lenOfLargestWord);
        // print(" the hashTableSize(threotical) is {d} and largestValueOfHash(based on word) is {d} ++ \n", .{ hashTableSize, largestValOfHash });
        // std.debug.assert(hashTableSize == largestValOfHash);

        // const buf: [res.largestValue]u8 = dictFile[res.largestValueAtIndex - res.largestValue .. res.largestValue];
        // std.debug.print("well the largest word in the dictionary is of lenght {d} and the buff is {c}, -- and the hashTable size is {d}  \n ", .{ lenOfLargestWord, "--not there/implemented--", hashTableSize });

        // get the words from the dict and store it as the key and  bool or u2 as vlaue get it out, if true or the capture group is successfull then the word is there
        // else not

    }

    fn putTheWordsInTheHashMap(file: [:0]const u8, alloc: std.mem.Allocator) std.mem.Allocator.Error!void {
        var word: [50:0]u8 = undefined;
        var indexInWord: u32 = 0;
        for (file, 0..) |value, i| {
            // we can't over index on the word array
            std.debug.assert(indexInWord <= word.len);
            if (value == 10) {
                // got to a line break
                indexInWord = 0;
                word[indexInWord] = 0; // ascii for the null termination
                print("at index:{d} we are at a linebreak ->{c}<-or in ascii val:{d} and putting nullTerminator the word var and adding it to the hashMap \n\n", .{ i, value, value });
                // put it in the hashMap
                try this.HashMap.put(alloc, &word, true);
                continue;
            } else {
                word[indexInWord] = value;
                indexInWord += 1; // doing this before as I want to include the upperbound or include the last added word
                print("at index:{d} we've got ->{c}<-or in ascii val:{d} and putting this char at the indexInWord:{d} and the word[0..{d}] is {s} \n ", .{ i, value, value, indexInWord, indexInWord, word[0..indexInWord] });
            }
        }
        // this.hashMap;
    }

    /// goes through the dictFile and if there is a largest word then return it
    fn getTheLenOfLargestWordInDict(comptime fileContents: [:0]const u8) u32 {
        std.debug.print("in getTheLenOfLargestWordInDict() \n", .{});
        var largestValue: u32 = 0;
        var currentWordCount: u32 = 0;

        for (fileContents, 0..) |value, i| {
            // go through all the chars and if encounters the lb==10 then take the check if we have the largest word count;
            // if we do update it and if not then make it 0 and move on
            //
            // encountered a line break, now check for the change
            if (value == 10) {
                if (currentWordCount > largestValue) {
                    largestValue = currentWordCount;
                    std.debug.print("found the new largest word count and it is {d} and in the dictFile-- and the largest word is {c} \n", .{ largestValue, fileContents[i - largestValue .. i] });
                }
                currentWordCount = 0;
                continue;
            }
            currentWordCount += 1;
            // this missed out the last word count as it does not has the line break so let's make it happen
        }
        if (currentWordCount > largestValue) {
            largestValue = currentWordCount;
            std.debug.print("found the new largest word count and it is {d} and at the last index in the dictFile \n", .{largestValue});
        }
        currentWordCount = 0;
        return largestValue;
    }
};
