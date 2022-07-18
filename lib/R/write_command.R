write_command <- function(name, value, comment = NULL, textnormal = T) {

  if (textnormal) {
    if (is.null(comment)) {
      return(paste0("\\newcommand{\\", name, "}{\\textnormal{", value, "}}\n"))
    }
    else {
      return(paste0("\\newcommand{\\", name, "}{\\textnormal{", value, "}}\t%", comment,"\n"))
    }
  } 
  else {
    if (is.null(comment)) {
      return(paste0("\\newcommand{\\", name, "}{", value, "}\n"))
    }
    else {
      return(paste0("\\newcommand{\\", name, "}{", value, "}\t%", comment,"\n"))
    }
  }
}
