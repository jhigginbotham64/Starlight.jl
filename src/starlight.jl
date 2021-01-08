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
export rsi_demo, light_demo, scene_demo, plane_demo

# helpers
DEFAULT_TRANSFORM = Array{AbstractFloat, 2}(I(4))
export DEFAULT_TRANSFORM
Transform = Array{<:Number, 2}
export Transform
VectorN = Vector{<:Number}
export VectorN

# chapter 1
export point, vector

# chapter 2
export canvas, pixel, pixel!, pixels, flat, hadamard

# chapter 3
export submatrix, minor, cofactor, invertible

# chapter 4
export translation, scaling, reflection_x, reflection_y, reflection_z, rotation_x, rotation_y, rotation_z, shearing

# chapter 5
export ray, sphere, intersect, _intersect, intersection, intersections, Intersections, hit, transform

# chapter 6
export normal_at, _normal_at, reflect, point_light, material, lighting, round_color

# chapter 7
export world, default_world, prepare_computations, shade_hit, color_at, view_transform, camera, ray_for_pixel, render

# chapter 8
export is_shadowed

# chapter 9
export plane

# chapter 10
export pattern, pattern_at, pattern_at_object, test_pattern, stripes, gradient, rings, checkers, OptionalShape

# chapter 11
export glass_sphere, reflected_color, refracted_color, schlick
DEFAULT_RECURSION_LIMIT = 5
export DEFAULT_RECURSION_LIMIT

# chapter 12
export cube

# chapter 13
export cylinder, intersect_caps!, check_cap, cone

#=
    chapter 1
=#

# point and vector are just length-4 arrays with particular valuesin the last
# index. x, y, z, and w are kept consistently in the same index by convention
# for now, crowding the namespace with one-letter identifiers is bad and
# overriding getproperty and setproperty! for Vector is worse.
point(x, y, z) = [x, y, z, 1.0]
vector(x, y, z) = [x, y, z, 0.0]

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
    origin::VectorN
    # the book calls this field "direction", but in my mind direction
    # is a unit vector which you combine with a magnitude (speed)
    # to get velocity, and the book uses direction mathematically
    # like a velocity, so i'm calling it velocity.
    velocity::VectorN
end

abstract type pattern end # chapter 10

# material added in chapter 6, put here for compilation
mutable struct material
    color::Color
    ambient::AbstractFloat
    diffuse::AbstractFloat
    specular::AbstractFloat
    shininess::AbstractFloat
    pattern::Union{Nothing, pattern}
    reflective::AbstractFloat # chapter 11
    transparency::AbstractFloat # chapter 11
    refractive_index::AbstractFloat # chapter 11
    material(; color = colorant"white", ambient = 0.1, diffuse = 0.9, specular = 0.9, shininess = 200.0, pattern = nothing, reflective = 0.0, transparency = 0.0, refractive_index = 1.0) = new(color, ambient, diffuse, specular, shininess, pattern, reflective, transparency, refractive_index)
end

abstract type shape end # chapter 9

mutable struct sphere <: shape # chapter 9
    transform::Transform
    material::material
    sphere(; transform = DEFAULT_TRANSFORM, material = material()) = new(transform, material)
end

mutable struct intersection
    t::Number
    object
end

Intersections = Vector{intersection}

intersections(is::intersection...) = Intersections([is...])
transform(r::ray, mat::Transform) = ray(mat * r.origin, mat * r.velocity)

import Base.position
position(r::ray, t::Number) = r.origin + r.velocity * t

import Base.intersect
intersect(s::shape, r::ray) = _intersect(s, transform(r, inv(s.transform))) # chapter 9

hit(is::Intersections) = (all(map(i -> i.t < 0, is))) ? nothing : is[argmin(map(i -> (i.t < 0) ? Inf : i.t, is))]

function rsi_demo(; height=100, width=100, bg_color=colorant"black", c=colorant"red")
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

