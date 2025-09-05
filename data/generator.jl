using JuMP, GZip, SparseArrays, Random, Gurobi
using ArgParse
mutable struct QuadraticProgrammingProblem
    n::Int64
    m::Int64
    variable_lower_bound::Vector{Float64}
    variable_upper_bound::Vector{Float64}
    isfinite_variable_lower_bound::Vector{Bool}
    isfinite_variable_upper_bound::Vector{Bool}
    P::SparseMatrixCSC{Float64,Int64}
    q::Vector{Float64}
    c::Float64
    A_constraint::SparseMatrixCSC{Float64,Int64}
    constraint_matrix_t::SparseMatrixCSC{Float64,Int64}
    ru_constraint::Vector{Float64}
    num_equalities::Int64
end

function generate_randomQP_problem(n::Int, seed::Int=1, sparsity::Float64=1e-3, condition_num::Float64=1e2)
    Random.seed!(seed)
    m = Int(0.5 * n)
    # Generate problem data
    P = sprandn(n, 1000, sparsity)
    rowval = collect(1:n)
    colptr = collect(1:n+1)
    nzval = ones(n)
    P = P * P' + (1/condition_num) * SparseMatrixCSC(n, n, colptr, rowval, nzval)
    q = randn(n)
    A = sprand(m, n, sparsity)

    v = randn(n)   # Fictitious solution
    delta = rand(m)  # To get inequality
    ru = A * v + delta
    rl = -Inf * ones(m)
    lb = -Inf * ones(n)
    ub = Inf * ones(n)
    
    return QuadraticProgrammingProblem(
        size(A, 2),
        size(A, 1),
        lb,
        ub,
        Vector{Bool}(isfinite.(lb)),
        Vector{Bool}(isfinite.(ub)),
        P,
        q,
        0.0,
        -A,
        -A',
        -ru,
        0,
    )
end

