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
export F, VectorF, point, vector
export x, x!, y, y!, z, z!, w, w!
export Canvas, pixel, pixel!, pixels, flat
export hadamard
export submatrix, minor, cofactor, invertible
export translation, scaling, reflection_x, reflection_y, reflection_z, rotation_x, rotation_y, rotation_z, shearing

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

# point and vector are just length-4 arrays with particular valuesin the last index

point(x, y, z) = point([x, y, z])
function point(coords = [])
    return vcat(fitn(coords), [AbstractFloat(1)])
end

vector(x, y, z) = vector([x, y, z])
function vector(coords = [])
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

translation(x, y, z) = [
    1 0 0 x
    0 1 0 y
    0 0 1 z
    0 0 0 1
]

scaling(x, y, z) = [
    x 0 0 0
    0 y 0 0
    0 0 z 0
    0 0 0 1
]

reflection_x = scaling(-1, 1, 1)
reflection_y = scaling(1, -1, 1)
reflection_z = scaling(1, 1, -1)

rotation_x(r) = [
    1 0 0 0
    0 cos(r) -sin(r) 0
    0 sin(r) cos(r) 0
    0 0 0 1
]

rotation_y(r) = [
    cos(r) 0 sin(r) 0
    0 1 0 0
    -sin(r) 0 cos(r) 0
    0 0 0 1
]

rotation_z(r) = [
    cos(r) -sin(r) 0 0
    sin(r) cos(r) 0 0
    0 0 1 0
    0 0 0 1
]

shearing(xy, xz, yx, yz, zx, zy) = [
    1 xy xz 0
    yx 1 yz 0
    zx zy 1 0
    0 0 0 1
]

end
