using Starlight

const window_width = 600
const window_height = 400
const paddle_width = 10
const paddle_height = 60
const ball_width = 10
const ball_height = 10
const wall_height = 10
const goal_width = 10
const hz = 1

# collision margins
const wmx = 0 # wall
const wmy = 0
const gmx = 0 # goal
const gmy = 0
const pmx = 0 # paddle
const pmy = 0
const bmx = 0 # ball
const bmy = 0

const pv = window_height # paddle velocity
const ball_vel_x_mult = 0.25
const ball_vel_y_mult = 1.5
const ball_vel_x = ball_vel_x_mult * window_width
const ball_vel_y_max = ball_vel_y_mult * window_height
const paddle_ball_x_tolerance = 2
ball_vel_y(i) =  -i * ball_vel_y_max
const score_scale = 10
const score_y_offset = 50
const msg_scale = 2
const center_line_dash_w = 10
const center_line_dash_h = 40
const center_line_dash_spacing = 20
const asset_base = joinpath(artifact"test", "test")
const secs_between_rounds = 2
const score_to_win = 10

a = App(; wdth=window_width, hght=window_height, bgrd=colorant"black")

# center line
center_line = []
for i in (wall_height + center_line_dash_spacing):(center_line_dash_h + center_line_dash_spacing):(window_height - wall_height - center_line_dash_h - center_line_dash_spacing)
  push!(center_line, ColorRect(center_line_dash_w, center_line_dash_h; 
  color=colorant"grey", pos=XYZ((window_width - center_line_dash_w) / 2, i)))
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
  function CellphoneString(str="", white=true; 
    scale=XYZ(1,1), color=colorant"white", kw...)
    instantiate!(new(); str=str, white=white, scale=scale, color=color, kw...)
  end
end

function Starlight.draw(s::CellphoneString)
  img = (s.white) ? joinpath(asset_base, "sprites", "charmap-cellphone_white.png") : joinpath(asset_base, "sprites", "charmap-cellphone_black.png")
  for (i,c) in enumerate(s.str)
    cell_ind = cpchars[c]
    TS_VkCmdDrawSprite(img, vulkan_colors(s.color)...,
    0, 0, 0, 0,
    7, 9, cell_ind[1], cell_ind[2],
    Int(floor(s.scale.x * 7)) * (i - 1) + s.abs_pos.x, s.abs_pos.y, 
              s.scale.x, s.scale.y)
  end
end

# p1 score
score1 = CellphoneString('0'; color=colorant"grey", 
  scale=XYZ(score_scale, score_scale), 
  pos=XYZ((window_width / 2) - (window_width / 4) - 
  (7 * score_scale / 2), score_y_offset))

# p2 score
score2 = CellphoneString('0'; color=colorant"grey", 
  scale=XYZ(score_scale, score_scale), 
  pos=XYZ((window_width / 2) + (window_width / 4) - 
  (7 * score_scale / 2), score_y_offset))

# welcome message
msg = CellphoneString("Press SPACE to start", false; 
  scale=XYZ(msg_scale, msg_scale), 
  pos=XYZ((window_width - 140 * msg_scale) / 2, 
  (window_height - 9 * msg_scale) / 2))

mutable struct PongPaddle <: Starlight.Renderable 
  function PongPaddle(w, h; kw...)
    instantiate!(new(); w=w, h=h, color=colorant"white", kw...)
  end
end

Starlight.draw(p::PongPaddle) = defaultDrawRect(p)

function Starlight.awake!(p::PongPaddle)
  hw = paddle_width / 2
  hh = paddle_height / 2
  addTriggerBox!(p, hw, hh, hz, p.pos.x + hw, p.pos.y + hh, 0, pmx, pmy, 0)
end

function Starlight.shutdown!(p::PongPaddle)
  removePhysicsObject!(p)
end

function Starlight.handleMessage!(p::PongPaddle, col::TS_CollisionEvent)
  otherId = other(p, col)
  if otherId == wallt.id
    if p.id == p1.id
      pg.p1TouchingTopWall = col.colliding
    elseif p.id == p2.id
      pg.p2TouchingTopWall = col.colliding
    end
  elseif otherId == wallb.id
    if p.id == p1.id
      pg.p1TouchingBottomWall = col.colliding
    elseif p.id == p2.id
      pg.p2TouchingBottomWall = col.colliding
    end
  end
end

# p1
p1 = PongPaddle(paddle_width, paddle_height; 
  pos=XYZ(paddle_width, (window_height - paddle_height) / 2))

# p2
p2 = PongPaddle(paddle_width, paddle_height; 
  pos=XYZ(window_width - 2 * paddle_width, 
  (window_height - paddle_height) / 2))

mutable struct PongArenaWall <: Starlight.Renderable
  function PongArenaWall(w, h; kw...)
    instantiate!(new(); w=w, h=h, color=colorant"white", kw...)
  end
end

Starlight.draw(p::PongArenaWall) = defaultDrawRect(p)

function Starlight.awake!(p::PongArenaWall)
  hw = window_width / 2
  hh = wall_height / 2
  addTriggerBox!(p, hw, hh, hz, p.pos.x + hw, p.pos.y + hh, 0, wmx, wmy, 0)
end

function Starlight.shutdown!(p::PongArenaWall)
  removePhysicsObject!(p)
end

# top wall
wallt = PongArenaWall(window_width, wall_height; pos=XYZ(0, 0))

# bottom wall
wallb = PongArenaWall(window_width, wall_height; 
  pos=XYZ(0, window_height - wall_height))

mutable struct PongArenaGoal <: Starlight.Entity
  function PongArenaGoal(w, h; kw...)
    instantiate!(new(); w=w, h=h, kw...)
  end
