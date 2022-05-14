export physics!
export other

other(e::Entity, col::TS_CollisionEvent) = (e.id == col.id1) ? col.id2 : col.id1

function physics!(ecs::ECS)
  TS_BtStepSimulation()

  runcomponent!(ecs, :physics_step)

  collisions = []

  while true
    col = TS_BtGetNextCollision()
    if col.id1 == -1 && col.id2 == -1 break end
    @debug "entities $(col.id1) and $(col.id2) have a collision event"
    push!(collisions, col)
  end

  Threads.@threads for col ∈ collisions
    runcomponentforentities!(ecs, [col.id1, col.id2], :oncollision, col)
  end
end
