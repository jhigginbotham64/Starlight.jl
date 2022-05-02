# Starlight.jl

Welcome to the documentation for Starlight.jl, a greedy application framework for [greedy developers](https://julialang.org/blog/2012/02/why-we-created-julia/). Its primary use case is video games, but the power of Julia, [SDL](http://www.libsdl.org/), [Vulkan](https://www.vulkan.org/), and [Bullet](https://pybullet.org/wordpress/) can be leveraged to make just about anything you want.

The walkthrough follows a storytelling approach where a Starlight-like framework is built from scratch. Hopefully this will help you understand the source code better. In any case it is highly recommended that you read everything in order, at least the first time.

It also presupposes knowledge of the Julia programming language. Patterns will be discussed, but core features like multiple dispatch will not. [Make sure you have a good grasp of Julia before proceeding](https://docs.julialang.org/en/v1/).

!!! note

    The struct and method names used in the walkthrough are mostly 
    the same as the ones used in Starlight's own source code. By 
    reading the guide you learn not only Starlight's API but its 
    source code as well, albeit in slightly simplified form.

!!! warning

    The purpose of the walkthrough is to prepare you to read the API 
    docs and source code, but not everything there is the same as in
    the walkthgouh. Use the walkthrough to ground yourself in 
    Starlight's design philosophy and core concepts, but try not to 
    confuse the "classroom" and "real world" versions.