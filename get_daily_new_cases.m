function [quant_to_plot,info] = get_daily_new_cases(cases,window_avg)

[D,C] = size(cases); % number of days
cases_Avg = movmean(cases,[window_avg-1,0]); 
change_in_cases = diff(cases_Avg)./cases_Avg(1:end-1,:)*100;
quant_to_plot = [zeros(1,C); change_in_cases];
quant_to_plot(isinf(quant_to_plot))=0; % set change to 0 on first day of cases (lag)
quant_to_plot(isnan(quant_to_plot))=0; % another numerical issue, set to 0 

% Provide supplemental info for plotting this quantity
N = 256; % number of distinct colors to use in color map
info = struct();
info.max_limit = prctile(quant_to_plot,98,'all'); % omit outliers from color scale
info.min_limit = -info.max_limit; % impose color scale symmetry, so that middle color = 0% change
info.quant_scale = linspace(info.min_limit,info.max_limit,N);
info.scale_type = 'linear';
info.color_map = @jet; % function handle to colormap
info.cbar_fontsize = 12;
info.cbar_label = ['% Change in Cases from Previous Day [' ...
        num2str(window_avg) '-day Moving Avg.]'];
info.video_name = 'usa_covid19_changes.mp4';
info.video_type = 'MPEG-4';