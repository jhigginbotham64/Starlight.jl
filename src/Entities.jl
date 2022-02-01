export Renderable
export draw, ColorLine, ColorRect, ColorCirc, ColorTri

draw(e::Entity) = nothing

abstract type Renderable <: Entity end

# NOTE all points are considered as offsets from the entity's position
# NOTE rotation is ignored for these simple 2d shapes, you
# either can't rotate them or can transform the points

mutable struct ColorLine <: Renderable
  function ColorLine(p1, p2; color=colorant"white", kw...)
    instantiate!(new(); p1=p1, p2=p2, color=color, kw...)
  end
end

function draw(l::ColorLine)
  SDL_SetRenderDrawColor(
      sdl.rnd,
      sdl_colors(l.color)...,
  )
  SDL_RenderDrawLine(sdl.rnd, Cint.((
    l.p1[1]+l.abs_pos.x, l.p1[2]+l.abs_pos.y, 
    l.p2[1]+l.abs_pos.x, l.p2[2]+l.abs_pos.y))...)
end

mutable struct ColorRect <: Renderable
  function ColorRect(p, w, h; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p=p, w=w, h=h, color=color, fill=fill, kw...)
  end
end

Base.convert(T::Type{SDL_Rect}, r::ColorRect) = SDL_Rect(
  Cint.((r.p[1]+r.abs_pos.x, r.p[2]+r.abs_pos.y, r.w, r.h))...)

function draw(r::ColorRect)
  SDL_SetRenderDrawColor(
      sdl.rnd,
      sdl_colors(r.color)...,
  )
  sr = convert(SDL_Rect, r)
  if !r.fill
      SDL_RenderDrawRect(sdl.rnd, Ref(sr))
  else
      SDL_RenderFillRect(sdl.rnd, Ref(sr))
  end
end

mutable struct ColorCirc <: Renderable
  function ColorCirc(p, r; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p=p, r=r, fill=fill, color=color, kw...)
  end
end

# improved circle drawing algorithm. slower but fills completely. needs optimization
function draw(circle::ColorCirc)
  # define the center and needed sides of circle
  centerX = Cint(circle.p[1]+circle.abs_pos.x)
  centerY = Cint(circle.p[2]+circle.abs_pos.y)
  int_rad = Cint(circle.r)
  left = centerX - int_rad
  top = centerY - int_rad

  SDL_SetRenderDrawColor(
      sdl.rnd,
      sdl_colors(circle.color)...,
  )

  # we consider a grid with sides equal to the circle's diameter
  for x in left:centerX
    for y in top:centerY

      # for each pixel in the top left quadrant of the grid we measure the distance from the center.
      dist = sqrt( (centerX - x)^2 + (centerY - y)^2 )

      # if it is close to the circle's radius it and all associated points in the other quadrants are colored in.
      if (dist <= circle.r + 0.5 && dist >= circle.r - 0.5)
        rel_x = centerX - x
        rel_y = centerY - y

        quad1 = (x              , y              )
        quad2 = (centerX + rel_x, y              )
        quad3 = (x              , centerY + rel_y)
        quad4 = (quad2[1]       , quad3[2]       )

        SDL_RenderDrawPoint(sdl.rnd, quad1[1], quad1[2])
        SDL_RenderDrawPoint(sdl.rnd, quad2[1], quad2[2])
        SDL_RenderDrawPoint(sdl.rnd, quad3[1], quad3[2])
        SDL_RenderDrawPoint(sdl.rnd, quad4[1], quad4[2])

        # if we are told to fill in the circle we draw lines between all of the quadrants to completely fill the circle
        if (circle.fill)
          SDL_RenderDrawLine(sdl.rnd, quad1[1], quad1[2], quad2[1], quad2[2])
          SDL_RenderDrawLine(sdl.rnd, quad2[1], quad2[2], quad4[1], quad4[2])
          SDL_RenderDrawLine(sdl.rnd, quad4[1], quad4[2], quad3[1], quad3[2])
          SDL_RenderDrawLine(sdl.rnd, quad3[1], quad3[2], quad1[1], quad1[2])
        end
      end

    end
  end

end

mutable struct ColorTri <: Renderable
  function ColorTri(p1, p2, p3; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p1=p1, p2=p2, p3=p3, color=color, fill=fill, kw...)
  end
end

function draw(tr::ColorTri)
  p1 = Cint.(tr.p1[1]+tr.abs_pos.x, tr.p1[2]+tr.abs_pos.y)
  p2 = Cint.(tr.p2[1]+tr.abs_pos.x, tr.p2[2]+tr.abs_pos.y)
  p3 = Cint.(tr.p3[1]+tr.abs_pos.x, tr.p3[2]+tr.abs_pos.y)
  SDL_SetRenderDrawColor(sdl.rnd, sdl_colors(tr.color)...)
  SDL_RenderDrawLines(sdl.rnd, [p1; p2; p3; p1], Cint(4))

  ymax = max(p1[2], p2[2], p3[2])
  ymin = min(p1[2], p2[2], p3[2])
  if tr.fill && ymin != ymax
    # Set q1, q2 and q3 in descending order of y-value
    q1 = (p1[2] != ymax != p2[2]) * p3 +
        (p2[2] != ymax != p3[2]) * p1 +
        (p3[2] != ymax != p1[2]) * p2 +
        (p1[2] == p2[2] == ymax) * p2 +
        (p2[2] == p3[2] == ymax) * p3 +
        (p3[2] == p1[2] == ymax) * p1
    q3 = (p1[2] != ymin != p2[2]) * p3 +
        (p2[2] != ymin != p3[2]) * p1 +
        (p3[2] != ymin != p1[2]) * p2 +
        (p1[2] == p2[2] == ymin) * p2 +
        (p2[2] == p3[2] == ymin) * p3 +
        (p3[2] == p1[2] == ymin) * p1
    q2 = ((q1 == p1 && q3 == p3) || (q1 == p3 && q3 == p1)) * p2 +
        ((q1 == p1 && q3 == p2) || (q1 == p2 && q3 == p1)) * p3 +
        ((q1 == p2 && q3 == p3) || (q1 == p3 && q3 == p2)) * p1

    n = q1[2] - q2[2]
    x0 = q1[1] + (q2[2] - q1[2]) / (q3[2] - q1[2]) * (q3[1] - q1[1])
    for j = Cint(0):n-Cint(1)
      r1 = [round(Cint, q2[1] + j / n * (q1[1] - q2[1])); q2[2] + j]
      r2 = [round(Cint, x0 + j / n * (q1[1] - x0)); q2[2] + j]
      SDL_RenderDrawLines(sdl.rnd, [r1; r2], Cint(2))
    end
    n = q2[2] - q3[2]
    for j = Cint(1):n-Cint(1)
      r1 = [round(Cint, q2[1] + j / n * (q3[1] - q2[1])); q2[2] - j]
      r2 = [round(Cint, x0 + j / n * (q3[1] - x0)); q2[2] - j]
      SDL_RenderDrawLines(sdl.rnd, [r1; r2], Cint(2))
    end
  end
end