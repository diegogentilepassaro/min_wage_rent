remove(list = ls())

library(data.table)

source('../../../lib/R/write_command.R')

main <- function() {
  
  in_baseline <- '../output'
  out_autofill <- '../output'
  
  # From estimates_static
  
  data <- fread(file.path(in_baseline, 'estimates_static.csv'))
  
  data[, `:=`(var   = fcase(var   == "mw_res", "Gamma",
                            var   == "mw_wkp_tot_17", "Beta",
                            var   == "cumsum_from0", "Sum"),
              model = fcase(model == 'mw_wkp_on_res_mw', 'WkpOnRes',
                            model %in% c('static_mw_res',
                                         'static_mw_wkp'), 'Only', 
                            model == 'static_both', 'Both'))]
  
  data <- data[!(model %in% c('Only', 'WkpOnRes') & var == 'Sum')]
  
  txt <- ''
  
  for (mm in c('WkpOnRes', 'Only', 'Both')) {
    for (vv in c('Gamma', 'Beta', 'Sum')) {
      b <- data[model == mm & var == vv, b]
      
      t <- data[model == mm & var == vv, .(t = b / se)]$t
      
      if (length(b) == 0) next
      
      estim <- write_command(paste0(mm, vv, 'Base'), round(b, 3))
      
      estim10 <- write_command(paste0(mm, vv, 'BaseTen'), round(10 * b, 2))
      
      tstat <- write_command(paste0(mm, vv, 'BasetStat'), round(t, 3))
      
      txt <- paste0(txt, estim, estim10, tstat)
    }
  }
  
  est <- data[model == 'Both', unique(p_equality)]
  
  comm <- write_command('GammaBetaBasePval', round(est, 3))
  
  txt <- paste0(txt, comm)
  
  # From estimates_dynamic
  
  data <- fread(file.path(in_baseline, 'estimates_dynamic.csv'))
  
  data[, `:=`(var = fcase(var == "mw_res", "Gamma",
                          var == "mw_wkp_tot_17", "Beta",
                          var == "cumsum_from0", "Sum"))]
  data <- data[model == 'both_mw_wkp_dynamic' & at == 0]
  
  for (vv in c('Gamma', 'Beta', 'Sum')) {
    b <- data[var == vv, b]
    
    t <- data[var == vv, .(t = b / se)]$t
    
    estim <- write_command(paste0('BothWkpDyn', vv, 'Base'), round(b, 4))
    
    estim10 <- write_command(paste0('BothWkpDyn', vv, 'BaseTen'), round(10 * b, 3))
    
    tstat <- write_command(paste0('BothWkpDyn', vv, 'BasetStat'), round(t, 3))
    
    txt <- paste0(txt, estim, estim10, tstat)
  }
  
  est <- data[var == 'Sum', p_equality]
  
  comm <- write_command('GammaBetaDynBasePval', round(est, 3))
  
  txt <- paste0(txt, comm)
  
  write.table(txt,
              file.path(out_autofill,'estimates_autofill.tex'),
              quote = F, row.names = F, col.names = F)
}     

main()
