
function inbounds(g, y, x)
    try
        g[y, x]
        true
    catch e
        if isa(e, BoundsError)
            false
        else
            throw(e)
        end
    end
end

function get(g, y, x)
    if inbounds(g, y, x)
        g[y, x]
    else
        # Bigger than any single-digit number that can appear in
        # the file.
        10
    end
end

# A 2D array where specific values are replaced with a default.
struct MaskedGrid{T}
    grid::Array{T}
    fill::Array{Bool}
    default::T
end

MaskedGrid(; grid, fill, default) = MaskedGrid(grid, fill, default)

inbounds(g::MaskedGrid{<:Any}, y, x) =
    inbounds(g.grid, y, x)

function get(g::MaskedGrid{<:Any}, y, x)
    if inbounds(g, y, x) && g.fill[y, x]
        g.default
    else
        get(g.grid, y, x)
    end
end

adjacent(g, y, x) =
    [
        get(g, y-1, x),
        get(g, y+1, x),
        get(g, y, x-1),
        get(g, y, x+1),
    ]

islowpoint(g, y, x, op) =
    op(get(g, y, x), minimum(adjacent(g, y, x)))

islowpoint(g, y, x) =
    islowpoint(g, y, x, <)

# Can only be called on a low point
function basinsize(g, y, x)
    fill = zeros(Bool, size(g))
    _traversebasin(g, y, x, fill)
    sum(fill)
end

function _traversebasin(g, y, x, fill)
    mask = MaskedGrid(grid=g, fill=fill, default=10)
    if inbounds(g, y, x) && !fill[y, x] && islowpoint(mask, y, x, <=) && get(g, y, x) != 9
        fill[y, x] = true
        _traversebasin(g, y-1, x, fill)
        _traversebasin(g, y+1, x, fill)
        _traversebasin(g, y, x-1, fill)
        _traversebasin(g, y, x+1, fill)
    end
end

# Load the file
grid = open("input.txt", "r") do f
    lines = collect(eachline(f))
    linecount = length(lines)
    alldata = vcat(map((x) -> map(y -> parse(Int64, y), collect(x)), lines)...)
    reshape(alldata, div(length(alldata), linecount), linecount)
end

let basins = []
    for y in 1:size(grid, 1)
        for x in 1:size(grid, 2)
            if islowpoint(grid, y, x)
                push!(basins, basinsize(grid, y, x))
            end
        end
    end
    sort!(basins)
    println(reduce(*, basins[end-2:end]))
end
