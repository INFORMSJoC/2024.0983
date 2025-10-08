using JuMP, GZip, SparseArrays, Random, Gurobi
using XLSX
using DelimitedFiles
using MatrixMarket

function analyze_matrix(A)

    m, n = size(A)
    total_elements = m * n

    if isa(A, SparseMatrixCSC)

        nonzero_count = nnz(A)  
    else
        nonzero_count = count(!iszero, A)
    end

    sparsity = nonzero_count / total_elements

    return nonzero_count, sparsity
end

function read_libsvm_file_txt(filename)
    lines = readlines(filename)

    nobs = length(lines)  
    nfeats = 0            

    y = zeros(Float64, nobs)  
    vals = [Float64[] for _ in 1:nobs]  
    feats = [Int[] for _ in 1:nobs]     

    for i in eachindex(lines)
        line = lines[i]
        line_split = split(line, " ")  
        
        y[i] = parse(Float64, line_split[1])  

        n = length(line_split) - 1
        lfeats = zeros(Int, n)
        lvals = zeros(Float64, n)
        
        for j in 1:n
            ls = split(line_split[j+1], ":")
            feat_index = parse(Int, ls[1])
            feat_value = parse(Float64, ls[2])

            lfeats[j] = feat_index
            lvals[j] = feat_value

            if feat_index > nfeats
                nfeats = feat_index
            end
        end
        
        feats[i] = lfeats
        vals[i] = lvals
    end

    row_indices = []
    col_indices = []
    data_values = []

    for i in 1:nobs
        for j in 1:length(feats[i])
            push!(row_indices, i)
            push!(col_indices, feats[i][j])
            push!(data_values, vals[i][j])
        end
    end

    x = sparse(row_indices, col_indices, data_values, nobs, nfeats)

    return (x, y) 
end


function generate_lasso_real_problem(problem_name::String)

    # Matrix = MatrixMarket.mmread("file.mtx")

    # bd = Matrix[:,end]
    # Ad = Matrix[:,1:end-1]
    # m,n = size(Ad)

    x,y = read_libsvm_file_txt(problem_name) 
    x_float = SparseMatrixCSC{Float64, Int64}(x)
    Ad = x_float
    bd = vec(y)
    m,n = size(Ad)

    nonzero_A,sparse_A = analyze_matrix(x)
    println("nonzeros_A ",nonzero_A)
    println("sparsity_A ",sparse_A)

    lambda_max = norm(Ad' * bd, Inf)
    lambda_param = 1e-2 * lambda_max

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

function main()
    args = parse_commandline()
    file_path = args["file_path"]
    output_path = args["output_path"]
    qp = generate_lasso_real_problem(file_path)
    save_qp_to_mps_gz(qp, output_path)
end

main()
