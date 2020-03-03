load_packages = function(packages_names) {
  
  for(name in packages_names) {
    if (!(name %in% installed.packages())) {
      install.packages(name)
    }
    
    library(name, character.only = TRUE)
  }
}
