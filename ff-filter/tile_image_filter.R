#Load methods and libraries
library(tidyverse)
library(foreach)
library(doParallel)
library(readr)
source("./image_filtering_method.R")

scene_dir <- "../ff-import/"
out_dir <- "../new_for_upload"

#setup the parallel backend
registerDoParallel(cores=4)


#get a list of scenes
files <- list.files(scene_dir)
files <- files[grep("LT05", files)] #fix to deal with other satellites
#files <- c(files, "grid_350")

#for each scene
scenes_out <- foreach(scene = files) %dopar%{
  #1) Figure out which images are good
  good_img <- get_filtered_tiles_by_score(paste0(scene_dir, scene),
                                          fun = get_rb_quant,
                                          score = 1,
					  quant = 0.98)
  
  #2) Write good images to the new output directory
  new_img <- paste(scene, good_img, sep="_") 
  
  #ugh, I hate a for loop in R, but....
  for(i in 1:length(good_img)){
    system(paste("cp", 
                 paste0(scene_dir, scene, "/accepted/", good_img[i]),
                 paste(out_dir,  new_img[i], sep="/"),
                 sep = " "))  
  }
  
  #3) Write a new manifest for the scene
  accepted <- read_csv(paste0(scene_dir, scene, "/accepted/manifest.csv")) %>%
    filter(`#filename` %in% good_img) %>%
    mutate(`!scene` = gsub("temp\\/", "", `!scene`)) %>%
    mutate(`#filename` = paste(scene, `#filename`, sep="--"))
  
  write_csv(accepted, paste0(out_dir, "/accepted/", scene, "_manifest.csv"))
  
  
  #4) Write a new rejection manifest for the scene
  new_rejected <- read_csv(paste0(scene_dir, scene, "/accepted/manifest.csv")) %>%
    filter(!(`#filename` %in% good_img)) %>%
    mutate(`#reason` = "All water, clouds, or blank")
  
  rejected <- read_csv(paste0(scene_dir, scene, "/rejected/rejected.csv"))
  
  rejected <- bind_rows(rejected, new_rejected) %>%
    mutate(`!scene` = gsub("temp\\/", "", `!scene`))
  
  write_csv(rejected, paste0(out_dir, "/rejected/", scene, "_rejected.csv"))
  
  scene
}

#Now, merge accepted manifests
merge_manifests <- function(adir){
  manifest_files <- list.files( paste0(out_dir, "/", adir, "/"))
  manifest_files <- manifest_files[-grep("\\.md", manifest_files)]
  manifest <- read_csv(paste0(out_dir, "/", adir, "/", manifest_files[1])) 
  for(a_manifest in manifest_files[-1]){
    manifest <- manifest %>%
      bind_rows(read_csv(paste0(out_dir, "/", adir, "/", a_manifest)))
  }
  
  if(adir=="accepted"){
    write_csv(manifest,  paste(out_dir,  "manifest.csv", sep="/"))
  }else{
    write_csv(manifest,  paste0(out_dir, "/", adir, "_",  "manifest.csv"))
    
  }
  
}

#do the merging!
merge_manifests("accepted")
merge_manifests("rejected")
