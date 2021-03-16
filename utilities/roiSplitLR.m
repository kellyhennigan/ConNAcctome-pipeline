function [roiL,roiR] = roiSplitLR(roi,saveOut)
% -------------------------------------------------------------------------
% usage: function to split an ROI into left and right hemisphere rois.
%
% INPUT:
%   roi - nifti roi mask or roi in .mat form
%   saveOut - 1 to save out L and R roi files, otherwise 0. Default is 0. 
%          If saveOut=1 and the roi file is a filepath, then L and R rois
%          will be saved out to the same directory as the roi file. 
%          If saveOut=1 and the input roi file is already loaded, then the 
%          L and R roi files will be saved out to the current working 
%          directory.
%
% OUTPUT:
%   roiL - left hemisphere coords or mask of roi.
%   roiR - right " "
% Will attempt to match input format (either nifti mask or roi coords in
% .mat format).
%
%
% author: Kelly, kelhennigan@gmail.com, 27-Apr-2015

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

% only save out L and R roi files if user requests it
if notDefined('saveOut')
    saveOut = 0;
end


% load roi as mat, regardless of input format
[roi,roiDir,roi_format,roiNii] = roiAsMat(roi);


     

%% do it

%  do different things for .mat vs nifti formats

l_idx=roi.coords(:,1)<0;

fprintf(['\n\n roi has ' num2str(length(find(l_idx))) ' left and ' num2str(length(find(l_idx==0))) ' right voxels.\n\n']);
roiL = dtiNewRoi([roi.name 'L'],[],roi.coords(l_idx,:));
roiR = dtiNewRoi([roi.name 'R'],[],roi.coords(~l_idx,:));


switch roi_format
        
    case 'mat'    % .mat format
    
        if saveOut
            dtiWriteRoi(roiL,fullfile(roiDir,roiL.name), [],'acpc');  % roi, filename, versionNum, coordinateSpace, xform
            dtiWriteRoi(roiR,fullfile(roiDir,roiR.name), [],'acpc');  % roi, filename, versionNum, coordinateSpace, xform
        end
        
        
    case 'nii'    % nifti format
        
        
        imgCoords = mrAnatXformCoords(roiNii.qto_ijk,roi.coords);
        img_idx = sub2ind(size(roiNii.data),imgCoords(:,1),imgCoords(:,2),imgCoords(:,3));
        
        % create new L and R rois
        roiL = createNewNii(roiNii,fullfile(roiDir,[roiL.name '.nii.gz']));
        img_idxL = img_idx(l_idx);
        roiL.data(img_idxL) = 1;
        
        roiR = createNewNii(roiNii,fullfile(roiDir,[roiR.name '.nii.gz']));
        img_idxR = img_idx(~l_idx);
        roiR.data(img_idxR) = 1;
        
        if saveOut
            writeFileNifti(roiL);
            writeFileNifti(roiR);
        end
        
        
end 


