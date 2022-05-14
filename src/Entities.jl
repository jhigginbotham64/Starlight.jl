export ColorRect, Sprite
export defaultDrawRect, defaultDrawSprite

defaultDrawRect(r) = TS_VkCmdDrawRect(vulkan_colors(r.color)..., r.abs_pos.x, r.abs_pos.y, r.w, r.h)

defaultDrawSprite(s) = TS_VkCmdDrawSprite(s.img, vulkan_colors(s.color)..., 
  s.region[1], s.region[2], s.region[3], s.region[4], 
  s.cell_size[1], s.cell_size[2], s.cell_ind[1], s.cell_ind[2],
  s.abs_pos.x, s.abs_pos.y, s.scale.x, s.scale.y)

function ColorRect(w, h; color=colorant"white", kw...)
  (ecs::ECS) -> Entity(
    ecs; w=w, h=h, color=color, draw=defaultDrawRect)
end

function Sprite(img; cell_size=[0, 0], region=[0, 0, 0, 0], 
  cell_ind=[0, 0], color=colorant"white", scale=XYZ(1,1,1), kw...)
  (ecs::ECS) -> Entity(
    ecs; img=img, cell_size=cell_size, 
    region=region, cell_ind=cell_ind, color=color,
    scale=scale, draw=defaultDrawSprite, kw...)
end

