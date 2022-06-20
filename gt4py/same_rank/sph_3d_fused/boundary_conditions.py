def apply_pbc(u):
    # periodic boundary conditions
    u.data[1:-1,0] = u.data[1:-1,-2] # north
    u.data[1:-1,-1] = u.data[1:-1,1] # south
    u.data[-1,1:-1] = u.data[1,1:-1] # east
    u.data[0,1:-1] = u.data[-2,1:-1] # west
    # return u
