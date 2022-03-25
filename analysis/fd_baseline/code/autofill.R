remove(list = ls())

library(data.table)

source('../../../lib/R/write_command.R')

main <- function() {
  
  in_baseline <- '../output'
  out_autofill <- '../output'
  
  # From estimates_static
  
  data <- load_data(in_baseline, 'static')
  
  data <- data[!(model %in% c('Only', 'WkpOnRes') & var == 'Sum')]
  
  txt <- ''

  for (mm in c('WkpOnRes', 'Only', 'Both')) {
    for (vv in c('Gamma', 'Beta', 'Sum')) {
      
      dt_comb <- data[model == mm & var == vv]
      
      combination_exists <- dim(dt_comb)[1] > 0
      
      if (combination_exists) {
      
        estim   <- write_command(paste0(mm, vv, 'Base'), round(dt_comb$b,4))
        
        estim10 <- write_command(paste0(mm, vv, 'BaseTen'), round(10 * dt_comb$b,3))
        
        tstat   <- write_command(paste0(mm, vv, 'BasetStat'), dt_comb$t)
        
        if (dt_comb$b < 0) {
          
          estimAbs   <- write_command(paste0(mm, vv, 'BaseAbs'), round(abs(dt_comb$b),4))
          
          estimAbs10 <- write_command(paste0(mm, vv, 'BaseTenAbs'), round(10* abs(dt_comb$b),3))
          
          txt <- paste0(txt, estim, estimAbs, estim10, estimAbs10, tstat)
          
        } else {
          
        txt <- paste0(txt, estim, estim10, tstat)
        
        }
      }
    }
  }
  
  est <- data[model == 'Both', unique(p_equality)]
  
  comm <- write_command('GammaBetaBasePval', round(est, 3))
  
  txt <- paste0(txt, comm)
  
  # From estimates_dynamic
  
  data <- load_data(in_baseline, 'dynamic')
  
  data <- data[model == 'both_mw_wkp_dynamic' & at == 0]
  
  for (vv in c('Gamma', 'Beta', 'Sum')) {
    
    dt_comb <- data[var == vv]
    
    name <- 'BothWkpDyn'
    
    estim   <- write_command(paste0(name, vv, 'Base'), round(dt_comb$b, 4))
    
    estim10 <- write_command(paste0(name, vv, 'BaseTen'), round(10 * dt_comb$b,3))
    
    tstat   <- write_command(paste0(name, vv, 'BasetStat'), dt_comb$t)
    
    if (dt_comb$b < 0) {
      
      estimAbs   <- write_command(paste0(name, vv, 'BaseAbs'), round(abs(dt_comb$b),4))
      
      estimAbs10 <- write_command(paste0(name, vv, 'BaseTenAbs'), round(10* abs(dt_comb$b),3))
      
      txt <- paste0(txt, estim, estimAbs, estim10, estimAbs10, tstat)
    } else {
      
    txt <- paste0(txt, estim, estim10, tstat)
      
    }
    
  }
  
  est <- data[var == 'Sum', p_equality]
  
  comm <- write_command('GammaBetaDynBasePval', round(est, 3))
  
  txt <- paste0(txt, comm)
  
  write.table(txt,
              file.path(out_autofill,'baseline_autofill.tex'),
              quote = F, row.names = F, col.names = F)
}

load_data <- function(path, panel) {
  
  name <- paste0('estimates_',panel,'.csv')
  
  data <- fread(file.path(path, name))
  
  data[, `:=`(var = fcase(var == "mw_res", "Gamma",
                          var == "mw_wkp_tot_17", "Beta",
                          var == "cumsum_from0", "Sum"),
              t   = round(b / se, 2))]
  
  if (panel=='static') {
    
    data[, `:=`(model = fcase(model == 'mw_wkp_on_res_mw', 'WkpOnRes',
                              model %in% c('static_mw_res',
                                           'static_mw_wkp'), 'Only', 
                              model == 'static_both', 'Both'))]
  }
  
  return(data)
}

main()
