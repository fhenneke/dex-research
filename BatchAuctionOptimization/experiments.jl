# %% some experiments using JuMP

using JuMP
using Ipopt, SCIP, Clp, Cbc, Gurobi

function setup_nlp!(m, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_old, delta, gamma, v_init, p_init)
    @variable(m, v[i=1:N] >= 0, start = v_init[i])
    @variable(m, 1 / (1 + delta) * p_old[i] <= p[i=1:n] <= (1 + delta) * p_old[i], start = p_init[i])

    @objective(m, Max, sum(v))

    for j in 1:n
        @constraint(m, sum(v[i] for i in find_t_b[j]) == sum(v[i] for i in find_t_s[j]))
    end

    for i in 1:N
        @NLconstraint(m, v[i] * p[t_b[i]] <= v[i] * p[t_s[i]] * p_bar[i])
        @constraint(m, v[i] <= p[t_b[i]] * x_bar[i])
        @constraint(m, v[i] <= p[t_s[i]] * y_bar[i])
    end

    @constraint(m, sum(p[i] * gamma[i] for i in 1:n) == 1)

    return m
end

function setup_lp!(m, n, N, t_b, t_s, x_bar, y_bar, p_bar, gamma, v_init, p_init)
    @variable(m, v[i=1:N] >= 0, start = v_init[i])

    @objective(m, Max, sum(v))

    for j in 1:n
        @constraint(m, sum(v[i] for i in find_t_b[j]) == sum(v[i] for i in find_t_s[j]))
    end

    for i in 1:N
        @constraint(m, v[i] * p_init[t_b[i]] <= v[i] * p_init[t_s[i]] * p_bar[i])
        @constraint(m, v[i] <= p_init[t_b[i]] * x_bar[i])
        @constraint(m, v[i] <= p_init[t_s[i]] * y_bar[i])
    end

    return m
end

function setup_lp_iter!(m, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_min, p_max, gamma, v_init, p_init)
    find_t_b = [find(t_b .== j) for j in 1:n]
    find_t_s = [find(t_s .== j) for j in 1:n]

    @variable(m, v[i=1:N] >= 0, start = v_init[i])
    @variable(m, p_min[j] <= p[j=1:n] <= p_max[j], start = p_init[j])

    @objective(m, Max, sum(v))

    for j in 1:n
        @constraint(m, sum(v[i] for i in find_t_b[j]) == sum(v[i] for i in find_t_s[j]))
    end

    for i in 1:N
        @constraint(m, p[t_b[i]] <= p[t_s[i]] * p_bar[i])
        @constraint(m, v[i] <= p[t_b[i]] * x_bar[i])
        @constraint(m, v[i] <= p[t_s[i]] * y_bar[i])
    end

    return m
end

function setup_mip!(m, n, N, t_b, t_s, x_bar, y_bar, p_bar, P_old, P_max, P_min, gamma, v_init, P_init, z_init)
    @variable(m, v[i=1:N] >= 0, start = v_init[i])
    @variable(m, z[i=1:N], category=:Bin, start = z_init[i])
    @variable(m, P_min[i] <= P[i=1:n] <= P_max[i], start = P_init[i])
    @variable(m, p_b[i=1:N, k=0:1] >= 0, start = k == z_init[i] ? P_init[t_b[i]] : 0)
    @variable(m, p_s[i=1:N, k=0:1] >= 0, start = k == z_init[i] ? P_init[t_s[i]] : 0)

    @objective(m, Max, sum(v))

    for j in 1:n
        @constraint(m, sum(v[i] for i in find_t_b[j]) == sum(v[i] for i in find_t_s[j]))
    end

    for i in 1:N
        @constraint(m, P_min[t_b[i]] * (1 - z[i]) <= p_b[i, 0])
        @constraint(m, p_b[i, 0] <= P_max[t_b[i]] * (1 - z[i]))
        @constraint(m, P_min[t_s[i]] * (1 - z[i]) <= p_s[i, 0])
        @constraint(m, p_s[i, 0] <= P_max[t_s[i]] * (1 - z[i]))

        @constraint(m, P_min[t_b[i]] * z[i] <= p_b[i, 1])
        @constraint(m, p_b[i, 1] <= P_max[t_b[i]] * z[i])
        @constraint(m, P_min[t_s[i]] * z[i] <= p_s[i, 1])
        @constraint(m, p_s[i, 1] <= P_max[t_s[i]] * z[i])

        @constraint(m, P[t_b[i]] == p_b[i, 0] + p_b[i, 1])
        @constraint(m, P[t_s[i]] == p_s[i, 0] + p_s[i, 1])

        @constraint(m, v[i] <= p_b[i, 1] * x_bar[i])
        @constraint(m, v[i] <= p_s[i, 1] * y_bar[i])

        @constraint(m, p_b[i, 0] >= p_bar[i] * p_s[i, 0])
        @constraint(m, p_b[i, 1] <= p_bar[i] * p_s[i, 1])
    end

    @constraint(m, sum(P[i] * gamma[i] for i in 1:n) == 1)

    return m
