module starlight

using Reexport
@reexport using Images
@reexport using ColorVectorSpace
@reexport using FileIO
@reexport using LinearAlgebra
@reexport using SimpleDirectMediaLayer

SDL2 = SimpleDirectMediaLayer

export SDL2
export fitn
export F, VectorF, Point4, Vector4
export Canvas
export pixel, pixel!
export x, x!, y, y!, z, z!, w, w!, height, width
export pixels, flat
export hadamard
export submatrix, minor, cofactor, invertible

function fitn(vec = [], n::Int = 3)
    """
        fit Vector4 to n elements, i.e. truncate or pad.
        defaults to n = 3 because that's my use case.
    """
    if length(vec) == 0
        return [0.0, 0.0, 0.0]
    else
        return vcat(vec[1:min(n, length(vec))], repeat([AbstractFloat(0)], max(0, n - length(vec))))
    end
end

# Point4 and Vector4 are just length-4 arrays with particular valuesin the last index

Point4(x, y, z) = Point4([x, y, z])
function Point4(coords = [])
    return vcat(fitn(coords), [AbstractFloat(1)])
end

Vector4(x, y, z) = Vector4([x, y, z])
function Vector4(coords = [])
    return vcat(fitn(coords), [AbstractFloat(0)])
end

F = T where T<:AbstractFloat
VectorF = Vector{T} where T<:AbstractFloat

function GetIndexOrWarn(vec::VectorF, i::Int, sym::Symbol)
    if length(vec) >= i
        return vec[i]
    else
        @warn "vector must have length at least $(String(i)) to interpret index $(String(i)) as its $(String(sym)) component"
        return nothing
    end
end

x(vec::VectorF) = GetIndexOrWarn(vec, 1, :x)
y(vec::VectorF) = GetIndexOrWarn(vec, 2, :y)
z(vec::VectorF) = GetIndexOrWarn(vec, 3, :z)
w(vec::VectorF) = GetIndexOrWarn(vec, 4, :w)

function SetIndexOrWarn!(vec::VectorF, i::Int, sym::Symbol, val::T where T<:AbstractFloat)
    if length(vec) >= i
        vec[i] = val
    else
        @warn "vector must have length at least $(String(i)) to interpret index $(String(i)) as its $(String(sym)) component"
        return nothing
    end
end

x!(vec::VectorF, val::F) = SetIndexOrWarn!(vec, 1, :x, val)
y!(vec::VectorF, val::F) = SetIndexOrWarn!(vec, 2, :y, val)
z!(vec::VectorF, val::F) = SetIndexOrWarn!(vec, 3, :z, val)
w!(vec::VectorF, val::F) = SetIndexOrWarn!(vec, 4, :w, val)

# height is number of rows, which in julia is the first dimension.
# width is number of columns, which in julia is the second dimension.
Canvas(w::Int, h::Int, c = colorant"black") = fill(c, (h, w))
pixel(mat, x::Int, y::Int) = mat[x,y]
pixel!(mat, x::Int, y::Int, c::Colorant) = mat[x,y] = c
pixels(mat) = flat(mat)
flat(mat) = reshape(mat, (prod(size(mat)), 1))
# stopgap solution from https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/119#issuecomment-573167024
# while waiting for long-term solution from https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/126
hadamard(c1, c2) = mapc(*, c1, c2)

function submatrix(mat, r::Int, c::Int)
    h = height(mat)
    w = width(mat)
    mask = [row != r && col != c for row=1:h, col=1:w]
    return reshape(mat[mask], (h-1,w-1))
end

minor(mat, r::Int, c::Int) = det(submatrix(mat, r, c))
cofactor(mat, r::Int, c::Int) = minor(mat, r, c) * (-1)^(r+c)
invertible(mat) = det(mat) != 0

end
