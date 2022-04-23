using Starlight
using Test

# the namespace in front of the method name is important, apparently
Starlight.update!(r::Root, Δ::AbstractFloat) = r.updated = true

mutable struct TestEntity <: Entity end
  
Starlight.update!(t::TestEntity, Δ::AbstractFloat) = t.updated = true

@testset "Starlight" begin
  # load test file
  a = App()

  # no systems should be running
  @test off(a)

  # kick off
  awake!(a)

  # all systems should be running
  @test on(a)

  # close
  shutdown!(a)

  # systems should no longer be running
  @test off(a)

  # ok back on
  awake!(a)

  # visual testing
  # NOTE in SDL, (0,0) is top-left and y goes down
  shapes = [
    ColorRect(200, 200; color=colorant"blue", pos=XYZ(200, 200)),
    Sprite(artifact"test/test/sprites/charmap-cellphone_black.png"; color=RGBA(1.0, 0, 0, 0.5), pos=XYZ(100, 100)),
  ]

  # test manipulations on root
  root = get_entity_by_id(0)

  root.updated = false

  @test !root.updated

  # takes just a little longer than a second
  # for the first update to propagate when
  # JULIA_DEBUG=Starlight, this fixes it
  sleep(1.5)

  @test root.updated

  # manipulations on test entity
  tst = TestEntity()
  instantiate!(tst, props=Dict(
    :updated=>false
  ))
  
  @test !tst.updated

  sleep(1)

  @test tst.updated

  destroy!(tst)

  @test length(ecs()) == 3

  destroy!(shapes...)

  @test length(ecs()) == 1

  shutdown!(a)

  # root should remain and be unmodified
  @test root.updated

  @test off(a)

end
