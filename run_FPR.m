%% This code demonstrates the faster variant of the proposed salient region detection algorithm "FPR"
% This code reads images from 'Input' folder, computes the saliency and
% saves the saliency maps to 'Output' folder
fprintf('Input images are in the directory "Input". \n');
input_dir = dir('Input\');
no_of_images = size(input_dir,1);
img_id = 1;
w = 15; % Size of square patch
M_Min = 5; M_Max = 10;  % Number of regions
for n = 1:no_of_images
    if strcmp(input_dir(n).name(end),'g') || strcmp(input_dir(n).name(end),'p')
        tic;
        img = imread(['Input\',input_dir(n).name]); % Reading an image
        [ls, am, sp] = patchUniformSampling(img, w);   % Uniform patch segmentation
        [lc, csp, sc] = regionSpectralClustering(ls, sp, am, M_Min, M_Max);  % Region segmentation using spectral clustering
        [salMap] = saliency(sp, csp, ls, sc, am);   % Saliency estimation
        salMap = imresize(salMap,[size(img,1),size(img,2)]);    % Resize image into original dimension
        imwrite(salMap, ['Output\',input_dir(n).name(1:end-4),'_FPR.png']);  % Writig the output saliency maps
        fprintf('Image %d is processed.\n', img_id);
        img_id = img_id + 1;
        toc;
    end
end

fprintf('Saliency Maps can be found in the directory "Output". \n');