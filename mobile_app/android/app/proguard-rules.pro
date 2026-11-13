# WorkManager brings Room 2.2.5 transitively. Its consumer rule keeps database
# class names, but R8 full mode removes the generated no-argument constructor.
# Room creates that implementation via reflection during AndroidX startup;
# without this constructor the release process dies before Flutter can start.
# Keep just the database types and their no-arg constructors, not entire SDKs.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
