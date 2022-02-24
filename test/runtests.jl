using Starlight
using Test

# the namespace in front of the method name is important, apparently
Starlight.update!(r::Root, Δ) = r.updated = true

mutable struct TestEntity <: Entity end
  
Starlight.update!(t::TestEntity, Δ) = t.updated = true

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
    ColorLine((-100,-100),(100,100);pos=XYZ(100,100)),
    ColorLine((-100,100),(100,-100);pos=XYZ(100,100)),
    ColorLine((-100,-100),(100,100);pos=XYZ(100,300),color=colorant"black"),
    ColorLine((-100,100),(100,-100);pos=XYZ(100,300),color=colorant"black"),
    ColorRect((0,0),200,200;pos=XYZ(300,100)),
    ColorRect((0,0),200,200;pos=XYZ(300,300),color=colorant"black",fill=false)
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

  @test length(ecs) == 7

  destroy!(shapes...)

  @test length(ecs) == 1

  shutdown!(a)

  # root should remain and be unmodified
  @test root.updated

  @test off(a)

end
