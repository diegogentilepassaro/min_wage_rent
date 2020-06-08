
## Simulation 

Notation:

- ![z](https://render.githubusercontent.com/render/math?math=z) indexes zipcode
- ![c](https://render.githubusercontent.com/render/math?math=c) indexes county
- ![s](https://render.githubusercontent.com/render/math?math=s) indexes state
- ![t](https://render.githubusercontent.com/render/math?math=t) indexes time
- ![r](https://render.githubusercontent.com/render/math?math=r) represents rents psqft
- ![h](https://render.githubusercontent.com/render/math?math=h) represents housing values psqft
- ![mw_{zt}](https://render.githubusercontent.com/render/math?math=mw_%7Bzt%7D) is an indicator for mw in zipcode ![z](https://render.githubusercontent.com/render/math?math=z) period ![t](https://render.githubusercontent.com/render/math?math=t)
- ![dinc_{zt}^n](https://render.githubusercontent.com/render/math?math=dinc_%7Bzt%7D%5En) is the change in monthly income in a househould with 2 minimum wage earners due to MW increase ![n](https://render.githubusercontent.com/render/math?math=n)
- ![nmw_z](https://render.githubusercontent.com/render/math?math=m_z) the number of MW changes in zipcode z
- ![\theta](https://render.githubusercontent.com/render/math?math=%5Ctheta) is the pass-through of the mw on rents.
- ![\epsilon](https://render.githubusercontent.com/render/math?math=%5Cepsilon) is a shock, typically iid

### Rents

I simulate several measures of rents based on different assumptions. 

#### rent1

Consider the model

![r_{zt} = \gamma_z + \delta_t + \epsilon_{zt}](https://render.githubusercontent.com/render/math?math=r_%7Bzt%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cepsilon_%7Bzt%7D)

where
- zipcode effects are computed as average of medrentprice_sfcc for each zipcode and and time effects as verage of _demeaned_ medrentprice_sfcc for each year month.
- ![v_{zt}](https://render.githubusercontent.com/render/math?math=v_%7Bzt%7D) is a normal ![\mathcal{N}(0, \sigma^2)](https://render.githubusercontent.com/render/math?math=%5Cmathcal%7BN%7D(0%2C%20%5Csigma%5E2)). 

I truncate the resulting simulated values with the minimum and maximum of observed rents.

Note that, in this measure, the minimum wage is assumed to have no effect on rents.

#### rent2 

Consider now the model

![r_{zt} = \gamma_z + \delta_t + \sum_{n=1}^{nmw_z} \theta\*dinc^n_{zt} + \epsilon\_{zt}](https://render.githubusercontent.com/render/math?math=r_%7Bzt%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Csum_%7Bn%3D1%7D%5E%7Bnmw_z%7D%20%5Ctheta*dinc%5En_%7Bzt%7D%20%2B%20%5Cepsilon_%7Bzt%7D)

Every minimum wage increase in the zipcode increases rents in ![theta](https://render.githubusercontent.com/render/math?math=theta)\*(the increase in income) 

#### rent3

The model is

![r_{zst} = \gamma_z + \delta_t + \mu_{st} + \epsilon\_{zst}](https://render.githubusercontent.com/render/math?math=r_%7Bzst%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cmu*t*1%5C%7Bstate%20%3D%20s%5C%7D%20%2B%20%5Cepsilon%5C_%7Bzst%7D)

This variable addes a state-specific time period effect, which is built with as a trend with a changing growth rate.

In this case we assume the minimum wage has no effect.

#### rent4

The model is

![r_{zt} = \gamma_z + \delta_t + \mu_{st} + \sum_{n=1}^{nmw_z} \theta\*dinc^n_{zt} + \epsilon\_{zt}](https://render.githubusercontent.com/render/math?math=r_%7Bzt%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cmu_%7Bst%7D%20%2B%20%5Csum_%7Bn%3D1%7D%5E%7Bnmw_z%7D%20%5Ctheta%5C*dinc%5En_%7Bzt%7D%20%2B%20%5Cepsilon%5C_%7Bzt%7D)

It's the same as rent3 but adding an effect of the minimum wage.
