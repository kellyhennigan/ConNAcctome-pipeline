#!/bin/bash

##############################################

# usage: estimate the transform between a subject's t1 and a group template

# written by Kelly MacNiven, Mar 15, 2021

# see here for documentation and examples for using ANTs commands:
# http://manpages.ubuntu.com/manpages/trusty/man1/WarpImageMultiTransform.1.html

########################## DEFINE VARIABLES #############################



# define main directory (this should )
#mainDir=path/to/maindirectory
cd ..
mainDir=$(pwd)
dataDir=$mainDir/data


# anatomical template in mni space
t1_template=$mainDir/templates/mni_icbm152_t1_tal_nlin_asym_09a_brain.nii # %s is data_dir


# define subject's acpc-aligned t1 (subjid will be replaced with subject id)
t1_dir=$dataDir/subjid/t1
t1_acpc=t1_acpc.nii.gz

# subject ids to process (assumes directory structure is dataDir/subjid)
# subjects=('subj001 subj002 subj003')
msg='enter subject ID(s) e.g., subj001 subj002:' 
echo $msg
read subjects
echo you entered: $subjects



############################# RUN IT ###################################


# if ants bin isn't already in the search path, add it here
# export PATH=$PATH:'~/repos/antsbin/bin'))


for subject in $subjects
do
	
	echo WORKING ON SUBJECT $subject

	# subject's t1 directory, acpc-aligned t1, and name for skull-stripped output
	subj_t1_dir=$(echo "${t1_dir/subjid/$subject}")
	cd $subj_t1_dir
	

	# if skull-stripped file doesn't exist, skull-strip the t1
	t1_ss=t1_ns.nii.gz
	if [ ! -f "$t1_ss" ]; then
		3dSkullStrip -prefix ${t1_ss} -input ${t1_acpc}
	fi 	
	
	##########  perform ants coreg command 
	# to do: add checks to see if xform files exist first
	xformstr=t12mni_xform_
	cmd="ANTS 3 -m CC[${t1_template},${t1_ss},1,4] -r Gauss[3,0] -o ${xformstr} -i 100x50x30x10 -t SyN[.25]"
	echo performing this ANTs command to estimate coregistration of native space t1 to template: $cmd	# print it out in terminal 
	eval $cmd	# execute the command
	


	########## apply xform on t1 
	t1_mni=t1_mni.nii.gz
	cmd="WarpImageMultiTransform 3 ${t1_ss} ${t1_mni} ${xformstr}Warp.nii.gz ${xformstr}Affine.txt"
	echo performing this ANTs command to transform native space t1 to template space: $cmd	# print it out in terminal 
	eval $cmd	# execute the command
	


	########## change header to play nice with afni's viewer 
	3drefit -view tlrc -space mni ${t1_mni}
		
	cd $dataDir


	echo DONE WITH SUBJECT $subject

done # subject loop


