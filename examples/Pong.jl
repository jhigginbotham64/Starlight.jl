using Starlight

a = App(; wdth=600, hght=400, bgrd=colorant"black")

# TODO: make sure z values are set properly
# TODO: short delay between score and new ball (use Clock for coroutines?) -> Clock function

# center line
center_line = []
for i in 30:60:330
  push!(center_line, ColorRect(10, 40; color=colorant"grey", pos=XYZ(295, i)))
end

# working with Cellphone strings
cpchars = Dict(
  ' ' => [0,0],
  '!' => [0,1],
  '\"' => [0,2],
  '#' => [0,3],
  '$' => [0,4],
  '%' => [0,5],
  '&' => [0,6],
  '\'' => [0,7],
  '(' => [0,8],
  ')' => [0,9],
  '*' => [0,10],
  '+' => [0,11],
  ',' => [0,12],
  '-' => [0,13],
  '.' => [0,14],
  '/' => [0,15],
  '0' => [0,16],
  '1' => [0,17],
  '2' => [1,0],
  '3' => [1,1],
  '4' => [1,2],
  '5' => [1,3],
  '6' => [1,4],
  '7' => [1,5],
  '8' => [1,6],
  '9' => [1,7],
  ':' => [1,8],
  ';' => [1,9],
  '<' => [1,10],
  '=' => [1,11],
  '>' => [1,12],
  '?' => [1,13],
  '@' => [1,14],
  'A' => [1,15],
  'B' => [1,16],
  'C' => [1,17],
  'D' => [2,0],
  'E' => [2,1],
  'F' => [2,2],
  'G' => [2,3],
  'H' => [2,4],
  'I' => [2,5],
  'J' => [2,6],
  'K' => [2,7],
  'L' => [2,8],
  'M' => [2,9],
  'N' => [2,10],
  'O' => [2,11],
  'P' => [2,12],
  'Q' => [2,13],
  'R' => [2,14],
  'S' => [2,15],
  'T' => [2,16],
  'U' => [2,17],
  'V' => [3,0],
  'W' => [3,1],
  'X' => [3,2],
  'Y' => [3,3],
  'Z' => [3,4],
  '[' => [3,5],
  '\\' => [3,6],
  ']' => [3,7],
  '^' => [3,8],
  '_' => [3,9],
  '`' => [3,10],
  'a' => [3,11],
  'b' => [3,12],
  'c' => [3,13],
  'd' => [3,14],
  'e' => [3,15],
  'f' => [3,16],
  'g' => [3,17],
  'h' => [4,0],
  'i' => [4,1],
  'j' => [4,2],
  'k' => [4,3],
  'l' => [4,4],
  'm' => [4,5],
  'n' => [4,6],
  'o' => [4,7],
  'p' => [4,8],
  'q' => [4,9],
  'r' => [4,10],
  's' => [4,11],
  't' => [4,12],
  'u' => [4,13],
  'v' => [4,14],
  'w' => [4,15],
  'x' => [4,16],
  'y' => [4,17],
  'z' => [5,0],
  '{' => [5,1],
  '|' => [5,2],
  '}' => [5,3],
  '~' => [5,4],
)

mutable struct CellphoneString <: Renderable
  function CellphoneString(str="", white=true; scale=XYZ(1,1), color=colorant"white", kw...)
    instantiate!(new(); str=str, white=white, scale=scale, color=color, kw...)
  end
end

function Starlight.draw(s::CellphoneString)
  img = (s.white) ? artifact"test/test/sprites/charmap-cellphone_white.png" : artifact"test/test/sprites/charmap-cellphone_black.png"
  for (i,c) in enumerate(s.str)
    cell_ind = cpchars[c]
    TS_VkCmdDrawSprite(img, vulkan_colors(s.color)...,
    0, 0, 0, 0,
    7, 9, cell_ind[1], cell_ind[2],
    Int(floor(s.scale.x * 7)) * (i - 1) + s.abs_pos.x, s.abs_pos.y, s.scale.x, s.scale.y)
  end
