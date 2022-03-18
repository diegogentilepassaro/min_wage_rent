intro_estimates <- function(in_estimates, mw_pc_change = 10) {
  
  estimates <- fread(
    file.path(in_estimates, 'estimates_static.csv'),
    select = c("model", "var", "b", "se")
  )
  
  estimates <- estimates[model == "static_both"][, model := NULL]
  
  vars <- c("BetaBaseline", "GammaBaseline", "BetaPlusGammaBaseline")
  
  estimates[, `:=`(b = round(mw_pc_change * b, 2),
                   se = round(mw_pc_change * se, 2),
                   var = vars)]
  
  output_estimates <- ""
    
  for (vv in vars) {
    b <- str_pad(abs(estimates[var == vv][, b]), 4, "right", pad = 0)
    se <- str_pad(abs(estimates[var == vv][, se]), 4, "right", pad = 0)
    
    text_b <- write_command(vv,b)
    text_se <- write_command(paste0(vv,"SE"),se)
    text <- paste0(text_b, text_se)
    
    output_estimates <- paste0(output_estimates,text)
    
  }
  
  return(output_estimates)
}


mw_summary <- function(data) {
  geographies <- c("state", "county", "local")
  
  old_names <- c('statefips', 'countyfips', 'place_code')
  
  setnames(data, old_names, geographies)
  
  data[, event_mw := fifelse(statutory_mw > shift(statutory_mw), 1, 0),
       by = 'zipcode']
  
  output_summary <- ""
  
  for (panels in c('Unbalanced', 'Full Balanced', 'Baseline')) {
    output_summary <- paste0(output_summary,count_events(data, panels, geographies))
    output_summary <- paste0(output_summary,count_local(data, panels))
  }
  
  # Average percent change among Zillow ZIP codes (line 143 of data_sample.tex)
  
  data[, mean_mw := fifelse(event_mw == 1, statutory_mw / shift(statutory_mw), 0)]
  
  avchange <- (mean(data[mean_mw > 0, mean_mw], na.rm = T) - 1) * 100
  
  text <- write_command('AvgPctChange',paste0(round(avchange, 2),"\\%"))
  
  output_summary <- paste0(output_summary,text)
  
  return(output_summary)
}
