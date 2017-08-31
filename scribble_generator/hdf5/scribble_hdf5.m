%% Author: Basil Mustafa (bm490@cam.ac.uk)
% acts as a HDF5 interface for freehand_scribble.m allowing user to
% annotate scribbles
% it will attempt to make a scribble by eroding ground truth first - 
% erosion code was created by Lisa Koch (lisa.koch@inf.ethz.ch)

%ADJUSTABLE PARAMETERS
hdf_folder = '/scratch/bmustafa/acdc_segmenter_internal/preproc_data/';
hdf_fname = 'data.hdf5';
slices_between_saves = 10;


hdf_path = fullfile(hdf_folder,hdf_fname);
%Get HDF5 info
hdf_info = h5info(hdf_path);

%Find datasets corresponding to image_train, mask_train and scribble_train
images_train = h5read(hdf_path,'/images_train');
masks_train = h5read(hdf_path, '/masks_train');
try
    scribbles_train = h5read(hdf_path,'/scribbles_train');
    disp('Loaded in scribbles_train dataset');
catch
    disp('Could not find scribbles_train dataset - creating now');
    scribbles_train = zeros(size(masks_train));
    h5create(hdf_path,'/scribbles_train',size(masks_train));
    h5writeatt(hdf_path,'/scribbles_train','current_slice',0);
end

%Find scribble_train info
for i = 1:length(hdf_info.Datasets)
    switch hdf_info.Datasets(i).Name
        case 'scribbles_train'
            scribble_index = i;
            break
    end
end
for i = 1:length(hdf_info.Datasets(scribble_index).Attributes)
    switch hdf_info.Datasets(scribble_index).Attributes(i).Name
        case 'current_slice'
            current_slice_attr_index = i;
            break
    end
end

%Get current slice from dataset attribute
current_slice = hdf_info.Datasets(scribble_index).Attributes(current_slice_attr_index).Value;

if current_slice == 0; current_slice = 1; end;

continue_scribbling = true;
while current_slice < size(images_train,3) && continue_scribbling
    if current_slice + slices_between_saves > size(images_train,3)
        slices_between_saves = size(images_train,3) - current_slice + 1;
    end
    end_slice = current_slice + slices_between_saves - 1
    %graph title to display
    graph_title = ['slices ' num2str(current_slice) ' to ' num2str(end_slice)]
    
    %get freehand scribble
%     try
        
        scribbled = freehand_scribble(images_train(:,:,current_slice:end_slice), ...
                                      masks_train(:,:,current_slice:end_slice), ...
                                      scribbles_train(:,:,current_slice:end_slice), ...
                                      graph_title);
%     catch
%         disp(sprintf(['Failed to get freehand scribble - likely just exited early. ' ...
%                      'Progress up to slice %d has been saved.'], current_slice - 1));
%         continue_scribbling = false;
%     end
    
    if continue_scribbling
        %save to hdf5 file
        h5write(hdf_path,'/scribbles_train',scribbled, [1 1 current_slice], [size(images_train,1) size(images_train,2) +slices_between_saves])

        %clearvars scribbled

        current_slice = current_slice + slices_between_saves;

        %update current_slice attribute
        h5writeatt(hdf_path,'/scribbles_train','current_slice',current_slice)
    end
end