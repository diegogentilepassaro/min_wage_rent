load_mw <- function(instub) {
  
  # State MW
  state_mw <- fread(file.path(instub, "state_monthly.csv"))
  
  setnames(state_mw, old = "mw", new = "state_mw")
  
  state_mw[, c("year", "month") := .(as.numeric(substr(monthly_date, 1, 4)),
                                     as.numeric(gsub("m", "", substr(monthly_date, 5, length(monthly_date)))))]
  state_mw[, c("monthly_date", "statename") := NULL]
  
  state_mw[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
  state_mw[, stateabb  := NULL]
  
  state_mw[, event := 1*(state_mw != shift(state_mw)), by = .(statefips)]
  
  # Substate MW
  local_mw <- fread(file.path(instub, "substate_monthly.csv"))
  
  local_mw[, c("year", "month") := .(as.numeric(substr(monthly_date, 1, 4)),
                                     as.numeric(gsub("m", "", substr(monthly_date, 5, length(monthly_date)))))]
  local_mw[, c("monthly_date", "statename") := NULL]
  
  local_mw[, statefips := str_pad(as.character(statefips), 2, pad = 0)]
  local_mw[, iscounty  := 1*grepl("County", locality)]
  
  mw_vars        <- names(local_mw)[grepl("mw", names(local_mw))]
  county_mw_vars <- paste0("county_", mw_vars)
  local_mw_vars  <- paste0("local_",  mw_vars)
  
  county_mw <- local_mw[iscounty == 1, ][, iscounty := NULL]
  setnames(county_mw, old = c("locality",    mw_vars), 
           new = c("countyfips_name", county_mw_vars))
  
  local_mw <- local_mw[iscounty == 0, ][, iscounty := NULL]
  setnames(local_mw, old = c("locality",   mw_vars),
           new = c("place_name", local_mw_vars))
  
  county_mw <- county_mw[, .(countyfips_name, statefips, county_mw, year, month)]
  local_mw <- local_mw[,   .(place_name,  statefips, local_mw,  year, month)]
  
  county_mw[, event := 1*(county_mw != shift(county_mw)), by = .(countyfips_name, statefips)]
  local_mw[,  event := 1*(local_mw  != shift(local_mw)),  by = .(place_name,  statefips)]
  
  return(list("state"  = state_mw, 
              "county" = county_mw, 
              "local"  = local_mw))
}