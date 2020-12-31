module starlight

using Reexport
@reexport using Images
@reexport using ColorVectorSpace
@reexport using FileIO
@reexport using LinearAlgebra
@reexport using SimpleDirectMediaLayer

SDL2 = SimpleDirectMediaLayer
export SDL2

# demo
export rsi_demo, light_demo, scene_demo

# chapter 1
export point, vector, x, x!, y, y!, z, z!, w, w!

# chapter 2
export canvas, pixel, pixel!, pixels, flat, hadamard

# chapter 3
export submatrix, minor, cofactor, invertible

# chapter 4
export translation, scaling, reflection_x, reflection_y, reflection_z, rotation_x, rotation_y, rotation_z, shearing

# chapter 5
export ray, sphere, intersect, intersection, intersections, hit, transform

# chapter 6
export normal_at, reflect, point_light, material, lighting, round_color

# chapter 7
export world, default_world, prepare_computations, shade_hit, color_at, view_transform, camera, ray_for_pixel, render

# chapter 8
export is_shadowed

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
    # the book calls this field "direction", but in my mind direction
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
    material(; color = colorant"white", ambient = 0.1, diffuse = 0.9, specular = 0.9, shininess = 200.0) = new(color, ambient, diffuse, specular, shininess)
end

mutable struct sphere
    origin::Vector{<:Number}
    transform::Array{<:Number, 2}
    material::material
    sphere(; origin = point(0, 0, 0), transform = Array{Float64, 2}(I(4)), material = material()) = new(origin, transform, material)
end

mutable struct intersection
    t::Number
    object
end

intersections(is::intersection...) = [is...]
transform(r::ray, mat::Array{<:Number, 2}) = ray(mat * r.origin, mat * r.velocity)

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

function rsi_demo(height=100, width=100, bg_color=colorant"black", c=colorant"red")
    canv = canvas(width, height)

    s = sphere()

    ray_origin = point(0, 0, -5)
    wz = 10 # wall z
    wall_size = 7.0
    half = wall_size / 2
    pixel_size = wall_size / width # can't accomodate stretching yet?

    for y = 1:height
        wy = half - pixel_size * y
        for x = 1:width
            wx = -half + pixel_size * x
            pos = point(wx, wy, wz)
            r = ray(ray_origin, normalize(pos - ray_origin))
            xs = intersect(s, r)
            if !isnothing(hit(xs))
                pixel!(canv, x, y, c)
            end
        end
    end

    return canv
end

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

function lighting(m, l, p, eyev, normalv, in_shadow = false)
    if in_shadow return m.color * m.ambient end # chapter 8
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

round_color(c::Color, ndigits::Int = 5) = mapc(chan -> round(chan, digits=ndigits), c)

function light_demo(height=100, width=100, bg_color=colorant"black", light_color=colorant"white", mat_color=colorant"purple")
    canv = canvas(width, height, bg_color)

    s = sphere(material = material(color = mat_color))
    l = point_light(point(-10, 10, -10), light_color)

    ray_origin = point(0, 0, -5)
    wz = 10 # wall z
    wall_size = 7.0
    half = wall_size / 2
    pixel_size = wall_size / width # can't accomodate stretching yet?

    for y = 1:height
        wy = half - pixel_size * y
        for x = 1:width
            wx = -half + pixel_size * x
            pos = point(wx, wy, wz)
            r = ray(ray_origin, normalize(pos - ray_origin))
            xs = intersect(s, r)
            h = hit(xs)
            if !isnothing(h)
                pos2 = position(r, h.t)
                n = normal_at(h.object, pos2)
                eye = -r.velocity
                c = lighting(h.object.material, l, pos2, eye, n)
                pixel!(canv, x, y, mapc(chan -> clamp(chan, 0, 1), c))
            end
        end
    end

    return canv
end

#=
    chapter 7
=#

mutable struct world
    lights
    objects
    world(; lights = [], objects = []) = new(lights, objects)
end

function default_world(; light = point_light(point(-10, 10, -10), colorant"white"), t1 = Array{Float64, 2}(I(4)), m1 = material(color = RGB(0.8, 0.1, 0.6), diffuse = 0.7, specular = 0.2), t2 = scaling(0.5, 0.5, 0.5), m2 = material())
    s1 = sphere(transform = t1, material = m1)
    s2 = sphere(transform = t2, material = m2)
    wrld = world()
    push!(wrld.lights, light)
    push!(wrld.objects, s1, s2)
    return wrld
end

intersect(w::world, r::ray) = Vector{intersection}(sort([i for o in w.objects for i in intersect(o, r)], by=(i)->i.t))

mutable struct computations
    t::Number
    object
    point::Vector{<:Number}
    eyev::Vector{<:Number}
    normalv::Vector{<:Number}
    inside::Bool
    over_point::Vector{<:Number} # chapter 8
end

function prepare_computations(i::intersection, r::ray)
    t = i.t
    obj = i.object
    p = position(r, t)
    eyev = -r.velocity
    normalv = normal_at(obj, p)
    inside = false
    if normalv ⋅ eyev < 0
        normalv = -normalv
        inside = true
    end
    #=
        chapter 8

        the book has us adjusting only by ϵ, but that doesn't appear
        to be enough for me. so i added zeros until the "fleas" went
        away, and i'll revisit my approach later if it breaks somehow.
    =#
    over_point = p + (normalv * eps() * 100000)
    return computations(t, obj, p, eyev, normalv, inside, over_point)
end

