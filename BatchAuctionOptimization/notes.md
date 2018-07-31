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
