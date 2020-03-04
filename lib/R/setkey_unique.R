setkey_unique <- function(x, cols, ...) {
   setkeyv(x, cols,...)
   if (uniqueN(x, by = key(x)) == nrow(x)) message('unique id OK')
   else print('the id provided is not unique! re-assign it')
}