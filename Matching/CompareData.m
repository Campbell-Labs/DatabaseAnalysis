function [ h, p, normal ] = CompareData( x, y, paired)
%CompareData Completes a comparison of data to check if data is
%differentiable between subjects. We will complete different statsicial
%studies based off if the data is normal or not or if the data is paired or
%unpaired.

% First we should check if the datasets are normal
if all(~isnan(x)) && all(~isnan(y));
    x_h = kstest(x);
    y_h = kstest(y);
    normal = y_h && x_h;
    
    if paired %&& ~normal
        [p,h] = signrank(x,y);    
    end
    
%     if paired && normal
%         [h,p] = ttest(x,y);    
%     end

    if ~paired && normal
        [h,p] = ttest2(x,y);    
    end

    if ~paired && ~normal
        [p, h] = ranksum(x,y);  
    end
else
    [p,h, normal] = deal(nan);
    
end