end

function setup_mip2!(m, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_min, p_max, gamma, v_init, p_init, z_init)
    @variable(m, v[i=1:N] >= 0, start = v_init[i])
    @variable(m, z[i=1:N], category=:Bin, start = z_init[i])
    @variable(m, p_min[i] <= p[i=1:n] <= p_max[i], start = p_init[i])

    @objective(m, Max, sum(v))

    for j in 1:n
        @constraint(m, sum(v[i] for i in find_t_b[j]) == sum(v[i] for i in find_t_s[j]))
    end

    for i in 1:N
        @constraint(m, v[i] <= p_max[t_b[i]] * x_bar[i] * z[i])
        @constraint(m, v[i] <= p_max[t_s[i]] * y_bar[i] * z[i])

        @constraint(m, v[i] <= p[t_b[i]] * x_bar[i])
        @constraint(m, v[i] <= p[t_s[i]] * y_bar[i])

        @constraint(m, p[t_b[i]] <= p_bar[i] * p[t_s[i]] + p_max[t_b[i]] * (1 - z[i]))
    end

    @constraint(m, sum(p[i] * gamma[i] for i in 1:n) == 1)

    return m
end

# %% example 1 from p. 7 of the manuscript
# data
# TODO: start from orders and not from the final data representation
n = 2
N = 2

t_b = [1, 2]
t_s = [2, 1]

find_t_b = [find(x -> x == i, t_b) for i in 1:n]
find_t_s = [find(x -> x == i, t_s) for i in 1:n]

x_bar = [1.0, 1.5]
y_bar = [100, 100] # Inf not supported atm

p_bar = [2.0, 1.0] # the name p_bar is used instead of pi
p_old = [1.0, 1.0]
delta = 1.0

gamma = [0.5, 0.5]

# JuMP model
m = Model(solver = IpoptSolver(print_level=0))
# m = Model(solver = SCIPSolver())
setup_nlp!(m, n, N, t_b, t_s, x_bar, y_bar, p_bar,p_old, delta, gamma, ones(N), ones(n))

# solve
@time status = solve(m);

println("p = ", getvalue(m[:p]))
println("v = ", getvalue(m[:v]))

# %% set up MIP

# data
n = 3
N = 3

# instead of the matrices
#
# T_b = [1 0 0;
#        0 1 0;
#        0 0 1]
#
# T_s = [0 1 0;
#        0 0 1;
#        1 0 0]
#
# the following index vectors are used, giving the index of the columns for the
# entry 1 for the different rows of T_b and T_s
t_b = [1, 2, 3]
t_s = [2, 3, 1]

find_t_b = [find(x -> x == i, t_b) for i in 1:n]
find_t_s = [find(x -> x == i, t_s) for i in 1:n]

x_bar = [1, 1, 1]
y_bar = [1, 1, 1]

p_bar = [1.0, 1.0, 1.0] # the name p_bar is used instead of pi
P_old = [1.0, 1.0, 1.0]
delta = 1.0
P_max = (1 + delta) * P_old
P_min = 1 / (1 + delta) * P_old

epsilon = 1e-5

gamma = 1 / n * ones(n)

v_init = zeros(N)
P_init = P_old
z_init = P_init[t_b] ./ P_init[t_s] .<= p_bar

# model
# m_mip = Model(solver = CbcSolver())
m_mip = Model(solver = SCIPSolver())

setup_mip!(m_mip, n, N, t_b, t_s, x_bar, y_bar, p_bar, P_old, P_max, P_min, gamma, v_init, P_init, z_init)

status = solve(m_mip)


# %% example 2: ring trade
# data
# TODO: also use function syntax?
n = 3
N = 3

# instead of the matrices
#
# T_b = [1 0 0;
#        0 1 0;
#        0 0 1]
#
# T_s = [0 1 0;
#        0 0 1;
#        1 0 0]
#
# the following index vectors are used, giving the index of the columns for the
# entry 1 for the different rows of T_b and T_s
t_b = [1, 2, 3]
t_s = [2, 3, 1]

find_t_b = [find(x -> x == i, t_b) for i in 1:n]
find_t_s = [find(x -> x == i, t_s) for i in 1:n]

x_bar = [1, 1, 1]
# y_bar = [Inf, Inf, Inf] # not supported atm

p_bar = [1.0, 1.0, 1.0] # the name p_bar is used instead of pi

gamma = 1 / n * ones(n)

