module RayTracing

using Reexport
@reexport using FileIO
@reexport using DelimitedFiles
@reexport using YAML
@reexport using UUIDs
@reexport using LinearAlgebra
@reexport using Images
@reexport using ColorVectorSpace

# helpers
DEFAULT_TRANSFORM = Array{Float64, 2}(I(4))
Transform = Array{Float64, 2}
VectorF = Vector{Float64}
optional{T} = Union{Nothing, T} # found myself doing this a lot
exists(thing) = !isnothing(thing) # and this

# important values
DEFAULT_RECURSION_LIMIT = 5 # number of reflections/refractions for a single ray
DEFAULT_BVH_THRESHOLD = 500 # https://forum.raytracerchallenge.com/post/1029/thread
my_eps = eps() * 1e8
my_floor(x::Number) = (abs(x) <= my_eps) ? 0.0 : floor(x)

export DEFAULT_TRANSFORM
export Transform
export VectorF
export optional
export exists
export DEFAULT_RECURSION_LIMIT
export DEFAULT_BVH_THRESHOLD
export my_eps, my_floor

export point, vector, cross
export canvas, pixel, pixel!, pixels, flat, hadamard
export translation, scaling, reflection_x, reflection_y, reflection_z
export rotation_x, rotation_y, rotation_z, shearing
export ray, sphere, intersect, _intersect, intersection
export intersections, Intersections, hit, transform
export normal_at, _normal_at, reflect, point_light, material, lighting
export round_color, clamp_color, scale_color_component, descale_color_component
export world, default_world, prepare_computations, shade_hit, color_at
export view_transform, camera, ray_for_pixel, raytrace
export is_shadowed
export shape, test_shape, plane
export pattern, pattern_at, pattern_at_object
export test_pattern, stripes, gradient, rings, checkers
export glass_sphere, reflected_color, refracted_color, schlick
export cube, check_axis
export cylinder, intersect_caps!, check_cap, cone
export group, propagate_material!, add_child!, has_child
export inherited_transform, world_to_object, normal_to_world
export aabb, _bounds, explode_aabb, bounds, intersects
export add_points!, partition!, subgroup!, divide!
export triangle, smooth_triangle
export csg, intersection_allowed, csg_filter
export point_on_light, area_light, intensity_at, sequence, next
export uv_pattern, uv_checkers, uv_align_check, texture_map, cube_map, image_map
export spherical_uv_map, planar_uv_map, cylindrical_uv_map
export cubical_uv_map, faces, LEFT, RIGHT, FRONT, BACK, UP, DOWN, face
export advance_xy, nice_str, ppm_mat, save_ppm, load_ppm, load_obj, OBJ, fan
export is_aggregate, scene, load_scene, update_cache!, chain_transforms
export parse_uvpat, apply_material!, parse_entity, add_entity!, raytrace_scene
export fir_branch

#= BASIC MATH STUFF =#

# point and vector are just length-4 arrays with particular valuesin the last
# index. x, y, z, and w are kept consistently in the same index by convention
# for now, crowding the namespace with one-letter identifiers is bad and
# overriding getproperty and setproperty! for Vector is worse.
point(x, y, z) = [x, y, z, 1.0]
vector(x, y, z) = [x, y, z, 0.0]
# cross(x, y) == y × x, NOT x × y. this is due to matching up test
# cases with the expectations of julia's cross product function.
cross(x::VectorF, y::VectorF) = vector((y[1:3] × x[1:3])...)
# reflect v over n
reflect(v::VectorF, n::VectorF) = v - (n * (2 * (v ⋅ n)))

#= CANVAS AND COLOR OPERATIONS =#

# height is number of rows, which in julia is the first dimension.
# width is number of columns, which in julia is the second dimension.
# also you have to be careful about Color types if precision matters to you.
canvas(w::Int, h::Int, c = RGB{Float64}(colorant"black")) = fill(c, (h, w))
pixel(mat, x::Int, y::Int) = mat[y,x]
pixel!(mat, x::Int, y::Int, c::Color) = mat[y,x] = c
flat(mat) = reshape(mat, (prod(size(mat)), 1))
pixels(mat) = flat(mat)
# stopgap solution from https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/119#issuecomment-573167024
# while waiting for long-term solution from https://github.com/JuliaGraphics/ColorVectorSpace.jl/issues/126
hadamard(c1, c2) = mapc(*, c1, c2)
round_color(c::Color, digits::Int = 5) = mapc(chan -> round(chan, digits=digits), c)
clamp_color(c::Color) = mapc(chan -> clamp(chan, 0, 1), c)
scale_color_component(c::Number; scale=255) = Int(round(clamp(c * scale, 0, scale)))
descale_color_component(c::Number; scale=255) = clamp(c / scale, 0, 1)

#= TRANSFORMATION MATRICES =#

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

reflection_x() = scaling(-1, 1, 1)
reflection_y() = scaling(1, -1, 1)
reflection_z() = scaling(1, 1, -1)

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

#= ABSTRACT TYPES =#

# NOTE could improve related code with type contracts and/or holy traits
# NOTE need more abstract types / a larger type tree
abstract type shape end
abstract type pattern end

#= AXIALLY-ALIGNED BOUNDING BOXES =#

mutable struct aabb
    min::VectorF
    max::VectorF
    aabb() = new(point(Inf, Inf, Inf), point(-Inf, -Inf, -Inf))
end

aabb(ps::VectorF...) = add_points!(aabb(), ps...)
aabb(bs::aabb...) = add_points!(aabb(), bs...)

function add_points!(b::aabb, ps::VectorF...)
    b.min = point([min(b.min[i], [p[i] for p ∈ ps]...) for i=1:3]...)
    b.max = point([max(b.max[i], [p[i] for p ∈ ps]...) for i=1:3]...)
    return b
end

add_points!(b::aabb, b2::aabb) = add_points!(b, b2.min, b2.max)

function add_points!(b::aabb, bs::aabb...)
    foreach(b2 -> add_points!(b, b2), bs)
    return b
end

import Base.contains
contains(b::aabb, p::VectorF) = all([b.min[i] <= p[i] <= b.max[i] for i=1:3])
contains(b::aabb, b2::aabb) = contains(b, b2.min) && contains(b, b2.max)
contains(b::aabb, s::shape) = contains(b, s.bbox)

explode_aabb(bs::aabb) =
    # goes around the top "counterclockwise" from min, then down, then around
    # "clockwise" to max, giving us all 8 corners of the bounding box
    (bs.min, point(bs.min[1], bs.min[2], bs.max[3]),
    point(bs.max[1], bs.min[2], bs.max[3]), point(bs.max[1], bs.min[2], bs.min[3]),
    point(bs.max[1], bs.max[2], bs.min[3]), point(bs.min[1], bs.max[2], bs.min[3]),
    point(bs.min[1], bs.max[2], bs.max[3]), bs.max)

