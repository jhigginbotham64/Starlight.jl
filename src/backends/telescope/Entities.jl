export TS_ColorRect, TS_Sprite
export tsDefaultDrawRect, tsDefaultDrawSprite

tsDefaultDrawRect(r) = TS_VkCmdDrawRect(vulkan_colors(r.color)..., r.pos[1], r.pos[2], r.w, r.h)

tsDefaultDrawSprite(s) = TS_VkCmdDrawSprite(s.img, vulkan_colors(s.color)..., 
  s.region[1], s.region[2], s.region[3], s.region[4], 
  s.cell_size[1], s.cell_size[2], s.cell_ind[1], s.cell_ind[2],
  s.pos[1], s.pos[2], s.scale[1], s.scale[2])

function TS_ColorRect(w, h; kw...)
  (ecs::Guard{ECS}) -> Entity(
    ecs; w=w, h=h, draw=tsDefaultDrawRect, kw...)
end

function TS_Sprite(img; kw...)
  (ecs::Guard{ECS}) -> Entity(
    ecs; img=img, draw=tsDefaultDrawSprite, kw...)
end