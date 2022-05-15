
export App
export run!

mutable struct App
  running::Bool
  App() = new(false)
end

awake!(a::App) = a.running = true
shutdown!(a::App) = a.running = false

function run!(as::App...)
  awake!.(as)
  if !isinteractive()
    while all(on.(as))
      yield()
    end
  end
end