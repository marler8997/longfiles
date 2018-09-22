/**
Proof of concept for supporting long filenames in windows.

TODO: what should be done about the MS-DOS FAT filesystem?
It only supports 8 charaters in the base name an 3 in the extension.

*/
module stdx.longfiles;

import std.traits;
import std.range.primitives;
static import std.file;

/**
Converts the given `path` to a string that will be accepted by the OS. For POSIX this
is a NO-OP, for Windows it will check a series of conditions and possibly convert it.
*/
pragma(inline)
auto toLongPath(T)(T path)
{
    version (Windows)
    {
        auto result = toLongPathWindows(path);
        version (TraceLongPaths)
        {
            import std.stdio;
            writefln("toLongPath(\"%s\") > \"%s\"", path, result);
        }
        return result;
    }
    else
        return path;
}

wchar[] toLongPathWindows(T)(T path)
{
    import core.sys.windows.winbase : GetCurrentDirectoryW;
    import std.string : startsWith;
    import std.path : isRooted, buildNormalizedPath;
    import stdx.longfiles.conv;
    import stdx.longfiles.path;

    if (isRooted(path))
    {
        if (path.length < 240 || path.startsWith(stringFor!(`\\?\`, path[0].sizeof)))
            return convertString!(wchar[])(path);
        // TODO: there's definitely more use cases to handle
        // TODO: this could be more efficient
        immutable(wchar)[] prefix;
        if (isDriveRoot(path))
            prefix = `\\?\`w;
        else
            prefix = `\\?`w;
        return copyAndConvertStrings!wchar(prefix, path);
    }
    const cwd = getCwdWindows();
    if (cwd.length + path.length < 240)
        return convertString!(wchar[])(path);
    // TODO: there's definitely more use cases to handle
    // TODO: there's probably a more efficient way to do this rather than using buildNormalizedPath
    return copyAndConvertStrings!wchar(`\\?\`w, cwd, buildNormalizedPath(path));
}


unittest
{
    `a\b\c`.toLongPath;

    enum p = `\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\0123456789\`;
    assert(`\\?` ~ p == p.toLongPath);
}


void[] read(R)(R name, size_t upTo = size_t.max)
if (isInputRange!R && isSomeChar!(ElementEncodingType!R) && !isInfinite!R && !isConvertibleToString!R)
{
    return std.file.read(toLongPath(name), upTo);
}
void[] read(R)(auto ref R name, size_t upTo = size_t.max)
if (isConvertibleToString!R)
{
    return std.file.read(toLongPath(name), upTo);
}

unittest
{
    string s = "hello";
    // just instantiate the read function for now
    try { read(s); }
    catch (std.file.FileException) { }
}

mixin template oneArgWrapper(string name)
{
    mixin(`
auto `~name~`(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) && !isConvertibleToString!R)
{
    return std.file.`~name~`(toLongPath(name));
}
void `~name~`(R)(auto ref R pathname)
if (isConvertibleToString!R)
{
    return std.file.`~name~`(toLongPath(pathname));
}
`);
}
mixin oneArgWrapper!"exists";
mixin oneArgWrapper!"mkdir";
mixin oneArgWrapper!"mkdirRecurse";
mixin oneArgWrapper!"rmdir";
