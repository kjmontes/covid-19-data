function [quant_to_plot,info] = get_cases_per_area(cases,land_area)

land_area = land_area*3.86102e-7; % convert from SI [m^2] to miles^2
D = size(cases,1); % number of days
quant_to_plot = cases./repmat(land_area,D,1); % cases/sq. mile 

% Provide supplemental info for plotting this quantity
info = struct();
info.scale_type = 'log';
info.color_map = @parula;
info.cbar_fontsize = 14;
info.cbar_label = 'Cases/Sq. Mile';
info.video_name = 'usa_covid19_density.avi';
info.video_type = 'Uncompressed AVI';
