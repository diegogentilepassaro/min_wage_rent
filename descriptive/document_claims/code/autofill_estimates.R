remove(list = ls())
library(data.table)
library(stringr)

source('../../../lib/R/write_command.R')

main <- function() {
  in_sample    <- '../../../drive/derived_large/estimation_samples'
  in_estimates <- '../../../analysis/fd_baseline/output'
  outstub      <- '../output'
  
  varchar <- c("zipcode", "countyfips", "statefips", "place_code", "year_month")
  varnum <-  c("statutory_mw", "binding_mw", "binding_mw_max", 
               "mw_res", "mw_wkp_tot_17", "mw_wkp_age_under29_17", 
               "mw_wkp_earn_under1250_17","baseline_sample", "fullbal_sample")

  dt <- fread(file.path(in_sample, 'zipcode_months.csv'),
                colClasses = list(character = varchar,
                                  numeric   = varnum))
  
  estimates <- fread(
    file.path(in_estimates, 'estimates_static.csv'),
    select = c("model", "var", "b", "se"))
  
  mw_pc_change <- 10
  
  out_estimates <- generate_autofill(estimates, mw_pc_change)
  out_estimates <- paste0(out_estimates, 
                          write_command("ReferencePcChangeMW", mw_pc_change))
  
  write.table(out_estimates, 
              file.path(outstub, "estimates.tex"),
              quote = F, row.names = F, col.names = F)
}

generate_autofill <- function(estimates, mw_pc_change = 10) {
  
  estimates <- estimates[model == "static_both"][, model := NULL]
  
  vars <- c("BetaBase", "GammaBase", "BetaPlusGammaBase")
  
  estimates[, var := vars]
  
  out_estimates <- ""
    
  for (vv in vars) {
    b     <- mw_pc_change*estimates[var == vv][["b"]]
    b_abs <- sprintf("%.2f", abs(b))
    b     <- sprintf("%.2f", b)

    se    <- sprintf("%.2f", mw_pc_change*estimates[var == vv][["se"]])
    
    text_b  <- write_command(vv, b)
    if (vv == "GammaBase") text_b <- paste0(text_b, write_command(paste0(vv, "Abs"), b_abs))

    text_se <- write_command(paste0(vv, "SE"), se)
    text    <- paste0(text_b, text_se)
    
    out_estimates <- paste0(out_estimates, text)    
  }
  
  return(out_estimates)
}

# Execute
main()
