# Long File Names for Windows

This is a proof of concept library for adding support in phobos for long filenames in windows.

You can either use the function `toLongPath` when you need operate on a filename with a long path or import the `stdx.longfiles` modules instead of `std.file`, i.e.

```D
void main()
{
    // make a large filename
    auto name = `c:\temp`;
    foreach (i; 0 .. 30)
    {
        name ~= "\0123456789";
    }

    // Method 1: reuse the same long name
    {
        import std.file;
        auto f = toLongName(name);
        if (!exists(f))
        {
            mkdirRecurse(f);
        }
    }

    // Method 2: have each call convert the long name
    {
        import stdx.longfiles;
        if (!exists(name))
        {
            mkdirRecurse(name);
        }
    }
}
```
