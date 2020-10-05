
## Simulation 

Notation:

- ![z](https://render.githubusercontent.com/render/math?math=z) indexes zipcode
- ![c](https://render.githubusercontent.com/render/math?math=c) indexes county
- ![s](https://render.githubusercontent.com/render/math?math=s) indexes state
- ![t](https://render.githubusercontent.com/render/math?math=t) indexes time
- ![r](https://render.githubusercontent.com/render/math?math=r) represents rents psqft
- ![h](https://render.githubusercontent.com/render/math?math=h) represents housing values psqft
- ![mw_{zt}](https://render.githubusercontent.com/render/math?math=mw_%7Bzt%7D) is the mw in zipcode ![z](https://render.githubusercontent.com/render/math?math=z) period ![t](https://render.githubusercontent.com/render/math?math=t)
- ![I_{zt}](https://render.githubusercontent.com/render/math?math=I_%7Bzt%7D) is an indicator for a mw change in zipcode ![z](https://render.githubusercontent.com/render/math?math=z) period ![t](https://render.githubusercontent.com/render/math?math=t)
- ![dinc_{zt}^n](https://render.githubusercontent.com/render/math?math=dinc_%7Bzt%7D%5En) is the change in monthly income in a househould with 2 minimum wage earners due to MW increase ![n](https://render.githubusercontent.com/render/math?math=n)
- ![nmw_{zt}](https://render.githubusercontent.com/render/math?math=nmw_%7Bzt%7D) the number of MW changes in zipcode ![z](https://render.githubusercontent.com/render/math?math=z) up to period ![t](https://render.githubusercontent.com/render/math?math=t)
- ![\theta_1](https://render.githubusercontent.com/render/math?math=%5Ctheta_1) is the pass-through of the mw on rents, set to 0.05.
- ![\theta_2](https://render.githubusercontent.com/render/math?math=%5Ctheta_2) is the level effect of any mw change on rents, set to $30.
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

![r_{zt} = \gamma_z + \delta_t + \sum_{n=1}^{nmw_{zt}} \theta_1 dinc^n_{zt} + \epsilon_{zt}](https://render.githubusercontent.com/render/math?math=r_%7Bzt%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Csum_%7Bn%3D1%7D%5E%7Bnmw_%7Bzt%7D%7D%20%5Ctheta_1%20dinc%5En_%7Bzt%7D%20%2B%20%5Cepsilon_%7Bzt%7D)

Every minimum wage increase in the zipcode increases rents in ![\theta_1](https://render.githubusercontent.com/render/math?math=%5Ctheta_1) \*(the average increase in income for a household with two minimum wage earners). The effect of the minimum wage depends on the magniute of the increase.

#### rent3

Model:

![r_{zt} = \gamma_z + \delta_t + \sum_{n=1}^{nmw_{zt}} \theta_2 + \epsilon_{zt}](https://render.githubusercontent.com/render/math?math=r_%7Bzt%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Csum_%7Bn%3D1%7D%5E%7Bnmw_%7Bzt%7D%7D%20%5Ctheta_2%20%2B%20%5Cepsilon_%7Bzt%7D)

Every minimum wage increase in the zipcode increases rents in ![\theta_2](https://render.githubusercontent.com/render/math?math=%5Ctheta_2) dollars. The effect of the minimum wage is fixed in levels.

#### rent4

The model is

![r_{zst} = \gamma_z + \delta_t + \mu_{s} t + \epsilon_{zst}](https://render.githubusercontent.com/render/math?math=r_%7Bzst%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cmu_%7Bs%7D%20t%20%2B%20%5Cepsilon_%7Bzst%7D)

where ![\mu_{s} = 1 + g_s](https://render.githubusercontent.com/render/math?math=%5Cmu_%7Bs%7D%20%3D%201%20%2B%20g_s) and ![g_s \sim Unif \\[0.001,0.007\\]](https://render.githubusercontent.com/render/math?math=g_s%20%5Csim%20Unif%20%5C%5B0.001%2C0.007%5C%5D) is the monthly growth rate.

In this case we assume the minimum wage has no effect.

#### rent5

The model is

![r_{zst} = \gamma_z + \delta_t + \mu_{s} t + \sum_{n=1}^{nmw_{zt}} \theta_1 dinc^n_{zt} + \epsilon_{zst}](https://render.githubusercontent.com/render/math?math=r_%7Bzst%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cmu_%7Bs%7D%20t%20%2B%20%5Csum_%7Bn%3D1%7D%5E%7Bnmw_%7Bzt%7D%7D%20%5Ctheta_1%20dinc%5En_%7Bzt%7D%20%2B%20%5Cepsilon_%7Bzst%7D)

It's the same as rent4 but adding an effect of the minimum wage. As in rent 2, the effect of the minimum wage on rents depends on the magnitude of the increase.

#### rent6

The model is

![r_{zst} = \gamma_z + \delta_t + \mu_{s} t + \sum_{n=1}^{nmw_{zt}} \theta_2 + \epsilon_{zst}](https://render.githubusercontent.com/render/math?math=r_%7Bzst%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cmu_%7Bs%7D%20t%20%2B%20%5Csum_%7Bn%3D1%7D%5E%7Bnmw_%7Bzt%7D%7D%20%5Ctheta_2%20%2B%20%5Cepsilon_%7Bzst%7D)

In this case the effect of the minimum wage is constant in levels, exactly as in rent3.
