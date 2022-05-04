# Rendering

Entities that get drawn on the screen must satisfy several requirements:

1. They *must* inherit from the abstract type `Starlight.Renderable`, since the scene graph culls objects based on type
2. They *must* be registered in the ECS using `instantiate!`, or the scene graph will not see them
3. They *must* define a `draw` method.

Here is an example from Starlight's source code:

```julia
mutable struct ColorRect <: Renderable
  function ColorRect(w, h; color=colorant"white", kw...)
    instantiate!(new(); w=w, h=h, color=color, kw...)
  end
end

defaultDrawRect(r) = TS_VkCmdDrawRect(
  vulkan_colors(r.color)..., 
  r.abs_pos.x, r.abs_pos.y, r.w, r.h)

draw(r::ColorRect) = defaultDrawRect(r)
```

...where `vulkan_colors` is a helper to convert `Colorant`s to the color format expected by Telescope/Vulkan.

Note that the real magic takes place in `TS_VkCmdDrawRect`, which is Telescope's API for specifically drawing rectangles. If you are using the Telescope backend, you are not able to draw anything that the API doesn't provide explicit support for, although you can compose supported "drawables" using for-loops and such inside your draw function.

Note too that properties are registered in the ECS rather than in the struct definition, as is true for all entities. You can still use struct fields, but they are only ever be referenced if the instance has no ECS attributes with the same name.

Finally, note the mix of property names. Some are constants defined as permanent columns of the underlying `DataFrame`, and others go to the `props` dictionary.

The only other `Renderable` exported by Starlight is `Sprite`:

```julia
mutable struct Sprite <: Renderable
  function Sprite(img; cell_size=[0, 0], region=[0, 0, 0, 0], cell_ind=[0, 0], 
    color=colorant"white", scale=XYZ(1,1,1), kw...)
    instantiate!(new(); img=img, cell_size=cell_size, 
      region=region, cell_ind=cell_ind, color=color,
      scale=scale, kw...)
  end
end

defaultDrawSprite(s) = TS_VkCmdDrawSprite(s.img, 
  vulkan_colors(s.color)..., 
  s.region[1], s.region[2], s.region[3], s.region[4], 
  s.cell_size[1], s.cell_size[2], s.cell_ind[1], s.cell_ind[2],
  s.abs_pos.x, s.abs_pos.y, s.scale.x, s.scale.y)

draw(s::Sprite) = defaultDrawSprite(s)
```

More `Renderable`'s will be "natively" supported in the future, if there's one in particular you'd like to see then feel free to create an issue or, better still, submit a pull request.

These are not a high priority for now though, since sprites and rectangles are sufficient for almost all 2D use cases, and 3D is not a priority (although we're happy to make it a priority if you get in touch, see the README for contact info).

However, check out the Pong example for an idea of what can be done by composing sprites and rectangles.

There are two final Telescope-dependent subsystems to cover: input and physics.