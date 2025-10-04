using Pkg
Pkg.activate("./src/env")
include("../src/PDHCG.jl")
qp = PDHCG.generateProblem("randomqp")
log = PDHCG.pdhcgSolve(qp, gpu_flag=true, warm_up_flag=true, verbose_level=2, time_limit = 600.)