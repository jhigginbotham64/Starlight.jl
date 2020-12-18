module starlight

#=
    points and vectors are just length-4 arrays with particular values
    in the last index
=#

export fitn
export point
export vector

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

#=
    lifecycle steps for drawing pixel buffers with Surface (vs Texture) in SDL:
    - Init
    - CreateWindow
    - GetWindowSurface
    - loop:
        - UpdateWindowSurface
    - DestroyWindow
    - Quit

    so after CreateWindow and GetWindowSurface i'm left with a...pointer to
    an SDL surface, which apparently is exactly the same as Actor.surface in
    GameZero, but my use case for it is completely different and their code now
    offers no guidance on what to do next.

    as soon as i can figure out how to work with Ptr{SDL.Surface}, the rest is
    as simple as SDL.UpdateWindowSurface(w).

    the first step is to figure out how to access the fields of the surface.
    ...this is strange enough, but further requires writing to a void* array,
    which appears to be difficult to do in julia. without taking the time to
    thoroughly understand julia's c interface and whether or not it's even
    possible to do things that way (let alone easy), i'm inclined to instead
    go the texture route.

    the flow is:
    - Init
    - CreateWindow
    - CreateRenderer
    - CreateTexture
    - initialize canvas
    - loop:
        - modify canvas
        - UpdateTexture
        - RenderCopy
        - RenderPresent
    - DestroyTexture
    - DestroyRenderer
    - DestroyWindow

    while more complex on the surface, it only requires reading C memory and
    figuring out what format to pass julia data in, both of which could be
    figured out experimentally, rather than having to first overcome the barrier
    of julia's preference for copying C data.

    i wish there were people i felt comfortable asking about this. tomorrow i
    need to look at the GitHub repos for the projects i'm studying, and look
    into julia's discourse and slack. and maybe see if anyone on discord might
    know about this sort of thing.

    ...did a bit more internetting, if it's as simple as RenderDrawPoint then
    everything is fine and i have nothing to worry about, altho this project
    at once dives deeply into "toy" territory on account of having to loop over
    pixels to render them. ...wait a sec, it already was, that was the plan all
    along...
=#

end