# this transform takes an aabb and a Transform,
# explodes the aabb, transforms the points, and
# returns a new aabb with the new points
function transform(b::aabb, mat::Transform)
    ps = explode_aabb(b)
    # remember that IEEE 754 defines Inf * 0 as NaN, which is
    # not the behavior you'd normally expect in graphics-land,
    # but is a highly probable occurrence when working specifically
    # with bounding boxes. this next if statement looks like a
    # small optimization, and it is, but its real purpose is to step
    # around a few such occurrences.
    if mat != I ps = map(p -> mat * p, ps) end
    return aabb(ps...)
end

#= CACHING TRANSFORMS AND BOUNDING BOXES =#

is_aggregate(s::shape) = s isa group || s isa csg

inherited_transform(s::shape)::Transform = ((exists(s.parent)) ? inherited_transform(s.parent) : DEFAULT_TRANSFORM) * s.transform
bounds(s::shape) = transform(_bounds(s), !(is_aggregate(s)) ? s.inherited_transform : DEFAULT_TRANSFORM)

function update_cache!(s, t = nothing)
    if !exists(t) t = s.transform end
    st = typeof(s)
    if hasfield(st, :transform)
        s.transform = t
        if hasfield(st, :inverse_transform)
            s.inverse_transform = inv(s.transform)
        end
        if hasfield(st, :inherited_transform)
            s.inherited_transform = inherited_transform(s)
            if hasfield(st, :inverse_inherited_transform)
                s.inverse_inherited_transform = inv(s.inherited_transform)
            end
        end
    end
    if s isa group foreach(c -> update_cache!(c), s.children)
    elseif s isa csg
        update_cache!(s.l)
        update_cache!(s.r)
    end
    # this has to go after children are updated, or shapes
    # that depend on child transforms for their bounding boxes
    # will not update correctly
    if hasfield(st, :bbox) s.bbox = bounds(s) end
    return s
end

#= RAYS AND INTERSECTIONS =#

mutable struct ray
    origin::VectorF
    velocity::VectorF
end

mutable struct intersection
    t::Number
    object::shape
    u::optional{Number}
    v::optional{Number}
    intersection(t, object; u = nothing, v = nothing) = new(t, object, u, v)
end

Intersections = Vector{intersection}

intersections(is::intersection...) = Intersections([is...])
transform(r::ray, mat::Array{Int, 2}) = transform(r, Float64.(mat))
transform(r::ray, mat::Transform) = ray(mat * r.origin, mat * r.velocity)

import Base.position
position(r::ray, t::Number) = r.origin + r.velocity * t

import Base.intersect
intersect(s::shape, r::ray) = _intersect(s, (is_aggregate(s)) ? r : transform(r, s.inverse_inherited_transform))

hit(is::Intersections) = (all(map(i -> i.t < 0, is))) ? nothing : is[argmin(map(i -> (i.t < 0) ? Inf : i.t, is))]

intersects(s::shape, r::ray) = (!(s isa group) || !isempty(s.children)) ? intersects(s.bbox, r) : false

function check_axis(origin::Float64, direction::Float64, axmin::Float64=-1.0, axmax::Float64=1.0)
    tmin_numerator = (axmin - origin)
    tmax_numerator = (axmax - origin)

    tmin = tmin_numerator * Inf
    tmax = tmax_numerator * Inf

    if abs(direction) >= my_eps
        tmin = tmin_numerator / direction
        tmax = tmax_numerator / direction
    end

    return min(tmin, tmax), max(tmin, tmax)
end

function intersects(b::aabb, r::ray)
    # almost identical to cube intersection
    xtmin, xtmax = check_axis(r.origin[1], r.velocity[1], b.min[1], b.max[1])
    ytmin, ytmax = check_axis(r.origin[2], r.velocity[2], b.min[2], b.max[2])
    ztmin, ztmax = check_axis(r.origin[3], r.velocity[3], b.min[3], b.max[3])

    tmin = max(xtmin, ytmin, ztmin)
    tmax = min(xtmax, ytmax, ztmax)

    if tmin > tmax return false end

    return true
end

#= WORLDS =#

mutable struct world
    lights
    objects
    world(; lights = [], objects = []) = new(lights, objects)
end

intersect(w::world, r::ray) = Intersections(sort([i for o in w.objects for i in intersect(o, r)], by=(i)->i.t))

world_to_object(s::shape, p::VectorF) = s.inverse_inherited_transform * p

function normal_to_world(s::shape, n::VectorF)
    n = s.inverse_inherited_transform' * n
    n[4] = 0
    normalize!(n)
    return n
end

function normal_at(s::shape, p::VectorF; hit::optional{intersection} = nothing)
    lp = world_to_object(s, p)
    ln = _normal_at(s, lp, hit=hit)
    return normal_to_world(s, ln)
end

function default_world(;
    light = point_light(point(-10, 10, -10), colorant"white"),
    t1 = DEFAULT_TRANSFORM,
    m1 = material(color = RGB(0.8, 1.0, 0.6), diffuse = 0.7, specular = 0.2),
    t2 = scaling(0.5, 0.5, 0.5),
    m2 = material())

    s1 = sphere(transform = t1, material = m1)
    s2 = sphere(transform = t2, material = m2)
    w = world()
    push!(w.lights, light)
    push!(w.objects, s1, s2)
    return w
end

#= CAMERAS =#

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
    inverse_transform::Transform
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
        return update_cache!(new(hsize, vsize, fov, transform, half_view, aspect, half_width, half_height, pixel_size, DEFAULT_TRANSFORM))
    end
end

# almost always used to intialize a camera transform
function view_transform(from, to, up)
    forward = normalize(to - from)
    upn = normalize(up)
    left = cross(upn, forward)
    true_up = cross(forward, left)
    ornt = [
        left[1] left[2] left[3] 0
        true_up[1] true_up[2] true_up[3] 0
        -forward[1] -forward[2] -forward[3] 0
        0 0 0 1
    ]
    return ornt * translation(-from[1], -from[2], -from[3])
end

function ray_for_pixel(c::camera, px::Int, py::Int)
    xoff = (px + 0.5) * c.pixel_size
    yoff = (py + 0.5) * c.pixel_size
    wx = c.half_width - xoff
    wy = c.half_height - yoff
    pix = c.inverse_transform * point(wx, wy, -1)
    orgn = c.inverse_transform * point(0, 0, 0)
    dir = normalize(pix - orgn)
    return ray(orgn, dir)
end

#= RAY TRACING =#

function raytrace(cam::camera, w::world)
    img = canvas(cam.hsize, cam.vsize)
    for y=1:cam.vsize
        for x=1:cam.hsize
            r = ray_for_pixel(cam, x, y)
            c = color_at(w, r)
            pixel!(img, x, y, clamp_color(c))
        end
    end
    return img
end

