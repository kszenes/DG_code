# Problem

This directory contains files related to our DG solver for the planar linear advection problem with constant velocity field $\beta$:

$$
\frac{\partial u}{\partial t} + \nabla \cdot (\beta u) = 0 \qquad \text{with} \qquad \beta = [1, 1]^T
$$

# Usage
```
Usage:
    python main.py n p rk backend
  
Arguments:
    n              The number of elements used for both the x and y directions
    p              The polynomial degree (leads to a p+1 order method in space)
    rk             The order of Runge Kutta method
    backend        The name of the desired backend
  
Example:
    python main.py 20 3 4 numpy
```

# Demo

The following figure illustrates the numerical solution of the linear advection problem using our 4th order DG scheme.
The plot depicts a 1 second simulation on the unit square with periodic boundary conditions and a cosine bell as initial conditions.



<p align="center">
  <img width="400" height="400" src="https://user-images.githubusercontent.com/58524567/183125781-918d5460-6e8d-4df6-98d4-d533c751e029.gif">
</p>



