export Renderable
export draw, image_surface, ColorLine, ColorRect, ColorCirc, ColorTri, Sprite, Text

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

# CPP draw line
function draw(l::ColorLine)
  
end

mutable struct ColorRect <: Renderable
  function ColorRect(p, w, h; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p=p, w=w, h=h, color=color, fill=fill, kw...)
  end
end

# CPP draw rectangle
function draw(r::ColorRect)
  
end

mutable struct ColorCirc <: Renderable
  function ColorCirc(p, r; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p=p, r=r, fill=fill, color=color, kw...)
  end
end

# CPP draw circle
function draw(circle::ColorCirc)

end

mutable struct ColorTri <: Renderable
  function ColorTri(p1, p2, p3; fill=true, color=colorant"white", kw...)
    instantiate!(new(); p1=p1, p2=p2, p3=p3, color=color, fill=fill, kw...)
  end
end

# CPP draw triangle
function draw(tr::ColorTri)
  
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

# CPP draw sprite
function draw(s::Sprite)
  
end

mutable struct Text <: Renderable
  function Text(text, font_name; font_size=12, color=colorant"black", scale=XYZ(1,1,1), alpha=UInt8(255), kw...)
    instantiate!(new(), 
      text=text, font_name=font_name, 
      font_size=font_size, scale=scale, 
      color=color, alpha=alpha, kw...)
  end
end

# CPP draw text
function draw(t::Text)
  
end