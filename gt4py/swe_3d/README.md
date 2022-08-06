# Problem
This directory contains files related to our DG solver for the planar Shallow Water Equations which is expressed through the following PDE:

$$
\begin{cases}
    \partial_t (h) + \partial_x (hu) + \partial_y (hv) = 0 \\
    \partial_t (hu) + \partial_x (hu^2 + \frac{1}{2}gh^2) + \partial_y (huv) = 0 \\
     \partial_t (hu) + \partial_x (huv) + \partial_y (hv^2 + \frac{1}{2}gh^2) = 0\\
\end{cases}   
$$

# Usage
```
Usage:
    python main.py n z_levels p rk backend
  
Arguments:
    n               The number of elements used for both horizontal directions
    z_levels        The number of identical vertical levels
    p               The polynomial degree (leads to a p+1 order method in space)
    rk              The order of Runge Kutta method
    backend         The name of the desired backend
  
Example:
    python main.py 20 1 3 4 numpy
```


# Demo
The following figure illustrates the numerical solution for the planar Shallow Water Equations using our 4th order DG scheme.
The plot depicts the water height component evolved on a square domain with periodic boundary conditions.

<p align="center">
  <img width=400 src="https://user-images.githubusercontent.com/58524567/183141418-8cd5be6e-aaff-4640-9097-de5c85f6ca86.gif">
</p>

