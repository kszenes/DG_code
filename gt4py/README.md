# Configuration
Each simulation has number of configurations that can be specified.
The most significant ones are defined using the CLI tool however some are also found inside the respective `main.py` file for each problem.
They are listed below:

- `a, b, c, d`: the domain size (relevant for Linear Advection and planar SWE as the spherical geometry fixes these values for the SWE on the sphere)
- `ic_type`: initial conditions defined in `{problem}/initial_conditions.py` (planar SWE only comes with one initial condition)
- `n_qp_1D`: number of quadrature points in 1-dimension (currently uses overintegrates)
- `T`: final time of simulation
- `courant, dt`: timestepping parameters: courant number and time step size, respectively
- `plot_freq`: frequency of iterations at which the simulation is plotted 
- `quad_type`: quadrature type (Gauss-Legendre or Gauss-Lobatto), we exclusively use the former
