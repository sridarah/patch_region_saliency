%% This code demonstrates the faster variant of the proposed salient region detection algorithm "PFR"
% This code reads images from 'Input' folder, computes the saliency and
% saves the saliency maps to 'Output' folder
fprintf('Input images are in the directory "Input". \n');
input_dir = dir('Input\');
no_of_images = size(input_dir,1);
img_id = 1;
N = 500;    % Number of superpixels
z = 2;  % i.e Number of regions m = 4;
for n = 1:no_of_images
    if strcmp(input_dir(n).name(end),'g') || strcmp(input_dir(n).name(end),'p')
        tic;
        img = imread(['Input\',input_dir(n).name]); % Reading an image
        [ls, am, sp] = patchSuperpixel(img, N);   % Superpixel segmentation using SLIC superpixels
        [lc, csp, sc] = regionUniformSampling(ls, sp, z);  % Uniform region segmentation
        [salMap] = saliency(sp, csp, ls, sc, am);   % Saliency estimation
        imwrite(salMap, ['Output\',input_dir(n).name(1:end-4),'_PFR.png']);  % Writig the output saliency maps
        fprintf('Image %d is processed.\n', img_id);
        img_id = img_id + 1;
        toc;
    end
end

fprintf('Saliency Maps can be found in the directory "Output". \n');