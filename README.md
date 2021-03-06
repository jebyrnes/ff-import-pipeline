### How to import and process images for the Floating Forests Project

#### Installation  
1. Clone this repo.  `cd` into the repo.
2. Clone https://github.com/USGS-EROS/espa-bulk-downloader/  
3. Clone https://github.com/zooniverse/ff-import  
4. Install https://github.com/zooniverse/panoptes-cli

#### Operation

1. Create a single kml polygon using google earth of the area you would like with <30 vertices.

2. Go to https://earthexplorer.usgs.gov/ and upload the polygon. Select all dates from January 1 1980 to present.

3. When presented, choose all Landsat level 1 products.  

4. Use the make_scene_list.R in make_scene_list/R for each satellite to make a list of scenes for download.  

5. Go to https://espa.cr.usgs.gov/ordering/new/ and enter a scene list. You might have to do some extra filtering. Make sure you click surface reflectance products. In the description, note that this is for floating forests.  
     - Make sure to archive which scenes you've downloaded in `downloaded_scenes`  

6. Once your order is ready, use the espa-bulk downloader to get the scenes. You can find it at https://github.com/USGS-EROS/espa-bulk-downloader

7. Make a symbolic link from the directory with the scenes you want to process to `ff-import/tmp/archives`  
     - Depending on what HPCC you are using, you might want to do this by satellite, or even within a sattelite, split up the imagery into batches of 500.

8. In `ff-import` use `extract.sh` to unarchive the scenes and then use `generate_all.sh` to make the processed images.  

9. Use `ff-filter` for final filtering by color. Make sure to save the rejected and accepted manifests.  

10. Use https://github.com/zooniverse/panoptes-cli to upload new subject set and manifest. Do this from within the `new_for_upload` directory.
     - `panoptes subject-set create 2864 "NAME OF SET"`  
     - check subject set ids with `panoptes subject-set ls -p 2684`
     - `panoptes subject-set upload-subjects SUBJ_SET_ID  manifest.csv`  
     - After this point, you can manage things on the site or...
     - check workflows with `panoptes workflow ls -p 2864`  
     - add new subject set by number `panoptes workflow add-subject-sets workflow_id subj_id`

11. Archive subject set, manifest, and rejected manifest in `archived_uploaded`

#### Output
1. `panoptes project download --generate 2864 classifications.csv`
