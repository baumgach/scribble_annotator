function [ scribbles ] = freehand_scribble( scan, mask_gt, mask_scribble, graph_title,varargin)
%% AUTHOR: Basil Mustafa (bm490@cam.ac.uk)
% 
% freehand_scribble allows a user to quickly scribble on weak supervision data based off
% a provided ground truth and image 
%
%% USAGE:
%
% inputs:
%       scan    - array of slice images (width, height, slice)
%       mask_gt - the ground truth
%       mask_scribble - the scribble annotation
%
%%OUTPUTS:
%%

%Get scribbles via erosion
erosion_scribble = generateScribbles(mask_gt, 'SliceOrientation', 3, ...
    'ErosionRadii', [0 6 2 14], ...
    'Debug', 0 ...
    );

%default instructions when not scribbling
default_instructions = {'d for next slice'; ...
                        'a for previous slice'; ...
                        'w to create new scribble'; ...
                        's to append to current scribble'; ...
                        'e to reset to erosion scribble';...
                        'r to reset to loaded scribble';};
%initialise variables
new_vals = mask_scribble;
slice_count = size(mask_gt,3);
labels = unique(mask_gt);

%add label for background
if nargin == 5
    %background label has been specified in input
    bg_label = varargin;
    if sum(labels == bg_label) ~= 1
        %mask_gt has no background labelled pixels
        %so append background label
        labels = [labels; bg_label];
    end
else
    %bo background label included
    labels = [labels; max(labels) + 1];
    bg_label = max(labels);
end

