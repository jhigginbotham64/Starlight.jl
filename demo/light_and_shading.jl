using starlight

function draw_sphere(height=100, width=100, bg_color=colorant"black", light_color=colorant"white", mat_color=colorant"purple")
    canv = canvas(width, height, bg_color)

    m = material()
    m.color = mat_color
    s = sphere()
    material!(s, m)
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

canv = draw_sphere()
