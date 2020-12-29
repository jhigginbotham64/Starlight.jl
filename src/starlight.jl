module starlight

using Reexport
@reexport using Images
@reexport using ColorVectorSpace
@reexport using FileIO
@reexport using LinearAlgebra
@reexport using SimpleDirectMediaLayer

SDL2 = SimpleDirectMediaLayer
export SDL2

# chapter 1
export point, vector, x, x!, y, y!, z, z!, w, w!

# chapter 2
export canvas, pixel, pixel!, pixels, flat, hadamard

# chapter 3
export submatrix, minor, cofactor, invertible

# chapter 4
export translation, scaling, reflection_x, reflection_y, reflection_z, rotation_x, rotation_y, rotation_z, shearing

# chapter 5
export ray, sphere, intersect, intersection, intersections, hit, transform, transform!

# chapter 6
export normal_at, reflect, point_light, material, material!, lighting, round_color

#=
    chapter 1
=#

# point and vector are just length-4 arrays with particular valuesin the last index

point(x, y, z) = [x, y, z, 1.0]
vector(x, y, z) = [x, y, z, 0.0]

function GetIndexOrWarn(vec, i::Int, sym::Symbol)
    if length(vec) >= i
        return vec[i]
    else
        @warn "vector must have length at least $(String(i)) to interpret index $(String(i)) as its $(String(sym)) component"
        return nothing
    end
end

x(vec) = GetIndexOrWarn(vec, 1, :x)
y(vec) = GetIndexOrWarn(vec, 2, :y)
z(vec) = GetIndexOrWarn(vec, 3, :z)
w(vec) = GetIndexOrWarn(vec, 4, :w)

function SetIndexOrWarn!(vec, i::Int, sym::Symbol, val)
    if length(vec) >= i
        vec[i] = val
    else
        @warn "vector must have length at least $(String(i)) to interpret index $(String(i)) as its $(String(sym)) component"
        return nothing
    end
end

x!(vec, val) = SetIndexOrWarn!(vec, 1, :x, val)
y!(vec, val) = SetIndexOrWarn!(vec, 2, :y, val)
z!(vec, val) = SetIndexOrWarn!(vec, 3, :z, val)
w!(vec, val) = SetIndexOrWarn!(vec, 4, :w, val)

#=
    chapter 2
=#

# height is number of rows, which in julia is the first dimension.
# width is number of columns, which in julia is the second dimension.
canvas(w::Int, h::Int, c = colorant"black") = fill(c, (h, w))
pixel(mat, x::Int, y::Int) = mat[x,y]
pixel!(mat, x::Int, y::Int, c::Colorant) = mat[x,y] = c
pixels(mat) = flat(mat)
flat(mat) = reshape(mat, (prod(size(mat)), 1))
# stopgap solution from https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/119#issuecomment-573167024
# while waiting for long-term solution from https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/126
hadamard(c1, c2) = mapc(*, c1, c2)

#=
    chapter 3
=#

function submatrix(mat, r::Int, c::Int)
    h = height(mat)
    w = width(mat)
    mask = [row != r && col != c for row=1:h, col=1:w]
    return reshape(mat[mask], (h-1,w-1))
end

minor(mat, r::Int, c::Int) = det(submatrix(mat, r, c))
cofactor(mat, r::Int, c::Int) = minor(mat, r, c) * (-1)^(r+c)
invertible(mat) = det(mat) != 0

#=
    chapter 4
=#

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

#=
    chapter 5
=#

mutable struct ray
    origin::Vector{<:Number}
    # the book calls this "direction", but in my mind direction
    # is a unit vector which you combine with a magnitude (speed)
    # to get velocity, and the book uses direction mathematically
    # like a velocity, so i'm calling it velocity.
    velocity::Vector{<:Number}
end

# material added in chapter 6, put here for compilation
mutable struct material
    color::Color
    ambient::AbstractFloat
    diffuse::AbstractFloat
    specular::AbstractFloat
    shininess::AbstractFloat
    material(color = colorant"white", ambient = 0.1, diffuse = 0.9, specular = 0.9, shininess = 200.0) = new(color, ambient, diffuse, specular, shininess)
end

mutable struct sphere
    origin::Vector{<:Number}
    transform::Array{<:Number, 2}
    material::material
    sphere(origin = point(0, 0, 0), transform = Array{Float64, 2}(I(4)), material = material()) = new(origin, transform, material)
end

mutable struct intersection
    t::Number
    object
end

intersections(is::intersection...) = [is...]
transform(r::ray, mat::Array{<:Number, 2}) = ray(mat * r.origin, mat * r.velocity)
transform!(s::sphere, mat::Array{<:Number, 2}) = s.transform = mat

import Base.position
position(r::ray, t::Number) = r.origin + r.velocity * t

import Base.intersect
function intersect(s::sphere, _r::ray)
    r = transform(_r, inv(s.transform))
    sphere_to_ray = r.origin - point(0, 0, 0) # all spheres centered at origin for now
    a = r.velocity ⋅ r.velocity
    b = 2 * r.velocity ⋅ sphere_to_ray
    c = sphere_to_ray ⋅ sphere_to_ray - 1

    discriminant = b^2 - 4 * a * c

    if discriminant < 0
        return Vector{intersection}([])
    end

    t1 = (-b - √discriminant) / 2a
    t2 = (-b + √discriminant) / 2a

    return intersections(intersection(t1, s), intersection(t2, s))
end

hit(is::Vector{intersection}) = (all(map(i -> i.t < 0, is))) ? nothing : is[argmin(map(i -> (i.t < 0) ? Inf : i.t, is))]

#=
    chapter 6
=#

function normal_at(s::sphere, p::Vector{<:Number})
    op = inv(s.transform) * p
    on = op - point(0, 0, 0)
    wn = inv(s.transform)' * on
    w!(wn, 0)
    return normalize(wn)
end

reflect(v::Vector{<:Number}, n::Vector{<:Number}) = v - (n * (2 * (v ⋅ n)))

mutable struct point_light
    position::Vector{<:Number}
    intensity::Color
end

material!(s::sphere, m::material) = s.material = m

import Base.==
function ==(m1::material, m2::material)
   return (
        m1.color == m2.color &&
        m1.ambient == m2.ambient &&
        m1.diffuse == m2.diffuse &&
        m1.specular == m2.specular &&
        m1.shininess == m2.shininess
    )
end

function lighting(m, l, p, eyev, normalv)
    effective_color = hadamard(m.color, l.intensity)
    lightv = normalize(l.position - p)
    ambient = effective_color * m.ambient
    light_dot_normal = lightv ⋅ normalv
    diffuse = colorant"black"
    specular = colorant"black"
    if light_dot_normal >= 0
        diffuse = effective_color * m.diffuse * light_dot_normal
        reflectv = reflect(-lightv, normalv)
        reflect_dot_eye = reflectv ⋅ eyev
        if reflect_dot_eye > 0
            factor = reflect_dot_eye ^ m.shininess
            specular = l.intensity * m.specular * factor
        end
    end
    return ambient + diffuse + specular
end

round_color(c::Color, ndigits::Int) = mapc(chan -> round(chan, digits=ndigits), c)

#=
    chapter 7
=#



#=
    chapter 8
=#



#=
    chapter 9
=#



#=
    chapter 10
=#



#=
    chapter 11
=#



#=
    chapter 12
=#



#=
    chapter 13
=#



#=
    chapter 14
=#



#=
    chapter 15
=#



#=
    chapter 16
=#



end
