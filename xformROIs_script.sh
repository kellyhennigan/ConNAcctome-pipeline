#!/bin/bash

##############################################

# usage: use ANTs to apply estimated transforms to 
# put an atlas ROI in a subject's native space. 

# this script assumes that the script, t12template_ANTs_script has 
# already been run. That script saves out the estimated affine & warp 
# transforms to best align a subject's native space t1 to a 
# template in group space. 

# assuming you have an ROI mask in that group space, this script 
# will apply the inverse of the previously estimated xforms to 
# put the desired ROI mask into native space. 

# see here for documentation and examples for using ANTs commands:
# http://manpages.ubuntu.com/manpages/trusty/man1/WarpImageMultiTransform.1.html


# written by Kelly MacNiven, Mar 15, 2021


########################## DEFINE VARIABLES #############################



# define main directory (this should )
#mainDir=path/to/maindirectory
cd ..
mainDir=$(pwd)
dataDir=$mainDir/data


# anatomical template in mni space
atlasROIDir=$mainDir/templates
atlasROIMasks=('PauliAtlasDAL.nii.gz PauliAtlasDAR.nii.gz')


# define subject's acpc-aligned t1 (subjid will be replaced with subject id)
refFilepath=$dataDir/subjid/t1/t1_acpc.nii.gz

# define paths to xforms to be applied (subjid will be replaced with subject id)
xformAffPath=$dataDir/subjid/t1/t12mni_xform_Affine.txt
xformInvWarpPath=$dataDir/subjid/t1/t12mni_xform_InverseWarp.nii.gz


# directory to save out xformed ROIs (subjid will be replaced with subject id)
outDir=$dataDir/subjid/ROIs


# subject ids to process (assumes directory structure is dataDir/subjid)
# subjects=('subj001 subj002 subj003')
msg='enter subject ID(s) e.g., subj001 subj002:' 
echo $msg
read subjects
echo you entered: $subjects



############################# RUN IT ###################################


# add ants path to search path
# export PATH=$PATH:'+os.path.join(os.path.expanduser('~')+'/repos/antsbin/bin'))

for subject in $subjects
do
	
	echo WORKING ON SUBJECT $subject

	for atlasROI in $atlasROIMasks
	do

		inFile=$atlasROIDir/$atlasROI

		outFile=$(echo "${outDir/subjid/$subject}/$atlasROI")

		refFile=$(echo "${refFilepath/subjid/$subject}")

		xformAff=$(echo "${xformAffPath/subjid/$subject}")

		xformInvWarp=$(echo "${xformInvWarpPath/subjid/$subject}")
	
		cmd="WarpImageMultiTransform 3 ${inFile} ${outFile} -R ${refFile} -i ${xformAff} ${xformInvWarp}"
		echo $cmd	# print it out in terminal 
		eval $cmd	# execute the command
	
	done 

	echo DONE WITH SUBJECT $subject

done # subject loop


