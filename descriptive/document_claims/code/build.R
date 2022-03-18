remove(list = ls())

library(data.table)
library(stringr)

source('../../../lib/R/write_command.R')
source('autofill_estimates.R')
source('event_counts.R')

main <- function() {
  in_sample <- '../../../drive/derived_large/estimation_samples'
  in_estimates <- '../../../analysis/fd_baseline/output'
  out_estimates <- '../output/estimates.tex'
  out_events <- '../output/events_count.tex'
  out_corrmatrix <- '../output/corrmatrix.txt'
  
  varchar <- c('zipcode', 'countyfips', 'statefips', 'place_code','year_month')
  
  varnum <-  c("statutory_mw", "binding_mw", "binding_mw_max", 
              "mw_res", "mw_wkp_tot_17", "mw_wkp_age_under29_17", 
              "mw_wkp_earn_under1250_17","baseline_sample", "fullbal_sample")
  
  data <- fread(file.path(in_sample, 'zipcode_months.csv'),
    colClasses = list(
      character = varchar,
      numeric = varnum
      ),
    select = c(varchar,varnum)
    )
  
  # Correlation matrix
  
  vars <- c("mw_wkp_tot_17", "mw_wkp_age_under29_17", "mw_wkp_earn_under1250_17")
  
  corrmatrix <- cor(data[, ..vars])
  
  stargazer::stargazer(corrmatrix,
                       summary = F,
                       type="text",
                       out=out_corrmatrix, 
                       digits = 4)
  
  # Introduction estimates
  
  mw_pc_change <- 10
  
  output_estimates <- intro_estimates(in_estimates,mw_pc_change)
  
  write.table(output_estimates, out_estimates, quote = F, row.names = F, col.names = F)
  
  # MW summary statistics
  
  output_summary <- mw_summary(data)
  
  write.table(output_summary, out_events, quote = F, row.names = F, col.names = F)
  
}

# Execute
main()
