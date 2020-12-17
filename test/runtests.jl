using starlight
sl = starlight

using Test
using LinearAlgebra

@testset "ray tracer challenge" begin

    @testset "ch 1 - tuples, points, and vectors" begin

        #=
            ch 1 summary:

            julia's native data types and standard library functions
            turned this chapter into a smoke test of basic language features.
            very different experience from python, but that may because i'm
            older and have already done it once in python and am less inclined
            to go off the rails.

            it takes less than 100 lines of module code to make all these
            tests pass. define getproperty and setproperty! for arrays of
            numbers so you can use .x, .y, etc. then define point and vector
            "constructors" which are basically just functions that take an
            array and return the first 3 elements (or the list 0-padded to
            length 3) and tack 1 or 0 respectively onto the end. tuples as
            defined by the book become superfluous, even a hindrance, and this
            is why we now have test cases which are basically just "julia can do
            arithmetic on arrays, yaaaaaaay".

            the one weird spot is that the standard library cross product is
            only defined for arrays of length 3. the book's cross product is...
            the same, but is only defined for vectors and ignores the last
            element. i opted to cheat a little and just use the standard library
            cross product without "creating a vector" first (see the last two
            tests for what i mean). this is simple enough but requires me or
            whoever else to remember something extra about how this code works.
            i may come up with something else depending on how much i have to
            use and abuse the cross product in this book.

            whatever i do, my goal for now is to avoid breaking and/or
            revisiting previous tests as much as possible, so there's a good
            chance that it (and everything else from this chapter) will stay
            the way it is.

            i can't fault the book though. it's written to be language-agnostic,
            and the same content has still proved very valuable in helping me
            learn some of the julia fundamentals. remember, this is my first
            time using this language. overall i'm fairly pleased with it so far.
        =#

        vals = [4.3, -4.2, 3.1, 1.0]

        a = copy(vals)
        @test a.x == 4.3
        @test a.y == -4.2
        @test a.z == 3.1
        @test a.w == 1.0
        @test a == point(vals)
        @test a != vector(vals)

        a.w = 0.0
        @test a.x == 4.3
        @test a.y == -4.2
        @test a.z == 3.1
        @test a.w == 0.0
        @test a != point(vals)
        @test a == vector(vals)

        @test point([4, -4, 3]) == [4, -4, 3, 1]
        @test vector([4, -4, 3]) == [4, -4, 3, 0]
        @test [3, -2, 5, 1] + [-2, 3, 1, 0] == [1, 1, 6, 1]
        @test point([3, 2, 1]) - point([5, 6, 7]) == vector([-2, -4, -6])
        @test point([3, 2, 1]) - vector([5, 6, 7]) == point([-2, -4, -6])
        @test vector([3, 2, 1]) - vector([5, 6, 7]) == vector([-2, -4, -6])
        @test vector([0, 0, 0]) - vector([1, -2, 3]) == vector([-1, 2, -3])
        @test -[1, -2, 3, -4] == [-1, 2, -3, 4]
        @test 3.5 * [1, -2, 3, -4] == [3.5, -7, 10.5, -14]
        @test 0.5 * [1, -2, 3, -4] == [0.5, -1, 1.5, -2]
        @test [1, -2, 3, -4] / 2 == [0.5, -1, 1.5, -2]

        @test norm(vector([1, 0, 0])) == 1
        @test norm(vector([0, 1, 0])) == 1
        @test norm(vector([0, 0, 1])) == 1
        @test norm(vector([1, 2, 3])) == √14 # i love julia
        @test norm(vector([-1, -2, -3])) == √14

        @test normalize(vector([4, 0, 0])) == vector([1, 0, 0])
        @test normalize(vector([1, 2, 3])) == vector([1/√14, 2/√14, 3/√14]) # i really love julia
        @test norm(normalize(vector([1, 2, 3]))) == 1

        # i really really really love julia
        @test vector([1, 2, 3]) ⋅ vector([2, 3, 4]) == 20
        @test vector([1, 2, 3] × [2, 3, 4]) == vector([-1, 2, -1])
        @test vector([2, 3, 4] × [1, 2, 3]) == vector([1, -2, 1])
    end

    @testset "ch 2 - drawing on a canvas" begin

        #=
            ch 2 summary:

            again julia trivializes things that were difficult in python.
            this time i dispensed even with the "constructors" for colors,
            because since they're usually 3-tuples instead of 4-tuples it
            doesn't even make sense to have a shortcut. so i just added more
            stuff to getproperty and setproperty! and voila, tests pass.
            except for a couple which i had to adjust to use approx, because
            computers, but even that's cleaner than what tended to happen in
            python. can't wait to see what happens when i get to matrix ops.
            the tests are slightly different from the ones in the book, if i
            was to do the ones from the book it would be...more smoke-testing...

            

        =#
        c = [-0.5, 0.4, 1.7]
        @test c.red == c.r == -0.5
        @test c.green == c.g == 0.4
        @test c.blue == c.b == 1.7

        c = [0.9, 0.6, 0.75] + [0.7, 0.1, 0.25]
        @test c.r == 1.6
        @test c.g == 0.7
        @test c.b == 1.0

        c = [0.9, 0.6, 0.75] - [0.7, 0.1, 0.25]
        @test c.r ≈ 0.2 # never really know where numerical instability will strike
        @test c.g == 0.5
        @test c.b == 0.5

        c = 2 * [0.2, 0.3, 0.4]
        @test c.r == 0.4
        @test c.g == 0.6
        @test c.b == 0.8

        # the formula the book gives for color product is the hadamard product,
        # which is component-wise multiplication. this is so trivial in julia it
        # doesn't even warrant a separate function.
        c = [1, 0.2, 0.4] .* [0.9, 1, 0.1]
        @test c.r == 0.9
        @test c.g == 0.2
        @test c.b ≈ 0.04 # again with the instability, and again it's easier to handle in julia than python
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
