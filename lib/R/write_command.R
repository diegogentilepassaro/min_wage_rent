write_command <- function(name, value, comment = NULL) {
  if (is.null(comment)) {
    return(paste0("\\newcommand{\\", name, "}{\\textnormal{", value, "}}\n"))
  }
  else {
    return(paste0("\\newcommand{\\", name, "}{\\textnormal{", value, "}}\t%", comment,"\n"))
  }
}
