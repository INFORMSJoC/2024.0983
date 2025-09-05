# Data used in PDHCG

## Public Benchmarks

Following datasets can be found at https://github.com/Lhongpei/QP_datasets.

### Maros–Mészáros Dataset

The Maros–Mészáros dataset, a standard benchmark for convex quadratic programming, comprises 134 problems. We set the algorithm's time limit to 600 seconds for this dataset due to its smaller size.

### QPLIB Dataset

The QPLIB dataset includes various quadratic programming problems, including those with quadratic and integer constraints. 

We filtered and relaxed some of these, collecting 34 problems for our tests. Given the larger size of this dataset compared to Maros–Mészáros, we set the algorithm's time limit to 3600 seconds.


## Generated Datasets

We provide generating scripts for 4 types of QP problems.


## Real World Large Instances

### LIBSVM

- Original Data can be found at https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/.

### SuiteSparse Matrix Collection

- Original Data can be found at http://sparse.tamu.edu/.