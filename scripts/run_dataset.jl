using Pkg
Pkg.activate("./src/env")
include("../src/PDHCG.jl")
using DataFrames
using CSV
dataset_dir = "DATASET_PATH"  # Replace with the actual path to your dataset directory
result_df = DataFrame(
    dataset = String[],
    time_cost_sec = Float64[],
    objective_value = Float64[],
    outer_iteration_count = Int[],
    inner_iteration_count = Int[]
)
warm_up_flag = true
for file in readdir(dataset_dir)
    global warm_up_flag
    if endswith(file, ".QPS") || endswith(file, ".mps") || endswith(file, ".mps.gz")
        qp = PDHCG.readFile(joinpath(dataset_dir, file))
        log = PDHCG.pdhcgSolve(qp, gpu_flag=true, warm_up_flag=warm_up_flag, verbose_level=2, time_limit = 600.)
        time_cost = log.solve_time_sec
        obj = log.objective_value
        outer_iter = log.iteration_count
        inner_iter = log.CG_total_iteration
        push!(result_df, (file, time_cost, obj, outer_iter, inner_iter))
        CSV.write("results.csv", result_df, append=false)
        println("Processed file: $file, Time: $time_cost sec, Objective: $obj, Outer Iterations: $outer_iter, Inner Iterations: $inner_iter")
        warm_up_flag = false
    end

end