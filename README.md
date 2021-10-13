# ConNAcctome processing pipeline 

Brain regions communicate via long-range axonal connections, referred to as "white matter" because they are covered in fatty (myelin) sheaths that allow for faster communication. Diffusion-weighted imaging allows us to quantify some of the structural properties of these connections. This repository describes a pipeline for getting these structural measurements for tracts of interest, starting from raw diffusion-weighted imaging data. 

This pipeline focuses on identifying the **"ConNAcctome"**: white matter tracts in the brain that project to the Nucleus Accumbens (NAcc) from: 1) the dopaminergic midbrain, 2) anterior insula, 3) amygdala, and 4) medial prefrontal cortex. 

This code is based heavily on Josiah's tractography pipeline, which is well-documented here: https://github.com/josiahkl/spantracts

*to do: add Citations for these methods: Leong et al., 2016, 2018; MacNiven et al., 2020*


## Getting started


### Software requirements 

* [Python 2.7](https://www.python.org/)
* [Matlab](https://www.mathworks.com/products/matlab.html)
* [matlab package, VISTASOFT](https://github.com/vistalab/vistasoft) 
* [matlab package, spm (as a VISTASOFT dependency)](https://www.fil.ion.ucl.ac.uk/spm/) 
* [matlab package, AFQ](https://github.com/yeatmanlab/AFQ)
* [mrtrix 3.0](http://www.mrtrix.org/) 
* [freesurfer](https://surfer.nmr.mgh.harvard.edu/) 
* [ANTs (coregistration software)](http://stnava.github.io/ANTs/)

### Directory structure 

Pipeline assumes that the scripts in this repo sit in a "scripts" folder with following directory structure:

![directory structure](spantracts_directorystructure.png)

Additional project-specific scripts can be housed in the "scripts" directory as well. 

### Permissions

make sure the user has permission to execute scripts. From a terminal command line, cd to the scripts directory. Then type:
```
chmod 777 *sh
chmod 777 *py
```
to be able to execute them. This only needs to be run once. 


### Paths

make sure matlab has access to all the relevant paths for running this pipeline. Before running a matlab script, at the matlab command line, type: 
```
addpath(genpath('path/to/directory/with/matlab/scripts'))

```
where 'path/to/directory/with/matlab/scripts' is, e.g., 'projectdir/scripts'. 


## Pipeline (#pipeline)

- [raw data files and format](#raw-data-files-format)
- [Acpc-align t1 data](#acpc-align-t1-data)
- [Run freesurfer recon](#run-freesurfer-recon)
- [Convert freesurfer files to nifti](#convert-freesurfer-files-to-nifti)
- [Create ROI masks](#create-roi-masks)
- [Pre-process diffusion data](#pre-process-diffusion-data)
- [Mrtrix pre-processing steps](#mrtrix-pre-processing-steps)
- [fiber tractography](#track-fibers)
- [Clean fiber bundles](#clean-fiber-bundles)
- [Visualization](#Visualization)
- [Save out measurements from fiber bundles cores](#save-out-measurements-from-fiber-bundles-cores)
- [Correlate diffusivity measures with behavioral and functional measures](#correlate-diffusivity-measures-with-behavioral-and-functional-measures)
- [Quality Assurance checks](#QA)


### Acpc-align t1 data
In matlab, run:
```
mrAnatAverageAcpcNifti
```
Use GUI to manually acpc-align t1 data 

#### output
Save out acpc-aligned nifti to **projectdir/data/t1/t1_acpc.nii.gz**. 


### Run freesurfer recon
From terminal command line, cd to dir with subject's acpc-aligned t1 and run: 
```
recon-all -i t1_acpc.nii.gz -subjid subjid -all
```
This calls freesurfer's recon command to segment brain tissue

#### output
Saves out a bunch of files to directory, **/usr/local/freesurfer/subjects/subjid**.



### Convert freesurfer files to nifti 
In matlab, run:
```
convertFsSegFiles_script.m
```
To convert freesurfer segmentation files to be in nifti format.

#### output
Saves out converted freesurfer segmentation files to directory, **projectdir/data/subjid/t1**



### Create ROI masks
Its time to create ROI masks that will be used for tractgraphy. To save out ROIs that are based on freesurfer segmentation, in matlab, run:
```
createRoiMasks_script.m
```
To save out desired ROI masks based on FS segmentation labels. For example, save out NAcc, amygdala, and insula ROIs.  


To save out ROI masks that are atlas-based, we need to first estimate the transform that will align a subject's brain to the atlas template. The inverse transform can then be applied to move an atlas ROI to a subject's native space. To do this, from the terminal command line, run: 
```
t12mni_ANTS_script.py
```
and then in matlab, run:
```
xformROIs_script.m
```
We use this pipeline to create a midbrain dopaminergic ROI in each subject's native space that is based on the CIT168 atlas (Pauli et al., 2018) which combines the following labels (all dopaminergic regions): VTA, SNc, and PBP. 


Finally, you can create an ROI sphere that's based on coordinates. For example, to create an 8 mm diameter sphere ROI mask centered on coordinates (+/-4, 45, 4; Leong et al., 2016) in the medial prefrontal cortex, run: 
```
[add mpfc roi script here]
```

#### output
Desired ROI masks are saved out to **projectdir/data/subjid/ROIs** in nifti format. 


At this point, you should have ROI masks that will be used for tractography. **Make sure these look as you expect!!** To check that, load a subject's anatomy (t1.nii.gz) and ROI masks into your viewer of choice (e.g., ITKSnap, MRIcron, afni, FSL's viewer, or mrtrix's viewer, mrview) and confirm that the masks align nicely to the regions you care about. 

### Pre-process diffusion data
In Matlab, run:
```
dtiPreProcess_script
```
To do vistasoft standard pre-processing steps on diffusion data. 

#### output
Saves out files to directory, **projdir/data/subjid/dti96trilin**




### mrtrix pre-processing steps 
From terminal command line, run:
```
python mrtrix_proc.py
```
This script: 
* copies b_file and brainmask to mrtrix output dir
* make mrtrix tensor file and fa map (for comparison with mrvista maps and for QA)
* estimate response function using lmax of 8
* estimate fiber orientation distribution (FOD) (for tractography)

#### output
Saves out files to directory, **projectdir/subjid/dti96trilin/mrtrix**. 



### Track fibers
From terminal command line, run:
```
python mrtrix_fibertrack.py
```
tracks fiber pathways between 2 ROIs with desired parameters 

#### output
Saves out files to directory, **projectdir/data/subjid/fibers/dti96trilin/mrtrix**


### Clean fiber bundles
In matlab:
```
cleanFibers_script
```
uses AFQ software to iteratively remove errant fibers 

#### output
Saves out fiber group files to directory, **projectdir/data/subjid/fibers**

Also saves out images of pruned fiber bundles for QA purposes, for example: 
![Alt text](jj190821.png?raw=true "example subject's MFB after pruning")

Note that the figure windows in matlab can be rotated with user's cursor to visualize fiber bundle from all angles. 


### Visualization
Finally, visualize the fiber bundles you worked so hard to find! In matlab:
```
plot_singlesub_fgs_script
```
uses AFQ software to plot fiber bundles with a subject's anatomy as an underlay. This script contains a lot of hard-coded plotting parameters that are good for visualizing the medial forebrain bundle. I suggest using it as a example of how to use the AFQ plotting functions and you can take it from there. 

#### output
This script creates figures like this: 
![Alt text](subj001_DA_NAcc_2fgs_wholebrain_leftsagittal.png?raw=true "example subject's left DA to Nacc fiber bundles, wholebrain view")
![Alt text](subj001_DA_NAcc_2fgs_leftsagittal.png?raw=true "example subject's left DA to Nacc fiber bundles, close-up")

Note that the figure windows in matlab can be rotated with user's cursor to visualize fiber bundle from all angles. 


### Save out measurements from fiber bundles cores
In matlab:
```
dtiSaveFGMeasures_script  
dtiSaveFGMeasures_csv_script
```

#### output
script, dtiSaveFGMeasures_csv_script saves out a csv file with desired diffusion measurements (fa, md, ad, rd) for each subject. 


### Correlate diffusivity measurements with personality and/or fMRI measures, e.g., impulsivity scores:
In matlab:
```
add scripts here...
```

### Quality Assurance (QA)
Quality assurance checks should always be performed on data. Some common issues that can go wrong: 

#### bad co-registration
In a viewer, load subject's co-registered anatomy and B0 volumes (files "t1.nii.gz" and "B0.nii.gz"). These should be reasonably aligned. If they aren't, it means that ROI masks (defined based on anatomy) won't be well-aligned to the diffusion data, which could cause problems, especially for small ROIs. 

#### bad head motion
In matlab, run: 
```
doQA_subj_script.m
```
and then: 
```
doQA_group_script.m
```
to save out figures showing head motion. Figures saved out to **projdir/figures/QA/dwi**. These can be used to determine whether a subject should be excluded due to bad motion. 

#### tractography issues
Tractography can fail for a number of reasons: bad ROI mask alignment, bad alignment of the brain mask used to constrain tractography, or noisy data, to name a few. Check the number of fibers output from the mrtrix tractography step with the following terminal command: 
```
tckinfo [name of .tck file]
```
which will print out some info into the terminal window; the # of tracks is the "count" variable. 








