## Libraries ####
library(tidyverse)
library(readr)

#products
#LANDSAT_TM_C1
#LSR_LANDSAT_ETM_C1
#LANDSAT_8_C1

## Load data ####
dir_names <- list.files("../earth_explorer_output")
for(adir in dir_names){
  files <- list.files(paste0("../earth_explorer_output/", adir))
  for(file_name in files){
#  file_name <- files[3]
    earthexplorer_out <- read_csv(paste0("../earth_explorer_output/", adir, "/", file_name), col_types = cols()) %>% 
      filter(`Collection Category` == "T1") %>%
      #filters from ESPA that throws back bad scenes
      filter(!(`Landsat Product Identifier` %in% 
                 c("LE07_L1TP_221096_20160611_20161209_01_T1", #ls 7 falklands 
                   "LC08_L1TP_222096_20160219_20170329_01_T1",
                   "LC08_L1TP_220096_20160221_20170329_01_T1"))) #ls 8 falklands
    
    #Get some info
    print(paste0(adir, "_", file_name))
    print(nrow(earthexplorer_out))
    print(unique(earthexplorer_out[["Collection Category"]]))
    print(min(earthexplorer_out[["Acquisition Date"]]))
    print(max(earthexplorer_out[["Acquisition Date"]]))
    
    #Scene Names
    #unique(earthexplorer_out[["Landsat Product Identifier"]])
    #unique(earthexplorer_out[["Landsat Scene Identifier"]])
    #unique(earthexplorer_out[["Ordering ID"]])
    
    #  cat(paste(head(unique(earthexplorer_out[["Landsat Scene Identifier"]])), collapse='","'))
    #cat(paste(head(unique(earthexplorer_out[["Landsat Product Identifier"]])), collapse='","'))
    
    # nrow(earthexplorer_out)
    newfilename <- gsub("csv", "txt", file_name)
    
    write(earthexplorer_out[["Landsat Product Identifier"]], file = paste0("../scene_list/", adir, "_", newfilename), sep="\n")
  }
}
