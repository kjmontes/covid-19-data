function colorIndx = get_colorIndx(q,q_scale,scale_type)
% GET_COLORINDX Local function that returns appropriate colormap index
%   for each value in q, using the color scale in q_scale
    if isrow(q) & isrow(q_scale)
        a = repmat(q_scale',1,length(q));
        b = repmat(q,length(q_scale),1);
        if strcmp(scale_type,'log')
            [~,colorIndx] = min(abs(log10(a)-log10(b))); 
        elseif strcmp(scale_type,'linear')
            [~,colorIndx] = min(abs(a-b));
        end
    else
        disp('Both q and q_scale must be row vectors!')
        color_Indx = NaN(size(q));
    end
end