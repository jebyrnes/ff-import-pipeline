## Libraries ####
library(tidyverse)
library(readr)

scenelist_dir <- "../scene_list"
old_scenelist_dir <- "../../ea-downloaded-scenes/scene_lists/falklands_102017"

get_all_scenes <- function(adir){
  ret <- list()
  for(afile in list.files(adir)){
    ret[[afile]] <- read_csv(paste(adir, afile, sep="/"), col_names=FALSE)
  }
  
  ret <- bind_rows(ret) %>%
    group_by(X1) %>%
    slice(1L) %>%
    ungroup()
  
  ret
  
}

oldscenes <- get_all_scenes(old_scenelist_dir)
newscenes <- get_all_scenes(scenelist_dir)

#what's new?
sum(newscenes$X1 %in% oldscenes$X1)
nrow(newscenes)
clean_newscenes <- newscenes[!(newscenes$X1 %in% oldscenes$X1),]

write(clean_newscenes$X1, file = paste0("../scene_list/", "falklands_new.txt"), sep="\n")
