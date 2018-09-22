/**
A temporary module that shouldn't exist...this should be in std.path
*/
module stdx.longfiles.path;

version (Windows)
{
    import stdx.longfiles.conv;

    // TODO: this should be moved to std.path, and getcwd should call
    //       this function.
    auto tryGetCwdWindows() nothrow
    {
        // TODO: is there a way to cache this value?

        import core.sys.windows.windef : DWORD;
        import core.sys.windows.winbase : GetCurrentDirectoryW;
        DWORD lastSizeAttempted = 0;
        // We loop in order to handle race conditions between getting
        // the CWD size and changing directory.  We mitigate this by
        // retrying so long as we don't get the same size twice in a row.
        for (;;)
        {
            immutable size = GetCurrentDirectoryW(0, null);
            if (size == 0)
                return null; // fail
            auto cwd = new wchar[size];
            if (GetCurrentDirectoryW(size, cwd.ptr))
                return cwd;
            if (size == lastSizeAttempted)
                return null; // fail
        }
    }
    auto getCwdWindows()
    {
        import std.file : FileException;
        auto result = tryGetCwdWindows();
        if (result is null)
            throw new FileException("GetCurrentDirectory failed");
        return result;
    }


    bool isPartiallyQualified(T)(const(T)[] path)
    in { assert(path.length > 0); } do
    {
        return path[0] != cast(T)'\\';
    }

    /**
    \\?\, \\.\, \??\
    */
    enum DevicePrefixLength = 4;


    /**
    Get full path name of `path` and store in builder.
    Returns: 0 on error, length of path on success
    */
    uint tryAppendFullPathName(T, U)(const(T)[] path, U builder)
    {
        import std.internal.cstring;
        // create temporary string for path
        auto pathTempCstr = tempCString!wchar(path);
        return tryAppendFullPathNameImpl(pathTempCstr, builder);
    }

    /**
    Assumption: `nullTerminatedPath` is nullTerminated.
    */
    uint tryAppendFullPathNameImpl(T)(const(wchar)* nullTerminatedPath, T builder)
    /+
    in {
        // If the string starts with an extended prefix we would need to remove it from the path
        // before we call GetFullPathName as it doesn't root extended paths correctly. We don't
        // currently resolve extended paths, so we'll just assert here.
        assert(isPartiallyQualified(nullTerminatedPath) || !isExtended(nullTerminatedPath)); } do
    +/
    {
        import core.sys.windows.winbase : GetFullPathNameW;
        auto prefixLength = builder.data.length;
        for (;;)
        {
            const result = GetFullPathNameW(nullTerminatedPath, builder.capacity - prefixLength,
                builder.data.ptr + prefixLength, null);
            if (result <= (builder.capacity - prefixLength))
            {
                // note: cannot set Appender length
                //       phobos needs to add a function for this
                //builder.shrinkTo(result);
                return result;
            }
            builder.reserve(prefixLength + result);
        }
    }

    /**
    Returns true if the path uses the canonical form of extended syntax ("\\?\" or "\??\"). If the
    path matches exactly (cannot use alternate directory separators) Windows will skip normalization
    and path length checks.
    */
    bool isExtended(T)(const(T)[] path)
    {
        // While paths like "//?/C:/" will work, they're treated the same as "\\.\" paths.
        // Skipping of normalization will *only* occur if back slashes ('\') are used.
        return path.length >= DevicePrefixLength
            && path[0] == '\\'
            && (path[1] == '\\' || path[1] == '?')
            && path[2] == '?'
            && path[3] == '\\';
    }

    // TODO: THESE FUNCTIONS ARE ALREADY DEFINED IN std.path but are private
    private bool isDriveSeparator(dchar c) @safe pure nothrow @nogc
    {
        version(Windows) return c == ':';
        else return false;
    }
    bool isDriveRoot(R)(R path)
    //if (isRandomAccessRange!R && isSomeChar!(ElementType!R) ||
    //    isNarrowString!R)
    {
        import std.path : isDirSeparator;
        return path.length >= 3 && isDriveSeparator(path[1])
            && isDirSeparator(path[2]);
    }
}
