## DG_code

### Overview
This repository contains a Discontinuous Galerkin (DG) solver for various consevations laws that I implemented during my 4-month internship at the Swiss Supercomputing Center (CSCS).
The solver makes use of [GT4Py](https://github.com/GridTools/gt4py), a Domain-Specific-Language (DSL) for weather and climate simulations, to produce a high-performance implementation.
GT4Py provides the user with a high-level Python interface for stencil computations and generates high-performance implementations for a target architecture, including CPUs and GPUs.

This work builds upon a previous intenship at CSCS conducted by Niccolo Discacciati in 2019.
In particular, his Matlab [code](https://github.com/nickdisca/DG_code) has been adapted and used as a reference implementation.

The repository has the following filestructure:
```
DG_code
├── docs                   <-- Report containing documentation and benchmarks
├── gt4py                  <-- GT4Py implementation
    ├── linear_advection   <-- Linear Advection Solver
    ├── sph_swe_3d         <-- Shallow Water Equation on the Sphere Solver
    ├── swe_3d             <-- Planar Shallow Water Equation Solver
└── matlab                 <-- Reference Matlab implementation
```

### Documentation
- All the directories are complemented with dedicated `README` files.
- In addition, my final [report](https://github.com/kszenes/DG_code/blob/master/docs/main.pdf) contains the mathematical theory behind the DG method, implementation details as well as performance benchmarks carried out on the Piz Daint supercomputer.

### Installation
- First install GT4Py; installation instructions can be found in the [repository](https://github.com/GridTools/gt4py).
- Then install the additional dependencies contained in the requirements.txt file using pip: `pip install -r requirements.txt`.


