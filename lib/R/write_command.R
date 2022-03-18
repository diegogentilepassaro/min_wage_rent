write_command <- function(name, value, comment=NULL) {
  return(paste0("\\newcommand{\\", name, "}{\\textnormal{", value, "}}",comment,"\n"))
}
