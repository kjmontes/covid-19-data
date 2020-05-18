function [quant_to_plot,info] = get_cases_per_area(cases,land_area)

land_area = land_area*3.86102e-7; % convert from SI [m^2] to miles^2
D = size(cases,1); % number of days
quant_to_plot = cases./repmat(land_area,D,1); % cases/sq. mile
min_val = min(quant_to_plot(quant_to_plot~=0),[],'all'); % smallest, not 0
zero_indx = find(quant_to_plot==0); % find where there are no cases
quant_to_plot(zero_indx) = min_val/10; % make '0' be distinct color on log scale

% Provide supplemental info for plotting this quantity
N = 256; % number of distinct colors to use in color map
info = struct();
info.min_limit = min_val/10;
info.max_limit = max(quant_to_plot,[],'all');
info.quant_scale = logspace(log10(info.min_limit/10),log10(info.max_limit),N);
info.scale_type = 'log';
info.replace_min_with_0 = true; % for log scales -> replace min val w/ 0 on colorbar
info.color_map = @parula; % function handle to colormap
info.cbar_fontsize = 14;
info.cbar_label = 'Cases/Sq. Mile';
info.video_name = 'usa_covid19_density.avi';
info.video_type = 'Uncompressed AVI';
