# Notes

## 2018-07-30

- why is it possible to formulate the problem as continuous problem without discrete components?
- which abstract properties do the transactions have to satisfy? which 'attacks' have to be mitigated?

todo
- reproduce simple implementation in julia JuMP


## 2018-07-31

- test change of liquidity in model problem with 3 tokens
  - what is a good measure of liquidity?
    - number of fullfilled orders?
    - trading volume?
- test models with a different solver also to understand run times better
  - results: SCIP solver installed via installer takes forever on the large problem
- compare runtimes with the MIL approach

- why can the fractional crealing property not be satisfied by some postprocessing after the NL approach?

- the first formulation might be linear!!?? at least that is how it seems after applying the same tricks as done for the MIP formulations
  - NO! as it turns out, the nonlinearity might be necessary after all. limit prices should only be enforced for some of the orders!
  - BUT: by multiplying the incerrect contraint by v one recovers a wellposed problem with severely reduced dimensionality

## 2018-08-01

- read some stuff in the direction of parametrized linear problems
  - after fixing prices, the problem is fully linear
  - prices enter only in the form of linear coefficients
  - is there something to be gained here in terms of efficiency?
- looks like multiparametric linear programming does not really help here
- standard approach is to reformulate the bilinear constraints using integer variables to a MIP, as done in the paper. see [https://math.stackexchange.com/questions/1361014/bilinear-constraint]()
- solution of the nonlinear problem depends strongly on the initial solution
  - bug?
  - should the solution of the linear solve be postprocessed in some way?

## 2018-08-02

- I should keep in mind, that my timing are on a weaker machine (i5-4200U CPU @ 1.60GHz (2 cores) vs i7-8550U CPU @ 1.80GHz (4 cores))
  - not sure how much faster their laptop actually is
  - is this approach scalable? will it help to be on a better machine? what are realistic numbers of tokens and orders?
- i could try postprocessing in each step after the linear solve, this might make the problem better behaved
  - but the nonlinear formulation seems to be rather strangely behaved. the switching of some of the conditions seems to be close to discrete. the nonlinear formulation might not be wellposed, or at the least might not satisfy constraint qualifications
- testing the nonlinear solutions agains solutions of MIP should be instructive
  - in preliminary test the mip leads to better solutions but takes a lot longer
    - for n = 10, N = 100 it takes 90s, compared to the reported 0.32s in the manuscript. so Gurobi is a lot faster or i missed some code optimizations or the realistic workload produces simpler problems
- there must be some way to exploit that the problem only contains few *difficult* variables (p) and for fixed p becomes a linear problem!
  - iterative approach seems to get stuck. maybe the mip formulation is as effecient as it gets? (up to monotonie in z etc.)
