using Starlight
using Test

# the namespace in front of the method name is important, apparently
Starlight.update(r::Root, Δ) = r.updated = true

mutable struct TestEntity <: Entity end
  
Starlight.update(t::TestEntity, Δ) = t.updated = true

Starlight.handleMessage(t::TestEntity, m::UserEvent) = t.gotUserEvent = true

@testset "Starlight" begin
  # load test file
  a = App("test/test.yml")

  # no systems should be running
  @test off(a)

  # kick off
  # run with JULIA_DEBUG=Starlight to see clock messages
  awake(a)

  # all systems should be running
  @test on(a)

  # close
  shutdown(a)

  # systems should no longer be running
  @test off(a)

  # ok back on
  awake(a)

  # test manipulations on root
  root = get_entity_by_id(ecs, 0)

  root.updated = false

  @test !root.updated

  sleep(1)

  @test root.updated

  # manipulations on test entity
  tst = TestEntity()
  instantiate!(tst, props=Dict(
    :updated=>false,
    :gotUserEvent=>false
  ))
  
  @test !tst.updated
  @test !tst.gotUserEvent

  sleep(1)

  @test tst.updated
  @test !tst.gotUserEvent

  listenFor(tst, UserEvent)

  # haven't figured out how to push events to the SDL queue yet

  sleep(1)

  # ...therefore this test is broken
  @test_broken tst.gotUserEvent

  # be a nice boi
  shutdown(a)
end
