using starlight
sl = starlight

using Test
using LinearAlgebra
using Colors

@testset "ray tracer challenge" begin

    @testset "ch 1 - tuples, Point4s, and Vector4s" begin

        vals = [4.3, -4.2, 3.1, 1.0]

        a = copy(vals)
        @test x(a) == 4.3
        @test y(a) == -4.2
        @test z(a) == 3.1
        @test w(a) == 1.0
        @test a == Point4(vals)
        @test a != Vector4(vals)

        w!(a, 0.0)
        @test x(a) == 4.3
        @test y(a) == -4.2
        @test z(a) == 3.1
        @test w(a) == 0.0
        @test a != Point4(vals)
        @test a == Vector4(vals)

        @test Point4([4, -4, 3]) == [4, -4, 3, 1]
        @test Vector4([4, -4, 3]) == [4, -4, 3, 0]
        @test [3, -2, 5, 1] + [-2, 3, 1, 0] == [1, 1, 6, 1]
        @test Point4([3, 2, 1]) - Point4([5, 6, 7]) == Vector4([-2, -4, -6])
        @test Point4([3, 2, 1]) - Vector4([5, 6, 7]) == Point4([-2, -4, -6])
        @test Vector4([3, 2, 1]) - Vector4([5, 6, 7]) == Vector4([-2, -4, -6])
        @test Vector4([0, 0, 0]) - Vector4([1, -2, 3]) == Vector4([-1, 2, -3])
        @test -[1, -2, 3, -4] == [-1, 2, -3, 4]
        @test 3.5 * [1, -2, 3, -4] == [3.5, -7, 10.5, -14]
        @test 0.5 * [1, -2, 3, -4] == [0.5, -1, 1.5, -2]
        @test [1, -2, 3, -4] / 2 == [0.5, -1, 1.5, -2]

        @test norm(Vector4([1, 0, 0])) == 1
        @test norm(Vector4([0, 1, 0])) == 1
        @test norm(Vector4([0, 0, 1])) == 1
        @test norm(Vector4([1, 2, 3])) == √14 # i love julia
        @test norm(Vector4([-1, -2, -3])) == √14

        @test normalize(Vector4([4, 0, 0])) == Vector4([1, 0, 0])
        @test normalize(Vector4([1, 2, 3])) == Vector4([1/√14, 2/√14, 3/√14]) # i really love julia
        @test norm(normalize(Vector4([1, 2, 3]))) == 1

        # i really really really love julia
        @test Vector4([1, 2, 3]) ⋅ Vector4([2, 3, 4]) == 20
        @test Vector4([1, 2, 3] × [2, 3, 4]) == Vector4([-1, 2, -1])
        @test Vector4([2, 3, 4] × [1, 2, 3]) == Vector4([1, -2, 1])
    end

    @testset "ch 2 - drawing on a canvas" begin

        c = [-0.5, 0.4, 1.7]
        @test red(c) == -0.5
        @test green(c) == 0.4
        @test blue(c) == 1.7

        c = [0.9, 0.6, 0.75] + [0.7, 0.1, 0.25]
        @test red(c) == 1.6
        @test green(c) == 0.7
        @test blue(c) == 1.0

        c = [0.9, 0.6, 0.75] - [0.7, 0.1, 0.25]
        @test red(c) ≈ 0.2 # never really know where numerical instability will strike
        @test green(c) == 0.5
        @test blue(c) == 0.5

        c = 2 * [0.2, 0.3, 0.4]
        @test red(c) == 0.4
        @test green(c) == 0.6
        @test blue(c) == 0.8

        # the formula the book gives for color product is the hadamard product,
        # which is component-wise multiplication, pretty simple in julia.
        c = [1, 0.2, 0.4] .* [0.9, 1, 0.1]
        @test red(c) == 0.9
        @test green(c) == 0.2
        @test blue(c) ≈ 0.04 # again with the instability, and again it's easier to handle in julia than python

        c = BlankCanvas(10, 20)
        @test width(c) == 10
        @test height(c) == 20
        @test all(col == colorant"black" for col in pixels(c))

        pixel!(c, 2, 3, colorant"red")
        @test pixel(c, 2, 3) == colorant"red"
    end

    @testset "ch 3 - matrices" begin

    end

    @testset "ch 4 - matrix transformations" begin

    end

    @testset "ch 5 - ray-sphere intersections" begin

    end

    @testset "ch 6 - light and shading" begin

    end

    @testset "ch 7 - making a scene" begin

    end

    @testset "ch 8 - shadows" begin

    end

    @testset "ch 9 - planes" begin

    end

    @testset "ch 10 - patterns" begin

    end

    @testset "ch 11 - reflection and refraction" begin

    end

    @testset "ch 12 - cubes" begin

    end

    @testset "ch 13 - cylinders" begin

    end

    @testset "ch 14 - groups" begin

    end

    @testset "ch 15 - triangles" begin

    end

    @testset "ch 16 - constructive solid geometry" begin

    end

end