function shade_hit(w::world, c::computations)
    #=
        chapter 8

        doing shadows with multiple lights is sorta weird.
        something in shadow from one light may not be in shadow
        from a different light, but the expected lighting result
        for a point in shadow is always the ambient color of the
        object's material, so in a scene with multiple lights an
        object that is unlit by several of them will have its ambient
        color added multiple times, which doesn't seem right, and
        this isn't a case the book tests. nor is it simple to do this
        inside the lighting function. my solution for this is to do
        all the shadow calculations before the lighting calculations
        and either use the results in the sum or straight-up return
        the object's ambient color.
        unsure how to handle the object's ambient color being added multiple
        times from multiple light sources, but for now i'll assume that will
        be handled by the blending that occurs in the lighting function.
        i guess for several lit vs unlit sources, i'd need to sum the results
        from only the lit ones.
    =#
    shadows = [is_shadowed(w, c.over_point, i) for i=1:length(w.lights)]
    if all(shadows) return c.object.material.color * c.object.material.ambient end

    # this minus the shadow stuff is all you need for chapter 7
    return sum([
        lighting(c.object.material, l, c.point, c.eyev, c.normalv, shadows[i])
        for (i, l) in enumerate(w.lights) if !shadows[i]
    ])
end

function color_at(w::world, r::ray)
    h = hit(intersect(w, r))
    c = colorant"black"
    if !isnothing(h)
        c = shade_hit(w, prepare_computations(h, r))
    end
    return c
end

function view_transform(from, to, up)
    forward = normalize(to - from)
    upn = normalize(up)
    left = vector((forward[1:3] × upn[1:3])...)
    true_up = vector((left[1:3] × forward[1:3])...)
    ornt = [
        x(left) y(left) z(left) 0
        x(true_up) y(true_up) z(true_up) 0
        -x(forward) -y(forward) -z(forward) 0
        0 0 0 1
    ]
    return ornt * translation(-x(from), -y(from), -z(from))
end

mutable struct camera
    hsize::Number
    vsize::Number
    fov::Number
    transform::Array{<:Number, 2}
    half_view::Number
    aspect::Number
    half_width::Number
    half_height::Number
    pixel_size::Number
    function camera(; hsize = 160, vsize = 120, fov = π / 2, transform = Array{Float64, 2}(I(4)))
        half_view = tan(fov / 2)
        aspect = hsize / vsize
        half_width = half_view
        half_height = half_view
        if aspect >= 1
            half_height /= aspect
        else
            half_width *= aspect
        end
        pixel_size = (half_width * 2) / hsize
        return new(hsize, vsize, fov, transform, half_view, aspect, half_width, half_height, pixel_size)
    end
end

function ray_for_pixel(c::camera, px::Int, py::Int)
    xoff = (px + 0.5) * c.pixel_size
    yoff = (py + 0.5) * c.pixel_size
    wx = c.half_width - xoff
    wy = c.half_height - yoff
    pix = inv(c.transform) * point(wx, wy, -1)
    orgn = inv(c.transform) * point(0, 0, 0)
    dir = normalize(pix - orgn)
    return ray(orgn, dir)
end

function render(c::camera, w::world)
    img = canvas(c.hsize, c.vsize)
    for y=1:c.vsize
        for x=1:c.hsize
            r = ray_for_pixel(c, x, y)
            col = color_at(w, r)
            # idk why i have to swap x and y here, there's probably
            # a really good mathematical reason for it and i can probably
            # fix it...but i don't really want to right now...
            pixel!(img, y, x, mapc(chan -> clamp(chan, 0, 1), col))
        end
    end
    return img
end

function scene_demo(width = 100, height = 50, fov = π/3)
    wmat = material(color = RGB(1, 0.9, 0.9), specular = 0)

    floor = sphere(transform = scaling(10, 0.01, 10), material = wmat)
    left_wall = sphere(transform = translation(0, 0, 5) * rotation_y(-π/4) * rotation_x(π/2) * scaling(10, 0.01, 10), material = wmat)
    right_wall = sphere(transform = translation(0, 0, 5) * rotation_y(π/4) * rotation_x(π/2) * scaling(10, 0.01, 10), material = wmat)
    middle = sphere(transform = translation(-0.5, 1, 0.5), material = material(color = RGB(0.1, 1, 0.5), diffuse = 0.7, specular = 0.3))
    right = sphere(transform = translation(1.5, 0.5, -0.5) * scaling(0.5, 0.5, 0.5), material = material(color = RGB(0.5, 1, 0.1), diffuse = 0.7, specular = 0.3))
    left = sphere(transform = translation(-1.5, 0.33, -0.75) * scaling(0.33, 0.33, 0.33), material = material(color = RGB(1, 0.8, 0.1), diffuse = 0.7, specular = 0.3))

    wrld = world()
    push!(wrld.lights, point_light(point(-10, 10, -10), colorant"white"))
    push!(wrld.objects, floor, left_wall, right_wall, middle, right, left)

    cam = camera(hsize=width, vsize=height, fov=π/3, transform=view_transform(point(0, 1.5, -5), point(0, 1, 0), vector(0, 1, 0)))

    return render(cam, wrld)
end

#=
    chapter 8
=#

function is_shadowed(w::world, p::Vector{<:Number}, light_no = 1)
    v = w.lights[light_no].position - p
    dist = norm(v)
    dir = normalize(v)
    r = ray(p, dir)
    is = intersect(w, r)
    h = hit(is)
    return !isnothing(h) && h.t < dist
end

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