mutable struct computations
    t::Number
    object
    point::VectorF
    eyev::VectorF
    normalv::VectorF
    inside::Bool
    over_point::VectorF
    under_point::VectorF
    reflectv::VectorF
    n1::Float64
    n2::Float64
end

function prepare_computations(i::intersection, r::ray, xs::optional{Intersections} = nothing)
    t = i.t
    object = i.object
    p = position(r, t)
    eyev = -r.velocity
    normalv = normal_at(object, p, hit=i)
    inside = false
    if normalv ⋅ eyev < 0
        normalv = -normalv
        inside = true
    end

    over_point = p + (normalv * my_eps) # add zeros until the fleas go away

    under_point = p - (normalv * my_eps)

    reflectv = reflect(r.velocity, normalv)
    n1 = 1.0
    n2 = 1.0
    if exists(xs)
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

    return computations(t, object, p, eyev, normalv, inside, over_point, under_point, reflectv, n1, n2)
end

function color_at(w::world, r::ray, remaining::Int = DEFAULT_RECURSION_LIMIT)
    is = intersect(w, r)
    h = hit(is)
    c = colorant"black"
    if exists(h)
        c = shade_hit(w, prepare_computations(h, r, is), remaining)
    end
    return c
end

function shade_hit(w::world, c::computations, remaining::Int = DEFAULT_RECURSION_LIMIT)
    surface = sum(map(l -> lighting(c.object.material, l, c.over_point, c.eyev, c.normalv, intensity_at(l, c.over_point, w), object = c.object), w.lights))
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

#= LIGHTING =#

function lighting(m, l, p, eyev, normalv, intensity = 1.0; object::optional{shape} = nothing)
    # this convoluted expression is necessary for lighting test cases where you have a material without an object
    c = (exists(m.pattern)) ? ((exists(object)) ? pattern_at_object(m.pattern, object, p) : pattern_at(m.pattern, p)) : m.color
    effective_color = hadamard(c, l.intensity)
    ambient = effective_color * m.ambient
    dssum = colorant"black"
    for v=0:l.vsteps-1
        for u=0:l.usteps-1
            diffuse = colorant"black"
            specular = colorant"black"

            pos = point_on_light(l, u, v)
            lightv = normalize(pos - p)
            light_dot_normal = lightv ⋅ normalv
            if light_dot_normal >= 0
                diffuse = effective_color * m.diffuse * light_dot_normal
                reflectv = reflect(-lightv, normalv)
                reflect_dot_eye = reflectv ⋅ eyev
                if reflect_dot_eye > 0
                    factor = reflect_dot_eye ^ m.shininess
                    specular = l.intensity * m.specular * factor
                end
            end

            dssum += diffuse + specular
        end
    end

    return ambient + (dssum / l.samples) * intensity
end

function is_shadowed(w::world, lpos::VectorF, p::VectorF)
    v = lpos - p
    dist = norm(v)
    dir = normalize(v)
    r = ray(p, dir)
    is = intersect(w, r)
    return any(i -> i.t < dist && i.t > 0 && i.object.shadow, is)
end

mutable struct sequence
    elems::VectorF
    pos::Int
    sequence(elems::Float64...) = new([elems...], 1)
end

sequence(elems::Number...) = sequence(Float64.(elems)...)

function next(s::sequence)
    if length(s.elems) > 0
        e = s.elems[s.pos]
        s.pos += 1
        if s.pos > length(s.elems) s.pos = 1 end
    else e = rand() end
    return e
end

mutable struct area_light
    corner::VectorF
    uvec::VectorF
    usteps::Number
    vvec::VectorF
    vsteps::Number
    samples::Number
    intensity::Color
    jitter_by::sequence # will need to be refactored for "real" renders
    area_light(corner, uvec, usteps, vvec, vsteps, intensity = colorant"white", seq = sequence(0.5)) = new(corner, uvec / usteps, usteps, vvec / vsteps, vsteps, usteps * vsteps, intensity, seq)
end

point_light(pos::VectorF, intensity::Color) = area_light(pos, point(0, 0, 0), 1, point(0, 0, 0), 1, intensity, sequence(0))

point_on_light(l, u, v) = l.corner + l.uvec * (u + next(l.jitter_by)) + l.vvec * (v + next(l.jitter_by))

function intensity_at(l::area_light, p::VectorF, w::world)
    total = 0.0

    for v=0:l.vsteps-1
        for u=0:l.usteps-1
            if !is_shadowed(w, point_on_light(l, u, v), p) total += 1.0 end
        end
    end

    return total / l.samples
end

#= MATERIALS =#

mutable struct material
    color::Color
    ambient::Float64
    diffuse::Float64
    specular::Float64
    shininess::Float64
    pattern::optional{pattern}
    reflective::Float64
    transparency::Float64
    refractive_index::Float64
    material(;
        color = colorant"white",
        ambient = 0.1,
        diffuse = 0.9,
        specular = 0.9,
        shininess = 200.0,
        pattern = nothing,
        reflective = 0.0,
        transparency = 0.0,
        refractive_index = 1.0
    ) = new(color, ambient, diffuse, specular, shininess, pattern, reflective, transparency, refractive_index)
end

function propagate_material!(s::shape)
    if exists(s.material)
        if s isa group
            for c ∈ s.children
                c.material = s.material
                propagate_material!(c)
            end
        elseif s isa csg
            s.l.material = s.material
            s.r.material = s.material
            propagate_material!(s.l)
            propagate_material!(s.r)
        end
    end
end

#= PATTERNS =#

pattern_at_object(pat::pattern, object::shape, p::VectorF) = pattern_at(pat, pat.inverse_transform * world_to_object(object, p))

