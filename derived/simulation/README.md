
## Simulation 

Notation:

- ![z ~ ](https://render.githubusercontent.com/render/math?math=z%20~%20) indexes zipcode
- ![c ~ ](https://render.githubusercontent.com/render/math?math=c%20~%20) indexes county
- ![t ~ ](https://render.githubusercontent.com/render/math?math=t%20~%20) indexes time
- ![r](https://render.githubusercontent.com/render/math?math=r) represents rents psqft
- ![h](https://render.githubusercontent.com/render/math?math=h) represents housing values psqft
- ![mw_{zt}](https://render.githubusercontent.com/render/math?math=mw_%7Bzt%7D) is an indicator for mw in zipcode ![z](https://render.githubusercontent.com/render/math?math=z) period ![t](https://render.githubusercontent.com/render/math?math=t)
- ![\theta](https://render.githubusercontent.com/render/math?math=%5Ctheta) is the pass-through of the mw on rents.
- ![\epsilon](https://render.githubusercontent.com/render/math?math=%5Cepsilon) is a shock, typically iid

### Rents

I simulate several measures of rents based on different assumptions. 

#### rent1

Consider the model

![r_{zt} = \gamma_z + \delta_t + \epsilon_{zt}](https://render.githubusercontent.com/render/math?math=r_%7Bzt%7D%20%3D%20%5Cgamma_z%20%2B%20%5Cdelta_t%20%2B%20%5Cepsilon_%7Bzt%7D)

where ![\epsilon_{zt}](https://render.githubusercontent.com/render/math?math=%5Cepsilon_%7Bzt%7D) is a normal ![\mathcal{N}(0, \sigma^2_r)](https://render.githubusercontent.com/render/math?math=%5Cmathcal%7BN%7D(0%2C%20%5Csigma%5E2_r)) (with ![\sigma^2_r](https://render.githubusercontent.com/render/math?math=%5Csigma%5E2_r) the var of medrentpricepsqft_sfcc) trucated between ![\underline{r}](https://render.githubusercontent.com/render/math?math=%5Cunderline%7Br%7D) and ![\overline{r}](https://render.githubusercontent.com/render/math?math=%5Coverline%7Br%7D), the minimum and maximum observed values of medrentpricepsqft_sfcc. This is simulated with the R package [truncnorm](https://cran.r-project.org/web/packages/truncnorm/truncnorm.pdf).

Note that, in this measure, the minimum wage is assumed to have no effect.

#### rent2 




