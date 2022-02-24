export Renderable
export draw, image_surface, ColorLine, ColorRect, Sprite, Text

draw(e::Entity) = nothing

abstract type Renderable <: Entity end

# NOTE all points are considered as offsets from the entity's position
# NOTE rotation is ignored for the simple 2d shapes, you
# either can't rotate them or can transform the points

mutable struct ColorLine <: Renderable
  function ColorLine(p1, p2; color=colorant"white", kw...)
    instantiate!(new(); p1=p1, p2=p2, color=color, kw...)
  end
end

function draw(l::ColorLine)
  TS_DrawLine(sdl_colors(l.color)..., 
  l.p1[1]+l.abs_pos.x, l.p1[2]+l.abs_pos.y,
  l.p2[1]+l.abs_pos.x, l.p2[2]+l.abs_pos.y)
end

mutable struct ColorRect <: Renderable
  function ColorRect(p, w, h; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p=p, w=w, h=h, color=color, fill=fill, kw...)
  end
end

function draw(r::ColorRect)
  TS_DrawRect(sdl_colors(r.color)..., r.fill, r.p[1]+r.abs_pos.x, r.p[2]+r.abs_pos.y, r.w, r.h)
end

mutable struct Sprite <: Renderable
  # allow textures larger than a single sprite
  # by supporting cell_size, cell_ind, and region
  # fields. cell_size turns img into a matrix of
  # adjacent regions of the same size starting in
  # the top left of the texture. cell_ind is a 0-indexed
  # (row,col) index into a particular cell. region
  # overrides both and denotes the top-left corner
  # of a rectangle, its width, and its height, and
  # uses only that region of the texture.
  function Sprite(img; cell_size=[0, 0], region=[0, 0, 0, 0], cell_ind=[0, 0], 
    alpha=UInt8(255), scale=XYZ(1,1,1), kw...)
    instantiate!(new(); img=img, cell_size=cell_size, 
      region=region, cell_ind=cell_ind, 
      alpha=alpha, scale=scale, kw...)
  end
end

function draw(s::Sprite)
  TS_DrawSprite(s.img, s.alpha, 
  s.region[1], s.region[2], s.region[3], s.region[4], 
  s.cell_size[1], s.cell_size[2], s.cell_ind[1], s.cell_ind[2],
  s.abs_pos.x, s.abs_pos.y, s.scale.x, s.scale.y, s.abs_rot.z)
end

mutable struct Text <: Renderable
  function Text(text, font_name; font_size=12, color=colorant"black", scale=XYZ(1,1,1), alpha=UInt8(255), kw...)
    instantiate!(new(), 
      text=text, font_name=font_name, 
      font_size=font_size, scale=scale, 
      color=color, alpha=alpha, kw...)
  end
end

function draw(t::Text)
  TS_DrawText(t.font_name, t.font_size, t.text, sdl_colors(t.color)...,
  t.abs_pos.x, t.abs_pos.y, s.scale.x, t.scale.y, t.abs_rot.z)
end