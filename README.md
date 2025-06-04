## An interactive exploration of McLeod's Pitch Detection Method

In the 2005 paper titled ["A Smarter Way To Find Pitch" by Philip McLeod et al](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=60dd4c01f687858a5fbf6c021920c56247bcf2db#page=1.74), the authors describe a new algorithm to detect the pitch from an audio signal. This is named the **McLeod Pitch Method (MPM)**.

In this [Pluto.jl notebook](https://plutojl.org/), I have attempted to implement the algorithm one step at a time. At every step, I plot the outputs and explore various inputs to better understand the fundamentals.

[Here](https://mcleod.samyak.me/) is a live deployment of the notebook (it's interactive if the server is up. If not, you can still access a static version of it).

Disclaimer: I come with no background in signal processing or audio programming. This is my attempt at understanding these concepts. I welcome any feedback. Please open an issue or reach out to me directly.

### Why?

The paper is a little light on the details of some specific functions and algorithms. Some things are hand-waved away. But to implement it, we need those details.
- A visual exploration of differences between ACF Type I and II, SDF Type I and II and NSDF. In particular, this helped me see how NSDF "normalizes" the SDF.
- An explanation of how Power Spectral Density comes into the picture and how it's calculated.
- A derivation (thanks to Pluto.jl's LaTeX support) of `m(𝜏)` given `m(𝜏 - 1)`. This is hand-waved away in the paper - described in one big sentence light on details.
- Details on parabolic interpolation, along with a visualization of it.

### How do I use this?

I would recommend implementing the paper yourself using the approach I took. Julia is a great language for implementing papers - you can write formulas almost one-to-one with only a few changes. Pluto.jl makes it even better by providing an interactive environment, LaTeX support (so you can derive equations right next to the function itself) and built-in package management.

You could also run this notebook (`index.jl`) yourself using Pluto.jl and explore specific parts of the paper that you had trouble with.

In any case, I'll be using this as a reference implementation of MPM.
