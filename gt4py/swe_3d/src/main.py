# %%
import numpy as np
import time
import gt4py as gt
import quadpy as qp

from vander import Vander
from initial_conditions import set_initial_conditions
from modal_conversion import nodal2modal_gt, modal2nodal_gt, integration
from compute_mass import compute_mass
from run import run
from plotter import Plotter
from gt4py_config import backend, dtype, r, n_qp_1D, runge_kutta, nx, nz, perf_flag

# silence warning
np.warnings.filterwarnings('ignore', category=np.VisibleDeprecationWarning)

# %%
# domain
a = 0; b = 1e7; c = 0; d = 1e7

# number of elements in X and Y
nx = nx; ny = nx; nz = nz

hx = (b-a)/nx; hy = (d-c)/ny
dx = np.min((hx, hy))

# cardinality
dim=(r+1)**2

# Type of quadrature rule (Gauss-Legendre or Gauss-Legendre-Lobatto)
quad_type="leg"

# Number of quadrature points
n_qp=n_qp_1D*n_qp_1D


# timestep
courant = 0.001

dt = courant * dx / (r + 1)
alpha = courant * dx / dt

day_in_sec = 3600 * 24
T = 1 * day_in_sec
niter = int(T / dt)

# plotting
plot_freq = int(niter / 10)

plot_freq = 20
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
    print(quad_type,"unsupported quadrature rule, using Legendre")

pts2d_x = np.kron(pts,np.ones(n_qp_1D))
pts2d_y = np.kron(np.ones(n_qp_1D),pts)
wts2d   = np.kron(wts,wts)

half_cell_x = (b-a)/(2*nx)
half_cell_y = (d-c)/(2*ny)
x_c=np.linspace(a+half_cell_x,b-half_cell_x,nx); # Cell centers in X
y_c=np.linspace(c+half_cell_y,d-half_cell_y,ny); # Cell centers in Y

# all matrices are the same size but lower orders are padded!
vander_start = time.perf_counter()
vander = Vander(nx, ny, nz, dim, r, n_qp, pts2d_x, pts2d_y, pts, wts2d, backend=backend)
vander_end = time.perf_counter()

# --- Set initial conditions ---
neq, u0_nodal = set_initial_conditions(x_c, y_c, a, b, c, d, dim, vander)
h0, u0, v0 = u0_nodal
# identical systems in z component
if nz > 1:
    h0 = np.repeat(h0, nz, axis=2)
    u0 = np.repeat(u0, nz, axis=2)
    v0 = np.repeat(v0, nz, axis=2)

h0_nodal_gt = gt.storage.from_array(data=h0,
    backend=backend, default_origin=(0,0,0), shape=(nx,ny,nz), dtype=(dtype, (dim,)))
hu0_nodal_gt = gt.storage.from_array(data=u0*h0,
    backend=backend, default_origin=(0,0,0), shape=(nx,ny,nz), dtype=(dtype, (dim,)))
hv0_nodal_gt = gt.storage.from_array(data=v0*h0,
    backend=backend, default_origin=(0,0,0), shape=(nx,ny,nz), dtype=(dtype, (dim,)))

plotter = Plotter(x_c, y_c, r+1, nx, ny, neq, hx, hy, plot_freq)
if not perf_flag:
    plotter.plot_solution(h0_nodal_gt, fname='init')

h0_ref = nodal2modal_gt(vander.inv_vander_gt, h0_nodal_gt)
h0_modal_gt = nodal2modal_gt(vander.inv_vander_gt, h0_nodal_gt)
hu0_modal_gt = nodal2modal_gt(vander.inv_vander_gt, hu0_nodal_gt)
hv0_modal_gt = nodal2modal_gt(vander.inv_vander_gt, hv0_nodal_gt)
# --- End ---

mass, inv_mass = compute_mass(vander.phi_val_cell, wts2d, nx, ny, r, hx, hy, pts2d_y)

if nz > 1:
    inv_mass = np.repeat(inv_mass, nz, axis=2)

inv_mass_gt = gt.storage.from_array(inv_mass, backend=backend, default_origin=(0,0,0), shape=(nx,ny,nz), dtype=(dtype, (dim, dim)))

wts2d_gt = gt.storage.from_array(wts2d, backend=backend, default_origin=(0,0,0), shape=(nx,ny,nz), dtype=(dtype, (n_qp,)))

wts1d_gt = gt.storage.from_array(wts, backend=backend, default_origin=(0,0,0), shape=(nx,ny,nz), dtype=(dtype, (n_qp_1D,)))

print(f'\n\n--- Backend = {backend} ---')
print(f'Domain: {nx = }; {ny = }; {nz = }\nTimesteping: {dt = }; {niter = }')
print(f'Order: space {r+1}; time {runge_kutta}')

run((h0_modal_gt, hu0_modal_gt, hv0_modal_gt), vander, inv_mass_gt, wts2d_gt, wts1d_gt, dim, n_qp_1D, n_qp, hx, hy, nx, ny, nz, alpha, dt, niter, plotter)

u_final_nodal = modal2nodal_gt(vander.vander_gt, h0_modal_gt)

if backend == "cuda":
    u_final_nodal.device_to_host()

u_final = np.asarray(u_final_nodal)

# Timinig
print(f'Vander: {vander_end - vander_start}s')

plotter.plot_solution(u_final_nodal, fname='final_timestep')
