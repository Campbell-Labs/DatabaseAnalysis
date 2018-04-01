function [ h ] = bar3_stacked( x )
%   Input: 3 dimensional matrix
%   Output: None

width = size(x,1);
length = size(x,2);
depth = size(x,3);

newplot = figure;

for i = 1:width
    % Grab the first "slice of bars"
    for j = 1:depth
        y(j,1:length) = x(i,1:length,j);
    end

    y=y';
    
    figure(newplot);
    hold on;
    h = bar3(y,'stacked');
    newplot_gca = get(newplot,'children');
    plotdata = get(newplot_gca,'children');
    
    % Shift all the bars by 1 in order to make room for the next "slice"
    for j = 1:size(plotdata,1)
        xdat = get(plotdata(j),'xdata');
        xdat = xdat+1;
        set(plotdata(j),'xdata',xdat);
    end
    clear y;
end

view(3);