end

# p1 score
score1 = CellphoneString('0'; color=colorant"grey", scale=XYZ(10,10), pos=XYZ(115,50))

# p2 score
score2 = CellphoneString('0'; color=colorant"grey", scale=XYZ(10,10), pos=XYZ(415,50))

# welcome message
msg = CellphoneString("Press SPACE to start", false; scale=XYZ(2,2), pos=XYZ(160, 191))

@enum PongArenaSide LEFT RIGHT TOP BOTTOM

mutable struct PongPaddle <: Starlight.Renderable 
  function PongPaddle(w, h, side; kw...)
    instantiate!(new(); w=w, h=h, side=side, color=colorant"white", kw...)
  end
end

Starlight.draw(p::PongPaddle) = defaultDrawRect(p)

# p1
p1 = PongPaddle(10, 60, LEFT; pos=XYZ(10, 170))

# p2
p2 = PongPaddle(10, 60, RIGHT; pos=XYZ(580, 170))

mutable struct PongArenaWall <: Starlight.Renderable
  function PongArenaWall(w, h, side; kw...)
    instantiate!(new(); w=w, h=h, side=side, color=colorant"white", kw...)
  end
end

Starlight.draw(p::PongArenaWall) = defaultDrawRect(p)

# top wall
wallt = PongArenaWall(600, 10, TOP; pos=XYZ(0, 0))

# bottom wall
wallb = PongArenaWall(600, 10, BOTTOM; pos=XYZ(0, 390))

mutable struct PongArenaGoal <: Starlight.Entity
  function PongArenaGoal(w, h, side; kw...)
    instantiate!(new(); w=w, h=h, side=side, kw...)
  end
end

# left goal
walll = PongArenaGoal(400, 10, LEFT; pos=XYZ(-10, 0))

# right goal
wallr = PongArenaGoal(400, 10, RIGHT; pos=XYZ(610, 0))

mutable struct PongBall <: Starlight.Renderable
  function PongBall(w, h; kw...)
    instantiate!(new(); w=w, h=h, color=colorant"white", kw...)
  end 
end

Starlight.draw(p::PongBall) = defaultDrawRect(p)

mutable struct PongGame <: Starlight.Entity
  ball::Union{PongBall, Nothing}
  w::Bool
  s::Bool
  up::Bool
  down::Bool
  function PongGame() 
    instantiate!(new(); ball=nothing, w=false, s=false, up=false, down=false)
  end
end

Starlight.awake!(p::PongGame) = listenFor(p, SDL_KeyboardEvent)
Starlight.shutdown!(p::PongGame) = unlistenFrom(p, SDL_KeyboardEvent)

newball() = PongBall(10, 10; pos=XYZ(295, 195))

function Starlight.handleMessage!(p::PongGame, key::SDL_KeyboardEvent)
  if key.keysym.scancode == SDL_SCANCODE_SPACE && !msg.hidden
    msg.hidden = true
    p.ball = newball()
  elseif key.keysym.scancode == SDL_SCANCODE_W
    p.w = key.state == SDL_PRESSED
  elseif key.keysym.scancode == SDL_SCANCODE_S
    p.s = key.state == SDL_PRESSED
  elseif key.keysym.scancode == SDL_SCANCODE_UP
    p.up = key.state == SDL_PRESSED
  elseif key.keysym.scancode == SDL_SCANCODE_DOWN
    p.down = key.state == SDL_PRESSED
  end
end

function Starlight.update!(p::PongGame, Δ::AbstractFloat)
  if !(p.w ⊻ p.s)
    # set left paddle velocity to 0
  elseif p.w
    # set left paddle velocity to up
  elseif p.s
    # set left paddle velocity to down
  end
  if !(p.up ⊻ p.down)
    # set right paddle velocity to 0
  elseif p.up
    # set right paddle velocity to up
  elseif p.down
    # set right paddle velocity to down
  end
end

pg = PongGame()

run!(a)
