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
    simple to add that on top of its builtins.
=#

function Base.getproperty(vec::Vector{<:Number}, sym::Symbol)
    if sym === :x
        if length(vec) >= 1
            return vec[1]
        else
            @warn "property x is not defined for empty arrays"
            return nothing
        end
    elseif sym === :y
        if length(vec) >= 2
            return vec[2]
        else
            @warn "property y is not defined for arrays with fewer than 2 elements"
            return nothing
        end
    elseif sym === :z
        if length(vec) >= 3
            return vec[3]
        else
            @warn "property z is not defined for arrays with fewer than 3 elements"
            return nothing
        end
    elseif sym === :w
        if length(vec) >= 4
            return vec[4]
        else
            @warn "property w is not defined for arrays with fewer than 4 elements"
            return nothing
        end
    else
        return getfield(vec, sym)
    end
end

function Base.setproperty!(vec::Vector{<:Number}, sym::Symbol, val::T where T<:Number)
    if sym === :x
        if length(vec) >= 1
            vec[1] = val
        else
            @warn "property x is not defined for empty arrays"
        end
    elseif sym === :y
        if length(vec) >= 2
            vec[2] = val
        else
            @warn "property y is not defined for arrays with fewer than 2 elements"
        end
    elseif sym === :z
        if length(vec) >= 3
            vec[3] = val
        else
            @warn "property z is not defined for arrays with fewer than 3 elements"
        end
    elseif sym === :w
        if length(vec) >= 4
            vec[4] = val
        else
            @warn "property w is not defined for arrays with fewer than 4 elements"
        end
    else
        setfield!(vec, sym, val)
    end
end

end
