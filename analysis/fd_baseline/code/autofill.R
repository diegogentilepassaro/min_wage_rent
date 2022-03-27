remove(list = ls())

library(data.table)

source('../../../lib/R/write_command.R')

main <- function() {
  
  in_baseline  <- '../output'
  out_autofill <- '../output'
  
  # From estimates_static
  
  dt <- load_data(in_baseline, 'static')
  
  dt <- dt[!(model %in% c('Only', 'WkpOnRes') & var == 'Sum')]
  
  txt <- ''

  for (mm in c('WkpOnRes', 'Only', 'Both')) {
    for (vv in c('Gamma', 'Beta', 'Sum')) {
      
      dt_comb <- dt[model == mm & var == vv]
      
      combination_exists <- dim(dt_comb)[1] > 0
      
      if (combination_exists) {
      
        estim   <- write_command(paste0(mm, vv, 'Base'),      round(dt_comb$b,    4))        
        estim10 <- write_command(paste0(mm, vv, 'BaseTen'),   round(10*dt_comb$b, 2))        
        tstat   <- write_command(paste0(mm, vv, 'BasetStat'), round(dt_comb$t,    2))
        
        if (dt_comb$b < 0) {
          
          estimAbs   <- write_command(paste0(mm, vv, 'BaseAbs'),    round(abs(dt_comb$b),    4))          
          estimAbs10 <- write_command(paste0(mm, vv, 'BaseTenAbs'), round(10*abs(dt_comb$b), 2))

          txt <- paste0(txt, estim, estimAbs, estim10, estimAbs10, tstat)
          
        } else {          
          txt <- paste0(txt, estim, estim10, tstat)        
        }
      }
    }
  }
  
  est  <- dt[model == 'Both', unique(p_equality)]  
  comm <- write_command('GammaEqBetaBasePval', round(est, 3))
  
  txt <- paste0(txt, comm)
  
  # From estimates_dynamic
  
  dt <- load_data(in_baseline, 'dynamic')
  
  dt <- dt[model == 'both_mw_wkp_dynamic' & at == 0]
  
  for (vv in c('Gamma', 'Beta', 'Sum')) {
    
    dt_comb <- dt[var == vv]
    
    name <- 'BothWkpDyn'
    
    estim   <- write_command(paste0(name, vv, 'Base'),      round(dt_comb$b,    4))    
    estim10 <- write_command(paste0(name, vv, 'BaseTen'),   round(10*dt_comb$b, 2))    
    tstat   <- write_command(paste0(name, vv, 'BasetStat'), round(dt_comb$t,    2))
    
    if (dt_comb$b < 0) {
      
      estimAbs   <- write_command(paste0(name, vv, 'BaseAbs'),    round(abs(dt_comb$b),    4))      
      estimAbs10 <- write_command(paste0(name, vv, 'BaseTenAbs'), round(10*abs(dt_comb$b), 2))
      
      txt <- paste0(txt, estim, estimAbs, estim10, estimAbs10, tstat)
    } else {
      
    txt <- paste0(txt, estim, estim10, tstat)
      
    }
  }
  
  est  <- dt[var == 'Sum', p_equality]  
  comm <- write_command('GammaEqBetaBaseDynPval', round(est, 3))
  
  txt  <- paste0(txt, comm)
  
  est  <- dt[var == 'Sum', p_pretrend]  
  comm <- write_command('BetaPretrendDynBasePVal', round(est, 3))
  
  txt <- paste0(txt, comm)
  
  write.table(txt,
              file.path(out_autofill,'baseline_autofill.tex'),
              quote = F, row.names = F, col.names = F)
}

load_data <- function(path, panel) {
  
  name <- paste0('estimates_',panel,'.csv')
  
  data <- fread(file.path(path, name))
  
  data[, `:=`(var = fcase(var == "mw_res",        "Gamma",
                          var == "mw_wkp_tot_17", "Beta",
                          var == "cumsum_from0",  "Sum"),
              t   = b / se)]
  
  if (panel=='static') {
    
    data[, `:=`(model = fcase(model == 'mw_wkp_on_res_mw',                   'WkpOnRes',
                              model %in% c('static_mw_res','static_mw_wkp'), 'Only', 
                              model == 'static_both',                        'Both'))]
  }
  
  return(data)
}

main()
