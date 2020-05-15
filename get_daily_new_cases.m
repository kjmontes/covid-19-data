function [quant_to_plot,info] = get_daily_new_cases(cases,window_avg)

[D,C] = size(cases); % number of days
cases_Avg = movmean(cases,[window_avg-1,0]); 
change_in_cases = diff(cases_Avg)./cases_Avg(1:end-1,:)*100;
quant_to_plot = [zeros(1,C); change_in_cases];
quant_to_plot(isinf(quant_to_plot))=0; % set change to 0 on first day of cases (lag)
quant_to_plot(isnan(quant_to_plot))=0; % another numerical issue, set to 0 

% Provide supplemental info for plotting this quantity
info = struct();
info.scale_type = 'linear';
info.color_map = @jet;
info.cbar_fontsize = 12;
info.cbar_label = ['% Change in Cases from Previous Day [' ...
        num2str(window_avg) '-day Moving Avg.]'];
info.video_name = 'usa_covid19_changes.avi';
info.video_type = 'Uncompressed AVI';