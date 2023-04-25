import numpy as np
from cli_parser import n, r, runge_kutta, backend, perf_flag

n_qp_1D = r+1
dim=(r+1)**2
n_qp = n_qp_1D**2
dtype = np.float64
# dtypes
dtype_modal2qp_matrix = (dtype, (n_qp, dim))
dtype_modal2bd_matrix = (dtype, (n_qp_1D, dim))

dtype_qp_vec = (dtype, (n_qp,))
dtype_bd_vec = (dtype, (n_qp_1D,))
dtype_modal_vec = (dtype, (dim,))

backend_opts = {
    "rebuild": False,
#    "verbose": True
}
