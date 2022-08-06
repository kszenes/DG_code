# Problem

This directory contains files related to our DG solver for the Shallow Water Equations on the sphere. It was developed on the latitude-longitude grid and implemented using the following conservative form

$$
    \begin{cases}
        \partial_t (h \cos\theta)  + \cfrac{1}{R}\left[ \partial_\lambda \left(h u\right) + \partial_\theta \left(h v \cos\theta\right) \right] = 0 \\
        \partial_t (h u \cos\theta)  +  \cfrac{1}{R}\left[\partial_\lambda \left(h u^2 + \cfrac{g h^2}{2}\right) + \partial_\theta \left(h u v \cos\theta\right) \right] = f h v \cos\theta \\ 
        \partial_t (h v \cos\theta) + \cfrac{1}{R}\left[ \partial_\lambda \left(h u v\right) + \partial_\theta \left(\left(h v^2 + \cfrac{g h^2}{2}\right) \cos\theta\right) \right] = \cfrac{g h^2 \sin \theta}{2 R} - f h u \cos\theta
    \end{cases}
$$

# Usage
```
Usage:
    python main.py n z_levels p rk backend
  
Arguments:
    n              The number of elements used for both the x and y directions
    z_levels        The number of identical vertical levels
    p               The polynomial degree (leads to a p+1 order method in space)
    rk              The order of Runge Kutta method
    backend         The name of the desired backend
  
Example:
    python main.py 20 1 3 4 numpy
```

# Demo

The following figure illustrates an 8-day simulation of the Rossby-Haurwitz wave (Williamson et al., [1992](https://doi.org/10.1016/S0021-9991(05)80016-6)) using our 4th order DG scheme.
Each plot depicts the evolution of variable, namely the water height and longitudinal and latitudinal velocities.

![Rossby-Haurwitz wave](https://user-images.githubusercontent.com/58524567/183117994-13e4c36b-0ffe-4a3f-8241-4acef8ed4859.gif)


