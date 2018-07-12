%% This code implements salient region detection using patch and region image abstractions
%
% Input:    sp - Patch attribute structure array with fields:
%                   L  - Mean L* value
%                   a  - Mean a* value
%                   b  - Mean b* value
%                   r  - Mean row value
%                   c  - Mean column value
%           csp - clustered patches
%           ls - labelled patches in image
%           sc - labels of patches
%           am - adjacency matrix of neighbouring patches
%
% Output:   saliency_map - Saliency map
%           
function [saliency_map] = saliency(sp, csp, ls, sc, am)
N = length(sp);    % Number of patches
M = length(csp); % Number of regions
patch_color = zeros([N,3]); % Creating a vector to represent color each patch (L,a,b)
patch_location = zeros([N,2]); % Creating a vector to represent color each patch (x,y)

% Assigning color values and location to a vector
for i = 1 : N
    patch_color(i,1) = sp(1,i).L;    patch_color(i,2) = sp(1,i).a;     patch_color(i,3) = sp(1,i).b;
    patch_location(i,1) = sp(1,i).r;     patch_location(i,2) = sp(1,i).c;
end;

% Region prototyping using mediation
region_proto_color = zeros([M,3]); region_proto_location = zeros([M,2]);    % Color and location of region prototypes

region_color_sp = int32(M);   % indicates the color of prototype patch of a region
region_location_sp = int32(M);   % indicates the center of prototype patch of a region
for i = 1 : M
    col_distance = zeros([length(csp{1,i}),length(csp{1,i})]);
    loc_distance = zeros([length(csp{1,i}),length(csp{1,i})]);
    col_dist_selection = zeros([length(csp{1,i}),2]);
    loc_distance_selection = zeros([length(csp{1,i}),2]);
    % Calculate distance
    for j = 1 : length(csp{1,i})
        for k = 1 : length(csp{1,i})
        col_distance(j,k) = norm(patch_color(csp{1,i}(j),:) - patch_color(csp{1,i}(k),:)); % color distance
        loc_distance(j,k) = norm(patch_location(csp{1,i}(j),:) - patch_location(csp{1,i}(k),:)); % location distance
        end
    end
    temp1=sum(col_distance,2); % Summing up the rows to calculate the overall color distance of each patch
    cum_contrast=sum(loc_distance,2); % Summing up the rows to calculate the overall location distance of each patch
    for j = 1 : length(csp{1,i})
        col_dist_selection(j,1) = csp{1,i}(j);
        col_dist_selection(j,2) = temp1(j);
        loc_distance_selection(j,1) = csp{1,i}(j);
        loc_distance_selection(j,2) = cum_contrast(j);
    end
    col_dist_selection = sortrows(col_dist_selection, 2); % Sorting in acending order to find the patch with minimum color distance
    region_color_sp(i)=int32(col_dist_selection(1,1));   % Select color prototype patch i.e. the first element
    loc_distance_selection = sortrows(loc_distance_selection, 2); % Sorting in acending order to find the patch with minimum location distance
    region_location_sp(i)=int32(loc_distance_selection(1,1));   % Select location prototype patch i.e. the first element
end
for i = 1 : M
    region_proto_color(i,1)=patch_color(region_color_sp(i),1); % L
    region_proto_color(i,2)=patch_color(region_color_sp(i),2); % a
    region_proto_color(i,3)=patch_color(region_color_sp(i),3); % b
    region_proto_location(i,:)=patch_location(region_location_sp(i),:); % Location Coordinates [x,y]
end

% Color Contrast Cue Estimation
sp_rg_global_contrast = zeros([N, M-1]);
sp_rg_global_distance = zeros([N, M-1]);
contrast_contrast_cue = zeros([N,1]); % Color contrast cue of a patch

for i = 1 : N
    k = 1;
    for j = 1 : M
        if(sc(i)~=j)
            sp_rg_global_contrast(i,k) = norm(patch_color(i,:) - region_proto_color(j,:)); % color contrast to other regions
            sp_rg_global_distance(i,k) = norm(patch_location(i,:) - region_proto_location(j,:)); % Distance to other regions
            k = k+1;
        end
    end
end
% Normalizing the global contrast and distance values
    minval=min(sp_rg_global_contrast);   maxval=max(sp_rg_global_contrast);
    maxdim=max(size(ls));   % Maximum dimension of an image