function normal_at(s::shape, p::VectorN)
    op = inv(s.transform) * p
    on = _normal_at(s, op) # chapter 9
    wn = inv(s.transform)' * on
    wn[4] = 0
    return normalize(wn)
end

reflect(v::VectorN, n::VectorN) = v - (n * (2 * (v ⋅ n)))

mutable struct point_light
    position::VectorN
    intensity::Color
end

OptionalShape = Union{Nothing, shape} # chapter 10

function lighting(m, l, p, eyev, normalv, in_shadow = false; obj::OptionalShape = nothing)
    c = (!isnothing(m.pattern)) ? pattern_at_object(m.pattern, obj, p) : m.color # chapter 10
    if in_shadow return c * m.ambient end # chapter 8
    effective_color = hadamard(c, l.intensity)
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

round_color(c::Color, digits::Int = 5) = mapc(chan -> round(chan, digits=digits), c)

function light_demo(; height=100, width=100, bg_color=colorant"black", light_color=colorant"white", mat_color=colorant"purple")
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

function default_world(; light = point_light(point(-10, 10, -10), colorant"white"), t1 = DEFAULT_TRANSFORM, m1 = material(color = RGB(0.8, 1.0, 0.6), diffuse = 0.7, specular = 0.2), t2 = scaling(0.5, 0.5, 0.5), m2 = material())
    s1 = sphere(transform = t1, material = m1)
    s2 = sphere(transform = t2, material = m2)
    w = world()
    push!(w.lights, light)
    push!(w.objects, s1, s2)
    return w
end

intersect(w::world, r::ray) = Intersections(sort([i for o in w.objects for i in intersect(o, r)], by=(i)->i.t))

mutable struct computations
    t::Number
    object
    point::VectorN
    eyev::VectorN
    normalv::VectorN
    inside::Bool
    over_point::VectorN # chapter 8
    under_point::VectorN # chapter 11
    reflectv::VectorN # chapter 11
    n1::AbstractFloat
    n2::AbstractFloat
end

function prepare_computations(i::intersection, r::ray, xs::Union{Nothing, Intersections} = nothing)
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
    shift_factor = eps() * 100000
    over_point = p + (normalv * shift_factor)

    #=
        chapter 11
    =#

    under_point = p - (normalv * shift_factor)

    reflectv = reflect(r.velocity, normalv)
    n1 = 1.0
    n2 = 1.0
    if !isnothing(xs)
        containers = []

        for x in xs
            if x == i
                if isempty(containers)
                    n1 = 1.0
                else
                    n1 = last(containers).material.refractive_index
                end
            end

            if x.object ∈ containers
                filter!(s -> s != x.object, containers)
            else
                push!(containers, x.object)
            end

            if x == i
                if isempty(containers)
                    n2 = 1.0
                else
                    n2 = last(containers).material.refractive_index
                end
                break
            end
        end
    end

    return computations(t, obj, p, eyev, normalv, inside, over_point, under_point, reflectv, n1, n2)
end

function shade_hit(w::world, c::computations, remaining::Int = DEFAULT_RECURSION_LIMIT; obj::OptionalShape = nothing)
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

    # this minus the shadow  and pattern stuff is all you need for chapter 7
    surface =
    (all(shadows)) ?
    ((isnothing(c.object.material.pattern)) ? c.object.material.color : pattern_at_object(c.object.material.pattern, c.object, c.over_point)) * c.object.material.ambient :
    sum([
        lighting(c.object.material, l, c.point, c.eyev, c.normalv, false, obj = obj) # obj added in chapter 10
        for (i, l) in enumerate(w.lights) if !shadows[i]
    ])

    # chapter 11
    reflected = reflected_color(w, c, remaining)
    refracted = refracted_color(w, c, remaining)
    m = c.object.material
    if m.reflective > 0 && m.transparency > 0
        reflectance = schlick(c)
        return surface + reflected * reflectance + refracted * (1 - reflectance)
    else
        return surface + reflected + refracted
    end