mutable struct test_pattern <: pattern
    transform::Transform
    inverse_transform::Transform
    test_pattern(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = update_cache!(new(transform, DEFAULT_TRANSFORM))
end

pattern_at(pat::test_pattern, p::VectorF) = RGB(Float64.(p[1:3])...)

mutable struct stripes <: pattern
    a::Color
    b::Color
    transform::Transform
    inverse_transform::Transform
    stripes(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = update_cache!(new(a, b, transform, DEFAULT_TRANSFORM))
end

pattern_at(pat::stripes, p::VectorF) = (floor(p[1]) % 2 == 0) ? pat.a : pat.b

mutable struct gradient <: pattern
    a::Color
    b::Color
    transform::Transform
    inverse_transform::Transform
    gradient(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = update_cache!(new(a, b, transform, DEFAULT_TRANSFORM))
end

function pattern_at(pat::gradient, p::VectorF)
    # when you want to handle "negative" colors differently than your library
    a, b = pat.a, pat.b
    ar, ag, ab = Float64.([red(a), green(a), blue(a)])
    br, bg, bb = Float64.([red(b), green(b), blue(b)])
    dr, dg, db = [br - ar, bg - ag, bb - ab] * (p[1] - floor(p[1]))
    return RGB(red(pat.a) + dr, green(pat.a) + dg, blue(pat.a) + db)
end

mutable struct rings <: pattern
    a::Color
    b::Color
    transform::Transform
    inverse_transform::Transform
    rings(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = update_cache!(new(a, b, transform, DEFAULT_TRANSFORM))
end

pattern_at(pat::rings, p::VectorF) = (floor(√(p[1]^2 + p[3]^2)) % 2 == 0) ? pat.a : pat.b

mutable struct checkers <: pattern
    a::Color
    b::Color
    transform::Transform
    inverse_transform::Transform
    checkers(; a = colorant"white", b = colorant"black", transform = DEFAULT_TRANSFORM) = update_cache!(new(a, b, transform, DEFAULT_TRANSFORM))
end

pattern_at(pat::checkers, p::VectorF) = (sum(floor.(p[1:3])) % 2 ≈ 0) ? pat.a : pat.b

#= TEXTURE MAPPING =#

mutable struct texture_map <: pattern
    pat::pattern
    uvmap # should be a function that takes a point and returns a u,v pair
    transform::Transform
    inverse_transform::Transform
    texture_map(pat::pattern, uvmap; transform = DEFAULT_TRANSFORM) = update_cache!(new(pat, uvmap, transform, DEFAULT_TRANSFORM))
end

pattern_at(tmap::texture_map, p::VectorF) = pattern_at(tmap.pat, tmap.uvmap(p)...)

mutable struct cube_map <: pattern
    faces::Vector{pattern}
    transform::Transform
    inverse_transform::Transform
    # must pass faces in order L, F, R, B, U, D for pattern_at to work
    cube_map(faces::pattern...; transform = DEFAULT_TRANSFORM) = update_cache!(new([faces...], transform, DEFAULT_TRANSFORM))
end

pattern_at(c::cube_map, p::VectorF) = pattern_at(c.faces[Int(face(p))], cubical_uv_map(p)...)

mutable struct uv_checkers <: pattern
    width::Number
    height::Number
    a::Color
    b::Color
    transform::Transform
    inverse_transform::Transform
    uv_checkers(w::Number, h::Number, a::Color, b::Color; transform = DEFAULT_TRANSFORM) = update_cache!(new(w, h, a, b, transform, DEFAULT_TRANSFORM))
end

pattern_at(pat::uv_checkers, u::Number, v::Number) = ((floor(u * pat.width) + floor(v * pat.height)) % 2 == 0) ? pat.a : pat.b

mutable struct uv_align_check <: pattern
    main::Color
    ul::Color
    ur::Color
    bl::Color
    br::Color
    transform::Transform
    inverse_transform::Transform
    uv_align_check(main::Color, ul::Color, ur::Color, bl::Color, br::Color; transform = DEFAULT_TRANSFORM) = update_cache!(new(main, ul, ur, bl, br, transform, DEFAULT_TRANSFORM))
end

function pattern_at(pat::uv_align_check, u::Number, v::Number)
    if v > 0.8
        if u < 0.2 return pat.ul end
        if u > 0.8 return pat.ur end
    elseif v < 0.2
        if u < 0.2 return pat.bl end
        if u > 0.8 return pat.br end
    end

    return pat.main
end

mutable struct image_map <: pattern
    canvas
    transform::Transform
    inverse_transform::Transform
    image_map(canvas; transform = DEFAULT_TRANSFORM) = update_cache!(new(canvas, transform, DEFAULT_TRANSFORM))
end

function pattern_at(img::image_map, u::Number, v::Number)
    v = 1 - v
    x = u * (width(img.canvas) - 1) + 1
    y = v * (height(img.canvas) - 1) + 1
    return pixel(img.canvas, Int(round(x)), Int(round(y)))
end

function spherical_uv_map(p::VectorF)
    θ = atan(p[1], p[3])
    v = vector(p[1:3]...)
    r = norm(v)
    ϕ = acos(p[2] / r)

    u = 1 - ((θ / 2π) + 0.5)
    v = 1 - ϕ/π

    return (u, v)
end

function planar_uv_map(p::VectorF)
    u = p[1] % 1
    if u < 0 u += 1 end
    v = p[3] % 1
    if v < 0 v += 1 end
    return (u, v)
end

function cylindrical_uv_map(p::VectorF)
    θ = atan(p[1], p[3])
    u = 1 - ((θ / 2π) + 0.5)
    v = p[2] % 1
    if v < 0 v += 1 end

    return (u, v)
end

@enum faces LEFT=1 FRONT=2 RIGHT=3 BACK=4 UP=5 DOWN=6

function face(p::VectorF)
    coord = max(abs.(p[1:3])...)

    if coord == p[1] return RIGHT
    elseif coord == -p[1] return LEFT
    elseif coord == p[2] return UP
    elseif coord == -p[2] return DOWN
    elseif coord == p[3] return FRONT
    else return BACK end
end

function cubical_uv_map(p::VectorF)
    u = 0.0
    v = 0.0

    f = face(p)

    if f == FRONT
        u = ((p[1] + 1) % 2.0) / 2.0
        v = ((p[2] + 1) % 2.0) / 2.0
    elseif f == BACK
        u = ((1 - p[1]) % 2.0) / 2.0
        v = ((p[2] + 1) % 2.0) / 2.0
    elseif f == LEFT
        u = ((p[3] + 1) % 2.0) / 2.0
        v = ((p[2] + 1) % 2.0) / 2.0
    elseif f == RIGHT
        u = ((1 - p[3]) % 2.0) / 2.0
        v = ((p[2] + 1) % 2.0) / 2.0
    elseif f == DOWN
        u = ((p[1] + 1) % 2.0) / 2.0
        v = ((p[3] + 1) % 2.0) / 2.0
    else
        u = ((p[1] + 1) % 2.0) / 2.0
        v = ((1 - p[3]) % 2.0) / 2.0
    end

    return (u, v)
end

#= SHAPES =#

mutable struct test_shape <: shape
    transform::Transform
    material::material
    parent::optional{shape}
    saved_ray::optional{ray}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    test_shape(; transform = DEFAULT_TRANSFORM, material = material(), parent = nothing, r = nothing, shadow = true) = update_cache!(new(transform, material, parent, r, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

_bounds(t::test_shape) = aabb(point(-1, -1, -1), point(1, 1, 1))

function _intersect(t::test_shape, r::ray)
    t.saved_ray = r
    return Intersections([])
end

_normal_at(t::test_shape, p::VectorF; hit::optional{intersection} = nothing) = vector(p[1:3]...)

mutable struct sphere <: shape
    transform::Transform
    material::material
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    sphere(; transform = DEFAULT_TRANSFORM, material = material(), parent = nothing, shadow = true) = update_cache!(new(transform, material, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

_bounds(s::sphere) = aabb(point(-1, -1, -1), point(1, 1, 1))

function _intersect(s::sphere, r::ray)
    sphere_to_ray = r.origin - point(0, 0, 0)
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

_normal_at(s::sphere, op::VectorF; hit::optional{intersection} = nothing) = op - point(0, 0, 0)

# makes it easier to write test cases
glass_sphere() = sphere(material = material(transparency = 1.0, refractive_index = 1.5))

mutable struct plane <: shape
    transform::Transform
    material::material
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    plane(; transform = DEFAULT_TRANSFORM, material = material(), parent = nothing, shadow = true) = update_cache!(new(transform, material, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

_bounds(p::plane) = aabb(point(-Inf, 0, -Inf), point(Inf, 0, Inf))

function _intersect(p::plane, r::ray)
    if abs(r.velocity[2]) < my_eps
        return Intersections([])
    end

    t = -r.origin[2] / r.velocity[2]
    return intersections(intersection(t, p))
end

_normal_at(p::plane, op::VectorF; hit::optional{intersection} = nothing) = vector(0, 1, 0)

mutable struct cube <: shape
    transform::Transform
    material::material
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    cube(; transform = DEFAULT_TRANSFORM, material = material(), parent = nothing, shadow = true) = update_cache!(new(transform, material, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

_bounds(c::cube) = aabb(point(-1, -1, -1), point(1, 1, 1))

function _intersect(c::cube, r::ray)
    xtmin, xtmax = check_axis(r.origin[1], r.velocity[1])
    ytmin, ytmax = check_axis(r.origin[2], r.velocity[2])
    ztmin, ztmax = check_axis(r.origin[3], r.velocity[3])

    tmin = max(xtmin, ytmin, ztmin)
    tmax = min(xtmax, ytmax, ztmax)

    if tmin > tmax return Intersections([]) end

    return intersections(intersection(tmin, c), intersection(tmax, c))
end

function _normal_at(c::cube, op::VectorF; hit::optional{intersection} = nothing)
    maxc = max(abs(op[1]), abs(op[2]), abs(op[3]))

    if maxc == abs(op[1]) return vector(op[1], 0, 0)
    elseif maxc == abs(op[2]) return vector(0, op[2], 0)
    else return vector(0, 0, op[3]) end
end

mutable struct cylinder <: shape
    transform::Transform
    material::material
    min::Float64
    max::Float64
    closed::Bool
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    cylinder(; transform = DEFAULT_TRANSFORM, material = material(), min = -Inf, max = Inf, closed = false, parent = nothing, shadow = true) = update_cache!(new(transform, material, min, max, closed, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

_bounds(c::cylinder) = aabb(point(-1, c.min, -1), point(1, c.max, 1))

function check_cap(r::ray, t::Float64)
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

function _normal_at(c::cylinder, op::VectorF; hit::optional{intersection} = nothing)
    dist = op[1]^2 + op[3]^2
    if dist < 1 && op[2] >= c.max - my_eps
        return vector(0, 1, 0)
    elseif dist < 1 && op[2] <= c.min + my_eps
        return vector(0, -1, 0)
    else
        return vector(op[1], 0, op[3])
    end
end

mutable struct cone <: shape
    transform::Transform
    material::material
    min::Float64
    max::Float64
    closed::Bool
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    cone(; transform = DEFAULT_TRANSFORM, material = material(), min = -Inf, max = Inf, closed = false, parent = nothing, shadow = true) = update_cache!(new(transform, material, min, max, closed, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

function _bounds(c::cone)
    a = abs(c.min)
    b = abs(c.max)
    lim = max(a, b)
    return aabb(point(-lim, c.min, -lim), point(lim, c.max, lim))
end

function check_cap(r::ray, t::Float64, y::Float64)
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

function _normal_at(c::cone, op::VectorF; hit::optional{intersection} = nothing)
    dist = op[1]^2 + op[3]^2
    if dist < 1 && op[2] >= c.max - my_eps
        return vector(0, 1, 0)
    elseif dist < 1 && op[2] <= c.min + my_eps
        return vector(0, -1, 0)
    else
        y = √(op[1]^2 + op[3]^2)
        if op[2] > 0 y = -y end
        return vector(op[1], y, op[3])
    end
end

mutable struct triangle <: shape
    p1::VectorF # p == point, i.e. vertex
    p2::VectorF
    p3::VectorF
    e1::VectorF # e == edge, i.e. side
    e2::VectorF
    n::VectorF # n == normal, i.e. pre-calculated surface normal
    transform::Transform
    material::material
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    function triangle(; p1::VectorF, p2::VectorF, p3::VectorF, transform::Transform = DEFAULT_TRANSFORM, material = material(), parent = nothing, shadow = true)
        e1 = p2 - p1
        e2 = p3 - p1
        n = normalize(cross(e2, e1))
        return update_cache!(new(p1, p2, p3, p2 - p1, p3 - p1, n, transform, material, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
    end
end

_bounds(t::triangle) = aabb(t.p1, t.p2, t.p3)

function _intersect(t::triangle, r::ray)
    dir_cross_e2 = cross(r.velocity, t.e2)
    det = t.e1 ⋅ dir_cross_e2
    if abs(det) < my_eps return Intersections([]) end

    f = 1.0 / det
    p1_to_origin = r.origin - t.p1
    u = f * p1_to_origin ⋅ dir_cross_e2
    if u < 0 || u > 1 return Intersections([]) end

    origin_cross_e1 = cross(p1_to_origin, t.e1)
    v = f * r.velocity ⋅ origin_cross_e1
    if v < 0 || (u + v) > 1 return Intersections([]) end

    return intersections(intersection(f * t.e2 ⋅ origin_cross_e1, t))
end

_normal_at(t::triangle, p::VectorF; hit::optional{intersection} = nothing) = t.n

mutable struct smooth_triangle <: shape
    p1::VectorF
    p2::VectorF
    p3::VectorF
    e1::VectorF
    e2::VectorF
    n1::VectorF
    n2::VectorF
    n3::VectorF
    transform::Transform
    material::material
    parent::optional{shape}
    shadow::Bool
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    smooth_triangle(; p1::VectorF, p2::VectorF, p3::VectorF, n1::VectorF, n2::VectorF, n3::VectorF, transform::Transform = DEFAULT_TRANSFORM, material = material(), parent = nothing, shadow = true) = update_cache!(new(p1, p2, p3, p2 - p1, p3 - p1, n1, n2, n3, transform, material, parent, shadow, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb()))
end

_bounds(t::smooth_triangle) = aabb(t.p1, t.p2, t.p3)

function _intersect(t::smooth_triangle, r::ray)
    dir_cross_e2 = cross(r.velocity, t.e2)
    det = t.e1 ⋅ dir_cross_e2
    if abs(det) < my_eps return Intersections([]) end

    f = 1.0 / det
    p1_to_origin = r.origin - t.p1
    u = f * p1_to_origin ⋅ dir_cross_e2
    if u < 0 || u > 1 return Intersections([]) end

    origin_cross_e1 = cross(p1_to_origin, t.e1)
    v = f * r.velocity ⋅ origin_cross_e1
    if v < 0 || (u + v) > 1 return Intersections([]) end

    return intersections(intersection(f * t.e2 ⋅ origin_cross_e1, t, u=u, v=v))
end

# only _normal_at for which hit is non-optional
_normal_at(tri::smooth_triangle, p::VectorF; hit::intersection) = tri.n2 * hit.u + tri.n3 * hit.v + tri.n1 * (1 - hit.u - hit.v)

#= GROUPS =#

mutable struct group <: shape
    transform::Transform
    material::optional{material}
    children::Vector{<:shape}
    parent::optional{shape}
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    function group(; transform = DEFAULT_TRANSFORM, children = Vector{shape}([]), material = nothing, parent = nothing)
        g = new(transform, material, Vector{shape}([]), parent, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb())
        add_child!(g, children...)
        return g
    end
end

_bounds(g::group) = aabb([c.bbox for c in g.children]...)

function add_child!(g::group, ss::shape...)
    foreach(s -> s.parent = g, ss)
    push!(g.children, ss...)
    propagate_material!(g)
    update_cache!(g)
end

_intersect(g::group, r::ray) = Intersections((intersects(g, r)) ? sort([i for c in g.children for i in intersect(c, r)], by=(i)->i.t) : [])

#= CONSTRUCTIVE SOLID GEOMETRY =#

mutable struct csg <: shape
    op::Symbol # could probably make this an enum
    l::shape
    r::shape
    transform::Transform
    material::optional{material}
    parent::optional{shape}
    inverse_transform::Transform
    inherited_transform::Transform
    inverse_inherited_transform::Transform
    bbox::aabb
    function csg(s::Symbol, l::shape, r::shape; transform = DEFAULT_TRANSFORM, material = nothing, parent = nothing)
        c = new(s, l, r, transform, material, parent, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, DEFAULT_TRANSFORM, aabb())
        l.parent = c
        r.parent = c
        propagate_material!(c)
        update_cache!(c)
        return c
    end
end

_bounds(c::csg) = aabb(c.l.bbox, c.r.bbox)

function intersection_allowed(op::Symbol, lhit::Bool, inl::Bool, inr::Bool)
    if op == :union return (lhit && !inr) || (!lhit && !inl)
    elseif op == :intersect return (lhit && inr) || (!lhit && inl)
    elseif op == :difference return (lhit && !inr) || (!lhit && inl)
    else return false end
end

has_child(g::group, s::shape) = any(c -> (c isa group) ? c == s || has_child(c, s) : c == s, g.children)

function includes(a::shape, b::shape)
    if a == b return true
    elseif a isa group return has_child(a, b)
    elseif a isa csg return includes(a.l, b) || includes(a.r, b)
    else return false end
end

function csg_filter(c::csg, xs::Intersections)
    inl = false
    inr = false

    res = Intersections([])

    for i in xs
        lhit = includes(c.l, i.object)

        if intersection_allowed(c.op, lhit, inl, inr) push!(res, i) end

        if lhit inl = !inl
        else inr = !inr end
    end

    return intersections(res...)
end

function _intersect(c::csg, r::ray)
    if !intersects(c, r) return Intersections([]) end

    leftxs = intersect(c.l, r)
    rightxs = intersect(c.r, r)

    xs = intersections(sort(vcat(leftxs, rightxs), by=(i)->i.t)...)

    return csg_filter(c, xs)
end

#= BOUNDING VOLUME HIERARCHIES =#

import Base.split
function split(b::aabb)
    dx, dy, dz = [b.max[i] - b.min[i] for i=1:3]
    greatest = max(dx, dy, dz)
    x0, y0, z0 = b.min[1:3]
    x1, y1, z1 = b.max[1:3]
    if greatest == dx x0 = x1 = x0 + dx / 2.0
    elseif greatest == dy y0 = y1 = y0 + dy / 2.0
    else z0 = z1 = z0 + dz / 2.0 end
    mid_min = point(x0, y0, z0)
    mid_max = point(x1, y1, z1)
    return aabb(b.min, mid_max), aabb(mid_min, b.max)
end

function partition!(g::group)
    lb, rb = split(g.bbox)
    ls = findall(c -> contains(lb, c), g.children)
    rs = findall(c -> contains(rb, c), g.children)
    l = g.children[ls]
    r = g.children[rs]
    deleteat!(g.children, sort(vcat(ls, rs)))
    # cache is not updated here because in divide! the
    # deleted children are added right back as subgroups
    # so don't use this function on its own recklessly
    return l, r
end

subgroup!(g::group, ss::shape...) = add_child!(g, group(children = [ss...]))

function divide!(s::shape, thresh::Number = DEFAULT_BVH_THRESHOLD)
    if s isa group
        if thresh <= length(s.children)
            l, r = partition!(s)
            if !isempty(l) subgroup!(s, l...) end
            if !isempty(r) subgroup!(s, r...) end
        end
        foreach(c -> divide!(c, thresh), s.children)
    elseif s isa csg
        divide!(s.l, thresh)
        divide!(s.r, thresh)
    end
end

#= FILE IMPORT/EXPORT =#

# helper for translating between delimited files and canvases within loops
function advance_xy(x,y,xlim)
    x += 1
    if x > xlim
        y += 1
        x = 1
    end
    return x,y
end

#= PPM =#

# helper for formatting "PPM matrices"
nice_str(mat, r) = strip(join(mat[r,:], " "))

function ppm_mat(can)
    # a single matrix cell (the scaled value of a single color channel)
    # written to file will require at most this many characters
    scale = "255"
    cell_size = length(scale) + 1
    # could be different if we were writing grayscale, but this is really
    # just for convenience and readability
    num_channels = 3
    # worst-case line length in chars for a given canvas =>
    # num_channels * cell_size * width(canvas) = 12 * width(can) (in our case)
    # max width of writeable matrix inferred from max line length, which is 70
    can_cells = width(can) * num_channels
    w = Int(min(can_cells, floor(70 / cell_size)))
    lines_per_row = ceil(can_cells / w)
    h = Int(height(can) * lines_per_row + 3) # magic val, dims, and scale get one line each

    mat = fill("", (h, w))
    mat[1,1] = "P3" # the magic val. accept no substitutes.
    mat[2,1:2] = string.([width(can), height(can)])
    mat[3,1] = "255"

    # x is horizontal, y is vertical, which means x is column, y is row
    y = 4
    for i=1:height(can)
        # start at beginning on each new canvas row
        x = 1
        for j=1:width(can)
            c = can[i,j]
            r, g, b = string.(scale_color_component.([red(c), green(c), blue(c)]))
            mat[y,x] = r
            x,y = advance_xy(x,y,w)
            mat[y,x] = g
            x,y = advance_xy(x,y,w)
            mat[y,x] = b
            x,y = advance_xy(x,y,w)
            if j == width(can) && x != 1 y += 1 end
        end
    end

    return mat
end

save_ppm(f, can) = writedlm(f, ppm_mat(can), " ")

function load_ppm(source)
    p = readdlm(source, comments=true) # i ❤ julia
    if p[1,1] != "P3" error("magic id $(p[1,1]) is not P3") end
    scale = p[3,1]
    w, h = p[2,1:2]
    c = canvas(w, h)
    x = y = 1
    r = g = b = -1
    for i=4:height(p)
        for j=1:width(p)
            n = p[i,j]
            if n isa Number
                if r == -1 r = descale_color_component(n, scale=scale)
                elseif g == -1 g = descale_color_component(n, scale=scale)
                elseif b == -1
                    b = descale_color_component(n, scale=scale)
                    pixel!(c, x, y, RGB(r, g, b))
                    r = g = b = -1
                    x,y = advance_xy(x,y,width(c))
                    if y > height(c) return c end
                end
            end
        end
    end
    error("bad image data, expected $w × $h, got $x × $y")
end

#= OBJ =#

mutable struct OBJ
    ignored::Int
    vertices::Vector{VectorF}
    default_group::group
    groups::Dict{String, group}
    normals::Vector{VectorF}
end

function fan(vs::Vector{VectorF}, ns::Vector{VectorF} = Vector{VectorF}([]))
    ts = Vector{Union{triangle, smooth_triangle}}([])
    for i=2:length(vs)-1
        if length(ns) == 0
            t = triangle(p1=vs[1], p2=vs[i], p3=vs[i+1])
        else
            t = smooth_triangle(p1=vs[1], p2=vs[i], p3=vs[i+1], n1=ns[1], n2=ns[i], n3=ns[i+1])
        end
        push!(ts, t)
    end
    return ts
end

function load_obj(source)
    o = readdlm(source, comments=true)
    ignored = 0
    vertices = Vector{VectorF}([])
    default_group = group()
    groups = Dict{String, group}([])
    normals = Vector{VectorF}([])
    active_group = default_group

    for i=1:height(o)
        if o[i,1] == "v"
            push!(vertices, point(o[i,2:4]...))
        elseif o[i,1] == "f"
            j = findfirst(n -> !(n isa Number), o[i,2:width(o)])
            if isnothing(j)
                j = width(o)
                if j >= 4
                    add_child!(active_group, fan(vertices[o[i,2:j]])...)
                elseif j < 4
                    error("invalid face $(o[i,:]): not enough vertices")
                end
            else
                vsind = []
                nsind = []
                for j=2:width(o)
                    # ignoring 2nd value, the texture vertex, which i haven't
                    # implemented yet, also assumes normal is always defined.
                    # this bit would have to be completely redone if i decided
                    # to do texture vertices.
                    v = parse.(Int, split(o[i,j], '/')[[1,3]])
                    push!(vsind, v[1])
                    push!(nsind, v[2])
                end
                if length(vsind) < 3
                    error("invalid face $(o[i,:]): not enough vertices")
                end
                add_child!(active_group, fan(vertices[vsind], normals[nsind])...)
            end
        elseif o[i,1] == "g"
            g = o[i,2]
            if !haskey(groups, g) groups[g] = group() end
            active_group = groups[g]
        elseif o[i,1] == "vn"
            push!(normals, vector(o[i,2:4]...))
        else
            ignored += 1
        end
    end

    return OBJ(ignored, vertices, default_group, groups, normals)
end

group(o::OBJ) = group(children = [values(o.groups)..., o.default_group])

#= YAML (scenes) =#

mutable struct scene
    w::world
    cam::optional{camera}
    materials::Dict{String, material}
    transforms::Dict{String, Transform}
    entities::Dict{String, Union{camera, area_light, shape}}
    scene(; w = world(), cam = nothing, materials = Dict{String, material}([]), transforms = Dict{String, Transform}([]), entities = Dict{String, Union{camera, area_light, shape}}([])) = new(w, cam, materials, transforms, entities)
end

raytrace(scn::scene) = raytrace(scn.cam, scn.w)
raytrace_scene(scn::scene) = scn, raytrace(scn)
raytrace_scene(f) = raytrace_scene(load_scene(f))

function chain_transforms(ts, scn::scene = scene())
    s = DEFAULT_TRANSFORM
    for t ∈ ts
        if t isa String && t ∈ keys(scn.transforms) s = scn.transforms[t] * s
        elseif t[1] == "translate" s = translation(t[2:4]...) * s
        elseif t[1] == "scale" s = scaling(t[2:4]...) * s
        elseif t[1] == "rotate-x" s = rotation_x(t[2]) * s
        elseif t[1] == "rotate-y" s = rotation_y(t[2]) * s
        elseif t[1] == "rotate-z" s = rotation_z(t[2]) * s
        elseif t[1] == "reflect-x" s = reflection_x() * s
        elseif t[1] == "reflect-y" s = reflection_y() * s
        elseif t[1] == "reflect-z" s = reflection_z() * s
        elseif t[1] == "shear" s = shearing(t[2:7]...) * s
        end
    end
    return s
end

function parse_uvpat(puv::Dict{Any, Any})
    ptype = puv["type"]
    if ptype == "checkers"
        uvpat = uv_checkers(
            puv["width"],
            puv["height"],
            RGB(puv["colors"][1]...),
            RGB(puv["colors"][2]...)
        )
    elseif ptype == "align_check"
        cols = puv["colors"]
        uvpat = uv_align_check(
            RGB(cols["main"]...),
            RGB(cols["ul"]...),
            RGB(cols["ur"]...),
            RGB(cols["bl"]...),
            RGB(cols["br"]...)
        )
    elseif ptype == "image"
        uvpat = image_map(load_ppm(puv["file"]))
    end

    return uvpat
end

function apply_material!(s::material, m::Dict{Any, Any}, scn::scene = scene())
    if haskey(m, "color") s.color = RGB(m["color"]...) end
    if haskey(m, "ambient") s.ambient = m["ambient"] end
    if haskey(m, "diffuse") s.diffuse = m["diffuse"] end
    if haskey(m, "specular") s.specular = m["specular"] end
    if haskey(m, "shininess") s.shininess = m["shininess"] end
    if haskey(m, "reflective") s.reflective = m["reflective"] end
    if haskey(m, "transparency") s.transparency = m["transparency"] end
    if haskey(m, "refractive-index") s.refractive_index = m["refractive-index"] end
    if haskey(m, "pattern")
        p = m["pattern"]
        t = p["type"]
        if t == "checkers" s.pattern = checkers()
        elseif t == "stripes" s.pattern = stripes()
        elseif t == "gradient" s.pattern = gradient()
        elseif t == "rings" s.pattern = rings()
        elseif t == "map"
            pmap = p["mapping"]
            if pmap == "spherical" s.pattern = texture_map(parse_uvpat(p["uv_pattern"]), spherical_uv_map)
            elseif pmap == "planar" s.pattern = texture_map(parse_uvpat(p["uv_pattern"]), planar_uv_map)
            elseif pmap == "cylindrical" s.pattern = texture_map(parse_uvpat(p["uv_pattern"]), cylindrical_uv_map)
            elseif pmap == "cube"
                # remember: L, F, R, B, U, D
                s.pattern = cube_map(
                    parse_uvpat(p["left"]),
                    parse_uvpat(p["front"]),
                    parse_uvpat(p["right"]),
                    parse_uvpat(p["back"]),
                    parse_uvpat(p["up"]),
                    parse_uvpat(p["down"]),
                )
            end
        end
        if haskey(p, "transform") update_cache!(s.pattern, chain_transforms(p["transform"], scn)) end
        if haskey(p, "colors")
            s.pattern.a = RGB(p["colors"][1]...)
            s.pattern.b = RGB(p["colors"][2]...)
        end
    end
end

function parse_entity(scn::scene, e::Dict{Any, Any})
    if haskey(e, "add") o = e["add"]
    elseif haskey(e, "type") o = e["type"] end

    if o == "camera"
        s = camera(
            hsize=e["width"],
            vsize=e["height"],
            fov=e["field-of-view"],
            transform=view_transform(point(e["from"]...), point(e["to"]...), vector(e["up"]...))
        )
    elseif o == "light"
        if haskey(e, "at")
            s = point_light(point(e["at"]...), RGB(e["intensity"]...))
        elseif haskey(e, "corner")
            s = area_light(
            point(e["corner"]...),
            vector(e["uvec"]...),
            e["usteps"],
            vector(e["vvec"]...),
            e["vsteps"],
            RGB(e["intensity"]...),
            (!haskey(e, "jitter") || e["jitter"]) ? sequence() : sequence(0))
        end
    else
        if o ∈ keys(scn.entities) s = deepcopy(scn.entities[o])
        elseif o == "obj" s = group(load_obj(e["file"]))
        elseif o == "sphere" s = sphere()
        elseif o == "plane" s = plane()
        elseif o == "cube" s = cube()
        elseif o == "fir_branch" s = fir_branch()
        elseif o == "group"
            s = group()
            if haskey(e, "children")
                add_child!(s, [parse_entity(scn, c) for c ∈ e["children"]]...)
            end
        elseif o == "csg"
            s = csg(
                Symbol(e["operation"]),
                parse_entity(scn, e["left"]),
                parse_entity(scn, e["right"])
            )
        else
            if o == "cylinder" s = cylinder()
            elseif o == "cone" s = cone() end
            if haskey(e, "min") s.min = e["min"] end
            if haskey(e, "max") s.max = e["max"] end
            if haskey(e, "closed") s.closed = e["closed"] end
        end
        if haskey(e, "shadow") s.shadow = e["shadow"] end
        if haskey(e, "transform") update_cache!(s, chain_transforms(e["transform"], scn)) end
        if haskey(e, "material")
            m = e["material"]
            if m isa String
                s.material = scn.materials[m]
            else
                if !exists(s.material) s.material = material() end # needed for groups and csgs
                apply_material!(s.material, e["material"], scn)
            end
            propagate_material!(s)
        end
    end

    return s
end

function add_entity!(scn::scene, e::Dict{Any, Any})
    ent = parse_entity(scn, e)
    if ent isa camera
        scn.cam = ent
    elseif ent isa area_light
        push!(scn.w.lights, ent)
    elseif ent isa shape
        push!(scn.w.objects, ent)
    end
    return ent
end

function load_scene(f)
    yml = YAML.load_file(f)
    scn = scene()
    for e ∈ yml
        if haskey(e, "add")
            scn.entities["$(e["add"])-$(uuid1())"] = add_entity!(scn, e)
        elseif haskey(e, "define")
            d = e["define"]
            v = e["value"]
            if v isa Dict
                if !haskey(v, "add") && d ∉ keys(scn.materials)
                    if haskey(e, "extend") && e["extend"] ∈ keys(scn.materials) m = deepcopy(scn.materials[e["extend"]])
                    else m = material() end
                    apply_material!(m, v, scn)
                    scn.materials[d] = m
                elseif d ∉ keys(scn.entities)
                    scn.entities[d] = parse_entity(scn, v)
                end
            elseif v isa Array && d ∉ keys(scn.transforms)
                scn.transforms[d] = chain_transforms(v, scn)
            end
        end
    end
    return scn
end

#= PROCEDURAL GEOMETRY =#

# for the christmas scene:
# https://forum.raytracerchallenge.com/thread/16/merry-christmas-scene-description
function fir_branch()
    # the length of the branch
    len = 2.0
    # the radius of the branch
    radius = 0.025
    # how many groups of needles cover the branch
    segments = 20
    # how needles per group, or segment
    per_segment = 24
    # the branch itself, just a cylinder
    branch = cylinder(
        min=0, max=len,
        transform=scaling(radius, 1, radius),
        material=material(color=RGB(0.5, 0.35, 0.26), ambient=0.2, specular=0, diffuse=0.6)
    )
    # how much branch each segment gets
    seg_size = len / (segments - 1)
    # the radial distance, in radians, between adjacent needles
    # in a group
    θ = 2.1 * π / per_segment
    # the maximum length of each needle
    max_len = 20.0 * radius
    # the group that will contain the branch and all needles
    object = group(children=[branch])

    for y=0:segments-1
        # create a subgroup for each segment of needles
        subgrp = group()
        for i=0:per_segment-1
            # each needle is a triangle.
            # y_base y coordinate of the base of the triangle
            y_base = seg_size * y + rand() * seg_size

            # y_tip is the y coordinate of the tip of the triangle
            y_tip = y_base - rand() * seg_size

            # y_angle is angle (in radians) that the needle should be
            # rotated around the branch.
            y_angle = i * θ + rand() * θ

            # how long is the needle?
            needle_len = max_len / 2 * (1 + rand())

            # how much is the needle offset from the center of the branch?
            ofs = radius / 2

            # the three points of the triangle that form the needle
            p1 = point(ofs, y_base, ofs)
            p2 = point(-ofs, y_base, ofs)
            p3 = point(0.0, y_tip, needle_len)

            # create, transform, and texture the needle
            tri = triangle(
                p1=p1, p2=p2, p3=p3,
                transform=rotation_y(y_angle),
                material=material(color=RGB(0.26, 0.36, 0.16), specular=0.1)
            )

            add_child!(subgrp, tri)
        end

        add_child!(object, subgrp)
    end

    return object
end

end
