# %% some experiments using JuMP

using JuMP
using Ipopt

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
m = Model(solver = IpoptSolver())
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
solve(m);

println("x = ", getvalue(x))
println("y = ", getvalue(y))
println("p = ", getvalue(p))
println("v = ", getvalue(v))
getvalue(p)[1]

# %% example 2
# data
# TODO: start from orders and not from the final data representation
n = 2
N = 3

# instead of the matrices
#
# T_b = [1 0;
#        0 1;
#        0 1]
#
# T_s = [0 1;
#        1 0;
#        1 0]
#
# the following index vectors are used, giving the index of the columns for the
# entry 1 for the different rows of T_b and T_s
t_b = [1, 2, 2]
t_s = [2, 1, 1]

find_t_b = [find(x -> x == i, t_b) for i in 1:n]
find_t_s = [find(x -> x == i, t_s) for i in 1:n]

x_bar = [1, 1, 1]
# y_bar = [Inf, Inf, Inf] # not supported atm

p_bar = [1.0, 1.0, 0.5] # the name p_bar is used instead of pi

gamma = [0.5, 0.5]

# JuMP model
m = Model(solver = IpoptSolver())
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
solve(m)

display(m)
println("x = ", getvalue(x))
println("y = ", getvalue(y))
println("p = ", getvalue(p))