end

function color_at(w::world, r::ray, remaining::Int = DEFAULT_RECURSION_LIMIT)
    h = hit(intersect(w, r))
    c = colorant"black"
    if !isnothing(h)
        c = shade_hit(w, prepare_computations(h, r), remaining)
    end
    return c
end

function view_transform(from, to, up)
    forward = normalize(to - from)
    upn = normalize(up)
    left = vector((forward[1:3] × upn[1:3])...)
    true_up = vector((left[1:3] × forward[1:3])...)
    ornt = [
        left[1] left[2] left[3] 0
        true_up[1] true_up[2] true_up[3] 0
        -forward[1] -forward[2] -forward[3] 0
        0 0 0 1
    ]
    return ornt * translation(-from[1], -from[2], -from[3])
end

mutable struct camera
    hsize::Number
    vsize::Number
    fov::Number
    transform::Transform
    half_view::Number
    aspect::Number
    half_width::Number
    half_height::Number
    pixel_size::Number
    function camera(; hsize = 160, vsize = 120, fov = π / 2, transform = DEFAULT_TRANSFORM)
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

function scene_demo(; width = 100, height = 50, fov = π/3)
    wmat = material(color = RGB(1, 0.9, 0.9), specular = 0)

    flr = sphere(transform = scaling(10, 0.01, 10), material = wmat)
    left_wall = sphere(transform = translation(0, 0, 5) * rotation_y(-π/4) * rotation_x(π/2) * scaling(10, 0.01, 10), material = wmat)
    right_wall = sphere(transform = translation(0, 0, 5) * rotation_y(π/4) * rotation_x(π/2) * scaling(10, 0.01, 10), material = wmat)
    middle = sphere(transform = translation(-0.5, 1, 0.5), material = material(color = RGB(0.1, 1, 0.5), diffuse = 0.7, specular = 0.3))
    right = sphere(transform = translation(1.5, 0.5, -0.5) * scaling(0.5, 0.5, 0.5), material = material(color = RGB(0.5, 1, 0.1), diffuse = 0.7, specular = 0.3))
    left = sphere(transform = translation(-1.5, 0.33, -0.75) * scaling(0.33, 0.33, 0.33), material = material(color = RGB(1, 0.8, 0.1), diffuse = 0.7, specular = 0.3))

    w = world()
    push!(w.lights, point_light(point(-10, 10, -10), colorant"white"))
    push!(w.objects, flr, left_wall, right_wall, middle, right, left)

    cam = camera(hsize=width, vsize=height, fov=π/3, transform=view_transform(point(0, 1.5, -5), point(0, 1, 0), vector(0, 1, 0)))

    return render(cam, w)
end

#=
    chapter 8
=#

function is_shadowed(w::world, p::VectorN, light_no = 1)
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

# algorithm written in chapter 5 and refactored to here in chapter 9
function _intersect(s::sphere, r::ray)
    sphere_to_ray = r.origin - point(0, 0, 0) # all spheres centered at origin for now
    a = r.velocity ⋅ r.velocity
    b = 2 * r.velocity ⋅ sphere_to_ray
    c = sphere_to_ray ⋅ sphere_to_ray - 1

    discriminant = b^2 - 4 * a * c

    if discriminant < 0
        return Intersections([])
    end

    t1 = (-b - √discriminant) / 2a
    t2 = (-b + √discriminant) / 2a

    return intersections(intersection(t1, s), intersection(t2, s))
end

# algorithm written in chapter 6 and refactored to here in chapter 9
_normal_at(s::sphere, op::VectorN) = op - point(0, 0, 0)

# this is literally exactly the same as sphere,
# the only purpose of this struct is to facilitate
# dispatch. unsure how to refactor though.
mutable struct plane <: shape
    transform::Transform
    material::material
    plane(; transform = DEFAULT_TRANSFORM, material = material()) = new(transform, material)
end

