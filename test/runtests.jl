using Starlight
using Test
import Starlight: update

Starlight.update(r::Root, Δ) = r.updated = true

mutable struct TestEntity <: Starlight.Entity end
  
Starlight.update(t::TestEntity, Δ) = t.updated = true

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
  instantiate!(tst, props=Dict(:updated=>false))
  
  @test !tst.updated

  sleep(1)

  @test tst.updated

end
