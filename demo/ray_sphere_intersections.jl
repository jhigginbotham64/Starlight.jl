using starlight

function draw_circle(height=100, width=100, bg_color=colorant"black", c=colorant"red")
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
            # because
            r = ray(ray_origin, normalize(pos - ray_origin))
            xs = intersect(s, r)
            if !isnothing(hit(xs))
                pixel!(canv, x, y, c)
            end
        end
    end

    return canv
end

canv = draw_circle()