end

function Starlight.awake!(p::PongArenaGoal)
  hw = goal_width / 2
  hh = window_height / 2
  addTriggerBox!(p, hw, hh, hz, p.pos.x + hw, p.pos.y + hh, 0, gmx, gmy, 0)
end

function Starlight.shutdown!(p::PongArenaGoal)
  removePhysicsObject!(p)
end

# left goal
goal1 = PongArenaGoal(window_height * 2, goal_width; 
  pos=XYZ(-goal_width, 0))

# right goal
goal2 = PongArenaGoal(window_height * 2, goal_width; 
  pos=XYZ(window_width, 0))

mutable struct PongBall <: Starlight.Renderable
  function PongBall(w, h; kw...)
    instantiate!(new(); w=w, h=h, color=colorant"white", kw...)
  end 
end

Starlight.draw(p::PongBall) = defaultDrawRect(p)

function Starlight.awake!(p::PongBall)
  hw = ball_width / 2
  hh = ball_height / 2
  addTriggerBox!(p, hw, hh, hz, p.pos.x + hw, p.pos.y + hh, 0, bmx, bmy, 0)
end

function Starlight.shutdown!(p::PongBall)
  removePhysicsObject!(p)
end

function hit_edge(p::PongBall, o::PongPaddle)
  if o.id == p1.id # left
    return p.abs_pos.x < (o.abs_pos.x + paddle_width - paddle_ball_x_tolerance)
  else # right
    return p.abs_pos.x > (o.abs_pos.x - ball_width + paddle_ball_x_tolerance)
  end
end

function hit_angle(p::PongBall, o::PongPaddle)
  paddle_top = o.abs_pos.y - ball_height / 2
  ball_center = p.abs_pos.y + ball_height / 2
  paddle_hit_area = paddle_height + ball_height
  return -(2 * ((ball_center - paddle_top) / paddle_hit_area) - 1)
end

function wait_and_start_new_round(arg)
  sleep(SLEEP_SEC(secs_between_rounds))
  pg.ball = newball()
end

getP1Score() = parse(Int, score1.str)
getP2Score() = parse(Int, score2.str)

function Starlight.handleMessage!(p::PongBall, col::TS_CollisionEvent)
  otherId = other(p, col)
  vel = TS_BtGetLinearVelocity(p.id)
  if col.colliding
    if otherId ∈ [wallt.id, wallb.id]
      TS_PlaySound(joinpath(asset_base, 
        "sounds", "ping_pong_8bit_plop.ogg"), 0, -1)
      TS_BtSetLinearVelocity(p.id, vel.x, -vel.y, vel.z)
    elseif otherId ∈ [goal1.id, goal2.id]
      TS_PlaySound(joinpath(asset_base, 
        "sounds", "ping_pong_8bit_peeeeeep.ogg"), 0, -1)
      destroy!(p)

      if otherId == goal2.id
        score1.str = string(getP1Score() + 1)
      elseif otherId == goal1.id
        score2.str = string(getP2Score() + 1)
      end

      if getP1Score() == score_to_win || getP2Score() == score_to_win
        msg.hidden = false
        score1.str = "0"
        score2.str = "0"
      else
        oneshot!(clk(), wait_and_start_new_round)
      end
    elseif otherId ∈ [p1.id, p2.id]
      TS_PlaySound(joinpath(asset_base, 
        "sounds", "ping_pong_8bit_beeep.ogg"), 0, -1)
      o = getEntityById(otherId)
      TS_BtSetLinearVelocity(p.id, (hit_edge(p, o) ? 1 : -1) * vel.x,
        ball_vel_y(hit_angle(p, o)), vel.z)
    end
  end
end

mutable struct PongGame <: Starlight.Entity
  function PongGame() 
    instantiate!(new(); ball=nothing, w=false, s=false, up=false, down=false, 
      p1TouchingTopWall=false, p2TouchingTopWall=false, 
      p1TouchingBottomWall=false, p2TouchingBottomWall=false)
  end
end

function Starlight.awake!(p::PongGame)
  listenFor(p, SDL_KeyboardEvent)
  listenFor(p, SDL_QuitEvent)
  TS_BtSetGravity(0, 0, 0)
end

function Starlight.shutdown!(p::PongGame)
  unlistenFrom(p, SDL_KeyboardEvent)
  unlistenFrom(p, SDL_QuitEvent)
end

function newball()
  p = PongBall(ball_width, ball_height; 
    pos=XYZ((window_width - ball_width) / 2, 
    (window_height - ball_height) / 2))
  TS_BtSetLinearVelocity(p.id, 
    ((rand(Bool)) ? 1 : -1) * ball_vel_x, ball_vel_y(2 * rand() - 1), 0)
  return p
end

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

function Starlight.handleMessage!(p::PongGame, q::SDL_QuitEvent)
  shutdown!(a)
end

function Starlight.update!(p::PongGame, Δ::AbstractFloat)
  TS_BtSetLinearVelocity(p1.id, 0, 0, 0)
  TS_BtSetLinearVelocity(p2.id, 0, 0, 0)
  if p.w && !p.p1TouchingTopWall
    TS_BtSetLinearVelocity(p1.id, 0, -pv, 0)
  elseif p.s && !p.p1TouchingBottomWall
    TS_BtSetLinearVelocity(p1.id, 0, pv, 0)
  end
  if p.up && !p.p2TouchingTopWall
    TS_BtSetLinearVelocity(p2.id, 0, -pv, 0)
  elseif p.down && !p.p2TouchingBottomWall
    TS_BtSetLinearVelocity(p2.id, 0, pv, 0)
  end
end

pg = PongGame()

run!(a)