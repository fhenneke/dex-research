# %% some experiments using JuMP

using JuMP
using Ipopt, SCIP

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
# y_bar = [Inf, Inf, Inf] # not supported atm

p_bar = [2.0, 1.0] # the name p_bar is used instead of pi

gamma = [0.5, 0.5]

# JuMP model
# m = Model(solver = IpoptSolver())
m = Model(solver = SCIPSolver())
@variable(m, v[1:N] >= 0, start = 1.0)
@variable(m, x[1:N] >= 0, start = 1.0)
@variable(m, y[1:N] >= 0, start = 1.0)
@variable(m, p[1:n] >= 0, start = 1.0)

@objective(m, Max, sum(v))

@constraint(m, sum(x[i] for i in find_t_b[1]) == sum(y[i] for i in find_t_s[1]))
@constraint(m, sum(x[i] for i in find_t_b[2]) == sum(y[i] for i in find_t_s[2]))

for i in 1:N
    @NLconstraint(m, v[i] == x[i] * p[t_b[i]])
    @NLconstraint(m, v[i] == y[i] * p[t_s[i]])
end

@constraint(m, x .<= x_bar)
# @constraint(m, y .<= y_bar) # does not work like this

@constraint(m, y .<= x .* p_bar)

@constraint(m, sum(p[i] * gamma[i] for i in 1:n) == 1)

# solve
@time status = solve(m);

println("x = ", getvalue(x))
println("y = ", getvalue(y))
println("p = ", getvalue(p))
println("v = ", getvalue(v))

# %% example 2: ring trade
# data
# TODO: start from orders and not from the final data representation
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
m = Model(solver = IpoptSolver())
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
n = 40
N = 500

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

# x_bar = ones(N)
# y_bar = ones(N)
x_bar = 0.1 + rand(N)
y_bar = 0.3 + rand(N)
# y_bar = [Inf, Inf, Inf] # not supported atm

# p_bar = ones(N)
p_bar = 0.1 + rand(N) # the name p_bar is used instead of pi

gamma = 1 / n * ones(n);

# %% JuMP model
m = Model(solver = IpoptSolver())
# m = Model(solver = SCIPSolver())
@variable(m, v[1:N] >= 0, start = 0.0)
@variable(m, p[1:n] >= 0, start = 1.0)

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

# solve
@time status = solve(m)

println("p = ", getvalue(p))
println("v = ", getvalue(v))
sum(getvalue(v))

# %% visualization
using Plots, LightGraphs, GraphPlot

g = DiGraph(n)
for i = 1:N
    if getvalue(v)[i] >= 1e-3 # some cutoff for plotting purposes
        add_edge!(g, t_s[i], t_b[i])
    end
end

A = zeros(n, n)
for i=1:N
    A[t_s[i],t_b[i]] += getvalue(v)[i]
end

p1 = gplot(g, nodelabel=1:n, nodesize=vec(sum(A, 2)) + vec(sum(A, 1)), layout=circular_layout);
p1
