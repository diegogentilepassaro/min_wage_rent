remove(list = ls())
library(data.table)


make_coefs_cols <- function(estlist, models, rows) {
  estlist<- estlist[model %in% models]
  
  est2 <- CJ(var=rows, model=estlist$model, at=estlist$at, variable=estlist$variable, unique=TRUE)
  estlist <- estlist[est2, on = c('model', 'at', 'variable', 'var')]
  estlist$value[is.na(estlist$value)] <- ""
      
  estlist <- estlist[rows, on='var']
  setorderv(estlist, cols = c('model', 'at'), order=c(1, 1))
  estlist <- estlist[models, on='model']
  
  coefs <- lapply(models, function(x) estlist[estlist$model == x,]$value)
  coefs <- do.call(paste, c(coefs, sep="\t"))
  return(coefs)
}

main <- function() {
  
  instub  <- "../output/"
  outstub <- "../output/"
  
  est <- read.csv(file.path(instub, "estimates_static.csv"))

  est_coefs <- est[c('model', 'var', 'at', 'b', 'se')]
  est_coefs <- melt(setDT(est_coefs), id.vars = c('model', 'var', 'at'), 
                                      measure.vars = c('b', 'se'))
  

  est_stats <- setDT(est[c('model', 'p_equality', 'r2', 'N')])[
               , .SD[c(.N)], by=model]
  
  est_stats <- est_stats[, data.table(t(.SD)),]
  colnames(est_stats) <- unlist(est_stats[1,])
  est_stats <- est_stats[-1,]
  
  
  txt_static_sample <- c("<tab:static>")
  txt_static_sample <- c(txt_static_sample, 
                         make_coefs_cols(est_coefs, 
                                         models = c('static_stat', 'static_stat_unbal', 
                                                    'static_stat_wgt', 'static_stat_unbal_wgt'), 
                                         rows = c('ln_mw', 'exp_ln_mw', 'cumsum_from0')
                                         )
                         )
  
  txt_static_sample <- c(txt_static_sample, 
           paste(est_stats$static_stat, 
                 est_stats$static_stat_unbal, 
                 est_stats$static_stat_wgt, 
                 est_stats$static_stat_unbal_wgt, sep = "\t"))
  
  
  
  fileConn <- file(file.path(outstub, "static_sample.txt"))
  writeLines(txt_static_sample, fileConn)
  close(fileConn)
  
  txt_static_ab <- c("<tab:static>")
  txt_static_ab <- c(txt_static_ab,make_coefs_cols(est_coefs, 
                                                   models=c('static_stat_nocontrol', 
                                                            'static_stat', 
                                                            'static_stat_AB_nocontrol', 
                                                            'static_stat_AB'), 
                                                   rows=c('ln_mw', 'exp_ln_mw', 
                                                          'L_ln_med_rent_var', 'cumsum_from0')
                                                   )
                     )
  
  txt_static_ab <- c(txt_static_ab, 
                         paste(est_stats$static_stat_nocontrol, 
                               est_stats$static_stat, 
                               est_stats$static_stat_AB_nocontrol, 
                               est_stats$static_stat_AB, sep = "\t"))
  
  
  
  fileConn <- file(file.path(outstub, "static_ab.txt"))
  writeLines(txt_static_ab, fileConn)
  close(fileConn) 
  
  
}




main()