function _intersect(p::plane, r::ray)
    if abs(r.velocity[2]) < eps()
        return Intersections([])
    end

    t = -r.origin[2] / r.velocity[2]
    return intersections(intersection(t, p))
end

_normal_at(p::plane, op::VectorN) = vector(0, 1, 0) # we're in object space, and the normal is the same everywhere...

function plane_demo(; width = 100, height = 50, fov = π/3)
    flr = plane(transform = scaling(10, 0.01, 10), material = material(color = RGB(1, 0.9, 0.9), specular = 0))
    middle = sphere(transform = translation(-0.5, 1, 0.5), material = material(color = RGB(0.1, 1, 0.5), diffuse = 0.7, specular = 0.3))
    right = sphere(transform = translation(1.5, 0.5, -0.5) * scaling(0.5, 0.5, 0.5), material = material(color = RGB(0.5, 1, 0.1), diffuse = 0.7, specular = 0.3))
    left = sphere(transform = translation(-1.5, 0.33, -0.75) * scaling(0.33, 0.33, 0.33), material = material(color = RGB(1, 0.8, 0.1), diffuse = 0.7, specular = 0.3))

    w = world()
    push!(w.lights, point_light(point(-10, 10, -10), colorant"white"))
    push!(w.objects, flr, middle, right, left)

    cam = camera(hsize=width, vsize=height, fov=π/3, transform=view_transform(point(0, 1.5, -5), point(0, 1, 0), vector(0, 1, 0)))

    return render(cam, w)
end

#=
    chapter 10

    TODO: look into refactoring these pattern structs with macros or something
=#