# JuMP model
m = Model(solver = IpoptSolver(print_level=0))
# m = Model(solver = SCIPSolver())
@variable(m, v[1:N] >= 0, start = 0.5)
@variable(m, x[1:N] >= 0, start = 0.5)
@variable(m, y[1:N] >= 0, start = 0.5)
@variable(m, p[1:n] >= 0, start = 1.0)

@objective(m, Max, sum(v))

for j in 1:n
    @constraint(m, sum(x[i] for i in find_t_b[j]) == sum(y[i] for i in find_t_s[j]))
end

for i in 1:N
    @NLconstraint(m, v[i] == x[i] * p[t_b[i]])
    @NLconstraint(m, v[i] == y[i] * p[t_s[i]])
end

@constraint(m, x .<= x_bar)
# @constraint(m, y .<= y_bar) # does not work like this

@constraint(m, y .<= x .* p_bar)

@constraint(m, sum(p[i] * gamma[i] for i in 1:n) == 1)

# solve
@time status = solve(m)

println("x = ", getvalue(x))
println("y = ", getvalue(y))
println("p = ", getvalue(p))
println("v = ", getvalue(v))


# %% example 3, more orders
# data
# TODO: start from orders and not from the final data representation
Base.Random.srand(42) # set random seed for reproducibility

n = 20
N = 100

t_b = Int[]
t_s = Int[]
counter = 0
while counter < N
    r = rand(1:n, 2)
    if r[1] != r[2]
        push!(t_b, r[1])
        push!(t_s, r[2])
        counter += 1
    end
end

find_t_b = [find(x -> x == i, t_b) for i in 1:n]
find_t_s = [find(x -> x == i, t_s) for i in 1:n]

x_bar = 0.4 + rand(N)
y_bar = 0.5 + rand(N)
# y_bar = [Inf, Inf, Inf] # not supported atm

delta = 0.5
p_old = rand(n)
p_max = (1 + delta) * p_old
p_min = 1 / (1 + delta) * p_old
p_bar = [p_old[t_b[i]] / p_old[t_s[i]] * (0.9 + rand() - 0.5) for i in 1:N] # the name p_bar is used instead of pi

gamma = 1 / n ./ p_old;

# %% iterative LP formulation
p_init = p_old
v_init = zeros(N)

trade_possible = p_init[t_b] .<= p_bar .* p_init[t_s]

K = 20
for k in 1:K
    println("k = ", k)
    # @assert all(trade_possible .<= (p_init[t_b] .<= p_bar .* p_init[t_s] + 1e-10))
    if trade_possible == (p_init[t_b] .<= p_bar .* p_init[t_s] + 1e-15)
        trade_possible = p_init[t_b] .<= p_bar .* p_init[t_s] - 1e-15
    else
        trade_possible = p_init[t_b] .<= p_bar .* p_init[t_s] + 1e-15
    end

    println("number of feasible trades: ", sum(trade_possible))

    # m_iter = Model(solver = IpoptSolver(print_level=0))
    # potentially choose a different/more efficient linear solver here
    # m_iter = Model(solver = ClpSolver())
    # m_iter = Model(solver = CbcSolver())
    m_iter = Model(solver = SCIPSolver("display/verblevel", 0))
    setup_lp_iter!(m_iter, n, sum(trade_possible), t_b[trade_possible], t_s[trade_possible], x_bar[trade_possible], y_bar[trade_possible], p_bar[trade_possible], p_min, p_max, gamma, v_init[trade_possible], p_init)
    status_iter = solve(m_iter)

    p_init = getvalue(m_iter[:p])
    # v_init = zeros(N)
    # v_init[trade_possible] .= getvalue(m_iter[:v])

    println("total trading volume: ", sum(getvalue(m_iter[:v])), "\n")
end


getvalue(m_iter[:p])[t_b] .<= p_bar .* getvalue(m_iter[:p])[t_s]
getvalue(m_mip[:P])[t_b] .<= p_bar .* getvalue(m_mip[:P])[t_s]

getvalue(m_iter[:p]) ./ p_old
p_init = getvalue(m_mip[:P]) ./ p_old


# getvalue(m_iter[:p]) ./ p_old
# p_init ./ p_old


# %% MIP formulations
epsilon = 1e-5

v_init = zeros(N)
p_init = p_old
z_init = p_init[t_b] ./ p_init[t_s] .<= p_bar

m_mip = Model(solver = GurobiSolver(Threads=1))

setup_mip!(m_mip, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_old, p_max, p_min, gamma, v_init, p_init, z_init, epsilon)

# JuMP.build(m_mip)
# grb = JuMP.internalmodel(m_mip).inner  # get the Gurobi.Model object
# Gurobi.tune_model(grb)

@time status = solve(m_mip)

