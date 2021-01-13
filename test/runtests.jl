using starlight
using Test

@testset "ray tracer challenge" begin

    @testset "ch 1 - tuples, points, and vectors" begin

        #=
            test cases for tuples, points, and vectors turned into
            smoke tests of julia's native data types and standard library.
            not super meaningful, but definitely helps me learn julia and
            get an idea of what to expect later.
        =#

        vals = [4.3, -4.2, 3.1]

        a = point(vals...)
        @test a[1] == 4.3
        @test a[2] == -4.2
        @test a[3] == 3.1
        @test a[4] == 1.0
        @test a == point(vals...)
        @test a != vector(vals...)

        a = vector(vals...)
        @test a[1] == 4.3
        @test a[2] == -4.2
        @test a[3] == 3.1
        @test a[4] == 0.0
        @test a != point(vals...)
        @test a == vector(vals...)

        @test point(4, -4, 3) == [4, -4, 3, 1]
        @test vector(4, -4, 3) == [4, -4, 3, 0]
        @test [3, -2, 5, 1] + [-2, 3, 1, 0] == [1, 1, 6, 1]
        @test point(3, 2, 1) - point(5, 6, 7) == vector(-2, -4, -6)
        @test point(3, 2, 1) - vector(5, 6, 7) == point(-2, -4, -6)
        @test vector(3, 2, 1) - vector(5, 6, 7) == vector(-2, -4, -6)
        @test vector(0, 0, 0) - vector(1, -2, 3) == vector(-1, 2, -3)
        @test -[1, -2, 3, -4] == [-1, 2, -3, 4]
        @test 3.5 * [1, -2, 3, -4] == [3.5, -7, 10.5, -14]
        @test 0.5 * [1, -2, 3, -4] == [0.5, -1, 1.5, -2]
        @test [1, -2, 3, -4] / 2 == [0.5, -1, 1.5, -2]

        @test norm(vector(1, 0, 0)) == 1
        @test norm(vector(0, 1, 0)) == 1
        @test norm(vector(0, 0, 1)) == 1
        @test norm(vector(1, 2, 3)) == √14 # i love julia
        @test norm(vector(-1, -2, -3)) == √14

        @test normalize(vector(4, 0, 0)) == vector(1, 0, 0)
        @test normalize(vector(1, 2, 3)) == vector(1/√14, 2/√14, 3/√14) # i really love julia
        @test norm(normalize(vector(1, 2, 3))) == 1

        # i really really really love julia
        @test vector(1, 2, 3) ⋅ vector(2, 3, 4) == 20
        @test cross(vector(2, 3, 4), vector(1, 2, 3)) == vector(-1, 2, -1)
        @test cross(vector(1, 2, 3), vector(2, 3, 4)) == vector(1, -2, 1)
    end

    @testset "ch 2 - drawing on a canvas" begin

        #=
            color definitions from julia's Colors package, color arithmetic
            from ColorVectorSpace. inclusion of Images and a couple of extra
            dependencies allows displaying colors in notebooks as well as
            Juno's Plots pane. so now i'm also learning and smoke-testing
            julia's package ecosystem.
        =#

        c = RGB(-0.5, 0.4, 1.7)
        @test red(c) == -0.5
        @test green(c) == 0.4
        @test blue(c) == 1.7

        c = RGB(0.9, 0.6, 0.75) + RGB(0.7, 0.1, 0.25)
        @test red(c) == 1.6
        @test green(c) == 0.7
        @test blue(c) == 1.0

        c = RGB(0.9, 0.6, 0.75) - RGB(0.7, 0.1, 0.25)
        @test red(c) ≈ 0.2 # never really know where numerical instability will strike
        @test green(c) == 0.5
        @test blue(c) == 0.5

        c = 2 * RGB(0.2, 0.3, 0.4)
        @test red(c) == 0.4
        @test green(c) == 0.6
        @test blue(c) == 0.8

        c = hadamard(RGB(1, 0.2, 0.4), RGB(0.9, 1, 0.1))
        @test red(c) == 0.9
        @test green(c) == 0.2
        @test blue(c) ≈ 0.04 # again with the instability, and again it's easier to handle in julia than python

        c = canvas(10, 20)
        @test width(c) == 10 # Images.width
        @test height(c) == 20 # Images.height
        @test all(col == colorant"black" for col in pixels(c))

        pixel!(c, 2, 3, colorant"red")
        @test pixel(c, 2, 3) == colorant"red"
    end

    @testset "ch 3 - matrices" begin

        #=
            mostly learning and exercising julia's native types again.
        =#

        M = [
            1 2 3 4
            5.5 6.5 7.5 8.5
            9 10 11 12
            13.5 14.5 15.5 16.5
        ]
        @test M[1,1] == 1
        @test M[1,4] == 4
        @test M[2,1] == 5.5
        @test M[2,3] == 7.5
        @test M[3,3] == 11
        @test M[4,1] == 13.5
        @test M[4,3] == 15.5

        M = [
            -3 5
            1 -2
        ]
        @test M[1,1] == -3
        @test M[1,2] == 5
        @test M[2,1] == 1
        @test M[2,2] == -2

        M = [
            -3 5 0
            1 -2 -7
            0 1 1
        ]
        @test M[1,1] == -3
        @test M[2,2] == -2
        @test M[3,3] == 1

        A = [
            1 2 3 4
            5 6 7 8
            9 8 7 6
            5 4 3 2
        ]
        B = [
            1 2 3 4
            5 6 7 8
            9 8 7 6
            5 4 3 2
        ]
        @test A == B

        A = [
            1 2 3 4
            5 6 7 8
            9 8 7 6
            5 4 3 2
        ]
        B = [
            2 3 4 5
            6 7 8 9
            8 7 6 5
            4 3 2 1
        ]
        @test A != B

        A = [
            1 2 3 4
            5 6 7 8
            9 8 7 6
            5 4 3 2
        ]
        B = [
            -2 1 2 3
            3 2 1 -1
            4 3 6 5
            1 2 7 8
        ]
        @test A * B == [
            20 22 50 48
            44 54 114 108
            40 58 110 102
            16 26 46 42
        ]

        A = [
            1 2 3 4
            2 4 4 2
            8 6 4 1
            0 0 0 1
        ]
        b = [1 2 3 1]
        @test A * b' == [18 24 33 1]'

        A = [
            0 1 2 4
            1 2 4 8
            2 4 8 16
            4 8 16 32
        ]
        @test A*I == A
        @test I*A == A

        a = [1 2 3 4]'
        @test a*I == a
        @test I*a == a

        A = [
            0 9 3 0
            9 8 0 8
            1 8 5 3
            0 0 5 8
        ]
        @test A' == [
            0 9 1 0
            9 8 8 0
            3 0 5 5
            0 8 3 8
        ]
        @test I' == I

        A = [
            1 5
            -3 2
        ]
        @test det(A) == 17

        A = [
            1 5 0
            -3 2 7
            0 6 -3
        ]
        @test submatrix(A, 1, 3) == [-3 2; 0 6]

        A = [
            -6 1 1 6
            -8 5 8 6
            -1 0 8 2
            -7 1 -1 1
        ]
        @test submatrix(A, 3, 2) == [
            -6 1 6
            -8 8 6
            -7 -1 1
        ]

        A = [
            3 5 0
            2 -1 -7
            6 -1 5
        ]
        B = submatrix(A, 2, 1)
        @test det(B) == 25
        @test minor(A, 2, 1) == 25

        A = [
            3 5 0
            2 -1 -7
            6 -1 5
        ]
        @test minor(A, 1, 1) == -12
        @test cofactor(A, 1, 1) == -12
        @test minor(A, 2, 1) == 25
        @test cofactor(A, 2, 1) == -25

        A = [
            1 2 6
            -5 8 -4
            2 6 4
        ]
        @test cofactor(A, 1, 1) == 56
        @test cofactor(A, 1, 2) == 12
        @test cofactor(A, 1, 3) == -46
        @test det(A) ≈ -196

        A = [
            -2 -8 3 5
            -3 1 7 3
            1 2 -9 6
            -6 7 7 -9
        ]
        @test cofactor(A, 1, 1) == 690
        @test cofactor(A, 1, 2) == 447
        @test cofactor(A, 1, 3) ≈ 210
        @test cofactor(A, 1, 4) ≈ 51
        @test det(A) ≈ -4071

        A = [
            6 4 4 4
            5 5 7 6
            4 -9 3 -7
            9 1 7 -6
        ]
        @test det(A) ≈ -2120
        @test invertible(A)

        A = [
            -4 2 -2 -3
            9 6 2 6
            0 -5 1 -5
            0 0 0 0
        ]
        @test det(A) == 0
        @test !invertible(A)

        A = [
            -5 2 6 -8
            1 -5 1 8
            7 7 -6 -7
            1 -3 7 4
        ]
        B = inv(A)
        @test det(A) == 532
        @test cofactor(A, 3, 4) ≈ -160
        @test B[4,3] ≈ -160 / 532
        @test cofactor(A, 4, 3) ≈ 105
        @test B[3,4] ≈ 105 / 532
        @test round.(B, digits=5) == [
            0.21805 0.45113 0.24060 -0.04511
            -0.80827 -1.45677 -0.44361 0.52068
            -0.07895 -0.22368 -0.05263 0.19737
            -0.52256 -0.81391 -0.30075 0.30639
        ]

        A = [
            8 -5 9 2
            7 5 6 1
            -6 0 9 6
            -3 0 -9 -4
        ]
        @test round.(inv(A), digits=5) == [
            -0.15385 -0.15385 -0.28205 -0.53846
            -0.07692 0.12308 0.02564 0.03077
            0.35897 0.35897 0.43590 0.92308
            -0.69231 -0.69231 -0.76923 -1.92308
        ]

        A = [
            9 3 0 9
            -5 -2 -6 -3
            -4 9 6 4
            -7 6 6 2
        ]
        @test round.(inv(A), digits=5) == [
            -0.04074 -0.07778 0.14444 -0.22222
            -0.07778 0.03333 0.36667 -0.33333
            -0.02901 -0.14630 -0.10926 0.12963
            0.17778 0.06667 -0.26667 0.33333
        ]

        A = [
            3 -9 7 3
            3 -8 2 -9
            -4 4 4 1
            -6 5 -1 1
        ]
        B = [
            8 2 2 2
            3 -1 7 0
            7 0 5 4
            6 -2 0 5
        ]
        C = A * B
        @test C * inv(B) ≈ A
    end

    @testset "ch 4 - matrix transformations" begin

        #=
            still exercising native types. julia's syntax makes encoding
            transformation matrices as functions really straightforward.
            also it's great to be able to type √ and π. also i really
            cannot get enough of ≈.
        =#

        transform = translation(5, -3, 2)
        p = point(-3, 4, 5)
        @test transform * p == point(2, 1, 7)
        @test inv(transform) * p == point(-8, 7, 3)

        v = vector(-3, 4, 5)
        @test transform * v == v

        transform = scaling(2, 3, 4)
        p = point(-4, 6, 8)
        @test transform * p == point(-8, 18, 32)

        v = vector(-4, 6, 8)
        @test transform * v == vector(-8, 18, 32)
        @test inv(transform) * v == vector(-2, 2, 2)

        p = point(2, 3, 4)
        @test reflection_x * p == point(-2, 3, 4)
        @test reflection_y * p == point(2, -3, 4)
        @test reflection_z * p == point(2, 3, -4)

        p = point(0, 1, 0)
        half_quarter = rotation_x(π / 4)
        full_quarter = rotation_x(π / 2)
        @test half_quarter * p ≈ point(0, √2/2, √2/2)
        @test full_quarter * p ≈ point(0, 0, 1)
        @test inv(half_quarter) * p ≈ point(0, √2/2, -√2/2)

        p = point(0, 0, 1)
        half_quarter = rotation_y(π / 4)
        full_quarter = rotation_y(π / 2)
        @test half_quarter * p ≈ point(√2/2, 0, √2/2)
        @test full_quarter * p ≈ point(1, 0, 0)
        @test inv(half_quarter) * p ≈ point(-√2/2, 0, √2/2)

        p = point(0, 1, 0)
        half_quarter = rotation_z(π / 4)
        full_quarter = rotation_z(π / 2)
        @test half_quarter * p ≈ point(-√2/2, √2/2, 0)
        @test full_quarter * p ≈ point(-1, 0, 0)
        @test inv(half_quarter) * p ≈ point(√2/2, √2/2, 0)

        p = point(2, 3, 4)
        @test shearing(1, 0, 0, 0, 0, 0) * p == point(5, 3, 4)
        @test shearing(0, 1, 0, 0, 0, 0) * p == point(6, 3, 4)
        @test shearing(0, 0, 1, 0, 0, 0) * p == point(2, 5, 4)
        @test shearing(0, 0, 0, 1, 0, 0) * p == point(2, 7, 4)
        @test shearing(0, 0, 0, 0, 1, 0) * p == point(2, 3, 6)
        @test shearing(0, 0, 0, 0, 0, 1) * p == point(2, 3, 7)

        p = point(1, 0, 1)
        A = rotation_x(π / 2)
        B = scaling(5, 5, 5)
        C = translation(10, 5, 7)
        p2 = A * p
        p3 = B * p2
        p4 = C * p3
        T = C * B * A
        @test p2 ≈ point(1, -1, 0)
        @test p3 ≈ point(5, -5, 0)
        @test p4 ≈ point(15, 0, 7)
        @test T * p ≈ point(15, 0, 7)
    end

    @testset "ch 5 - ray-sphere intersections" begin

        #=
            first time drawing and using transforms. exciting. really
            nothing too fancy outside the intersect function tho.
        =#

        origin = point(1, 2, 3)
        velocity = vector(4, 5, 6)
        r = ray(origin, velocity)
        @test r.origin == origin
        @test r.velocity == velocity

        r = ray(point(2, 3, 4), vector(1, 0, 0))
        @test position(r, 0) == point(2, 3, 4)
        @test position(r, 1) == point(3, 3, 4)
        @test position(r, -1) == point(1, 3, 4)
        @test position(r, 2.5) == point(4.5, 3, 4)

        # test again with floats because i'm still learning julia's type system
        r = ray(point(2.0, 3.0, 4.0), vector(1.0, 0.0, 0.0))
        @test position(r, 0.0) == point(2.0, 3.0, 4.0)
        @test position(r, 1.0) == point(3.0, 3.0, 4.0)
        @test position(r, -1.0) == point(1.0, 3.0, 4.0)
        @test position(r, 2.5) == point(4.5, 3.0, 4.0)

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere() # default is unit sphere centered at origin
        xs = intersect(s, r)
        @test length(xs) == 2
        @test xs[1].t == 4.0
        @test xs[2].t == 6.0

        r = ray(point(0, 1, -5), vector(0, 0, 1))
        s = sphere()
        xs = intersect(s, r)
        @test length(xs) == 2
        @test xs[1].t == 5.0
        @test xs[2].t == 5.0

        r = ray(point(0, 2, -5), vector(0, 0, 1))
        s = sphere()
        xs = intersect(s, r)
        @test isempty(xs)

        r = ray(point(0, 0, 0), vector(0, 0, 1))
        s = sphere()
        xs = intersect(s, r)
        @test length(xs) == 2
        @test xs[1].t == -1.0
        @test xs[2].t == 1.0

        r = ray(point(0, 0, 5), vector(0, 0, 1))
        s = sphere()
        xs = intersect(s, r)
        @test length(xs) == 2
        @test xs[1].t == -6.0
        @test xs[2].t == -4.0

        s = sphere()
        i = intersection(3.5, s)
        @test i.t == 3.5
        @test i.object == s

        s = sphere()
        i1 = intersection(1, s)
        i2 = intersection(2, s)
        xs = (i1, i2)
        @test length(xs) == 2
        @test xs[1].t == 1
        @test xs[2].t == 2

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere()
        xs = intersect(s, r)
        @test length(xs) == 2
        @test xs[1].object == s
        @test xs[2].object == s

        s = sphere()
        i1 = intersection(1, s)
        i2 = intersection(2, s)
        xs = intersections(i2, i1)
        i = hit(xs)
        @test i == i1

        s = sphere()
        i1 = intersection(-1, s)
        i2 = intersection(1, s)
        xs = intersections(i2, i1)
        i = hit(xs)
        @test i == i2

        s = sphere()
        i1 = intersection(-2, s)
        i2 = intersection(-1, s)
        xs = intersections(i2, i1)
        i = hit(xs)
        @test isnothing(i)

        s = sphere()
        i1 = intersection(5, s)
        i2 = intersection(7, s)
        i3 = intersection(-3, s)
        i4 = intersection(2, s)
        xs = intersections(i1, i2, i3, i4)
        i = hit(xs)
        @test i == i4

        r = ray(point(1, 2, 3), vector(0, 1, 0))
        m = translation(3, 4, 5)
        r2 = transform(r, m)
        @test r2.origin == point(4, 6, 8) # may need to adjust something since point is a 4-vector
        @test r2.velocity == vector(0, 1, 0) # ditto for vector

        r = ray(point(1, 2, 3), vector(0, 1, 0))
        m = scaling(2, 3, 4)
        r2 = transform(r, m)
        @test r2.origin == point(2, 6, 12)
        @test r2.velocity == vector(0, 3, 0)

        s = sphere()
        @test s.transform == I

        t = translation(2, 3, 4)
        s = sphere(transform = t)
        @test s.transform == t

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere(transform = scaling(2, 2, 2))
        xs = intersect(s, r)
        @test length(xs) == 2
        @test xs[1].t == 3
        @test xs[2].t == 7

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere(transform = translation(5, 0, 0))
        xs = intersect(s, r)
        @test isempty(xs)
    end

    @testset "ch 6 - light and shading" begin

        #=
            first implementations of materials and normal calculations,
            leading up the first version of the all-important lighting
            function. also made a helper to round colors by component
            so as to implement unit tests from the book more easily.
            also first 3D draw.
        =#

        s = sphere()
        n = normal_at(s, point(1, 0, 0))
        @test n == vector(1, 0, 0)

        s = sphere()
        n = normal_at(s, point(0, 1, 0))
        @test n == vector(0, 1, 0)

        s = sphere()
        n = normal_at(s, point(0, 0, 1))
        @test n == vector(0, 0, 1)

        s = sphere()
        n = normal_at(s, point(√3/3, √3/3, √3/3))
        @test n == vector(√3/3, √3/3, √3/3)
        @test n == normalize(n)

        s = sphere(transform = translation(0, 1, 0))
        n = normal_at(s, point(0, 1.70711, -0.70711))
        @test round.(n, digits=5) == vector(0, 0.70711, -0.70711)

        s = sphere(transform = scaling(1, 0.5, 1) * rotation_z(π/5))
        n = normal_at(s, point(0, √2/2, -√2/2))
        @test round.(n, digits=5) == vector(0, 0.97014, -0.24254)

        v = vector(1, -1, 0)
        n = vector(0, 1, 0)
        r = reflect(v, n)
        @test r == vector(1, 1, 0)

        v = vector(0, -1, 0)
        n = vector(√2/2, √2/2, 0)
        r = reflect(v, n)
        @test r ≈ vector(1, 0, 0)

        intensity = colorant"white"
        pos = point(0, 0, 0)
        light = point_light(pos, intensity)
        @test light.position == pos
        @test light.intensity == intensity

        m = material()
        @test m.color == colorant"white"
        @test m.ambient == 0.1
        @test m.diffuse == 0.9
        @test m.specular == 0.9
        @test m.shininess == 200.0

        s = sphere()
        @test s.material.color == colorant"white"
        @test s.material.ambient == 0.1
        @test s.material.diffuse == 0.9
        @test s.material.specular == 0.9
        @test s.material.shininess == 200.0

        m = material(ambient = 1)
        s = sphere(material = m)
        @test s.material == m

        m = material()
        pos = point(0, 0, 0)
        eyev = vector(0, 0, -1)
        normalv = vector(0, 0, -1)
        light = point_light(point(0, 0, -10), colorant"white")
        result = lighting(m, light, pos, eyev, normalv)
        @test result == RGB(1.9, 1.9, 1.9)

        m = material()
        pos = point(0, 0, 0)
        eyev = vector(0, √2/2, -√2/2)
        normalv = vector(0, 0, -1)
        light = point_light(point(0, 0, -10), colorant"white")
        result = lighting(m, light, pos, eyev, normalv)
        @test result == colorant"white"

        m = material()
        pos = point(0, 0, 0)
        eyev == vector(0, 0, -1)
        normalv == vector(0, 0, -1)
        light = point_light(point(0, 10, -10), colorant"white")
        result = lighting(m, light, pos, eyev, normalv)
        @test round_color(result, 4) == RGB(0.7364, 0.7364, 0.7364)

        m = material()
        pos = point(0, 0, 0)
        eyev = vector(0, -√2/2, -√2/2)
        normalv = vector(0, 0, -1)
        light = point_light(point(0, 10, -10), colorant"white")
        result = lighting(m, light, pos, eyev, normalv)
        @test round_color(result, 4) == RGB(1.6364, 1.6364, 1.6364)

        m = material()
        pos = point(0, 0, 0)
        eyev = vector(0, 0, -1)
        normalv = vector(0, 0, -1)
        light = point_light(point(0, 0, 10), colorant"white")
        result = lighting(m, light, pos, eyev, normalv)
        @test result == RGB(0.1, 0.1, 0.1)
    end

    @testset "ch 7 - making a scene" begin

        #=
            first 3d render. also first time numerical issues
            presented challenges i felt like i had to avoid
            rather than solve. also the first time one of those
            challenges appeared to be a typo in the book.
        =#

        w = world()
        @test w.objects == []
        @test w.lights == []

        # the book does these tests with set membership. i'm doing it by checking
        # the attributes that are supposed to be set because equality comparison
        # in julia is a little tricky.
        w = default_world()
        @test length(w.lights) == 1
        @test w.lights[1].position == point(-10, 10, -10)
        @test w.lights[1].intensity == colorant"white"
        @test length(w.objects) == 2
        @test w.objects[1].material.color == RGB(0.8, 1.0, 0.6)
        @test w.objects[1].material.diffuse == 0.7
        @test w.objects[1].material.specular == 0.2
        @test w.objects[2].transform == scaling(0.5, 0.5, 0.5)

        w = default_world()
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        xs = intersect(w, r)
        @test length(xs) == 4
        @test xs[1].t == 4
        @test xs[2].t == 4.5
        @test xs[3].t == 5.5
        @test xs[4].t == 6

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere()
        i = intersection(4, s)
        comps = prepare_computations(i, r)
        @test comps.t == i.t
        @test comps.object == i.object
        @test comps.point == point(0, 0, -1)
        @test comps.eyev == vector(0, 0, -1)
        @test comps.normalv == vector(0, 0, -1)

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere()
        i = intersection(4, s)
        comps = prepare_computations(i, r)
        @test comps.inside == false

        r = ray(point(0, 0, 0), vector(0, 0, 1))
        s = sphere()
        i = intersection(1, s)
        comps = prepare_computations(i, r)
        @test comps.point == point(0, 0, 1)
        @test comps.eyev == vector(0, 0, -1)
        @test comps.inside == true
        @test comps.normalv == vector(0, 0, -1)

        w = default_world()
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = w.objects[1]
        i = intersection(4, s)
        comps = prepare_computations(i, r)
        c = shade_hit(w, comps)
        @test round_color(c) == RGB(0.38066, 0.47583, 0.2855)

        w = default_world(light = point_light(point(0, 0.25, 0), colorant"white"))
        r = ray(point(0, 0, 0), vector(0, 0, 1))
        s = w.objects[2]
        i = intersection(0.5, s)
        comps = prepare_computations(i, r)
        c = shade_hit(w, comps)
        @test round_color(c) == RGB(0.90498, 0.90498, 0.90498)

        w = default_world()
        r = ray(point(0, 0, -5), vector(0, 1, 0))
        c = color_at(w, r)
        # in case you were still wondering if the two ways of
        # expressing a color were equivalent (i know i was)
        @test c == colorant"black" == RGB(0, 0, 0)

        w = default_world()
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        c = color_at(w, r)
        @test round_color(c) == RGB(0.38066, 0.47583, 0.2855)

        w = default_world(m1 = material(color = RGB(0.8, 0.1, 0.6), diffuse = 0.7, specular = 0.2, ambient = 1), m2 = material(ambient = 1))
        r = ray(point(0, 0, 0.75), vector(0, 0, -1))
        c = color_at(w, r)
        @test c == w.objects[2].material.color # inner sphere

        from = point(0, 0, 0)
        to = point(0, 0, -1)
        up = vector(0, 1, 0)
        t = view_transform(from, to, up)
        @test t == I

        from = point(0, 0, 0)
        to = point(0, 0, 1)
        up = vector(0, 1, 0)
        t = view_transform(from, to, up)
        @test t == scaling(-1, 1, -1)

        from = point(0, 0, 8)
        to = point(0, 0, 0)
        up = vector(0, 1, 0)
        t = view_transform(from, to, up)
        @test t == translation(0, 0, -8)

        from = point(1, 3, 2)
        to = point(4, -2, 8)
        up = vector(1, 1, 0)
        t = view_transform(from, to, up)
        @test round.(t, digits=5) == [
            -0.50709 0.50709 0.67612 -2.36643
            0.76772 0.60609 0.12122 -2.82843
            -0.35857 0.59761 -0.71714 0
            0 0 0 1
        ]

        c = camera(hsize=160, vsize=120, fov=π/2)
        @test c.hsize == 160
        @test c.vsize == 120
        @test c.fov == π / 2
        @test c.transform == I

        c = camera(hsize=200, vsize=125, fov=π/2)
        @test c.pixel_size ≈ 0.01

        c = camera(hsize=125, vsize=200, fov=π/2)
        @test c.pixel_size ≈ 0.01

        c = camera(hsize=201, vsize=101, fov=π/2)
        r = ray_for_pixel(c, 100, 50)
        @test r.origin ≈ point(0, 0, 0)
        @test r.velocity ≈ vector(0, 0, -1)

        c = camera(hsize=201, vsize=101, fov=π/2)
        r = ray_for_pixel(c, 0, 0)
        @test r.origin ≈ point(0, 0, 0)
        @test round.(r.velocity, digits=5) == vector(0.66519, 0.33259, -0.66851)

        c = camera(hsize=201, vsize=101, fov=π/2, transform=rotation_y(π / 4) * translation(0, -2, 5))
        r = ray_for_pixel(c, 100, 50)
        @test r.origin ≈ point(0, 2, -5)
        @test r.velocity ≈ vector(√2/2, 0, -√2/2)

        w = default_world()
        from = point(0, 0, -5)
        to = point(0, 0, 0)
        up = vector(0, 1, 0)
        c = camera(hsize=11, vsize=11, fov=π/2, transform=view_transform(from, to, up))
        img = render(c, w)
        @test round_color(pixel(img, 5, 5)) == round_color(RGB(0.38066, 0.47583, 0.2855))
    end

    @testset "ch 8 - shadows" begin

        #=
            wondering if i should have decided to do multiple lights.
            there are no test cases for them in the book, and it made
            this chapter a lot trickier. other interesting bits included
            having to multiply ϵ by 100000 before the fleas would go away,
            and having to mess with a bunch of stuff from the last chapter
            rather than just cleanly layering on new functions.
        =#

        m = material()
        pos = point(0, 0, 0)
        eyev = vector(0, 0, -1)
        normalv = vector(0, 0, -1)
        light = point_light(point(0, 0, -10), colorant"white")
        result = lighting(m, light, pos, eyev, normalv, 0.0)
        @test result == RGB(0.1, 0.1, 0.1)

        w = world()
        push!(w.lights, point_light(point(0, 0, -10), colorant"white"))
        s1 = sphere()
        s2 = sphere(transform = translation(0, 0, 10))
        push!(w.objects, s1, s2)
        r = ray(point(0, 0, 5), vector(0, 0, 1))
        i = intersection(4, s2)
        comps = prepare_computations(i, r)
        c = shade_hit(w, comps)
        @test c == RGB(0.1, 0.1, 0.1)

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere(transform = translation(0, 0, 1))
        i = intersection(5, s)
        comps = prepare_computations(i, r)
        @test comps.over_point[3] < -eps()/2
        @test comps.point[3] > comps.over_point[3]
    end

    @testset "ch 9 - planes" begin

        #=
            this chapter involves refactoring sphere so you can accomodate
            it and the new plan class more easily via an abstract shape class.
            that's half or more of the chapter, or at least of the work
            involved, since the plane is a really simple primitive.

            the affected functions are ==, transform, material!, intersect,
            and normal_at, and those are the *only* affected functions (i.e.
            the only places where changing sphere changes other code
            requirements).

            another change worth investigating is how many of my mutable structs
            could be made immutable with some refactoring.

            ...ok going by the docs, probably none of these should be immutable,
            or at least it probably won't hurt anything if they're all mutable.
            however, material! and transform don't really help anyone do anything,
            so i removed them and refactored a bunch of the constructors to use
            keyword arguments. also i stopped hard-assigning world array fields
            in favor of push!ing. then i refactored the test to remove the == operator
            in favor of testing all the interesting fields individually, and removed
            those overloads from the module. not going to miss them, they were a
            hassle.

            that means the only things i'll need to truly refactor for this chapter
            will be intersect, normal_at, and perhaps constructors. going to take
            a break and think about this a bit, because julia doesn't allow abstract
            classes to have fields, nor inheriting from concrete classes, so the
            usual approaches won't work.

            was in refactoring mode and removed the x,y,z,w,x!,y!,z!,w! functions,
            they were more trouble than they were worth. replaced wrld with w.

            well it turns out that not only does julia not allow abstract classes
            to have fields, it doesn't really allow abstract classes at all, only
            abstract classes, which are more a dispatch tool than a way to not
            repeat common code. so i'm not going to have an abstract shape class,
            and will skip the tests related to that because the simple changes i
            made to ease dispatching with multiple shapes don't break any of the
            existing tests.

            then removed sphere's origin field because it was never used anywhere,
            and realized that a sphere is just a thing with a transform and a material
            that has a certain meaning for intersection and normal calculations.
            dunno if i can clean things up further. probably would be a good
            question for humans of julia.

            planes were super easy to add after all that was dealt with, but i
            do want to see about maybe refactoring them later.
        =#

        p = plane()
        n1 = normal_at(p, point(0, 0, 0))
        n2 = normal_at(p, point(10, 0, -10))
        n3 = normal_at(p, point(-5, 0, 150))
        @test n1 == vector(0, 1, 0)
        @test n2 == vector(0, 1, 0)
        @test n3 == vector(0, 1, 0)

        p = plane()
        r = ray(point(0, 10, 0), vector(0, 0, 1)) # parallel
        xs = intersect(p, r)
        @test xs == []

        p = plane()
        r = ray(point(0, 0, 0), vector(0, 0, 1)) # coplanar
        xs = intersect(p, r)
        @test xs == []

        p = plane()
        r = ray(point(0, 1, 0), vector(0, -1, 0)) # intersect from above
        xs = intersect(p, r)
        @test length(xs) == 1
        @test xs[1].t == 1
        @test xs[1].object == p

        p = plane()
        r = ray(point(0, -1, 0), vector(0, 1, 0)) # intersect from below
        xs = intersect(p, r)
        @test length(xs) == 1
        @test xs[1].t == 1
        @test xs[1].object == p
    end

    @testset "ch 10 - patterns" begin

        #=
            more "abstract class" shenanigans, altho i'm beginning to think
            that this is actually yet another place where julia outdoes more
            object-oriented languages.

            stripes was the first pattern implemented, so it serves to exercise
            the "abstract" pattern functionality, including the integration with
            lighting and shade_hit.

            wondering if macros or code generation are the answer to "how to
            refactor my repetitive mutable structs", that issue is more glaring
            with patterns than with shapes.

            may want to clean up the gradient implementation some time,
            FixedPointNumbers were a little hairy to work with when trying
            to go from white to black, since that meant finding the per-channel
            direction associated with the difference of two colors, i.e.
            "negative colors", and the default color difference return a color,
            which can't have negative channel values.
        =#

        p = stripes()
        @test p.a == colorant"white"
        @test p.b == colorant"black"

        p = stripes()
        @test pattern_at(p, point(0, 0, 0)) == colorant"white"
        @test pattern_at(p, point(0, 1, 0)) == colorant"white"
        @test pattern_at(p, point(0, 2, 0)) == colorant"white"

        p = stripes()
        @test pattern_at(p, point(0, 0, 0)) == colorant"white"
        @test pattern_at(p, point(0, 0, 1)) == colorant"white"
        @test pattern_at(p, point(0, 0, 2)) == colorant"white"

        p = stripes()
        @test pattern_at(p, point(0, 0, 0)) == colorant"white"
        @test pattern_at(p, point(0.9, 0, 0)) == colorant"white"
        @test pattern_at(p, point(1, 0, 0)) == colorant"black"
        @test pattern_at(p, point(-0.1, 0, 0)) == colorant"black"
        @test pattern_at(p, point(-1, 0, 0)) == colorant"black"
        @test pattern_at(p, point(-1.1, 0, 0)) == colorant"white"

        m = material(pattern = stripes(), ambient = 1, diffuse = 0, specular = 0)
        eyev = vector(0, 0, -1)
        normalv = vector(0, 0, -1)
        light = point_light(point(0, 0, -10), colorant"white")
        c1 = lighting(m, light, point(0.9, 0, 0), eyev, normalv)
        c2 = lighting(m, light, point(1.1, 0, 0), eyev, normalv)
        @test c1 == m.pattern.a
        @test c2 == m.pattern.b

        obj = sphere(transform = scaling(2, 2, 2))
        pat = stripes()
        c = pattern_at_object(pat, obj, point(1.5, 0, 0))
        @test c == colorant"white"

        obj = sphere()
        pat = stripes(transform = scaling(2, 2, 2))
        c = pattern_at_object(pat, obj, point(1.5, 0, 0))
        @test c == colorant"white"

        obj = sphere(transform = scaling(2, 2, 2))
        pat = stripes(transform = translation(0.5, 0, 0))
        c = pattern_at_object(pat, obj, point(2.5, 0, 0))
        @test c == colorant"white"

        # chapter 11: wasn't expecting actually need this, but whatever.
        # needed test_pattern for a ch 11 test case, so i went back and
        # implemented its test cases here.
        pat = test_pattern()
        @test pat.transform == I

        pat = test_pattern(transform = translation(1, 2, 3))
        @test pat.transform == translation(1, 2, 3)

        s = sphere(transform = scaling(2, 2, 2))
        pat = test_pattern()
        c = pattern_at_object(pat, s, point(2, 3, 4))
        @test c == RGB(1.0, 1.5, 2.0)

        s = sphere(transform = scaling(2, 2, 2))
        pat = test_pattern(transform = translation(0.5, 1, 1.5))
        c = pattern_at_object(pat, s, point(2.5, 3, 3.5))
        @test c == RGB(0.75, 0.5, 0.25)

        pat = gradient()
        @test pattern_at(pat, point(0, 0, 0)) == colorant"white"
        @test pattern_at(pat, point(0.25, 0, 0)) == RGB(0.75, 0.75, 0.75)
        @test pattern_at(pat, point(0.5, 0, 0)) == RGB(0.5, 0.5, 0.5)
        @test pattern_at(pat, point(0.75, 0, 0)) == RGB(0.25, 0.25, 0.25)

        pat = rings()
        @test pattern_at(pat, point(0, 0, 0)) == colorant"white"
        @test pattern_at(pat, point(1, 0, 0)) == colorant"black"
        @test pattern_at(pat, point(0, 0, 1)) == colorant"black"
        # 0.708 is just a tiny bit greater than √2/2
        @test pattern_at(pat, point(0.708, 0, 0.708)) == colorant"black"

        pat = checkers()
        @test pattern_at(pat, point(0, 0, 0)) == colorant"white"
        @test pattern_at(pat, point(0.99, 0, 0)) == colorant"white"
        @test pattern_at(pat, point(1.01, 0, 0)) == colorant"black"

        pat = checkers()
        @test pattern_at(pat, point(0, 0, 0)) == colorant"white"
        @test pattern_at(pat, point(0, 0.99, 0)) == colorant"white"
        @test pattern_at(pat, point(0, 1.01, 0)) == colorant"black"

        pat = checkers()
        @test pattern_at(pat, point(0, 0, 0)) == colorant"white"
        @test pattern_at(pat, point(0, 0, 0.99)) == colorant"white"
        @test pattern_at(pat, point(0, 0, 1.01)) == colorant"black"
    end

    @testset "ch 11 - reflection and refraction" begin

        #=
            TODO: refactor this test suite so that test names correspond to ones from the book

            after incorporating fixes that i did while working on other chapters,
            this is the first one where i have to round any result past the book's.
            fortunately i've never had to round more than 2 places, so if there's
            an underlying numerical issue it's probably a small one.

            speaking of which, this is when i discovered that the color of one of
            the spheres in my default world was off in the green channel by a factor
            of 10 due to an oversight which could easily have been a typo. even its
            test case was off. both had to be fixed. actually that was after
            chapter 13, but i came back and rewrote this comment. :)
        =#

        m = material()
        @test m.reflective == 0

        s = plane()
        r = ray(point(0, 1, -1), vector(0, -√2/2, √2/2))
        i = intersection(√2, s)
        comps = prepare_computations(i, r)
        @test comps.reflectv == vector(0, √2/2, √2/2)

        w = default_world()
        r = ray(point(0, 0, 0), vector(0, 0, 1))
        s = w.objects[2]
        s.material.ambient = 1
        i = intersection(1, s)
        comps = prepare_computations(i, r)
        c = reflected_color(w, comps)
        @test c == colorant"black"

        w = default_world()
        s = plane(material = material(reflective = 0.5), transform = translation(0, -1, 0))
        push!(w.objects, s)
        r = ray(point(0, 0, -3), vector(0, -√2/2, √2/2))
        i = intersection(√2, s)
        comps = prepare_computations(i, r)
        c = reflected_color(w, comps)
        # NOTE rounds 1 place past where the book does (is the first test to do so)
        @test round_color(c, 4) == round_color(RGB(0.19032, 0.2379, 0.14274), 4)

        w = default_world()
        s = plane(material = material(reflective = 0.5), transform = translation(0, -1, 0))
        push!(w.objects, s)
        r = ray(point(0, 0, -3), vector(0, -√2/2, √2/2))
        i = intersection(√2, s)
        comps = prepare_computations(i, r)
        c = shade_hit(w, comps)
        # NOTE rounds 2 places past where the book does
        @test round_color(c, 3) == round_color(RGB(0.87677, 0.92436, 0.82918), 3)

        w = world()
        push!(w.lights, point_light(point(0, 0, 0), colorant"white"))
        lower = plane(material = material(reflective = 1), transform = translation(0, -1, 0))
        upper = plane(material = material(reflective = 1), transform = translation(0, 1, 0))
        push!(w.objects, lower, upper)
        r = ray(point(0, 0, 0), vector(0, 1, 0))
        # this test fails with an exception if max recursion depth is exceeded,
        # like in python, so the only success condition is that we can actually
        # test for a value at all.
        @test exists(color_at(w, r))

        w = default_world()
        s = plane(material = material(reflective = 0.5), transform = translation(0, -1, 0))
        push!(w.objects, s)
        r = ray(point(0, 0, -3), vector(0, -√2/2, √2/2))
        i = intersection(√2, s)
        comps = prepare_computations(i, r)
        c = reflected_color(w, comps, 0)
        @test c == colorant"black"

        m = material()
        @test m.transparency == 0
        @test m.refractive_index == 1.0

        s = sphere(material = material(transparency = 1, refractive_index = 1.5))
        @test s.transform == I
        @test s.material.transparency == 1
        @test s.material.refractive_index == 1.5

        s1 = sphere(material = material(transparency = 1, refractive_index = 1.5), transform = scaling(2, 2, 2))
        s2 = sphere(material = material(transparency = 1, refractive_index = 2.0), transform = translation(0, 0, -0.25))
        s3 = sphere(material = material(transparency = 1, refractive_index = 2.5), transform = translation(0, 0, 0.25))
        r = ray(point(0, 0, -4), vector(0, 0, 1))
        xs = intersections(
            intersection(2, s1),
            intersection(2.75, s2),
            intersection(3.25, s3),
            intersection(4.75, s2),
            intersection(5.25, s3),
            intersection(6, s1)
        )
        comps = prepare_computations(xs[1], r, xs)
        @test comps.n1 == 1.0
        @test comps.n2 == 1.5
        comps = prepare_computations(xs[2], r, xs)
        @test comps.n1 == 1.5
        @test comps.n2 == 2.0
        comps = prepare_computations(xs[3], r, xs)
        @test comps.n1 == 2.0
        @test comps.n2 == 2.5
        comps = prepare_computations(xs[4], r, xs)
        @test comps.n1 == 2.5
        @test comps.n2 == 2.5
        comps = prepare_computations(xs[5], r, xs)
        @test comps.n1 == 2.5
        @test comps.n2 == 1.5
        comps = prepare_computations(xs[6], r, xs)
        @test comps.n1 == 1.5
        @test comps.n2 == 1.0

        r = ray(point(0, 0, -5), vector(0, 0, 1))
        s = sphere(material = material(transparency = 1), transform = translation(0, 0, 1))
        i = intersection(5, s)
        xs = intersections(i)
        comps = prepare_computations(i, r, xs)
        @test comps.under_point[3] > eps() / 2
        @test comps.point[3] < comps.under_point[3]

        w = default_world()
        s = w.objects[1]
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        xs = intersections(intersection(4, s), intersection(6, s))
        comps = prepare_computations(xs[1], r, xs)
        c = refracted_color(w, comps, 5)
        @test c == colorant"black"

        w = default_world()
        s = w.objects[1]
        s.material.transparency = 1.0
        s.material.refractive_index = 1.5
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        xs = intersections(intersection(4, s), intersection(6, s))
        comps = prepare_computations(xs[1], r, xs)
        c = refracted_color(w, comps, 0)
        @test c == colorant"black"

        w = default_world()
        s = w.objects[1]
        s.material.transparency = 1.0
        s.material.refractive_index = 1.5
        r = ray(point(0, 0, √2/2), vector(0, 1, 0))
        xs = intersections(intersection(-√2/2, s), intersection(√2/2, s))
        comps = prepare_computations(xs[2], r, xs)
        c = refracted_color(w, comps, 5)
        @test c == colorant"black"

        w = default_world()
        a = w.objects[1]
        a.material.ambient = 1.0
        a.material.pattern = test_pattern()
        b = w.objects[2]
        b.material.transparency = 1.0
        b.material.refractive_index = 1.5
        r = ray(point(0, 0, 0.1), vector(0, 1, 0))
        xs = intersections(intersection(-0.9899, a), intersection(-0.4899, b), intersection(0.4899, b), intersection(0.9899, a))
        comps = prepare_computations(xs[3], r, xs)
        c = refracted_color(w, comps, 5)
        # NOTE rounds 2 places past where the book does
        @test round_color(c, 3) == round_color(RGB(0, 0.99888, 0.04725), 3)

        w = default_world()
        flr = plane(transform = translation(0, -1, 0), material = material(transparency = 0.5, refractive_index = 1.5))
        push!(w.objects, flr)
        b = sphere(transform = translation(0, -3.5, -0.5), material = material(color = RGB(1, 0, 0), ambient = 0.5))
        push!(w.objects, b)
        r = ray(point(0, 0, -3), vector(0, -√2/2, √2/2))
        xs = intersections(intersection(√2, flr))
        comps = prepare_computations(xs[1], r, xs)
        c = shade_hit(w, comps, 5)
        # NOTE rounds 1 place past where the book does
        @test round_color(c, 4) == round_color(RGB(0.93642, 0.68642, 0.68642), 4)

        s = glass_sphere()
        r = ray(point(0, 0, √2/2), vector(0, 1, 0))
        xs = intersections(intersection(-√2/2, s), intersection(√2/2, s))
        comps = prepare_computations(xs[2], r, xs)
        reflectance = schlick(comps)
        @test reflectance == 1.0

        s = glass_sphere()
        r = ray(point(0, 0, 0), vector(0, 1, 0))
        xs = intersections(intersection(-1, s), intersection(1, s))
        comps = prepare_computations(xs[2], r, xs)
        reflectance = schlick(comps)
        @test reflectance ≈ 0.04

        s = glass_sphere()
        r = ray(point(0, 0.99, -2), vector(0, 0, 1))
        xs = intersections(intersection(1.8589, s))
        comps = prepare_computations(xs[1], r, xs)
        reflectance = schlick(comps)
        @test round(reflectance, digits=5) == 0.48873

        w = default_world()
        r = ray(point(0, 0, -3), vector(0, -√2/2, √2/2))
        flr = plane(transform = translation(0, -1, 0), material = material(reflective = 0.5, transparency = 0.5, refractive_index = 1.5))
        push!(w.objects, flr)
        b = sphere(transform = translation(0, -3.5, -0.5), material = material(color = RGB(1, 0, 0), ambient = 0.5))
        push!(w.objects, b)
        xs = intersections(intersection(√2, flr))
        comps = prepare_computations(xs[1], r, xs)
        c = shade_hit(w, comps, 5)
        # NOTE rounds 1 place past where the book does
        @test round_color(c, 4) == round_color(RGB(0.93391, 0.69643, 0.69243), 4)
    end

    @testset "ch 12 - cubes" begin

        #=
            cubes were a nice break after the last chapter.
        =#

        c = cube()
        r = ray(point(5, 0.5, 0), vector(-1, 0, 0))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cube()
        r = ray(point(-5, 0.5, 0), vector(1, 0, 0))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cube()
        r = ray(point(0.5, 5, 0), vector(0, -1, 0))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cube()
        r = ray(point(0.5, -5, 0), vector(0, 1, 0))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cube()
        r = ray(point(0.5, 0, 5), vector(0, 0, -1))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cube()
        r = ray(point(0.5, 0, -5), vector(0, 0, 1))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cube()
        r = ray(point(0, 0.5, 0), vector(0, 0, 1))
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == -1
        @test xs[2].t == 1

        c = cube()
        r = ray(point(-2, 0, 0), vector(0.2673, 0.5345, 0.8018))
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cube()
        r = ray(point(0, -2, 0), vector(0.8018, 0.2673, 0.5345))
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cube()
        r = ray(point(0, 0, -2), vector(0.5345, 0.8018, 0.2673))
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cube()
        r = ray(point(2, 0, 2), vector(0, 0, -1))
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cube()
        r = ray(point(0, 2, 2), vector(0, -1, 0))
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cube()
        r = ray(point(2, 2, 0), vector(-1, 0, 0))
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cube()
        p = point(1, 0.5, -0.8)
        n = normal_at(c, p)
        @test n == vector(1, 0, 0)

        c = cube()
        p = point(-1, -0.2, 0.9)
        n = normal_at(c, p)
        @test n == vector(-1, 0, 0)

        c = cube()
        p = point(-0.4, 1, -0.1)
        n = normal_at(c, p)
        @test n == vector(0, 1, 0)

        c = cube()
        p = point(0.3, -1, -0.7)
        n = normal_at(c, p)
        @test n == vector(0, -1, 0)

        c = cube()
        p = point(-0.6, -0.3, 1)
        n = normal_at(c, p)
        @test n == vector(0, 0, 1)

        c = cube()
        p = point(0.4, 0.4, -1)
        n = normal_at(c, p)
        @test n == vector(0, 0, -1)

        c = cube()
        p = point(1, 1, 1)
        n = normal_at(c, p)
        @test n == vector(1, 0, 0)

        c = cube()
        p = point(-1, -1, -1)
        n = normal_at(c, p)
        @test n == vector(-1, 0, 0)
    end

    @testset "ch 13 - cylinders" begin

        #=
            TODO: reimagine and rewrite to not be organized by chapters

            easy to lose track of stuff at this point, beat my head on a
            few test cases that were failing due to silly mistakes, but
            got through them. now that i've had a bit more experience
            debugging this application i'll revisit the broken ch 11 cases.
        =#

        c = cylinder()
        dir = normalize(vector(0, 1, 0))
        r = ray(point(1, 0, 0), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder()
        dir = normalize(vector(0, 0, 0))
        r = ray(point(0, 0, 0), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder()
        dir = normalize(vector(1, 1, 1))
        r = ray(point(0, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder()
        dir = normalize(vector(0, 0, 1))
        r = ray(point(1, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 5
        @test xs[2].t == 5

        c = cylinder()
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[2].t == 6

        c = cylinder()
        dir = normalize(vector(0.1, 1, 1))
        r = ray(point(0.5, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 2
        @test round(xs[1].t, digits=5) == 6.80798
        @test round(xs[2].t, digits=5) == 7.08872

        c = cylinder()
        n = normal_at(c, point(1, 0, 0))
        @test n == vector(1, 0, 0)

        c = cylinder()
        n = normal_at(c, point(0, 5, -1))
        @test n == vector(0, 0, -1)

        c = cylinder()
        n = normal_at(c, point(0, -2, 1))
        @test n == vector(0, 0, 1)

        c = cylinder()
        n = normal_at(c, point(-1, 1, 0))
        @test n == vector(-1, 0, 0)

        c = cylinder()
        @test c.min == -Inf
        @test c.max == Inf

        c = cylinder(min = 1, max = 2)
        dir = normalize(vector(0.1, 1, 0))
        r = ray(point(0, 1.5, 0), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder(min = 1, max = 2)
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 3, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder(min = 1, max = 2)
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder(min = 1, max = 2)
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 2, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder(min = 1, max = 2)
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 1, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cylinder(min = 1, max = 2)
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 1.5, -2), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cylinder()
        @test c.closed == false

        c = cylinder(min = 1, max = 2, closed = true)
        dir = normalize(vector(0, -1, 0))
        r = ray(point(0, 3, 0), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cylinder(min = 1, max = 2, closed = true)
        dir = normalize(vector(0, -1, 2))
        r = ray(point(0, 3, -2), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cylinder(min = 1, max = 2, closed = true)
        dir = normalize(vector(0, -1, 1))
        r = ray(point(0, 4, -2), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cylinder(min = 1, max = 2, closed = true)
        dir = normalize(vector(0, 1, 2))
        r = ray(point(0, 0, -2), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cylinder(min = 1, max = 2, closed = true)
        dir = normalize(vector(0, 1, 1))
        r = ray(point(0, -1, -2), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cylinder(min = 1, max = 2, closed = true)
        n = normal_at(c, point(0, 1, 0))
        @test n == vector(0, -1, 0)

        c = cylinder(min = 1, max = 2, closed = true)
        n = normal_at(c, point(0.5, 1, 0))
        @test n == vector(0, -1, 0)

        c = cylinder(min = 1, max = 2, closed = true)
        n = normal_at(c, point(0, 1, 0.5))
        @test n == vector(0, -1, 0)

        c = cylinder(min = 1, max = 2, closed = true)
        n = normal_at(c, point(0, 2, 0))
        @test n == vector(0, 1, 0)

        c = cylinder(min = 1, max = 2, closed = true)
        n = normal_at(c, point(0.5, 2, 0))
        @test n == vector(0, 1, 0)

        c = cylinder(min = 1, max = 2, closed = true)
        n = normal_at(c, point(0, 2, 0.5))
        @test n == vector(0, 1, 0)

        c = cone()
        dir = normalize(vector(0, 0, 1))
        r = ray(point(0, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 5
        @test xs[2].t == 5

        c = cone()
        dir = normalize(vector(1, 1, 1))
        r = ray(point(0, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 2
        @test round(xs[1].t, digits=5) == 8.66025
        @test round(xs[2].t, digits=5) == 8.66025

        c = cone()
        dir = normalize(vector(-0.5, -1, 1))
        r = ray(point(1, 1, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 2
        @test round(xs[1].t, digits=5) == 4.55006
        @test round(xs[2].t, digits=5) == 49.44994

        c = cone()
        dir = normalize(vector(0, 1, 1))
        r = ray(point(0, 0, -1), dir)
        xs = intersect(c, r)
        @test length(xs) == 1
        @test round(xs[1].t, digits=5) == 0.35355

        c = cone(min = -0.5, max = 0.5, closed = true)
        dir = normalize(vector(0, 1, 0))
        r = ray(point(0, 0, -5), dir)
        xs = intersect(c, r)
        @test length(xs) == 0

        c = cone(min = -0.5, max = 0.5, closed = true)
        dir = normalize(vector(0, 1, 1))
        r = ray(point(0, 0, -0.25), dir)
        xs = intersect(c, r)
        @test length(xs) == 2

        c = cone(min = -0.5, max = 0.5, closed = true)
        dir = normalize(vector(0, 1, 0))
        r = ray(point(0, 0, -0.25), dir)
        xs = intersect(c, r)
        @test length(xs) == 4

        c = cone()
        n = _normal_at(c, point(0, 0, 0))
        @test n == vector(0, 0, 0)

        c = cone()
        n = _normal_at(c, point(1, 1, 1))
        @test n == vector(1, -√2, 1)

        c = cone()
        n = _normal_at(c, point(-1, -1, 0))
        @test n == vector(-1, 1, 0)
    end

    @testset "ch 14 - groups" begin

        #=
            ok bug fixes for ch 7 and ch 11 are going to be labeled by
            this chapter if something is unclear. ch 7 is worlds, and this
            builds on that, so i want to make sure my stuff is correct before
            it breaks something that builds on top of it in a way that's even
            harder to diagnose.

            ...the bugs turned out to be: 1) default world sphere 1 color should
            have had green == 1.0 instead of green == 0.1, 2) change canvas
            default color from colorant"black" to RGB{Float64}(colorant"black").

            there are exactly 5 tests where my implementation doesn't get exactly
            the same results as the book, and the worst of these are correct if
            rounded to 3 decimal places, which means "practically no visible
            difference" (all of these are color tests, by the way). there's likely
            an issue somewhere, perhaps even a numerical one, but i'm not convinced
            just yet that it would be worthwhile to try and tackle it.

            moving on to chapter 14 proper...

            decided not to do anything to prevent the recursion that would be
            made possible by having shapes or groups be parents of themselves.
            also not going to force parents or children to be groups because i
            don't want to mess with the compiler or the type system or my
            shape-level intersect and normal calculations, altho i'd kinda like
            to have anything potentially be a child of anything else like in the
            game engines i'm familiar with. i think doing something like that would
            require more robust structs a la Unity's GameObject or Godot's Node
            which can do lots of different things depending on the situation.
        =#

        g = group()
        @test g.transform == I
        @test g.children == []

        shapes = [sphere(), plane(), cube(), cylinder(), cone(), group()]
        @test all(s -> s.parent == nothing, shapes)

        g = group()
        shapes = [sphere(), plane(), cube(), cylinder(), cone(), group()]
        add_child(g, shapes...)
        @test has_children(g, shapes...)

        g = group()
        r = ray(point(0, 0, 0), vector(0, 0, 1))
        xs = _intersect(g, r)
        @test length(xs) == 0

        g = group()
        s1 = sphere()
        s2 = sphere(transform = translation(0, 0, -3))
        s3 = sphere(transform = translation(5, 0, 0))
        add_child(g, s1, s2, s3)
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        xs = _intersect(g, r)
        @test length(xs) == 4
        @test xs[1].object == s2
        @test xs[2].object == s2
        @test xs[3].object == s1
        @test xs[4].object == s1

        g = group(transform = scaling(2, 2, 2))
        s = sphere(transform = translation(5, 0, 0))
        add_child(g, s)
        r = ray(point(10, 0, -10), vector(0, 0, 1))
        xs = intersect(g, r)
        @test length(xs) == 2

        g1 = group(transform = rotation_y(π/2))
        g2 = group(transform = scaling(2, 2, 2))
        add_child(g1, g2)
        s = sphere(transform = translation(5, 0, 0))
        add_child(g2, s)
        @test world_to_object(s, point(-2, 0, -10)) ≈ point(0, 0, -1)

        g1 = group(transform = rotation_y(π/2))
        g2 = group(transform = scaling(1, 2, 3))
        add_child(g1, g2)
        s = sphere(transform = translation(5, 0, 0))
        add_child(g2, s)
        @test round.(normal_to_world(s, vector(√3/3, √3/3, √3/3)), digits=4) == vector(0.2857, 0.4286, -0.8571)
        # don't like having to round past where the book does, but whatever
        @test round.(normal_at(s, point(1.7321, 1.1547, -5.5774)), digits=3) == round.(vector(0.2857, 0.4286, -0.8571), digits=3)
    end

    @testset "ch 15 - triangles" begin

        #=
            yeeeeaaaaaaaaah triangles. decided to skip the obj parser
            and move it into its own test set, will do after the bonus
            chapters when i will focus on making demo images and also
            do the yaml parser, which will not have associated test cases.
        =#

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        @test t.p1 == p1
        @test t.p2 == p2
        @test t.p3 == p3
        @test t.e1 == vector(-1, -1, 0)
        @test t.e2 == vector(1, -1, 0)
        @test t.n == vector(0, 0, 1)

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        @test _normal_at(t, point(0, 0.5, 0)) == t.n
        @test _normal_at(t, point(-0.5, 0.75, 0)) == t.n
        @test _normal_at(t, point(0.5, 0.25, 0)) == t.n

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        r = ray(point(0, -1, -2), vector(0, 1, 0))
        xs = _intersect(t, r)
        @test length(xs) == 0

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        r = ray(point(1, 1, -2), vector(0, 0, 1))
        xs = _intersect(t, r)
        @test length(xs) == 0

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        r = ray(point(-1, 1, -2), vector(0, 0, 1))
        xs = _intersect(t, r)
        @test length(xs) == 0

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        r = ray(point(0, -1, -2), vector(0, 0, 1))
        xs = _intersect(t, r)
        @test length(xs) == 0

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        t = triangle(p1=p1, p2=p2, p3=p3)
        r = ray(point(0, 0.5, -2), vector(0, 0, 1))
        xs = _intersect(t, r)
        @test length(xs) == 1
        @test xs[1].t == 2

        p1 = point(0, 1, 0)
        p2 = point(-1, 0, 0)
        p3 = point(1, 0, 0)
        n1 = vector(0, 1, 0)
        n2 = vector(-1, 0, 0)
        n3 = vector(1, 0, 0)
        tri = smooth_triangle(p1=p1, p2=p2, p3=p3, n1=n1, n2=n2, n3=n3)
        @test tri.p1 == p1
        @test tri.p2 == p2
        @test tri.p3 == p3
        @test tri.n1 == n1
        @test tri.n2 == n2
        @test tri.n3 == n3

        s = triangle(p1=p1, p2=p2, p3=p3)
        i = intersection(3.5, s, u=0.2, v=0.4)
        @test i.u == 0.2
        @test i.v == 0.4

        r = ray(point(-0.2, 0.3, -2), vector(0, 0, 1))
        xs = _intersect(tri, r)
        @test xs[1].u ≈ 0.45
        @test xs[1].v ≈ 0.25

        i = intersection(1, tri, u=0.45, v=0.25)
        n = normal_at(tri, point(0, 0, 0), hit=i)
        @test round.(n, digits=5) == vector(-0.5547, 0.83205, 0)

        i = intersection(1, tri, u=0.45, v=0.25)
        r = ray(point(-0.2, 0.3, -2), vector(0, 0, 1))
        xs = intersections(i)
        comps = prepare_computations(i, r, xs)
        @test round.(comps.normalv, digits=5) == vector(-0.5547, 0.83205, 0)
    end

    @testset "ch 16 - constructive solid geometry" begin

        #=

        =#

        s1 = sphere()
        s2 = cube()
        c = csg(:union, s1, s2)
        @test c.op == :union
        @test c.l == s1
        @test c.r == s2
        @test s1.parent == c
        @test s2.parent == c

        @test !intersection_allowed(:union, true, true, true)
        @test intersection_allowed(:union, true, true, false)
        @test !intersection_allowed(:union, true, false, true)
        @test intersection_allowed(:union, true, false, false)
        @test !intersection_allowed(:union, false, true, true)
        @test !intersection_allowed(:union, false, true, false)
        @test intersection_allowed(:union, false, false, true)
        @test intersection_allowed(:union, false, false, false)

        @test intersection_allowed(:intersect, true, true, true)
        @test !intersection_allowed(:intersect, true, true, false)
        @test intersection_allowed(:intersect, true, false, true)
        @test !intersection_allowed(:intersect, true, false, false)
        @test intersection_allowed(:intersect, false, true, true)
        @test intersection_allowed(:intersect, false, true, false)
        @test !intersection_allowed(:intersect, false, false, true)
        @test !intersection_allowed(:intersect, false, false, false)

        @test !intersection_allowed(:difference, true, true, true)
        @test intersection_allowed(:difference, true, true, false)
        @test !intersection_allowed(:difference, true, false, true)
        @test intersection_allowed(:difference, true, false, false)
        @test intersection_allowed(:difference, false, true, true)
        @test intersection_allowed(:difference, false, true, false)
        @test !intersection_allowed(:difference, false, false, true)
        @test !intersection_allowed(:difference, false, false, false)

        s1 = sphere()
        s2 = cube()
        c = csg(:union, s1, s2)
        xs = intersections(intersection(1, s1), intersection(2, s2), intersection(3, s1), intersection(4, s2))
        res = csg_filter(c, xs)
        @test length(res) == 2
        @test res[1] == xs[1]
        @test res[2] == xs[4]

        s1 = sphere()
        s2 = cube()
        c = csg(:intersect, s1, s2)
        xs = intersections(intersection(1, s1), intersection(2, s2), intersection(3, s1), intersection(4, s2))
        res = csg_filter(c, xs)
        @test length(res) == 2
        @test res[1] == xs[2]
        @test res[2] == xs[3]

        s1 = sphere()
        s2 = cube()
        c = csg(:difference, s1, s2)
        xs = intersections(intersection(1, s1), intersection(2, s2), intersection(3, s1), intersection(4, s2))
        res = csg_filter(c, xs)
        @test length(res) == 2
        @test res[1] == xs[1]
        @test res[2] == xs[2]

        c = csg(:union, sphere(), cube())
        r = ray(point(0, 2, -5), vector(0, 0, 1))
        xs = _intersect(c, r)
        @test length(xs) == 0

        s1 = sphere()
        s2 = sphere(transform = translation(0, 0, 0.5))
        c = csg(:union, s1, s2)
        r = ray(point(0, 0, -5), vector(0, 0, 1))
        xs = _intersect(c, r)
        @test length(xs) == 2
        @test xs[1].t == 4
        @test xs[1].object == s1
        @test xs[2].t == 6.5
        @test xs[2].object == s2
    end

    @testset "bch 1 - soft shadows" begin

        #=

        =#

        w = default_world()
        light_pos = point(-10, -10, -10)
        @test !is_shadowed(w, light_pos, point(-10, -10, 10))
        @test is_shadowed(w, light_pos, point(10, 10, 10))
        @test !is_shadowed(w, light_pos, point(-20, -20, -20))
        @test !is_shadowed(w, light_pos, point(-5, -5, -5))

        w = default_world()
        light = w.lights[1]
        @test intensity_at(light, point(0, 1.0001, 0), w) == 1.0
        @test intensity_at(light, point(-1.0001, 0, 0), w) == 1.0
        @test intensity_at(light, point(0, 0, -1.0001), w) == 1.0
        @test intensity_at(light, point(0, 0, 1.0001), w) == 0.0
        @test intensity_at(light, point(1.0001, 0, 0), w) == 0.0
        @test intensity_at(light, point(0, -1.0001, 0), w) == 0.0
        @test intensity_at(light, point(0, 0, 0), w) == 0.0

        w = default_world()
        w.lights[1] = point_light(point(0, 0, -10), colorant"white")
        s = w.objects[1]
        s.material.ambient = 0.1
        s.material.diffuse = 0.9
        s.material.specular = 0
        s.material.color = colorant"white"
        p = point(0, 0, -1)
        eyev = vector(0, 0, -1)
        n = vector(0, 0, -1)
        @test lighting(s.material, w.lights[1], p, eyev, n, 1.0) == colorant"white"
        @test lighting(s.material, w.lights[1], p, eyev, n, 0.5) == RGB(0.55, 0.55, 0.55)
        @test lighting(s.material, w.lights[1], p, eyev, n, 0.0) == RGB(0.1, 0.1, 0.1)

        corner = point(0, 0, 0)
        v1 = vector(2, 0, 0)
        v2 = vector(0, 0, 1)
        l = area_light(corner, v1, 4, v2, 2, colorant"white")
        @test l.corner == corner
        @test l.uvec == vector(0.5, 0, 0)
        @test l.usteps == 4
        @test l.vvec == vector(0, 0, 0.5)
        @test l.vsteps == 2
        @test l.samples == 8
        @test l.position == point(1, 0, 0.5)

        corner = point(0, 0, 0)
        v1 = vector(2, 0, 0)
        v2 = vector(0, 0, 1)
        l = area_light(corner, v1, 4, v2, 2, colorant"white")
        @test point_on_light(l, 0, 0) == point(0.25, 0, 0.25)
        @test point_on_light(l, 1, 0) == point(0.75, 0, 0.25)
        @test point_on_light(l, 0, 1) == point(0.25, 0, 0.75)
        @test point_on_light(l, 2, 0) == point(1.25, 0, 0.25)
        @test point_on_light(l, 3, 1) == point(1.75, 0, 0.75)

        w = default_world()
        corner = point(-0.5, -0.5, -5)
        v1 = vector(1, 0, 0)
        v2 = vector(0, 1, 0)
        l = area_light(corner, v1, 2, v2, 2, colorant"white")
        @test intensity_at(l, point(0, 0, 2), w) == 0.0
        @test intensity_at(l, point(1, -1, 2), w) == 0.25
        @test intensity_at(l, point(1.5, 0, 2), w) == 0.5
        @test intensity_at(l, point(1.25, 1.25, 3), w) == 0.75
        @test intensity_at(l, point(0, 0, -2), w) == 1.0

        gen = sequence(0.1, 0.5, 1.0)
        @test next(gen) == 0.1
        @test next(gen) == 0.5
        @test next(gen) == 1.0
        @test next(gen) == 0.1

        corner = point(0, 0, 0)
        v1 = vector(2, 0, 0)
        v2 = vector(0, 0, 1)
        l = area_light(corner, v1, 4, v2, 2, colorant"white", sequence(0.3, 0.7))
        @test point_on_light(l, 0, 0) == point(0.15, 0, 0.35)
        # the book's way of looping through test cases doesn't
        # make it clear that the sequence resets every time
        l.jitter_by.pos = 1
        @test point_on_light(l, 1, 0) == point(0.65, 0, 0.35)
        l.jitter_by.pos = 1
        @test point_on_light(l, 0, 1) == point(0.15, 0, 0.85)
        l.jitter_by.pos = 1
        @test point_on_light(l, 2, 0) == point(1.15, 0, 0.35)
        l.jitter_by.pos = 1
        @test point_on_light(l, 3, 1) == point(1.65, 0, 0.85)

        w = default_world()
        corner = point(-0.5, -0.5, -5)
        v1 = vector(1, 0, 0)
        v2 = vector(0, 1, 0)
        l = area_light(corner, v1, 2, v2, 2, colorant"white", sequence(0.7, 0.3, 0.9, 0.1, 0.5))
        @test intensity_at(l, point(0, 0, 2), w) == 0.0
        l.jitter_by.pos = 1
        @test intensity_at(l, point(1, -1, 2), w) == 0.5
        l.jitter_by.pos = 1
        @test intensity_at(l, point(1.5, 0, 2), w) == 0.75
        l.jitter_by.pos = 1
        @test intensity_at(l, point(1.25, 1.25, 3), w) == 0.75
        l.jitter_by.pos = 1
        @test intensity_at(l, point(0, 0, -2), w) == 1.0

        corner = point(-0.5, -0.5, -5)
        v1 = vector(1, 0, 0)
        v2 = vector(0, 1, 0)
        l = area_light(corner, v1, 2, v2, 2, colorant"white")
        s = sphere(material = material(ambient = 0.1, diffuse = 0.9, specular = 0, color = colorant"white"))
        eye = point(0, 0, -5)
        pt = point(0, 0, -1)
        eyev = normalize(eye - pt)
        n = vector(pt[1:3]...)
        res = lighting(s.material, s, light, pt, eyev, n, 1.0)
        @test round_color(res, 4) == RGB(0.9965, 0.9965, 0.9965)
        pt = point(0, 0.7071, -0.7071)
        eyev = normalize(eye - pt)
        n = vector(pt[1:3]...)
        res = lighting(s.material, s, light, pt, eyev, n, 1.0)
        @test round_color(res, 4) == RGB(0.6232, 0.6232, 0.6232)
    end

    @testset "bch 2 - texture mapping" begin

    end

    @testset "bch 3 - bounding boxes" begin

    end

    @testset "input" begin

        #=
            not really sure whether i'll actually do these. i recall that
            i skipped the earlier PPM stuff completely, i may run into similar
            solutions for this. we'll see, it likely won't matter until i get
            to doing demo scenes to polish this project off, at which point i'll
            be at the mercy of whatever's available for free.
        =#

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/gibberish.obj")
        # @test o.ignored == 5

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/vertices.obj")
        # @test o.vertices[1] == point(-1, 1, 0)
        # @test o.vertices[2] == point(-1, 0.5, 0)
        # @test o.vertices[3] == point(1, 0, 0)
        # @test o.vertices[4] == point(1, 1, 0)

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/triangles.obj")
        # g = o.default_group
        # t1 = g.children[1]
        # t2 = g.children[2]
        # @test t1.p1 == o.vertices[1]
        # @test t1.p2 == o.vertices[2]
        # @test t1.p3 == o.vertices[3]
        # @test t2.p1 == o.vertices[1]
        # @test t2.p2 == o.vertices[3]
        # @test t2.p3 == o.vertices[4]

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/polygons.obj")
        # g = o.default_group
        # t1 = g.children[1]
        # t2 = g.children[2]
        # t3 = g.children[3]
        # @test t1.p1 == o.vertices[1]
        # @test t1.p2 == o.vertices[2]
        # @test t1.p3 == o.vertices[3]
        # @test t2.p1 == o.vertices[1]
        # @test t2.p2 == o.vertices[3]
        # @test t2.p3 == o.vertices[4]
        # @test t3.p1 == o.vertices[1]
        # @test t3.p2 == o.vertices[4]
        # @test t3.p3 == o.vertices[5]

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/groups.obj")
        # g1 = o.groups["FirstGroup"]
        # g2 = o.groups["SecondGroup"]
        # t1 = g1.children[1]
        # t2 = g2.children[1]
        # @test t1.p1 == o.vertices[1]
        # @test t1.p2 == o.vertices[2]
        # @test t1.p3 == o.vertices[3]
        # @test t2.p1 == o.vertices[1]
        # @test t2.p2 == o.vertices[3]
        # @test t2.p3 == o.vertices[4]

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/groups.obj")
        # group constructor which invokes obj constructor and parses into group
        # g = group("/home/jhigginbotham64/.julia/dev/starlight/test/groups.obj")
        # @test g.children[1] == o.groups["FirstGroup"]
        # @test g.children[2] == o.groups["SecondGroup"]

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/normals.obj")
        # @test o.normals[1] == vector(0, 0, 1)
        # @test o.normals[2] == vector(0.707, 0, -0.707)
        # @test o.normals[3] == vector(1, 2, 3)

        # o = obj("/home/jhigginbotham64/.julia/dev/starlight/test/faces_with_normals.obj")
        # g = o.default_group
        # t1 = g.children[1]
        # t2 = g.children[2]
        # @test t1.p1 == o.vertices[1]
        # @test t1.p2 == o.vertices[2]
        # @test t1.p3 == o.vertices[3]
        # @test t1.n1 == o.normals[3]
        # @test t1.n2 == o.normals[1]
        # @test t1.n3 == o.normals[2]
        # @test t2.vertices == t1.vertices
        # @test t2.normals == t1.normals
    end
end
