
% script to plot publication-quality figures of fiber groups with
% anatomical underlay. Note that the plotting parameters are very
% tract-specific, so feel free to tinker with the params to make it most
% suitable to a project's needs. 

% also note that you can get different figure views by rotating the figure
% window around with your cursor! Try that out to get a better sense of
% what you're looking at. 

% this example plots 2 fiber groups: 1 going from the midbrain to NAcc
% below the anterior commissure (consistent with the trajectory of the
% medial forebrain bundle) and another group going above the anterior
% commissure. 

% plot fiber groups in the left hemisphere. 


% define variables, directories, etc.
clear all
close all

% mainDir = '/home/span/lvta/dwi_workshop';
mainDir = '/Users/kelly/repos';
scriptsDir = [mainDir '/spantracts_DWIworkshop']; % this should be the directory where this script is located
dataDir = [mainDir '/data']; 


% add scripts to matlab's search path
path(path,genpath(scriptsDir)); % add scripts dir to matlab search path


subjects = {'subj001'};


% dir to save output files
outDir = fullfile(mainDir,'figures','fgs_single_subs');



% where to find subjects t1 file to plot
t1Path = fullfile(dataDir,'%s','t1','t1_fs.nii.gz'); % %s is subject id


fgDir = fullfile(dataDir,'%s','fibers');


% cell array specifying which fiber files to plot; files should be located
% in directory, fgDir
fgFiles = {'DAL_naccL_belowAC_autoclean.pdb';
    'DAL_naccL_aboveAC_autoclean.pdb'};

% RGB colors; should be in a cell array corresponding to fgFiles
cols = {[0.9333    0.6980    0.1373];
    [0.9569    0.3961    0.0275]};
  
% string identifying what fiber groups are being plotted
outStr = ['DA_NAcc_2fgs'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% some useful plot params, change as desired
scsz=get(0,'Screensize');
plotTubes = 1;  % plot fiber pathways as tubes or lines?
fg_rad = .2;   % radius of fiber pathway tubes (only matters if plotTubes=1)
nfibers=100;


%%

if ~exist(outDir,'dir')
    mkdir(outDir)
end

cd(dataDir);

i=1;
% for i = 1:numel(subjects)
    % for i = 1:5
    
    % close any open figures 
    close all
    
    subject = subjects{i};
    
    fprintf('\n\nworking on subject %s...\n',subject);
    
    %load t1
    t1 = niftiRead(sprintf(t1Path,subject));
    
    % Rescale image values to get better gary/white/CSF contrast
    img = mrAnatHistogramClip(double(t1.data),0.3,0.99);
    t1.data=img;
    
    
    % load fiber groups
    for j=1:numel(fgFiles)
        fg{j} = fgRead([sprintf(fgDir,subject) '/' fgFiles{j}]);
    end
    
    
    
    %%   PLOT FIBER GROUPS
    
    
    sh=AFQ_RenderFibers(fg{1},'color',cols{1},'numfibers',nfibers,'tubes',plotTubes,'radius',fg_rad);
    delete(sh); % delete light object (for some reason this needs to be deleted from the first FG plotted to look good...
    fig = gcf;
    pos=get(fig,'position');
    set(fig,'Position',[scsz(3)-610 scsz(4)-610 600 600])
    %   llh = lightangle(vw(1),vw(2));
    
    % this command makes the image fill the entire figure window:
    %    set(gca,'Position',[0,0,1,1]);
    
    set(gca,'fontName','Helvetica','fontSize',12)
    
    % now plot the remaining fiber groups
    for j=2:numel(fgFiles)
        sh=AFQ_RenderFibers(fg{j},'color',cols{j},'numfibers',nfibers,'tubes',plotTubes,'radius',fg_rad,'newfig',0);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% SAGITTAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%% left
    
    % view for left fibers
    vwL = [270,0];
    
    h=AFQ_AddImageTo3dPlot(t1,[1, 0, 0],'gray');
    
    % get whole brain axes limits
    zl=zlim;
    yl=ylim;
    
    view(vwL);
    
    % save out left fibers whole-brain figure
    print(gcf,'-dpng','-r300',fullfile(outDir,[subject '_' outStr '_wholebrain_leftsagittal']));
    
    % change axis on y and zlims to close-up
    zlim(gca,[-50,50])
    ylim(gca,[-50,50])
    
    print(gcf,'-dpng','-r300',fullfile(outDir,[subject '_' outStr '_leftsagittal']));
    
      
    % go back to whole brain view 
    zlim(gca,zl)
    ylim(gca,yl)
  
    
    % if desired, you can delete the sagittal underlay slice like so: 
%     delete(h) % delete that slice
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% CORONAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    vwC = [0,0]; % coronal view
    
    h=AFQ_AddImageTo3dPlot(t1,[0, 5, 0],'gray');
    view(vwC);
    
    % at this point, try rotating the figure around with your cursor -
    % check it out! 
    
    %   llh = lightangle(vwC(1),vwC(2));
    
    set(gca,'fontName','Helvetica','fontSize',12)
    
    print(gcf,'-dpng','-r300',fullfile(outDir,[subject '_' outStr '_wholebrain_coronal']));
    
    % change axis on x and zlims
    xlim(gca,[-40,40])
    zlim(gca,[-40,40])
    
    print(gcf,'-dpng','-r300',fullfile(outDir,[subject '_' outStr '_coronal']));
    
    fprintf('done.\n\n');
    
    
    %
    %      camlight(sh.l,'left');
    %   print(gcf,'-dpdf','-r600','naccR_corr_light')
    
% end % subjects