using Starlight
using Test

# the namespace in front of the method name is important, apparently
Starlight.update!(r::Root, Δ) = r.updated = true

mutable struct TestEntity <: Entity end
  
Starlight.update!(t::TestEntity, Δ) = t.updated = true

Starlight.handleMessage(t::TestEntity, m::SDL_UserEvent) = t.gotUserEvent = true

@testset "Starlight" begin
  # load test file
  a = App("test.yml")

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

  # test manipulations on root
  root = get_entity_by_id(0)

  root.updated = false

  @test !root.updated

  # takes just a little longer than a second
  # for the tick to come through, and longer
  # still in debug mode, this seems to work
  sleep(3)

  @test root.updated

  # manipulations on test entity
  tst = TestEntity()
  instantiate!(tst, props=Dict(
    :updated=>false
  ))
  
  @test !tst.updated

  sleep(1)

  @test tst.updated

end
