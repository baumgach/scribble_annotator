%% Author: Basil Mustafa (bm490@cam.ac.uk)
% acts as a niifti interface for freehand_scribble.m allowing user to
% annotate scribbles
% it will attempt to make a scribble by eroding ground truth first - 
% erosion code was created by Lisa Koch (lisa.koch@inf.ethz.ch)
% code for reading/writing niifti files

folder_path = '/scratch/bmustafa/datasets/ACDC/ACDC_challenge_20170617/';
addpath('MRI_Toolbox')
%INITIALISE LOOP
%This part will likely need to be redone to match
%Your data
%CHECK LOG FILE
if exist(fullfile(folder_path,'log.txt'))
    done = csvread(fullfile(folder_path,'log.txt'));
    if length(done) > 0
        idx = size(done,1);
        choice = questdlg(sprintf('Annotations recorded up to and including patient %03d frame %02d. Continue or start from scratch?', ...
                                  done(idx,1), done(idx,2)), 'Initialising...','Continue','Start over','Continue');
        switch choice
            case 'Continue'
                if idx > 1
                    if done(idx - 1, 1) == done(idx, 1)
                        %Both frames for final patient were annotated
                        current_patient = done(idx,1) + 1;
                        skip_frame = false;
                    else
                        current_patient = done(idx,1);
                        skip_frame = true;
                    end
                else
                    current_patient = done(idx,1);
                    skip_frame = true;
                end
            otherwise
                current_patient = 1;
                skip_frame = false;
        end
    else
        edit(fullfile(folder_path,'log.txt'));
        current_patient = 1;
        skip_frame = false;
    end
end

while current_patient <=100
    %FIND FILES IN CURRENT PATIENT FOLDER
    patient_path = [folder_path 'patient' num2str(current_patient,'%03d') '/'];
    current_files = dir([patient_path '*gt.nii.gz']);
    
    %skip frame if already done
    if skip_frame
        start_i = 2;
        skip_frame = false;
    else
        start_i = 1;
    end
    
    for i = start_i:numel(current_files)
        %get frame number
        current_frame = str2num(current_files(i).name(17:strfind(current_files(1).name,'_gt.nii.gz') - 1));
        
        %set filenames
        gt_filename = current_files(i).name;
        scan_filename = strrep(gt_filename,'_gt','');
        scrib_filename = strrep(gt_filename,'_gt','_scribble');
        
        %load MRIs
        input_gt = MRIread(fullfile(patient_path,gt_filename));
        input_scan = MRIread(fullfile(patient_path,scan_filename));
        graph_title = ['patient ' num2str(current_patient) ' frame ' num2str(current_frame)];
        
        if exist(fullfile(patient_path,scrib_filename)) == 2
            disp('Found previous scribble file');
            input_scribble = MRIread(fullfile(patient_path,scrib_filename));
            scribbled = freehand_scribble(input_scan.vol,input_gt.vol,input_scribble.vol, graph_title);
        else
            scribbled = freehand_scribble(input_scan.vol,input_gt.vol,zeros(size(input_gt.vol)),graph_title);
        end
        choice = questdlg(sprintf('Scribbling complete for patient %i frame %i - save?',current_patient,current_frame),'Save scribble','Yes','No','No');
        
        switch choice
            case 'Yes'
                MRIwrite(scribbled,fullfile(patient_path,scrib_filename));
                log_file = fopen(fullfile(folder_path,'log.txt'),'a');
                fprintf(log_file,'\n%d,%d',current_patient,current_frame);
                fclose(log_file)
            otherwise
                disp('Not saving');
        end
        clearvars scribbled input_scan input_gt
    end
    current_patient = current_patient + 1;
end