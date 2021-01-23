# starlight

My garden/playground for Julia and computer graphics.

## NOTES
- current bugs can be approached by trying to render simpler CSG scenes
- something similar can be done for OBJ loading and rendering

## BUGS
- [ ] csg transforms and bounding boxes are completely broken
- [ ] ring pattern not working on csg cylinder

## TODO
- [ ] look into refactoring shapes and patterns with macros or something
- [ ] refactor test suite so that test names correspond to ones from the book
- [ ] reimagine and rewrite to not be organized by chapters
- [ ] programatically find good resolution for "final" render (based on fov?)
- [ ] refactor into modules (i.e. fir_branch probably shouldn't have it's own case in parse_entity along with geometric primitives)
- [ ] torus primitive
- [ ] pyramid primitive
- [ ] curves
- [ ] 2D drawing
- [ ] text drawing
- [ ] fonts
- [ ] anti-aliasing/supersampling
- [ ] multiprocess the raytrace function by canvas regions
- [ ] see about parallelizing divide!
- [ ] quaternions and animation
- [ ] fix whatever's keeping you from parsing the standford bunny OBJ file
- [ ] profile performance
- [ ] OBJ texture coordinates
- [ ] MTL parsing
- [ ] full OBJ spec
- [ ] full MTL spec
- [ ] YAML scenes referencing other scenes
- [ ] OBJ export
- [ ] MTL export
- [ ] YAML export
- [ ] rasterization
- [ ] real-time stuff
- [ ] more sophisticated lighting model
