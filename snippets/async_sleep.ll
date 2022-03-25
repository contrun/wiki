   %7 = bitcast i64* %_1 to %"[static generator@src/main.rs:4:17: 6:2]"*, !dbg !2665
   %8 = getelementptr inbounds %"[static generator@src/main.rs:4:17: 6:2]", %"[static generator@src/main.rs:4:17: 6:2]"* %7, i32 0, i32 1, !dbg !2665
   %9 = load i8, i8* %8, align 128, !dbg !2665, !range !2623
   %_19 = zext i8 %9 to i32, !dbg !2665
   switch i32 %_19, label %bb18 [
     i32 0, label %bb1
     i32 1, label %bb17
     i32 2, label %bb16
     i32 3, label %bb15
   ], !dbg !2665
