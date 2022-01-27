using Starlight
using Test

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
end