beta1 = 2;
for i = 1 : N
    for j = 1 : M-1
        sp_rg_global_contrast(i,j) = (sp_rg_global_contrast(i,j)-minval)/(maxval-minval);
        sp_rg_global_distance(i,j) = sp_rg_global_distance(i,j)/maxdim;
        temp1(i,j) = (length(csp{1,j})/N)*(exp(-sp_rg_global_distance(i,j)*beta1))*sp_rg_global_contrast(i,j);
    end
end
    contrast_contrast_cue=sum(temp1,2); % Global contrast of each patch

contrast_contrast_cue(:) = (contrast_contrast_cue(:)-min(contrast_contrast_cue))/(max(contrast_contrast_cue)-min(contrast_contrast_cue)); % Normalization

% Color Distribution Cue Estimation
sp_rg_mean_position =  zeros([N, 2]); % Store mean position of color of a patch
color_distribution_cue = zeros([N,1]); % Color distribution cue

% Compute mean position of each patch wrt region prototypes
beta2=8; tempx=[]; tempy=[];
for i = 1 : N
    k = 1;
    for j = 1 : M
        if(sc(i)~=j)
        tempx(k) = (exp(-sp_rg_global_contrast(i,k)*beta2))*region_proto_location(j,1);
        tempy(k) = (exp(-sp_rg_global_contrast(i,k)*beta2))*region_proto_location(j,2);
        k = k+1;
        end
    end
    sp_rg_mean_position(i,1) = sum(tempx(:))/(M-1); % Mean x position
    sp_rg_mean_position(i,2) = sum(tempy(:))/(M-1); % Mean y position
end

% Compute color distribution of each patch wrt region prototypes
temp = zeros(N,M-1);
for i = 1 : N
    k = 1;
    for j = 1 : M
        if(sc(i)~=j)
        temp(i,k) = (length(csp{1,j})/N)*(norm(region_proto_location(j,:)-sp_rg_mean_position(i,:))/maxdim)*(exp(-sp_rg_global_contrast(i,k)*beta2)); % color distribution
        k=k+1;
        end
    end
end
color_distribution_cue = sum(temp,2); % Cumulative color distribution of each patch

color_distribution_cue(:) = (color_distribution_cue(:)-min(color_distribution_cue))/(max(color_distribution_cue)-min(color_distribution_cue));
color_distribution_cue(:) = (1-color_distribution_cue(:));

% patch Saliency Assignment
saliency_cue = zeros([N,1]);
saliency_cue = contrast_contrast_cue.*color_distribution_cue; % Multiplicative Fusion
saliency_cue(:) = (saliency_cue(:)-min(saliency_cue))/(max(saliency_cue)-min(saliency_cue)); % Normalization

% Saliency refinement
[nei sp_id] = find(am);   % 'nei' stores neighbours and 'sp_id' stores patch ids
mu = 0.2;   % Refinement parameter
max_thr = 1-mu; min_thr = mu;
refined_saliency_cue = zeros([N,1]);
for i = 1 : N
    avg_nei_sal = mean(saliency_cue(nei(sp_id==i)));
    
    if(avg_nei_sal>=max_thr && saliency_cue(i)<=max(saliency_cue(nei(sp_id==i))))
        refined_saliency_cue(i) = max(saliency_cue(nei(sp_id==i)));
    elseif(avg_nei_sal<=min_thr && saliency_cue(i)>=min(saliency_cue(nei(sp_id==i))))
        refined_saliency_cue(i) = min(saliency_cue(nei(sp_id==i)));
    else
        refined_saliency_cue(i) = saliency_cue(i);
    end
end
saliency_cue = refined_saliency_cue; % Refined saliency cue assignment

% Incorporation of center prior
height = size(ls,1); width = size(ls,2);    % Image dimensions
center_prior_cue = zeros([N,1]); % Center prior value
center_position = [height/2,width/2];   % Center of image
sigma2 = min(height,width)/2.5;
for i = 1:N
        d = norm(patch_location(i,:)-center_position);
        center_prior_cue(i) = exp(-d^2/(2*sigma2^2));
end
saliency_cue = saliency_cue.*center_prior_cue;  % Fusing refined saliency with center prior
saliency_cue(:) = (saliency_cue(:)-min(saliency_cue))/(max(saliency_cue)-min(saliency_cue));   % Normalization

% Saliency assignment
saliency_map = ls;  % Initializing saliency map
for i = 1 : N  
    saliency_map(saliency_map==i) = saliency_cue(i);    % Pixel accurate saliency assignment
end
end