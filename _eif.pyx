"""Extended Isolation Forest

This is the implementation of the Extended Isolation Forest algorithm for anomaly detection. This extension improves the consistency and reliability of the anomaly scores produced by the standard Isolation Forest algorithm, which can be found in Liu et al.

Our method allows for the slicing of the data to be done using hyperplanes with random slopes resulting in improved score maps. The consistency and reliability of the algorithm are improved significantly using this extension."""

# Cython wrapper for Extended Isolation Forest

# distutils: language = C++
# distutils: sources  = eif.cxx
# cython: language_level = 3

__author__ = 'Matias Carrasco Kind, Sahand Hariri & Seng Keat Yeoh'
import cython
import numpy as np
cimport numpy as np

cimport __eif

np.import_array()


cdef class _iForest:
    cdef int size_Xfit
    cdef int dim
    cdef __eif.iForest* thisptr

    def __cinit__ (self, int ntrees, int sample, int limit=0, int exlevel=0, int seed=-1):
        self.thisptr = new __eif.iForest (ntrees, sample, limit, exlevel, seed)

    def __dealloc__ (self):
        del self.thisptr

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def fit (self, np.ndarray[double, ndim=2] Xfit not None):
        if not Xfit.flags['C_CONTIGUOUS']:
            Xfit = Xfit.copy(order='C')
        self.size_Xfit = Xfit.shape[0]
        self.dim = Xfit.shape[1]
        self.thisptr.fit (<double*> np.PyArray_DATA(Xfit), self.size_Xfit, self.dim)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def predict (self, np.ndarray[double, ndim=2] Xpred=None):
        cdef np.ndarray[double, ndim=1, mode="c"] S
        if Xpred is None:
            S = np.empty(self.size_Xfit, dtype=np.float64, order='C')
            self.thisptr.predict (<double*> np.PyArray_DATA(S), NULL, 0)
        else:
            if not Xpred.flags['C_CONTIGUOUS']:
                Xpred = Xpred.copy(order='C')
            S = np.empty(Xpred.shape[0], dtype=np.float64, order='C')
            self.thisptr.predict (<double*> np.PyArray_DATA(S), <double*> np.PyArray_DATA(Xpred), Xpred.shape[0])
        return S

    def OutputTreeNodes (self, int tree_index):
        self.thisptr.OutputTreeNodes (tree_index)


# ******** Redefinition for backward compatiblity ********
cdef class iForest:
    cdef int size_X
    cdef int dim
    cdef __eif.iForest* thisptr

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def __cinit__ (self, np.ndarray[double, ndim=2] X not None, int ntrees, int sample_size, int limit=0, int ExtensionLevel=0, int seed=-1):
        self.thisptr = new __eif.iForest (ntrees, sample_size, limit, ExtensionLevel, seed)

        if not X.flags['C_CONTIGUOUS']:
            X = X.copy(order='C')
        self.size_X = X.shape[0]
        self.dim = X.shape[1]
        self.thisptr.fit (<double*> np.PyArray_DATA(X), self.size_X, self.dim)

    def __dealloc__ (self):
        del self.thisptr

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def compute_paths (self, np.ndarray[double, ndim=2] X_in=None):
        cdef np.ndarray[double, ndim=1, mode="c"] S
        if X_in is None:
            S = np.empty(self.size_X, dtype=np.float64, order='C')
            self.thisptr.predict (<double*> np.PyArray_DATA(S), NULL, 0)
        else:
            if not X_in.flags['C_CONTIGUOUS']:
                X_in = X_in.copy(order='C')
            S = np.empty(X_in.shape[0], dtype=np.float64, order='C')
            self.thisptr.predict (<double*> np.PyArray_DATA(S), <double*> np.PyArray_DATA(X_in), X_in.shape[0])
        return S

    def output_tree_nodes (self, int tree_index):
        self.thisptr.OutputTreeNodes (tree_index)
