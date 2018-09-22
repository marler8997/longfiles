module stdx.longfiles.conv;

// TODO: this is not robust...just a temporary implementation.
//       I bet phobos already has a function for this anyway.
template stringFor(string s, size_t width)
{
    static if (width == 1)
        enum stringFor = s;
    else static if (width == 2)
        enum stringFor = mixin("w`" ~ s ~ "`");
    else static if (width == 4)
        enum stringFor = mixin("d`" ~ s ~ "`");
    else static assert(0, "cannot make string for this width width");
}

void copyAndConvertString(T, U)(T* dst, const(U)[] src)
{
    static if (T.sizeof == U.sizeof)
    {
        dst[0 .. src.length] = src[];
    }
    else static if (T.sizeof > U.sizeof)
    {
        foreach (i; 0 .. src.length)
        {
            dst[i] = cast(T)src[i];
        }
    }
    else
    {
        // TODO: not implemented, this is where encoding would need to be handled
        static assert(0, "not impl");
    }
}
T[] copyAndConvertStrings(T, U...)(U parts)
{
    // TODO: this won't always work. if T.sizeof < U.sizeof
    //       then certain characters can result in encodings with
    //       more than 1 T element.
    T[] result = void;
    {
        auto size = 0;
        foreach (part; parts)
        {
            size += part.length;
        }
        result = new T[size];
    }
    {
        auto offset = 0;
        foreach (part; parts)
        {
            copyAndConvertString(result.ptr + offset, part);
            offset += part.length;
        }
        assert(offset == result.length, "code bug");
    }
    return result;
}

T convertString(T, U)(U path)
{
    static if (path[0].sizeof == T.init[0].sizeof)
    {
        return cast(T)path;
    }
    else
    {
        //static assert(0, "not implemented");
        import std.conv : to;
        return to!T(path);
    }
}