sum(getvalue(m_mip[:v]))

m_mip2 = Model(solver = GurobiSolver())

m_mip2 = setup_mip2!(m_mip2, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_min, p_max, gamma, v_init, p_init, z_init)

@time status = solve(m_mip2)

m_mip2 = Model(solver = SCIPSolver())
# m_mip = Model(solver = CbcSolver())

m_mip2 = setup_mip2!(m_mip2, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_min, p_max, gamma, v_init, p_init, z_init)

@time status = solve(m_mip2)
sum(getvalue(m_mip2[:v]))
# find(.!(trade_possible .<= (p_init[t_b] .<= p_bar .* p_init[t_s])))
#
# getvalue(m_mip[:P]) ./ p_old

v_init = getvalue(m_mip[:v])
p_init = getvalue(m_mip[:P])

# %% two stage formulation
v_init = zeros(N)
p_init = p_old

K = 2
@time for k in 1:K
    println("k = ", k)

    m_l = Model(solver = IpoptSolver(print_level=0))
    # potentially choose a different/more efficient linear solver here
    # m_l = Model(solver = ClpSolver())
    # m_l = Model(solver = CbcSolver())
    # m_l = Model(solver = SCIPSolver("display/verblevel", 0))
    setup_lp!(m_l, n, N, t_b, t_s, x_bar, y_bar, p_bar, gamma, zeros(N), p_init)
    status_l = solve(m_l)
    v_init = getvalue(m_l[:v])

    println("volume after linear problem: ", sum(v_init))

    m_nl = Model(solver = IpoptSolver(print_level=0))
    setup_nlp!(m_nl, n, N, t_b, t_s, x_bar, y_bar, p_bar, p_old, delta, gamma, v_init, p_init)
    status_nl = solve(m_nl)
    v_init = getvalue(m_nl[:v])
    p_init = getvalue(m_nl[:p])

    println("volume after nonlin problem: ", sum(v_init))
end

# %% post-processing
# first post-processing step is to solve the linear problem again

m_post = Model(solver = ClpSolver())
# m_l = Model(solver = CbcSolver())
# m_l = Model(solver = SCIPSolver("display/verblevel", 0))
setup_lp!(m_post, n, N, t_b, t_s, x_bar, y_bar, p_bar, gamma, zeros(N), p_init)
status_post = solve(m_post)
v_post = getvalue(m_post[:v])

# then go through v to change as desired
trade_possible = p_init[t_b] ./ p_init[t_s] .<= p_bar

@assert N - sum(trade_possible .| (v_post .<= 1e-10)) == 0
N - sum(xor.(trade_possible, v_post .<= 1e-10))

# no_trade_but_possible = .!xor.(trade_possible, v_init .<= 1e-10)

v_post = copy(v_init)
# this strategy might be a bit strict. might be playable by proposing very large p_bar
for i in find(trade_possible)
    for ip in find_t_b[t_b[i]]
        if t_s[ip] == t_s[i]
            if p_bar[i] > p_bar[ip] && v_post[ip] > 0. && v_post[i] < p_init[t_b[i]] * x_bar[i] - 1e-5 && v_post[i] < p_init[t_s[i]] * y_bar[i] - 1e-5
                println("bad trade at i: ", i, ", ip: ", ip, "!")
                println("p_bar[i]: ", p_bar[i], ", p_bar[ip]: ", p_bar[ip])
                println("v[i]: ", v_post[i], ", v[ip]: ", v_post[ip])
                println("x[i]: ", v_post[i] / p_init[t_b[i]], ", x_bar[i]: ", x_bar[i])
                println("y[i]: ", v_post[i] / p_init[t_s[i]], ", y_bar[i]: ", y_bar[i])
                maximum_transfer = min(p_init[t_b[i]] * x_bar[i] - v_post[i],
                                       p_init[t_s[i]] * y_bar[i] - v_post[i],
                                       v_post[ip])

                v_post[i]  += maximum_transfer
                v_post[ip] -= maximum_transfer
                println("transfered ", maximum_transfer)
                println("new volumes: v[i] = ", v_post[i], ", v[ip] = ", v_post[ip])
            end
        end
    end
end
println("total trading volume: ", sum(v_post))

# %% visualization
using Plots, LightGraphs, GraphPlot

g = DiGraph(n)
for i = 1:N
    if v_post[i] >= 1e-3 # some cutoff for plotting purposes
        add_edge!(g, t_s[i], t_b[i])
    end
end

A = zeros(n, n)
for i=1:N
    A[t_s[i],t_b[i]] += v_post[i]
end

p1 = gplot(g, nodelabel=1:n, nodesize=vec(sum(A, 2)) + vec(sum(A, 1)), layout=circular_layout)
p1