%initialise variables
sliceNo = 1;
go_to_previous_slice = false;
lab_idx = 2;        %start from 2 as we're not interested in the 0 label
k_press = ' ';
while sliceNo <= slice_count
    if go_to_previous_slice; sliceNo = sliceNo - 2; lab_idx = numel(labels);go_to_previous_slice = false; end
    
    %Prevent going back to slice that doesn't exist
    if sliceNo < 1; sliceNo = 1; end;
    
    %If mask_scrib has no data, set it to equal the erosion_scribble
    if max(max(max(new_vals(:,:,sliceNo)))) < 1 
        new_vals(:,:,sliceNo) = erosion_scribble(:,:,sliceNo);
    end
    
    %Initialise figure
    h = figure(1);
    set(gcf,'units','normalized','outerposition',[0 0.5 1 0.5]);
    
    %Label, for instructions
    mTextBox = uicontrol('style','text');
    set(mTextBox,'Units','Characters','HorizontalAlignment','Left');
    set(h,'Units','Characters');
    %graph_dims = get(h,'Position');
    set(mTextBox,'String',default_instructions);
    t_dims = get(mTextBox,'Position');
    set(mTextBox,'Position',[t_dims(1), t_dims(2), 35, length(default_instructions)]);
    
    %normalise scan
    i_min = min(min(min(scan(:,:,sliceNo))));
    i_max = max(max(max(scan(:,:,sliceNo))));
    scan(:,:,sliceNo) = (scan(:,:,sliceNo) - i_min)/(i_max - i_min);
    
    %Show actual scan
    subplot(131); 
    imshow(scan(:,:,sliceNo),[0 1]);
    title(['Annotating ' graph_title ' slice ' num2str(sliceNo)]);
    
    %Isolate this slice's ground truth
    ground_truth = mask_gt(:,:,sliceNo);
    
    while lab_idx <= numel(labels)
        if lab_idx < 2; go_to_previous_slice = true; lab_idx = numel(labels); end
        
        if ~go_to_previous_slice 
            current_label = labels(lab_idx);
            %skip if current label not in ground truth
            if current_label == bg_label || or(max(max(max(ground_truth == current_label))),max(max(max(new_vals(:,:,sliceNo)==current_label)))) || k_press == 'a'                 
                %get grayscale of ground truth
                incr = 0.6/ (numel(labels) - 2);
                grayscale = zeros(size(ground_truth));
                for i = 2:numel(labels) - 1
                    grayscale = grayscale + (ground_truth == labels(i))*i*incr;
                end

                %initialise RGB matrix
                rgb = zeros([size(grayscale) 3]);
                for i = 1:3; rgb(:,:,i) = grayscale; end
                grayscale = rgb;

                %current ground truth label appears green
                rgb(:,:,2) = rgb(:,:,2) + (ground_truth == current_label);

                %SHOW GROUND TRUTH
                subplot(132);
                imshow(rgb,[0,1]);
                if current_label == max(labels)
                    %this is background label
                    title(['GROUND TRUTH - BACKGROUND LABEL']);
                else
                    title(['GROUND TRUTH - LABEL ' num2str(current_label)]);
                end

                %SHOW SCRIBBLE PLOT
                subplot(133);

                %faint background of scan
                for i = 1:3; grayscale(:,:,i) = 0.4*scan(:,:,sliceNo); end;

                %Make current scribble 
                grayscale(:, :, 3) =  grayscale(:,:,3)+ (new_vals(:,:,sliceNo) == current_label);
                if current_label == bg_label
                    %if background scribble, we want entire ground truth to be
                    %visible
                    grayscale(:, :, 1) = grayscale(:,:,1) + 0.1*(ground_truth ~=0);
                else
                    %if not background scribble, we only  want current label
                    %ground truth to show up (as green)
                    grayscale(:, :, 2) = grayscale(:,:,2) + 0.1*(ground_truth == current_label);
                end
                imshow(grayscale,[0,1]);
                title('SCRIBBLE');


                %keyboard control
                while waitforbuttonpress == 0; k_press = ' '; end;
                k_press = h.CurrentCharacter;            

                while (k_press ~= 'd') && (k_press~='a') && (k_press~='w') && (k_press~='r') && (k_press~='e') && (k_press~='s')
                    while waitforbuttonpress == 0; k_press = ' '; end;
                    k_press = h.CurrentCharacter;
                end

                %GO PREVIOUS IMAGE
                if k_press == 'a'
                    lab_idx = lab_idx -2;

                %GET USER INPUT
                elseif k_press == 'w' || k_press == 's'
                    %Getting input from user

                    %Set instructions
                    set(mTextBox,'string', {sprintf('SCRIBBLING ON LABEL %s',num2str(current_label)); ...
                                            'Press ESC to cancel'});
                    set(mTextBox,'Position',[t_dims(1), t_dims(2), 35, 2]);

                    %Get freehand scribble
                    c = -1;
                    try
                        c = getPosition(imfreehand('Closed',0));
                        x = c(:,1);
                        y = c(:,2);
                    end

                    %if c still -1, no data was captured from imfreehand
                    if c ~=-1
                        %Clip to fit
                        x(x<1)=1;
                        y(y<1)=1;
                        x(x>size(grayscale,2)) = size(grayscale,2);
                        y(y>size(grayscale,1)) = size(grayscale,1);

                        new_mask = generate_freehand_stroke(x,y,size(grayscale,1),size(grayscale,2),1);
                        %Update old mask
                        old_mask = new_vals(:,:,sliceNo);                       

                        if k_press == 'w'
                            %remove old mask for label if sketching from new
                            old_mask((old_mask == current_label)) = 0;
                        end
                        %Where there are no allocated pixels, insert new mask

                        %N.B. using ground truth as a mask here 
                        if current_label == bg_label
                            %Dealing with background
                            %Cannot scribble over ground truth - different mask
                            old_mask((new_mask~=0) & (ground_truth == 0)) = current_label;    
                        else
                            %Scribble cannot exit ground truth
                            old_mask((new_mask~=0) & (ground_truth == current_label)) = current_label;
                        end
                        new_vals(:,:,sliceNo) = old_mask;

                    end
                    lab_idx = lab_idx - 1;

                    %Reset instructions
                    set(mTextBox,'String',default_instructions);
                    set(mTextBox,'Position',[t_dims(1), t_dims(2), 25, length(default_instructions)]);


                %RESET TO EROSION SCRIBBLE
                elseif k_press == 'e'
                    %Reset to erosion scribble
                    old_mask = new_vals(:,:,sliceNo);
                    old_mask(old_mask == current_label) = 0;
                    old_mask((erosion_scribble(:,:,sliceNo) == current_label)) = current_label;
                    new_vals(:,:,sliceNo) = old_mask;
                    lab_idx = lab_idx - 1;
                %RESET TO LOADED SCRIBBLE
                elseif k_press == 'r'
                    old_mask = new_vals(:,:,sliceNo);
                    old_mask(old_mask == current_label) = 0;
                    old_mask((mask_scribble(:,:,sliceNo) == current_label)) = current_label;
                    new_vals(:,:,sliceNo) = old_mask;
                    lab_idx = lab_idx - 1;
                end
            end
            lab_idx = lab_idx + 1;
        else
            lab_idx = numel(labels) + 1;
        end;
    end
    lab_idx = 2;
    sliceNo = sliceNo + 1;
    
    %Have to close figure to prevent glitch
    %of cursor misalignment with imfreehand scribble
    %close(h);
    %close all
    
end

new_vals(new_vals < 0) = 0;
scribbles = new_vals;
end