function generate_lasso_problem(n::Int, seed::Int=1, sparsity::Float64=1e-2)
    # Set random seed
    Random.seed!(seed)

    # Initialize parameters
    m = Int(n * 0.5)
    Ad = sprandn(m, n, sparsity)
    x_true = (rand(n) .> 0.5) .* randn(n) ./ sqrt(n)
    bd = Ad * x_true + randn(m)
    lambda_max = norm(Ad' * bd, Inf)
    lambda_param = (1/5) * lambda_max

    # Construct the QP problem
    rowval_m = collect(1:m)
    colptr_m = collect(1:m+1)
    nzval_m = ones(m)
    P = blockdiag(spzeros(n, n), SparseMatrixCSC(m, m, colptr_m, rowval_m, nzval_m .* 2), spzeros(n, n))
    q = vcat(zeros(m + n), lambda_param * ones(n))
    rowval_n = collect(1:n)
    colptr_n = collect(1:n+1)
    nzval_n = ones(n)
    In = SparseMatrixCSC(n, n, colptr_n, rowval_n, nzval_n)
    Onm = spzeros(n, m)
    A = vcat(hcat(Ad, -SparseMatrixCSC(m, m, colptr_m, rowval_m, nzval_m), spzeros(m, n)),
             hcat(In, Onm, -In),
             hcat(-In, Onm, -In))
    rl = vcat(bd, -Inf * ones(n), -Inf * ones(n))
    ru = vcat(bd, zeros(n), zeros(n))
    lb = -Inf * ones(2*n+m)
    ub = Inf * ones(2*n+m)

    return QuadraticProgrammingProblem(
        size(A, 2),
        size(A, 1),
        lb,
        ub,
        Vector{Bool}(isfinite.(lb)),
        Vector{Bool}(isfinite.(ub)),
        P,
        q,
        0.0,
        -A,
        -A',
        -ru,
        m,
    )
end

function generate_svm_problem(n::Int, seed::Int=1, Sparsity::Float64=1e-2)

    Random.seed!(seed)

    n_features = n          
    m_data = Int(n_features*0.5)
    N_half = Int(m_data * 0.5)
    gamma_val = 1.0
    b_svm_val = vcat(ones(N_half), -ones(N_half))

    A_upp = sprandn(N_half, n_features, Sparsity)
    A_low = sprandn(N_half, n_features, Sparsity)
    A_svm_val = vcat(A_upp / sqrt(n_features) .+ (A_upp .!= 0) / n_features,
                     A_low / sqrt(n_features) .- (A_low .!= 0) / n_features)

    P = spdiagm(0 => vcat(ones(n_features), zeros(m_data)))
    q = vcat(zeros(n_features), (gamma_val) * ones(m_data))

    rowval1 = collect(1:length(b_svm_val))
    colptr1 = collect(1:length(b_svm_val)+1)
    rowval2 = collect(1:m_data)
    colptr2 = collect(1:m_data+1)
    nzval2 = ones(m_data)

    A = hcat(-SparseMatrixCSC(colptr1, rowval1, b_svm_val) * A_svm_val, SparseMatrixCSC(colptr2, rowval2, nzval2))
    ru = ones(m_data)

    lb = vcat(-Inf * ones(n_features), zeros(m_data))
    ub = vcat(Inf * ones(n_features), Inf * ones(m_data))

    println("norm_A")
    println(norm(A))
    return QuadraticProgrammingProblem(
        size(A, 2),
        size(A, 1),
        lb,
        ub,
        Vector{Bool}(isfinite.(lb)),
        Vector{Bool}(isfinite.(ub)),
        P,
        q,
        0.0,
        A,
        A',
        ru,
        0,
    )
end

function generate_portfolio_problem(n::Int, seed::Int=1, sparsity::Float64=1e-4)
    Random.seed!(seed)
    
    n_assets = n 
    k = Int(n*1)
    F = sprandn(n_assets, k, sparsity)
    D = spdiagm(0 => rand(n_assets) .* sqrt(k))
    mu = randn(n_assets)
    gamma = 1.0

    # Generate QP problem
    rowval1 = collect(1:n_assets)
    colptr1 = collect(1:n_assets + 1)
    nzval1 = rand(n_assets) .* sqrt(k) .* 2

    rowval2 = collect(n_assets + 1:k + n_assets)
    colptr2 = collect(n_assets + 2:k + n_assets + 1)
    nzval2 = ones(k) .* 2

    rowval = vcat(rowval1, rowval2)
    colptr = vcat(colptr1, colptr2)
    nzval = vcat(nzval1, nzval2)

    rand(n_assets) .* sqrt(k)

    rowval_k = collect(1:k)
    colptr_k = collect(1:k + 1)
    nzval_k = ones(k)

    P = SparseMatrixCSC(n_assets + k, n_assets + k, colptr, rowval, nzval)
    q = vcat(-mu ./ gamma, zeros(k))
    A = vcat(
        hcat(sparse(ones(1, n_assets)), spzeros(1, k)),
        hcat(F', -SparseMatrixCSC(k, k, colptr_k, rowval_k, nzval_k)),
    )
    ru = vcat(1.0, zeros(k))

    lb = vcat(zeros(n_assets), -Inf * ones(k))
    ub = vcat(ones(n_assets), Inf * ones(k))

    return QuadraticProgrammingProblem(
        size(A, 2),
        size(A, 1),
        lb,
        ub,
        Vector{Bool}(isfinite.(lb)),
        Vector{Bool}(isfinite.(ub)),
        P,
        q,
        0.0,
        -A,
        -A',
        -ru,
        k+1,
    )
end


function save_qp_to_mps_gz(qp::QuadraticProgrammingProblem, filename::String)

    model = Model()

    n = qp.n
    @variable(model, x[1:n])
    
    for i in 1:n
        if qp.isfinite_variable_lower_bound[i]
            set_lower_bound(x[i], qp.variable_lower_bound[i])
        end
        if qp.isfinite_variable_upper_bound[i]
            set_upper_bound(x[i], qp.variable_upper_bound[i])
        end
    end

    m = qp.m
    A = qp.A_constraint
    rhs = qp.ru_constraint
    
    for i in 1:m
        expr = @expression(model, sum(A[i, j] * x[j] for j in 1:n))
        if i <= qp.num_equalities
            @constraint(model, expr == rhs[i])
        else
            @constraint(model, expr <= rhs[i])
        end
    end

    P = qp.P
    q_vec = qp.q
    c = qp.c
    @objective(model, Min, 1/2 * x' * P * x + q_vec' * x + c)

    mps_filename = tempname() * ".mps"
    write_to_file(model, mps_filename)

    gz_filename = endswith(filename, ".gz") ? filename : filename * ".gz"
    open(mps_filename) do input
        GZip.open(gz_filename, "w") do output
            write(output, read(input))
        end
    end

    rm(mps_filename)
    println("Problem saved to ", gz_filename)
end


function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--problem", "-p"
            help = "problem type: random, lasso, svm, portfolio"
            required = true
        "--n"
            help = "problem dimension (n)"
            arg_type = Int
            default = 1000
        "--seed"
            help = "random seed"
            arg_type = Int
            default = 1
        "--sparsity"
            help = "sparsity for random/lasso/svm/portfolio"
            arg_type = Float64
            default = 1e-3
        "--condition"
            help = "condition number for random QP"
            arg_type = Float64
            default = 1e2
        "-o", "--output"
            help = "output .mps.gz file"
            required = true
    end
    parse_args(s)
end

function main()
    args = parse_commandline()
    n    = args["n"]
    seed = args["seed"]
    sp   = args["sparsity"]
    cond = args["condition"]
    qp   = let
        if args["problem"] == "random"
            generate_randomQP_problem(n, seed, sp, cond)
        elseif args["problem"] == "lasso"
            generate_lasso_problem(n, seed, sp)
        elseif args["problem"] == "svm"
            generate_svm_problem(n, seed, sp)
        elseif args["problem"] == "portfolio"
            generate_portfolio_problem(n, seed, sp)
        else
            error("unknown problem type")
        end
    end
    save_qp_to_mps_gz(qp, args["output"])
    println("✅  Problem saved to $(args["output"])")
end

main()