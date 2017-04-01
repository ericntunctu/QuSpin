

# cython template[basis_type,matrix_type,N_type], do not call from script
cdef int boson_op_func(npy_intp Ns, object[basis_type,ndim=1,mode="c"] basis,
                    str opstr,NP_INT32_t *indx,scalar_type J,
                    object[basis_type,ndim=1,mode="c"] row, matrix_type *ME,object[basis_type,ndim=1,mode="c"] op_pars):

    cdef npy_intp i
    cdef basis_type r,occ,b
    cdef int j,error
    cdef int N_indx = len(opstr)
    cdef scalar_type M_E
    cdef long double M_E_offdiag, M_E_diag # coefficient coming from bosonic creation operators
    cdef basis_type Nmax = op_pars[2]-1 # max number of particles allowed per site (equals m-1)
    cdef unsigned char[:] c_opstr = bytearray(opstr,"utf-8")
    cdef int L = op_pars[0]
    cdef object[basis_type,ndim=1,mode="c"] M = op_pars[1:]
    cdef bool spin_me = op_pars[L+2]
    cdef long double S = Nmax/2.0

    cdef char I = "I"
    cdef char n = "n"
    cdef char z = "z"
    cdef char p = "+"
    cdef char m = "-"

    error = 0
    for i in range(Ns): #loop over basis
        M_E_offdiag = 1.0
        M_E_diag = 1.0
        r = basis[i]
        
        for j in range(N_indx-1,-1,-1): #loop over the copstr
            b = M[indx[j]]
            occ = (r/b)%(Nmax+1)  #calculate occupation of site ind[j]
            
            # loop over site positions
            if c_opstr[j] == I:
                continue
            elif c_opstr[j] == z: # S^z = n - (m-1)/2 for 2S=2,3,4,... and m=2S+1
                M_E_diag *= occ-S 
            elif c_opstr[j] == n:
                M_E_diag *= occ # square root taken below
            elif c_opstr[j] == p: # (S-S^z)*(S+S^z+1) = (n_max-n)*(n+1)
                M_E_offdiag *= (occ+1 if occ<Nmax else 0.0)
                M_E_offdiag *= (Nmax-occ if spin_me else 1.0) 
                r   += (b if occ<Nmax else 0)
            elif c_opstr[j] == m:# (S+S^z)*(S-S^z+1) = n*(n_max-n+1)
                M_E_offdiag *= occ
                M_E_offdiag *= (Nmax-occ+1 if spin_me else 1.0)
                r   -= (b if occ>0 else 0)
            else:
                error = 1
                return error

            if M_E_offdiag == 0.0:
                r = basis[i]
                break

        M_E = J*sqrtl(M_E_offdiag)*M_E_diag

        if matrix_type is float or matrix_type is double or matrix_type is longdouble:
            if M_E.imag != 0.0:
                error = -1
                return error

            ME[i] = M_E.real
            row[i] = r
        else:
            ME[i] = M_E
            row[i] = r

    return error





# operator
def op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[basis_type,ndim=1] basis,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    return op_template[basis_type,matrix_type](boson_op_func,pars,Ns,basis,opstr,&indx[0],J,row,col,&ME[0])

def n_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
              str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
              _np.ndarray[basis_type,ndim=1] basis,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    return n_op_template[basis_type,matrix_type](boson_op_func,pars,Ns,basis,opstr,&indx[0],J,row,col,&ME[0])

def p_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int pblock = blocks["pblock"]

    return p_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,fliplr,pars,L,pblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def p_z_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int pblock = blocks["pblock"]
    cdef int zblock = blocks["zblock"]

    return p_z_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,fliplr,flip_all,pars,L,pblock,zblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def pz_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int pzblock = blocks["pzblock"]

    return pz_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,fliplr,flip_all,pars,L,pzblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])



def t_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int a = blocks["a"]

    return t_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,shift,pars,L,kblock,a,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])



def t_p_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[N_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int pblock = blocks["pblock"]
    cdef int a = blocks["a"]

    return t_p_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,shift,fliplr,pars,L,kblock,pblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def t_p_z_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[M_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int pblock = blocks["pblock"]
    cdef int zblock = blocks["zblock"]
    cdef int a = blocks["a"]

    return t_p_z_op_template[basis_type,matrix_type,N_type,M_type](boson_op_func,pars,shift,fliplr,flip_all,pars,L,kblock,pblock,zblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def t_pz_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[N_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int pzblock = blocks["pzblock"]
    cdef int a = blocks["a"]

    return t_pz_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,shift,fliplr,flip_all,pars,L,kblock,pzblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def t_z_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[N_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int zblock = blocks["zblock"]
    cdef int a = blocks["a"]

    return t_z_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,shift,flip_all,pars,L,kblock,zblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def t_zA_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[N_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int zAblock = blocks["zAblock"]
    cdef int a = blocks["a"]

    return t_zA_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,shift,flip_sublat_A,pars,L,kblock,zAblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def t_zB_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[N_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int zBblock = blocks["zBblock"]
    cdef int a = blocks["a"]

    return t_zB_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,shift,flip_sublat_B,pars,L,kblock,zBblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])


def t_zA_zB_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
                str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J, _np.ndarray[N_type,ndim=1] N,
                _np.ndarray[M_type,ndim=1] M, _np.ndarray[basis_type,ndim=1] basis, int L,_np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int kblock = blocks["kblock"]
    cdef int zAblock = blocks["zAblock"]
    cdef int zBblock = blocks["zBblock"]
    cdef int a = blocks["a"]

    return t_zA_zB_op_template[basis_type,matrix_type,N_type,M_type](boson_op_func,pars,shift,flip_sublat_A,flip_sublat_B,flip_all,pars,L,kblock,zAblock,zBblock,a,Ns,&N[0],&M[0],basis,opstr,&indx[0],J,row,col,&ME[0])

def z_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L, _np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int zblock = blocks["zblock"]
    return z_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,flip_all,pars,L,zblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])



def zA_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L, _np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int zAblock = blocks["zAblock"]
    return zA_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,flip_sublat_A,pars,L,zAblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])



def zB_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L, _np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int zBblock = blocks["zBblock"]
    return zB_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,flip_sublat_B,pars,L,zBblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])



def zA_zB_op(_np.ndarray[basis_type,ndim=1] row, _np.ndarray[basis_type,ndim=1] col, _np.ndarray[matrix_type,ndim=1] ME,
            str opstr, _np.ndarray[NP_INT32_t,ndim=1] indx, scalar_type J,
            _np.ndarray[N_type,ndim=1] N,_np.ndarray[basis_type,ndim=1] basis,int L, _np.ndarray[basis_type,ndim=1] pars,**blocks):
    cdef npy_intp Ns = basis.shape[0]
    cdef int zBblock = blocks["zBblock"]
    cdef int zAblock = blocks["zAblock"]
    return zA_zB_op_template[basis_type,matrix_type,N_type](boson_op_func,pars,flip_sublat_A,flip_sublat_B,flip_all,pars,L,zAblock,zBblock,Ns,&N[0],basis,opstr,&indx[0],J,row,col,&ME[0])


