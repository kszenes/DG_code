# DG_code
### Created by: Kalman Szenes (ETH, Zurich)

### Overview
This repository contains a Discontinuous Galerkin solver that I implemented during my 4-month internship at the Swiss Supercomputing Center (CSCS).
This work is a continuation an a previous internship at CSCS conducted by Niccolo Discacciati in 2019.
It contains a GT4Py implementation as well as reference Matlab implementation.
[GT4Py](https://github.com/GridTools/gt4py) is a Domain-Specific Language (DSL) which provides a high-level Python syntax for stencil computations and generates high-performance code both for CPUs as well as GPUs.


The following conservation laws have been implemented:
- Linear Advection
- Planar Shallow Water Equations
- Shallow Water Equations on the sphere.
