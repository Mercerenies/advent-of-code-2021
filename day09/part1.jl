
function get(g, y, x)
    try
        g[y, x]
    catch e
        if isa(e, BoundsError)
            # Bigger than any single-digit number that can appear in
            # the file.
            10
        else
            throw(e)
        end
    end
end

adjacent(g, y, x) =
    [
        get(g, y-1, x),
        get(g, y+1, x),
        get(g, y, x-1),
        get(g, y, x+1),
    ]

islowpoint(g, y, x) =
    get(g, y, x) < minimum(adjacent(g, y, x))

# Load the file
grid = open("input.txt", "r") do f
    lines = collect(eachline(f))
    linecount = length(lines)
    alldata = vcat(map((x) -> map(y -> parse(Int64, y), collect(x)), lines)...)
    reshape(alldata, div(length(alldata), linecount), linecount)
end

let risklevel = 0
    for y in 1:size(grid, 1)
        for x in 1:size(grid, 2)
            if islowpoint(grid, y, x)
                risklevel += 1 + get(grid, y, x)
            end
        end
    end
    println(risklevel)
end
