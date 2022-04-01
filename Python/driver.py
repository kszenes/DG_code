from dataclasses import dataclass
import numpy as np
import quadpy as qp
import math
import sys
import matplotlib
import matplotlib.cm as cm
import matplotlib.pyplot as plt

# Radius of the earth (for spherical geometry)
radius=6.37122e6;

# Equation type
#eq_type="linear";
eq_type="adv_sphere";
#eq_type="swe";

# number of elements in X and Y
d1=20; d2=20


# definition of the domain [a,b]x[c,d]
a=0; b=2*np.pi; c=-np.pi/2; d=np.pi/2;

# length of the 1D intervals
hx=(b-a)/d1; hy=(d-c)/d2;

# polynomial degree of DG
r_max=2

# cardinality
dim=(r_max+1)**2

# Type of quadrature rule (Gauss-Legendre or Gauss-Legendre-Lobatto)
quad_type="leg"

# Number of quadrature points in one dimension
n_qp_1D=4

# Number of quadrature points
n_qp=n_qp_1D*n_qp_1D

# Time interval, initial and final time
t=0
T=1000
#T=86400
#T=5*86400

# Order of the RK scheme (1,2,3,4)
RK=4

# Time step
# For "linadv":  dt=1/r_max^2*min(hx,hy)*0.1;
# For "adv_sphere" with earth radius
dt=100

# Plotting frequency (time steps)
plot_freq=1000

# Derived temporal loop parameters
Courant=dt/min(hx,hy)
N_it=math.ceil(T/dt)

# Coriolis function currently zero
coriolis_fun=lambda x,y: np.zeros(len(x));  # Needed only for swe_sphere

# beginning and end of the intervals
x_e=np.linspace(a,b,d1+1); 
y_e=np.linspace(c,d,d2+1);