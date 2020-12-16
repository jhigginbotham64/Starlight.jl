using starlight
sl = starlight

using Test
using LinearAlgebra

@testset "ray tracer challenge" begin

    @testset "ch 1 - tuples, points, and vectors" begin
        #=
            overload getproperty and setproperty! to implement x,y,z,w?
            these new definitions would be exported, while the array wrapper
            functions would not be to avoid conflicts with built-ins, especially
            tuple.
        =#

        vals = [4.3, -4.2, 3.1, 1.0]

        a = sl.tuple(vals...)
        @test a.x == 4.3
        @test a.y == -4.2
        @test a.z == 3.1
        @test a.w == 1.0
        @test a == sl.point(vals...)
        @test a != sl.vector(vals...)

        a.w = 0.0
        @test a.x == 4.3
        @test a.y == -4.2
        @test a.z == 3.1
        @test a.w == 0.0
        @test a != sl.point(vals...)
        @test a == sl.vector(vals...)

        @test sl.point(4, -4, 3) == sl.tuple(4, -4, 3, 1)
        @test sl.vector(4, -4, 3) == sl.tuple(4, -4, 3, 0)
        @test sl.tuple(3, -2, 5, 1) - sl.tuple(-2, 3, 1, 0) == sl.tuple(1, 1, 6, 1)
        @test sl.point(3, 2, 1) - sl.point(5, 6, 7) == sl.vector(-2, -4, -6)
        @test sl.point(3, 2, 1) - sl.vector(5, 6, 7) == sl.point(-2, -4, -6)
        @test sl.vector(3, 2, 1) - sl.vector(5, 6, 7) == sl.vector(-2, -4, -6)
        @test sl.vector(0, 0, 0) - sl.vector(1, -2, 3) == sl.vector(-1, 2, -3)
        @test -sl.tuple(1, -2, 3, -4) == sl.tuple(-1, 2, -3, 4)
        @test 3.5 * sl.tuple(1, -2, 3, -4) == sl.tuple(3.5, -7, 10.5, -14)
        @test 0.5 * sl.tuple(1, -2, 3, -4) == sl.tuple(0.5, -1, 1.5, -2)
        @test sl.tuple(1, -2, 3, -4) / 2 == sl.tuple(0.5, -1, 1.5, -2)

        @test norm(sl.vector(1, 0, 0)) == 1
        @test norm(sl.vector(0, 1, 0)) == 1
        @test norm(sl.vector(0, 0, 1)) == 1
        @test norm(sl.vector(1, 2, 3)) == √14 # i love julia
        @test norm(sl.vector(-1, -2, -3)) = √14

        @test normalize(sl.vector(4, 0, 0)) == sl.vector(1, 0, 0)
        @test normalize(sl.vector(1, 2, 3)) ≈ sl.vector(1/√14, 2/√14, 3/√14) # i really love julia
        @test norm(normalize(sl.vector(1, 2, 3))) == 1

        # i really really really love julia
        @test sl.vector(1, 2, 3) ⋅ sl.vector(2, 3, 4) == 20
        @test sl.vector(1, 2, 3) × sl.vector(2, 3, 4) == sl.vector(-1, 2, -1)
        @test sl.vector(2, 3, 4) × sl.vector(1, 2, 3) == sl.vector(1, -2, 1)
    end

    @testset "ch 2 - drawing on a canvas" begin

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
