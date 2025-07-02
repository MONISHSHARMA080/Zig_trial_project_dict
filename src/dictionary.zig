const std = @import("std");
const print = std.debug.print;
const ThreadPool = std.Thread.Pool;

pub fn getDictionary(comptime ResultType: type) type {
    return struct {
        const this = @This();
        const Self = @This();

        // var HashMap = std.hash_map.HashMapUnmanaged([]const u8, bool, std.hash_map.StringContext, 92){};
        hashMap: std.hash_map.StringHashMap(ResultType),
        allocator: std.mem.Allocator,

        // returns a runtime instance of the object
        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{ .allocator = allocator, .hashMap = std.hash_map.StringHashMap(ResultType).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.hashMap.deinit();
        }

        pub fn openFileAndReturnsHashTableOfAllTheWords(self: *Self, comptime fileLocation: [:0]const u8, threadPool: *ThreadPool, comptime noOfWorkers: u32) !void {
            const dictFile = @embedFile(fileLocation);

            // @compileLog("the type of the file is {any} ", .{@typeInfo(@TypeOf(dictFile))});

            // try HashMap.ensureTotalCapacity(allocator, 200_000);

            // make a function that will return the NulChar and
            // try putTheWordsInTheHashMap(dictFile, allocator); // const lenOfLargestWord = this.getTheLenOfLargestWordInDict(dictFile);

            const indicesToGoToForWork = this.getDistributedWorkLocation(dictFile, noOfWorkers);

            print("the indices to go to the work is {any} \n", .{indicesToGoToForWork});

            var prevVal: u32 = 0;

            print("launching threadPool to put the words in the hashMap \n ", .{});

            var wg: std.Thread.WaitGroup = std.Thread.WaitGroup{};

            for (indicesToGoToForWork, 0..) |value, i| {
                print("on index:{d} and dictFile[prevVal..value] --> dictFile[{d}..{d}] \n", .{ i, prevVal, value });

                // try threadPool.spawn(this.putTheWordsInTheHashMap, .{ dictFile[prevVal..value], allocator, &wg });
                try threadPool.spawn(Self.putTheWordsInTheHashMap, .{ self, dictFile[prevVal..value], &wg });

                wg.start();

                prevVal = value;
            }

            threadPool.waitAndWork(&wg);

            print("the thread pool finished\n", .{});
        }

        /// returns the nearest ascii 10 value's index #noOfWorkers times
        fn getDistributedWorkLocation(comptime f: [:0]const u8, comptime noOfWorkers: u32) [noOfWorkers]u32 {
            const workRange: u32 = f.len / noOfWorkers;

            // eg if the noOfWorkers = 5 I want a 5 values for each worker, eg 1,2,3,4,5 at index 4 or noOfWorkers - 1

            var resArray: [noOfWorkers]u32 = [_]u32{0} ** noOfWorkers;

            var resArrIndex: u16 = 0;

            print("the lenght of the file is {d} \n", .{f.len});

            var i: u32 = workRange;

            while (i < f.len and resArrIndex < resArray.len) : (i -= 1) {
                std.debug.assert(i <= f.len); // you can't tell us to go to the index after the file
                std.debug.assert(resArrIndex < resArray.len); // eg. arr of len 5 has index range from 0->4
                std.debug.assert(resArrIndex < noOfWorkers); // eg. arr of len 5 has index range from 0->4
                print("at the filelocation:{d} \n ", .{i});
                if (f[i] == 10) {
                    resArray[resArrIndex] = i;
                    resArrIndex += 1;
                    // got the value and now update the i to go to the next one
                    i = i + workRange;
                    print("\n got the ascii value 10 at index:{d} and new index in file is:{d} and the resultArrayIndex is {d} and the resultArray is {any} \n\n ", .{ i - workRange, i, resArrIndex, resArray });
                    // not asserting here as I am not accessing the file here and in the case of the last i(index) It can be as this is not a problem
                    // std.debug.assert(i <= f.len); // you can't tell us to go to the index after the file
                    continue;
                }
            }
            return resArray;
        }

        /// get's the word from the file and add it to the hashMap -- if we get the ascii 10 we assume we have a new char and add the prev one in hashMap
        /// if for some reason the last thing in the file is not 10 and we got some words then it will treat it as words and add it in the hashMap too !!
        ///
        ///NOTE:-> the file here is not :0(0/null terminated/sentinel ) as I am indexing the file, and the func assumes the file ends when it runds out of words and not when we get
        /// ascii 0 value
        //
        fn putTheWordsInTheHashMap(self: *Self, file: []const u8, wg: *std.Thread.WaitGroup) void {
            defer wg.finish();
            var word: [59:0]u8 = undefined;
            var indexInWord: u32 = 0;
            var isTheWordIn: ?bool = false;
            for (file, 0..) |value, i| {

                // we can't over index on the word array
                std.debug.assert(indexInWord <= word.len);
                if (value == 10) {
                    // got to a line break
                    word[indexInWord] = 0; // ascii for the null termination
                    print("at index:{d} we are at a linebreak ->{c}<-or in ascii val:{d} and putting nullTerminator the word var that is ->{s}<- or ascii of it is word[0..{d} :0]:-->{d}<-- to the hashMap \n\n", .{ i, value, value, word[0..indexInWord], indexInWord, word[0..indexInWord :0] });
                    // put it in the hashMap
                    // try this.HashMap.put(alloc, &word, true);
                    // this.HashMap.put(alloc, word[0..indexInWord :0], true) catch |e| std.debug.panic("\n the put call in the hashMap returned an error and we are not able to put stuff in the hashMap so we crash, error is ->{any} \n\n ", .{e});
                    self.hashMap.put(word[0..indexInWord :0], true) catch |e| {
                        print("reached the panic stage in the putting function and the error is {any}", .{e});
                        std.debug.panic("\n the put call in the hashMap returned an error and we are not able to put stuff in the hashMap so we crash, error is ->{any} \n\n ", .{e});
                    };
                    isTheWordIn = self.hashMap.get(word[0..indexInWord :0]);
                    if (isTheWordIn) |a| {
                        print("we got the word ->{s}<- from hashTable and it is ->{any} ++ \n\n ", .{ word[0..indexInWord :0], a });
                    } else {
                        print("we dod not got the word ->{s}<- from hashTable ++ \n\n ", .{word[0..indexInWord :0]});
                    }
                    indexInWord = 0;
                    continue;
                } else {
                    word[indexInWord] = value;

                    indexInWord += 1; // doing this before as I want to include the upperbound or include the last added word

                    print("at index:{d} we've got ->{c}<-or in ascii val:{d} and putting this char at the indexInWord:{d} and the word[0..{d}] is {s} \n ", .{ i, value, value, indexInWord, indexInWord, word[0..indexInWord] });
                }
            }

            // if we are at the end of the file and not got the ascii 10 then we would skip the last word so (this func could be running on diff thread too) so of the ascii 10

            // is not there then let's add it, we will assert (or in that case) indexInWord != 0 and word does not have 0 at the first place

            if (indexInWord != 0) {
                std.debug.assert(word[0] != 10);

                // try this.HashMap.put(alloc, &word, true);

                word[indexInWord] = 0; // in the else block above we have moved the value by one os null on this one

                self.hashMap.put(word[0..indexInWord :0], true) catch |e| std.debug.panic("\n the put call in the hashMap returned an error and we are not able to put stuff in the hashMap(in the last case) so we crash, error is ->{any} \n\n ", .{e});
                // this.HashMap.put(alloc, word[0..indexInWord :0], true) catch |e| std.debug.panic("\n the put call in the hashMap returned an error and we are not able to put stuff in the hashMap(in the last case) so we crash, error is ->{any} \n\n ", .{e});

                print("-- we were not able to find the end ascii 10 and the indexInWord != 0, it is {d} so adding a new word: {s} \n", .{ indexInWord, word[0..indexInWord] });
            }
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
}
