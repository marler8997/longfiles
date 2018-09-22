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