# chapter 11
mutable struct test_pattern <: pattern
    transform::Transform
    test_pattern(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = new(transform)
end

mutable struct stripes <: pattern
    a::Color
    b::Color
    transform::Transform
    stripes(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = new(a, b, transform)
end

mutable struct gradient <: pattern
    a::Color
    b::Color
    transform::Transform
    gradient(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = new(a, b, transform)
end

mutable struct rings <: pattern
    a::Color
    b::Color
    transform::Transform
    rings(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = new(a, b, transform)
end

mutable struct checkers <: pattern
    a::Color
    b::Color
    transform::Transform
    checkers(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = new(a, b, transform)
end

pattern_at(pat::test_pattern, p::VectorN) = RGB(AbstractFloat.(p[1:3])...)
pattern_at(pat::stripes, p::VectorN) = (floor(p[1]) % 2 == 0) ? pat.a : pat.b
function pattern_at(pat::gradient, p::VectorN)
    # when you want to handle "negative colors" differently than your library
    a, b = pat.a, pat.b
    ar, ag, ab = AbstractFloat.([red(a), green(a), blue(a)])
    br, bg, bb = AbstractFloat.([red(b), green(b), blue(b)])
    dr, dg, db = [br - ar, bg - ag, bb - ab] * (p[1] - floor(p[1]))
    return RGB(red(pat.a) + dr, green(pat.a) + dg, blue(pat.a) + db)
end
pattern_at(pat::rings, p::VectorN) = (floor(√(p[1]^2 + p[3]^2)) % 2 == 0) ? pat.a : pat.b
pattern_at(pat::checkers, p::VectorN) = (sum(floor.(p[1:3])) % 2 == 0) ? pat.a : pat.b
pattern_at_object(pat::pattern, obj::OptionalShape, wp::VectorN) = (!isnothing(obj)) ? pattern_at(pat, inv(pat.transform) * inv(obj.transform) * wp) : pattern_at(pat, wp)

#=
    chapter 11
=#

# a helper the book uses, without which some test cases are confusing to transcribe
glass_sphere() = sphere(material = material(transparency = 1.0, refractive_index = 1.5))

function reflected_color(w::world, comps::computations, remaining::Int = DEFAULT_RECURSION_LIMIT)
    if comps.object.material.reflective == 0 || remaining <= 0 return colorant"black" end
    reflect_ray = ray(comps.over_point, comps.reflectv)
    c = color_at(w, reflect_ray, remaining - 1)
    return c * comps.object.material.reflective
end

function refracted_color(w::world, comps::computations, remaining::Int = DEFAULT_RECURSION_LIMIT)
    if comps.object.material.transparency == 0 || remaining <= 0 return colorant"black" end

    n_ratio = comps.n1 / comps.n2
    cos_i = comps.eyev ⋅ comps.normalv
    sin2_t = n_ratio^2 * (1 - cos_i^2)

    if sin2_t > 1 return colorant"black" end # snell's law

    cos_t = √(1.0 - sin2_t)
    dir = comps.normalv * (n_ratio * cos_i - cos_t) - comps.eyev * n_ratio
    refract_ray = ray(comps.under_point, dir)

    return color_at(w, refract_ray, remaining - 1) * comps.object.material.transparency
end

function schlick(c::computations)
    _cos = c.eyev ⋅ c.normalv

    if c.n1 > c.n2
        n = c.n1 / c.n2
        sin2_t = n^2 * (1.0 - _cos^2)
        if sin2_t > 1.0 return 1.0 end

        cos_t = √(1.0 - sin2_t)
        _cos = cos_t
    end

    r0 = ((c.n1 - c.n2) / (c.n1 + c.n2))^2

    return r0 + (1 - r0) * (1 - _cos)^5
end

#=
    chapter 12
=#

mutable struct cube <: shape
    transform::Transform
    material::material
    cube(; transform = DEFAULT_TRANSFORM, material = material()) = new(transform, material)
end

function check_axis(origin::AbstractFloat, direction::AbstractFloat)
    tmin_numerator = (-1 - origin)
    tmax_numerator = (1 - origin)

    tmin = tmin_numerator * Inf
    tmax = tmax_numerator * Inf

    if abs(direction) >= eps()
        tmin = tmin_numerator / direction
        tmax = tmax_numerator / direction
    end

    return min(tmin, tmax), max(tmin, tmax)
end

function _intersect(c::cube, r::ray)
    xtmin, xtmax = check_axis(r.origin[1], r.velocity[1])
    ytmin, ytmax = check_axis(r.origin[2], r.velocity[2])
    ztmin, ztmax = check_axis(r.origin[3], r.velocity[3])

    tmin = max(xtmin, ytmin, ztmin)
    tmax = min(xtmax, ytmax, ztmax)

    if tmin > tmax return Intersections([]) end

    return intersections(intersection(tmin, c), intersection(tmax, c))
end

function _normal_at(c::cube, op::VectorN)
    maxc = max(abs(op[1]), abs(op[2]), abs(op[3]))

    if maxc == abs(op[1]) return vector(op[1], 0, 0)
    elseif maxc == abs(op[2]) return vector(0, op[2], 0)
    else return vector(0, 0, op[3]) end
end

#=
    chapter 13
=#

mutable struct cylinder <: shape
    transform::Transform
    material::material
    min::AbstractFloat
    max::AbstractFloat
    closed::Bool
    cylinder(; transform = DEFAULT_TRANSFORM, material = material(), min = -Inf, max = Inf, closed = false) = new(transform, material, min, max, closed)
end

function check_cap(r::ray, t::AbstractFloat)
    x = r.origin[1] + t * r.velocity[1]
    z = r.origin[3] + t * r.velocity[3]

    return (x^2 + z^2) <= 1
end

function intersect_caps!(xs::Intersections, c::cylinder, r::ray)
    if !c.closed || r.velocity[2] ≈ 0 return end
    t1 = (c.min - r.origin[2]) / r.velocity[2]
    if check_cap(r, t1) push!(xs, intersection(t1, c)) end
    t2 = (c.max - r.origin[2]) / r.velocity[2]
    if check_cap(r, t2) push!(xs, intersection(t2, c)) end
end

function _intersect(c::cylinder, r::ray)
    xs = Intersections([])

    intersect_caps!(xs, c, r)

    a = r.velocity[1]^2 + r.velocity[3]^2
    if a ≈ 0 return xs end

    b = 2 * r.origin[1] * r.velocity[1] + 2 * r.origin[3] * r.velocity[3]
    _c = r.origin[1]^2 + r.origin[3]^2 - 1
    disc = b^2 - 4 * a * _c
    if disc < 0 return xs end

    t0 = (-b - √disc) / 2a
    t1 = (-b + √disc) / 2a

    t0, t1 = min(t0, t1), max(t0, t1)

    y0 = r.origin[2] + t0 * r.velocity[2]
    if c.min < y0 && y0 < c.max
        push!(xs, intersection(t0, c))
    end

    y1 = r.origin[2] + t1 * r.velocity[2]
    if c.min < y1 && y1 < c.max
        push!(xs, intersection(t1, c))
    end

    return xs
end

function _normal_at(c::cylinder, op::VectorN)
    dist = op[1]^2 + op[3]^2
    if dist < 1 && op[2] >= c.max - eps()
        return vector(0, 1, 0)
    elseif dist < 1 && op[2] <= c.min + eps()
        return vector(0, -1, 0)
    else
        return vector(op[1], 0, op[3])
    end
end

mutable struct cone <: shape
    transform::Transform
    material::material
    min::AbstractFloat
    max::AbstractFloat
    closed::Bool
    cone(; transform = DEFAULT_TRANSFORM, material = material(), min = -Inf, max = Inf, closed = false) = new(transform, material, min, max, closed)
end

function check_cap(r::ray, t::AbstractFloat, y::AbstractFloat)
    x = r.origin[1] + t * r.velocity[1]
    z = r.origin[3] + t * r.velocity[3]

    return (x^2 + z^2) <= abs(y)
end

function intersect_caps!(xs::Intersections, c::cone, r::ray)
    if !c.closed || r.velocity[2] ≈ 0 return end
    t1 = (c.min - r.origin[2]) / r.velocity[2]
    if check_cap(r, t1, c.min) push!(xs, intersection(t1, c)) end
    t2 = (c.max - r.origin[2]) / r.velocity[2]
    if check_cap(r, t2, c.max) push!(xs, intersection(t2, c)) end
end

function _intersect(c::cone, r::ray)
    xs = Intersections([])

    intersect_caps!(xs, c, r)

    a = r.velocity[1]^2 - r.velocity[2]^2 + r.velocity[3]^2
    b = 2 * r.origin[1] * r.velocity[1] - 2 * r.origin[2] * r.velocity[2] + 2 * r.origin[3] * r.velocity[3]
    _c = r.origin[1]^2 - r.origin[2]^2 + r.origin[3]^2

    if a ≈ 0 && b ≈ 0 return xs
    elseif a ≈ 0
        t = -_c / 2b
        push!(xs, intersection(t, c))
        return xs
    end

    disc = b^2 - 4 * a * _c
    if disc < 0 return xs end

    t0 = (-b - √disc) / 2a
    t1 = (-b + √disc) / 2a

    t0, t1 = min(t0, t1), max(t0, t1)

    y0 = r.origin[2] + t0 * r.velocity[2]
    if c.min < y0 && y0 < c.max
        push!(xs, intersection(t0, c))
    end

    y1 = r.origin[2] + t1 * r.velocity[2]
    if c.min < y1 && y1 < c.max
        push!(xs, intersection(t1, c))
    end

    return xs
end

function _normal_at(c::cone, op::VectorN)
    dist = op[1]^2 + op[3]^2
    if dist < 1 && op[2] >= c.max - eps()
        return vector(0, 1, 0)
    elseif dist < 1 && op[2] <= c.min + eps()
        return vector(0, -1, 0)
    else
        y = √(op[1]^2 + op[3]^2)
        if op[2] > 0 y = -y end
        return vector(op[1], y, op[3])
    end
end

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
