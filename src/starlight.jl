module starlight

using Colors

#=
    points and vectors are just length-4 arrays with particular values
    in the last index
=#

export fitn
export point
export vector
export color
export sdl_colors
export canvas

function fitn(vec = [], n::Int = 3)
    """
        fit vector to n elements, i.e. truncate or pad.
        defaults to n = 3 because that's my use case.
    """
    if length(vec) == 0
        return [0.0, 0.0, 0.0]
    else
        return vcat(vec[1:min(n, length(vec))], repeat([AbstractFloat(0)], max(0, n - length(vec))))
    end
end

function point(coords = [])
    return vcat(fitn(coords), [AbstractFloat(1)])
end

color = point # can be a simple alias due to how we handle points

function vector(coords = [])
    return vcat(fitn(coords), [AbstractFloat(0)])
end

#=
    really all the important matrix operations can be done directly
    with julia's built-in types, but we also like to be able to refer
    to coordinate axes by name. fortunately julia makes it relatively
    simple to add that on top of its builtins. the same holds for color
    components.
=#

function Base.getproperty(vec::Vector{<:AbstractFloat}, sym::Symbol)
    if sym === :x || sym === :red || sym === :r
        if length(vec) >= 1
            return vec[1]
        else
            @warn "property $(String(sym)) is not defined for empty arrays"
            return nothing
        end
    elseif sym === :y || sym === :green || sym === :g
        if length(vec) >= 2
            return vec[2]
        else
            @warn "property $(String(sym)) is not defined for arrays with fewer than 2 elements"
            return nothing
        end
    elseif sym === :z || sym === :blue || sym === :b
        if length(vec) >= 3
            return vec[3]
        else
            @warn "property $(String(sym)) is not defined for arrays with fewer than 3 elements"
            return nothing
        end
    elseif sym === :w || sym === :alpha || sym === :a
        if length(vec) >= 4
            return vec[4]
        else
            @warn "property $(String(sym)) is not defined for arrays with fewer than 4 elements"
            return nothing
        end
    elseif sym === :colorant
        # it just happens that the point function impelements sensible
        # defaults if we want to represent a shorter array as a color
        clamped = clamp.(vec, 0, 1)
        cols = (length(vec) >= 4) ? clamped : point(clamped)
        return RGBA(cols...)
    else
        return getfield(vec, sym)
    end
end

function Base.setproperty!(vec::Vector{<:AbstractFloat}, sym::Symbol, val::T where T<:AbstractFloat)
    if sym === :x || sym === :red || sym === :r
        if length(vec) >= 1
            vec[1] = val
        else
            @warn "property $(String(sym)) is not defined for empty arrays"
        end
    elseif sym === :y || sym === :green || sym === :g
        if length(vec) >= 2
            vec[2] = val
        else
            @warn "property $(String(sym)) is not defined for arrays with fewer than 2 elements"
        end
    elseif sym === :z || sym === :blue || sym === :b
        if length(vec) >= 3
            vec[3] = val
        else
            @warn "property $(String(sym)) is not defined for arrays with fewer than 3 elements"
        end
    elseif sym === :w || sym === :alpha || sym === :a
        if length(vec) >= 4
            vec[4] = val
        else
            @warn "property $(String(sym)) is not defined for arrays with fewer than 4 elements"
        end
    else
        setfield!(vec, sym, val)
    end
end

# first bit of code i've written for this project where i was
# like "idk if i really like this or not", but whatever
sdl_colors(c::Vector{<:AbstractFloat}) = sdl_colors(c.colorant)
# shamelessly copied from GameZero, hurrah for open source
sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

#=
    in the book, a canvas is a 3D array where the first 2 dimensions are height
    and width (perhaps not in that order) and the 3rd dimension is color. you
    use x,y coordinates to write colors.

    an empty canvas is initialized with color([]) which comes out to opaque
    black. the book also wants it to have width and height properties, as well
    as getters and setters for individual pixels (pixel_at and write_pixel).

    the workflow used in the book is to create a canvas, manipulate it, and save
    the results to PPM. the workflow i want is to create a canvas, manipulate it,
    and show it in an SDL window, and optionally save it to...something other than
    PPM, probably using an image library.

    it had not occurred to me that these first few chapters would be the hardest
    because of things like this, and were the last time i tried as well.

    the SDL stuff could be done using module-level state. since the canvas is
    maintained by the caller, the image saving would not require state unless
    i wanted to export from SDL using SaveBMP, which i'd kinda like to.

    ok so our canvas is going to be a w * h (or h * w, idk quite yet) * 4 Array,
    so that type needs to have width and height properties defined. idk if julia
    allows for a nicer way to do this, but i also think it would be helpful to
    have a "linear" property that returns the array reshaped to (w * h) * 4 so
    you can iterate over all pixels in a single unnested loop.
=#

#=
    again, canvases are just special matrices and we can layer the stuff
    we need for the test cases on top of native types. no setproperty! this
    time because all the properties are read-only properties of the underlying
    matrix, or else views onto it that wouldn't make sense to directly assign.
    (but see https://docs.julialang.org/en/v1/base/arrays/#Base.reshape, reshape
    returns a result that shares the same underlying data as the original
    matrix, so you can still "do stuff" with it).
=#

function canvas(w::Int, h::Int)
    # height is number of rows, which in julia is the first dimension.
    # width is number of columns, which in julia is the second dimension.
    return fill(color(), (h, w))
end

function Base.getproperty(mat::Array{Vector{T},2} where T<:AbstractFloat, sym::Symbol)
    if sym == :height || sym == :h
        return size(mat)[1]
    elseif sym == :width || sym == :w
        return size(mat)[2]
    elseif sym == :linear || sym == :pixels
        return reshape(mat, (prod(size(mat)), 1))
    end
end

end
