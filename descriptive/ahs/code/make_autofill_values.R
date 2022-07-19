remove(list = ls())
library(data.table)
library(stringr)

source('../../../lib/R/write_command.R')

main <- function() {
  in_values    <- "../output"
  out_autofill <- "../output"
  
  data <- fread(file.path(in_values, "sh_renters.csv"))
  
  bottom_dec  <- 100 * round(data[hh_income_decile %in% c(1,2), 
                                  .(mean = mean(pr_tenant))]$mean, 2)
  top_dec     <- 100 * round(data[hh_income_decile %in% c(9,10), 
                                  .(mean = mean(pr_tenant))]$mean, 2)
  
  text <- c(write_command("BottomDecPrRent", bottom_dec),
            write_command("TopDecPrRent"   , top_dec))
  
  text <- paste(text, collapse = "")
  
  write.table(text,
              file.path(out_autofill, "ahs_autofill.tex"),
              quote = F, row.names = F, col.names = F)
}

main()