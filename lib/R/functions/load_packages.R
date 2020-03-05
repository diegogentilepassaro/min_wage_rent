load_packages = function(names)
{
  for(name in names)
  {
    if (!(name %in% installed.packages()))
      install.packages(name, repo = "http://cran.rstudio.com/")
    
    library(name, character.only=TRUE)
  }
}
