%% This code demonstrates the proposed salient region detection algorithm
% This code reads images from 'Input' folder, computes the saliency and
% saves the saliency maps to 'Output' folder
fprintf('Input images are in the directory "Input". \n');
input_dir = dir('Input\');
no_of_images = size(input_dir,1);
img_id = 1;
N = 500;    % Number of superpixels
M_Min = 5; M_Max = 10;  % Number of regions
for n = 1:no_of_images
    if strcmp(input_dir(n).name(end),'g') || strcmp(input_dir(n).name(end),'p')
        tic;
        img = imread(['Input\',input_dir(n).name]); % Reading an image
        [ls, am, sp] = patchSuperpixel(img, N);   % Superpixel segmentation using SLIC superpixels
        [lc, csp, sc] = regionSpectralClustering(ls, sp, am, M_Min, M_Max);  % Region segmentation using spectral clustering
        [salMap] = saliency(sp, csp, ls, sc, am);   % Saliency estimation
        imwrite(salMap, ['Output\',input_dir(n).name(1:end-4),'_PR.png']);  % Writig the output saliency maps
        fprintf('Image %d is processed.\n', img_id);
        img_id = img_id + 1;
        toc;
    end
end

fprintf('Saliency Maps can be found in the directory "Output". \n');