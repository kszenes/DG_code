# %%
from email.policy import default
import numpy as np
import gt4py as gt
import gt4py.gtscript as gtscript
import quadpy as qp
from numpy.polynomial import legendre as L

from vander import Vander
from initial_conditions import set_initial_conditions
from generate_matmul_function import generate_matmul_function
from modal_conversion import nodal2modal, modal2nodal, nodal2modal_gt, modal2nodal_gt
from compute_mass import compute_mass
from compute_rhs import compute_rhs
from boundary_conditions import apply_pbc
from plotter import Plotter
from gt4py_config import backend, dtype, backend_opts

import plotly

# %%
# Radius of the earth (for spherical geometry)
radius=6.37122e6;

# Equation type
eq_type="linear";

# domain
a = 0; b = 1; c = 0; d =1
# number of elements in X and Y
nx = 20; ny = 20

hx = (b-a)/nx; hy = (d-c)/ny

# polynomial degree of DG
r = 1
# cardinality
dim=(r+1)**2

# Type of quadrature rule (Gauss-Legendre or Gauss-Legendre-Lobatto)
quad_type="leg"

# Number of quadrature points in one dimension
n_qp_1D=2

# Number of quadrature points
n_qp=n_qp_1D*n_qp_1D

# timestep
dt = 1e-3
niter = 10000

# plotting
plot_freq=10
plot_type = "contour"
# %%
# rdist_gt = degree_distribution("unif",nx,ny,r_max);

if quad_type == "leg":
# Gauss-Legendre quadrature
    [pts,wts]=np.polynomial.legendre.leggauss(n_qp_1D)
elif quad_type == "lob":
# Gauss-Lobatto quadrature
    scheme=qp.line_segment.gauss_lobatto(n_qp_1D)
    pts=scheme.points
    wts=scheme.weights
else:
    [pts,wts]=np.polynomial.legendre.leggauss(n_qp_1D)
    print (type,"unsupported quadrature rule, using Legendre")

pts2d_x = np.kron(pts,np.ones(n_qp_1D))
pts2d_y = np.kron(np.ones(n_qp_1D),pts)
wts2d   = np.kron(wts,wts)

half_cell_x = (b-a)/(2*nx)
half_cell_y = (d-c)/(2*ny)
x_c=np.linspace(a+half_cell_x,b-half_cell_x,nx); # Cell centers in X
y_c=np.linspace(c+half_cell_y,d-half_cell_y,ny); # Cell centers in Y

# all matrices are the same size but lower orders are padded!
vander = Vander(nx, ny, dim, r, n_qp, pts2d_x, pts2d_y, pts, wts2d, backend=backend)

neq, u0_nodal = set_initial_conditions(x_c, y_c, a, b, c, d, dim, vander, "linear")

# plot_solution(u0_nodal, x_c, y_c, r+1, nx, ny, neq, hx, hy, "contour")
u0_nodal_gt = gt.storage.from_array(data=u0_nodal,
    backend=backend, default_origin=(0,0,0), shape=(nx,ny,1), dtype=(dtype, (dim,)))

plotter = Plotter(x_c, y_c, r+1, nx, ny, neq, hx, hy, plot_freq, plot_type)
plotter.plot_solution(u0_nodal_gt, init=True, plot_type=plotter.plot_type)


u0_modal_gt = nodal2modal_gt(vander.inv_vander_gt, u0_nodal_gt)

mass, inv_mass = compute_mass(vander.phi_val_cell, wts2d, nx, ny, r, hx, hy, y_c, pts2d_y, eq_type)

inv_mass_gt = gt.storage.from_array(inv_mass, backend=backend, default_origin=(0,0,0), shape=(nx,ny, 1), dtype=(dtype, (dim, dim)))

wts2d_gt = gt.storage.from_array(wts2d, backend=backend, default_origin=(0,0,0), shape=(nx,ny, 1), dtype=(dtype, (dim, )))

wts1d_gt = gt.storage.from_array(wts, backend=backend, default_origin=(0,0,0), shape=(nx,ny, 1), dtype=(dtype, (len(wts), )))

compute_rhs(u0_modal_gt, vander, inv_mass_gt, wts2d_gt, wts1d_gt, dim, n_qp_1D, n_qp, hx, hy, nx, ny, dt, niter, plotter)
print("Done")

u0_nodal_gt = modal2nodal_gt(vander.vander_gt, u0_modal_gt)

