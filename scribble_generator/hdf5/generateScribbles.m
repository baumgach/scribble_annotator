function [ scribbles ] = generateScribbles( gt, varargin )
%generateScribbles 
%	
%   Created by lkoch, 2015-07-22
%   


% Input validation
if nargin < 1
    error('Function requires at least one input.');
end

if numel(size(gt))~=3
    error('Label image should be 3-dimensional.');
end

options = struct( ...
    'SliceOrientation', 3, ...
    'Labels', unique(gt), ...
    'ErosionRadii', 1 * ones(size(unique(gt))), ...
    'Debug', 0 ...
    );

optionNames = fieldnames(options);

nArgs = length(varargin);
assert(round(nArgs/2)==nArgs/2, 'createPartialLabelImage needs propertyName/propertyValue pairs');

for pair = reshape(varargin,2,[]) % pair is {propName;propValue}
    
    if any(strcmp(pair{1},'SliceOrientation')) && ismember(pair{2},[1 2 3])        
        options.(pair{1}) = pair{2};
                                        
    elseif any(strcmp(pair{1},optionNames))
        % overwrite options. If you want you can test for the right class here
        % Also, if you find out that there is an option you keep getting wrong,
        % you can use "if strcmp(inpName,'problemOption'),testMore,end"-statements
        options.(pair{1}) = pair{2};
        
    else
        error('%s is not a recognized parameter name',pair{1})
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. for each slice, for each label: erode label map
% 2. stitch together. Unlabelled regions denoted by -1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sizeL = size(gt);
labels = unique(gt);

scribbles = zeros(size(gt));

er = strrep(num2str(options.ErosionRadii),'  ','_'); %for printing output
for sliceNo=1:sizeL(options.SliceOrientation)
    
    if options.SliceOrientation == 1        
        slice = gt(sliceNo,:,:);        
    elseif options.SliceOrientation == 2
        slice = gt(:,sliceNo,:);
    elseif options.SliceOrientation == 3
        slice = gt(:,:,sliceNo);
    end
    
    slice = double(slice);
    erodedSlice = zeros * ones(size(slice));
    
    % erode for each label separately.
    for lab_idx=1:numel(labels)
        
        labelNo=labels(lab_idx);        
        labelmap = slice==labelNo;
        
        if options.Debug>1
            figure();
            imshow(labelmap)
        end
        labelmap = imerode(labelmap,strel('disk',options.ErosionRadii(lab_idx)));

        if options.Debug>1
            pause(.2)
            imshow(labelmap)
            pause(.2)
        end           
        
        % watch out, scribbles is 3d..
        scribbles(labelmap==1) = labelNo;
        
        erodedSlice(labelmap==1) = labelNo;
                        
    end

    if options.SliceOrientation == 1
        scribbles(sliceNo,:,:) = erodedSlice;
    elseif options.SliceOrientation == 2
        scribbles(:,sliceNo,:) = erodedSlice;
    elseif options.SliceOrientation == 3
        scribbles(:,:,sliceNo) = erodedSlice;
    end
    
    if options.Debug>0
        h = figure;set(h, 'Visible', 'off');
        subplot(131)
        imshow(slice, [0 max(labels)])
        subplot(132)
        imshow(erodedSlice, [0 max(labels)])
        subplot(133)
        imshow(slice-erodedSlice, [-max(labels) max(labels)])
        clear tmpslice
        %pause(1)
        print(strcat('outputs/slice_',num2str(sliceNo),'/slice_',num2str(sliceNo),'_erosion',er),'-dpng')
        clf;
    end
    
end

    
end

