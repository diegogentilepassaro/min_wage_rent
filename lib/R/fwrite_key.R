fwrite_key <- function(x, file, ...) {
   # require(data.table)
   x <- setDT(x)
   if (haskey(x)==T) {
      fwrite(x, file=file, ...)
      print("File saved succesfully")
   } else if (haskey(x)==F) {
      warning("The dataset does not have a unique ID! use setkeyv2(dataset, cols) to set that up")
   }
}