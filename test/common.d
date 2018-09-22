module common;

auto makePaths()
{
    string[] paths = null;
    auto name = `c:\temp`;
    foreach (i; 0 .. 30)
    {
        name ~= `\0123456789`;
        paths ~= name;
    }
    return paths;
}
