module starlight

using Colors

#=
    points and vectors are just length-4 arrays with particular values
    in the last index
=#

export fitn
export point
export vector
export sdl_colors

function fitn(vec::Vector, n::Int = 3)
    """
        fit vector to n elements, i.e. truncate or pad.
        defaults to n = 3 because that's my use case.
    """
    return vcat(vec[1:min(n, length(vec))], repeat([0], max(0, n - length(vec))))
end

function point(coords)
    return vcat(fitn(coords), [1])
end

function vector(coords)
    return vcat(fitn(coords), [0])
end

#=
    really all the important matrix operations can be done directly
    with julia's built-in types, but we also like to be able to refer
    to coordinate axes by name. fortunately julia makes it relatively
    simple to add that on top of its builtins. the same holds for color
    components.
=#

function Base.getproperty(vec::Vector{<:Number}, sym::Symbol)
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

function Base.setproperty!(vec::Vector{<:Number}, sym::Symbol, val::T where T<:Number)
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
sdl_colors(c::Vector{<:Number}) = sdl_colors(c.colorant)
# shamelessly copied from GameZero, hurrah for open source
sdl_colors(c::Colorant) = sdl_colors(convert(ARGB{Colors.FixedPointNumbers.Normed{UInt8,8}}, c))
sdl_colors(c::ARGB) = Int.(reinterpret.((red(c), green(c), blue(c), alpha(c))))

end
