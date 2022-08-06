# %%
import numpy as np
import time
import gt4py as gt
import quadpy as qp

from vander import Vander
from initial_conditions import set_initial_conditions
from modal_conversion import nodal2modal_gt, modal2nodal_gt
from compute_mass import compute_mass
from run import run
from plotter import Plotter
from gt4py_config import backend, dtype, r, n_qp_1D, runge_kutta, n, perf_flag

# silence warning
np.warnings.filterwarnings('ignore', category=np.VisibleDeprecationWarning)

#inital conditions ("cosine_bell" or "smooth_sine")
ic_type = "cosine_bell"

# domain
a = 0; b = 1; c = 0; d =1

# number of elements in X and Y
nx = n; ny = n

hx = (b-a)/nx; hy = (d-c)/ny

# polynomial degree of DG
# cardinality
dim=(r+1)**2

# Type of quadrature rule (Gauss-Legendre or Gauss-Legendre-Lobatto)
quad_type="leg"

# Number of quadrature points
n_qp=n_qp_1D*n_qp_1D


# timestep
# dt = 1e-4
courant = 0.2

dx = np.min((hx, hy))
dt = courant * dx / (r + 1)
alpha = courant * dx / dt
alpha = 1.0

T = 1
niter = int(T / dt)

# plotting
plot_freq = int(niter / 10)

# %%
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
vander_start = time.perf_counter()
vander = Vander(nx, ny, dim, r, n_qp, pts2d_x, pts2d_y, pts, wts2d, backend=backend)
vander_end = time.perf_counter()

neq, u0_nodal = set_initial_conditions(x_c, y_c, a, b, c, d, dim, vander, ic_type)

# plot_solution(u0_nodal, x_c, y_c, r+1, nx, ny, neq, hx, hy, "contour")
u0_nodal_gt = gt.storage.from_array(
    data=u0_nodal,backend=backend, default_origin=(0,0,0), shape=(nx,ny,1), dtype=(dtype, (dim,))
)

plotter = Plotter(x_c, y_c, r+1, nx, ny, neq, hx, hy, plot_freq)

if not perf_flag:
    plotter.plot_solution(u0_nodal_gt, fname="init")

u0_modal_gt = nodal2modal_gt(vander.inv_vander_gt, u0_nodal_gt)
u0_m = nodal2modal_gt(vander.inv_vander_gt, u0_nodal_gt)

mass, inv_mass = compute_mass(vander.phi_val_cell, wts2d, nx, ny, r, hx, hy, pts2d_y)

inv_mass_gt = gt.storage.from_array(inv_mass, backend=backend, default_origin=(0,0,0), shape=(nx,ny, 1), dtype=(dtype, (dim, dim)))

wts2d_gt = gt.storage.from_array(wts2d, backend=backend, default_origin=(0,0,0), shape=(nx,ny, 1), dtype=(dtype, (n_qp, )))

wts1d_gt = gt.storage.from_array(wts, backend=backend, default_origin=(0,0,0), shape=(nx,ny, 1), dtype=(dtype, (n_qp_1D, )))

tmp = np.sqrt(np.einsum('ijkl, ijkl', u0_m, np.einsum('ijklm,ijkm->ijkl', mass, u0_m)))

print(f'\n--- Backend = {backend} ---')
print(f'Domain: {nx = }; {ny = }\nTimesteping: {courant = } {dt = }; {niter = }')
print(f'Diffusion constanc: {alpha = }')
print(f'Order: space {r+1}; time {runge_kutta}')


run(u0_modal_gt, vander, inv_mass_gt, wts2d_gt, wts1d_gt, dim, n_qp_1D, n_qp, hx, hy, nx, ny, alpha, dt, niter, plotter, mass)

u_final_nodal = modal2nodal_gt(vander.phi_gt, u0_modal_gt)

if backend == "cuda":
    u_final_nodal.device_to_host()

u_final = np.asarray(u_final_nodal)

# Timinig
print(f'Vander: {vander_end - vander_start}s')

# Integrals
# print('--- Energy ---')
# initial_mass = np.sqrt(np.einsum('ijkl, ijkl', u0_m, np.einsum('ijklm,ijkm->ijkl', mass, u0_m)))
# final_mass = np.sqrt(np.einsum('ijkl, ijkl', u0_modal_gt, np.einsum('ijklm,ijkm->ijkl', mass, u0_modal_gt)))

print('--- Mass ---')
initial_mass = u0_m.sum()
final_mass = u0_modal_gt.sum()
print(f'{initial_mass = }; {final_mass = }')

# Error
print('--- Error ---')
l2_error = np.sqrt(np.einsum('ijkl, ijkl', (u0_m - u0_modal_gt), np.einsum('ijklm,ijkm->ijkl', mass, (u0_m - u0_modal_gt))))
print(f'L2 error: Absolute {l2_error}; Relative {l2_error / initial_mass}\n')

# Plot final time
# plotter.plot_solution(u_final_nodal, fname='final_timestep')
