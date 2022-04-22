export Renderable
export draw, image_surface, ColorRect, Sprite

draw(e::Entity) = nothing

mutable struct Root <: Entity end # used for root of ECS tree

abstract type Renderable <: Entity end

mutable struct ColorRect <: Renderable
  function ColorRect(w, h; color=colorant"white", kw...)
    instantiate!(new(); w=w, h=h, color=color, kw...)
  end
end

function draw(r::ColorRect)
  TS_VkCmdDrawRect(vulkan_colors(r.color)..., r.abs_pos.x, r.abs_pos.y, r.w, r.h)
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
    color=colorant"white", scale=XYZ(1,1,1), kw...)
    instantiate!(new(); img=img, cell_size=cell_size, 
      region=region, cell_ind=cell_ind, color=color,
      scale=scale, kw...)
  end
end

function draw(s::Sprite)
  TS_VkCmdDrawSprite(s.img, vulkan_colors(s.color)..., 
  s.region[1], s.region[2], s.region[3], s.region[4], 
  s.cell_size[1], s.cell_size[2], s.cell_ind[1], s.cell_ind[2],
  s.abs_pos.x, s.abs_pos.y, s.scale.x, s.scale.y)
end
