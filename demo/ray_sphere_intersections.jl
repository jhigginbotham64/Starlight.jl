using starlight

HEIGHT = WIDTH = 100
canv = canvas(WIDTH, HEIGHT)

# because a lot of these variable names are also used by unit tests
let
    local c = colorant"red"
    local s = sphere()

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
            if !isnothing(hit(xs))
                pixel!(canv, x, y, c)
            end
        end
    end
end

# if you're running this as a script and want to see the
# result in a plot, just use canv
canv
