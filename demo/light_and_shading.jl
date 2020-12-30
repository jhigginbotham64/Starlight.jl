using starlight

HEIGHT = WIDTH = 100
canv = canvas(WIDTH, HEIGHT)

# because a lot of these variable names are also used by unit tests
let
    local m = material()
    m.color = RGB(1, 0.2, 1)
    local s = sphere()
    material!(s, m)
    local l = point_light(point(-10, 10, -10), colorant"white")

    ray_origin = point(0, 0, -5)
    wz = 10 # wall z
    wall_size = 7.0
    half = wall_size / 2
    pixel_size = wall_size / WIDTH # can't accomodate stretching yet?

    for y = 1:HEIGHT
        wy = half - pixel_size * y
        for x = 1:WIDTH
            wx = -half + pixel_size * x
            local pos = point(wx, wy, wz)
            # because
            local r = ray(ray_origin, normalize(pos - ray_origin))
            local xs = intersect(s, r)
            local h = hit(xs)
            if !isnothing(h)
                local pos2 = position(r, h.t)
                local n = normal_at(h.object, pos2)
                local eye = -r.velocity
                local c = lighting(h.object.material, l, pos2, eye, n)
                pixel!(canv, x, y, mapc(chan -> clamp(chan, 0, 1), c))
            end
        end
    end
end

# if you're running this as a script and want to see the
# result in a plot, just use canv
canv
