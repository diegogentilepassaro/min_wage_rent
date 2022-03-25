remove(list = ls())

library(data.table)

source('../../../lib/R/write_command.R')

main <- function() {
  in_stacked <- '../output'
  out_autofill <- '../output'
  
  data <- fread(file.path(in_stacked, 'estimates_stacked_static_w6.csv'))
  
  data <- data[model=="static_both_w6" & var=="cumsum_from0"]
  
  b <- data[, b]
  
  t <- data[, .(t = b / se)]$t
  
  name <- 'BothSumStack'
  
  est <- write_command(name, round(b, 4))
  
  est10 <- write_command(paste0(name,'Ten'), round(10*b, 3))
  
  tstat <- write_command(paste0(name,'tStat'), round(t, 4))
  
  txt <- paste0(est,est10,tstat)
  
  write.table(txt,
              file.path(out_autofill,'stacked_autofill.tex'),
              quote = F, row.names = F, col.names = F)
}

main()
