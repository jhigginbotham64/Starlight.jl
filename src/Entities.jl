export ColorRect, Sprite
export defaultDrawRect, defaultDrawSprite

defaultDrawRect(r) = TS_VkCmdDrawRect(vulkan_colors(r.color)..., r.pos[1], r.pos[2], r.w, r.h)

defaultDrawSprite(s) = TS_VkCmdDrawSprite(s.img, vulkan_colors(s.color)..., 
  s.region[1], s.region[2], s.region[3], s.region[4], 
  s.cell_size[1], s.cell_size[2], s.cell_ind[1], s.cell_ind[2],
  s.pos[1], s.pos[2], s.scale[1], s.scale[2])

function ColorRect(w, h; color=colorant"white", kw...)
  (ecs::ECS) -> Entity(
    ecs; w=w, h=h, color=color, draw=defaultDrawRect)
end

function Sprite(img; cell_size=[0, 0], region=[0, 0, 0, 0], 
  cell_ind=[0, 0], color=colorant"white", scale=[1,1,1], kw...)
  (ecs::ECS) -> Entity(
    ecs; img=img, cell_size=cell_size, 
    region=region, cell_ind=cell_ind, color=color,
    scale=scale, draw=defaultDrawSprite, kw...)
end

