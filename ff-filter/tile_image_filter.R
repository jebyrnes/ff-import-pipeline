#for debug
sink("out.txt")

#Load methods and libraries
library(dplyr)
library(tidyr)
library(foreach)
library(doParallel)
library(readr)
source("./image_filtering_method.R")

scene_dir <- "../ff-import/"
out_dir <- "../new_for_upload"

#setup the parallel backend
registerDoParallel(cores=10)


#get a list of scenes
files <- list.files(scene_dir)
files <- files[grep("[LC08|LT05|LE07]", files)] #fix to deal with other satellites
#an empty one - LC08_L1TP_220096_20140130_20170426_01_T1_tiles
#files <- c(files, "grid_350")
#files <- files[grep("empty", files)] #fix to deal with other satellites

print("Starting to filter scenes...")

#for each scene
scenes_out <- foreach(scene = files) %dopar%{

  cat(paste0("Starting ", scene, "\n"))
  cat(paste0("Checking for valid accepted tiles in ", scene, "\n"))
  
  #0) Are there any tiles to filter?
  areFiles <- length(list.files(paste0(scene_dir, scene, "/accepted"))>0)
  
  if(areFiles==0){
    cat(paste0("No accepted tiles in ", scene, "\n"))
    
    #copy over the rejected manifest properly
    suppressMessages(rejected <- read_csv(paste0(scene_dir, scene, "/rejected/rejected.csv")))
    
    rejected <- rejected %>%
      mutate(`!scene` = gsub("temp\\/", "", `!scene`))
    
    write_csv(rejected, paste0(out_dir, "/rejected/", scene, "_rejected.csv"))
    
    #go to next loop iteration
    return(scene)
    
  }
  
  #1) Figure out which images are good
  cat(paste0("Filtering accepted tiles in ", scene, "\n"))
  
  good_img <- get_filtered_tiles_by_score(paste0(scene_dir, scene),
                                          fun = get_rb_quant,
                                          score = 1,
					  quant = 0.98)
  
  #2) Write good images to the new output directory
  new_img <- paste(scene, good_img, sep="_") 

  cat(paste0("Copying good images from ", scene, "\n"))
  
  #ugh, I hate a for loop in R, but....
  for(i in 1:length(good_img)){
    system(paste("cp", 
                 paste0(scene_dir, scene, "/accepted/", good_img[i]),
                 paste(out_dir,  new_img[i], sep="/"),
                 sep = " "))  
  }
  
  cat(paste0("Writing manifests for ", scene, "\n"))
  #3) Write a new manifest for the scene
  suppressMessages(accepted <- read_csv(paste0(scene_dir, scene, "/accepted/manifest.csv")) )
  accepted <- accepted %>%
    filter(`#filename` %in% good_img) %>%
    mutate(`!scene` = gsub("temp\\/", "", `!scene`)) %>%
    mutate(`#filename` = paste(scene, `#filename`, sep="_"))
  
  write_csv(accepted, paste0(out_dir, "/accepted/", scene, "_manifest.csv"))
  
  
  #4) Write a new rejection manifest for the scene
  suppressMessages(new_rejected <- read_csv(paste0(scene_dir, scene, "/accepted/manifest.csv")) )

  new_rejected <- new_rejected %>%
    filter(!(`#filename` %in% good_img)) %>%
    mutate(`#reason` = "All water, clouds, or blank")
  
  suppressMessages(rejected <- read_csv(paste0(scene_dir, scene, "/rejected/rejected.csv")))
  
  rejected <- bind_rows(rejected, new_rejected) %>%
    mutate(`!scene` = gsub("temp\\/", "", `!scene`))
  
  write_csv(rejected, paste0(out_dir, "/rejected/", scene, "_rejected.csv"))
  
  scene
}

print("Done parsing scenes.")

#Now, merge accepted manifests
merge_manifests <- function(adir){
  manifest_files <- list.files( paste0(out_dir, "/", adir, "/"))
  manifest_files <- manifest_files[-grep("\\.md", manifest_files)]
  suppressMessages(  manifest <- read_csv(paste0(out_dir, "/", adir, "/", manifest_files[1])) )
  for(a_manifest in manifest_files[-1]){
    manifest <- manifest %>%
      suppressMessages(bind_rows(read_csv(paste0(out_dir, "/", adir, "/", a_manifest))))
  }
  
  if(adir=="accepted"){
    write_csv(manifest,  paste(out_dir,  "manifest.csv", sep="/"))
  }else{
    write_csv(manifest,  paste0(out_dir, "/", adir, "_",  "manifest.csv"))
    
  }
  
}

#do the merging!
print("Making new accepted manifest.")
merge_manifests("accepted")

print("Making new rejected manifest.")
merge_manifests("rejected")

sink()
