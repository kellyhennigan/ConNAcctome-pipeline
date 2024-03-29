% dti pre-processing script 
% --------------------------------
% usage: this is a script to pre-process dti data using mrVista software.
% 
% calls dtiInit(), which does the following:
% -finds b=0 volumes in dti file (the first 8 volumes),
% motion corrects them all to the first one, 
% and makes a new nii file of mean b=0 volumes.
% - CNI handles eddy-distortion correction, so this default step should be
% turned off 
% - computes a rigid body transform to align the mean b0 nii to the t1 nii
% (note: make sure this t1.nii is ACPC aligned!!) 
% - resamples raw dw data to be aligned with the t1 using a 7th order b-spline interpolation method
% - b-vector directions are reoriented to match the resampled dw data 
% - fits tensor model for each voxel of resampled ACPC?aligned dw data and
% reoriented vectors.  Default method is least squares, but robust tensor
% fitting is supposed to be better ; to do this change fitMethod in
% dwParams from ?ls? to ?rt? (note this takes way longer!  Check to see if 
% it actually makes a difference!)

% see here for more info on pre-processing: 
% http://white.stanford.edu/newlm/index.php/DTI_Preprocessing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define variables, directories, etc.
clear all
close all

mainDir = '/home/span/lvta/dwi_workshop';
scriptsDir = [mainDir '/scripts']; % this should be the directory where this script is located
dataDir = [mainDir '/data']; 


% add scripts to matlab's search path
addpath(genpath(scriptsDir)); % add scripts dir to matlab search path


subjects = {'subj001','subj002','subj003','subj004','subj005'};

dwRawPath=fullfile(dataDir,'%s','raw','dwi.nii.gz'); %s will be subject id
t1Path=fullfile(dataDir,'%s','t1','t1_acpc.nii.gz'); %s will be subject id

%% do it

for i = 1:numel(subjects)
    
    subject = subjects{i};
    
    fprintf(['\npre-processing diffusion data for subject ' subject '...\n']);
    
    
    % define raw diffusion and t1 file names
    dwRawFileName = sprintf(dwRawPath,subject); % filepath to raw dwi nii file
    t1FileName = sprintf(t1Path,subject); % filepath to acpc-aligned t1

    % initialize pre-processing parameters
    dwParams = dtiInitParams;
        % dwParams.fitMethod='rt'
        
        % CNI uses a dual-spin echo sequence that doesn't require eddy
        % correction. Set this to 0 to only do a 6-parameter motion
        % correction.
    dwParams.eddyCorrect=0; 
        
    % re-orient bvecs
    dwParams.rotateBvecsWithCanXform = true;
    
%     if ~exist(dwParams.outDir,'dir')
%         mkdirquiet(dwParams.outDir);
%     end


    % call dtiInit() to do pre-processing: 
    [dt6FileName, outBaseDir] = dtiInit(dwRawFileName,t1FileName,dwParams);
    dt6file=dt6FileName{1}; clear dt6FileName
    [outDir,~]=fileparts(dt6file);    % e.g., dti80trilin
    [~,outStr]=fileparts(outBaseDir); % e.g., dwi_aligned_trilin 
    
    
%% move aligned data from raw to new outDir
% and fix dt6 file structure accordingly

dt=load(dt6file);
movefile([outBaseDir '*'],outDir); movefile([p.subj, '/*b0*'],outDir);
movefile([p.subj, '/dtiInitLog.mat'],outDir);

dt.files.alignedDwRaw = fullfile(outDir,[outStr '.nii.gz']);
dt.files.alignedDwBvecs = fullfile(outDir,[outStr '.bvecs']);
dt.files.alignedDwBvals = fullfile(outDir,[outStr '.bvals']);
save(dt6file,'-struct','dt');


%% check for any WM voxels with negative eigenvalues; if found, set to zero

dt=dtiLoadDt6(dt6file); % note the use of dtiLoadDt6 here instead of just load
[vec,val] = dtiEig(dt.dt6);  badData = any(val<0, 4);   
wmProb=dtiFindWhiteMatter(dt.dt6,dt.b0,dt.xformToAcpc);  badData(wmProb<0.8)=0;  
nBadWMVox=sum(badData(:));   
fprintf(['\nthis subject has ' num2str(nBadWMVox) ...
    ' white matter voxels with negative eigenvalues\n'])
if nBadWMVox>10
%   showMontage(double(badData));
%   resp=input('clip neg values to zero? (should say yes if # is low) ','s');
%   if strcmpi(resp(1),'y')
      dtiFixTensorsAndDT6(dt6file);
%   end
end


%% create FA and diffusivity maps and save them out to dti_proc dir

cd(outDir); cd bin;

[fa,md,rd,ad] = dtiComputeFA(dt.dt6);
% fa(fa>1) = 1; fa(fa<0) = 0;


% load b0 file as a template nii
nii=readFileNifti('b0.nii.gz');
    
% save out fa,md,rd, and ad maps as niftis
out=createNewNii(nii,'fa','fractional anisotropy',fa); writeFileNifti(out);
out=createNewNii(nii,'md','mean diffusivity',md); writeFileNifti(out);
out=createNewNii(nii,'rd','radial diffusivity',rd); writeFileNifti(out);
out=createNewNii(nii,'ad','axial diffusivity',ad); writeFileNifti(out);


%% make file w/bvals and bvecs in format to make mrtrix happy

cd(outDir);
bval_file = dir('*aligned*.bvals');
bvec_file = dir('*aligned*.bvecs');
if numel(bval_file)==1 && numel(bvec_file)==1
    makeMrTrixGradFile(bval_file.name, bvec_file.name, 'bin/b_file');
else
    error('either 0 or more than 1 file found for bvec/val files. Check the input directory before continuing.');
end

%% make a "time series" vector file averaged over white matter 

system('3dmaskave -mask bin/wmMask.nii.gz -quiet -mrange 1 2 dwi_aligned_trilin.nii.gz > wmMask_ts')

fprintf('done.\n\n');

%% Add more QA checks here


end % subjects loop

