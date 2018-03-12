function [] = DataGraph( dbts, polarization_names, output_directory)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Inside that directory, the subdirectories of graphs
scatter_directory = fullfile(output_directory, 'Scatter');
boxplot_directory = fullfile(output_directory, 'BoxPlot');
mkdir(scatter_directory)
mkdir(boxplot_directory)

%Find largest number of samples in subject
%Pretty brute force approach
max_samples = 0;
for diag_index = 1:length(dbts)
    local_max = height(dbts(diag_index).table);
    if max_samples < local_max;
        max_samples = local_max;
    end
end

for pol_prop_index = 1:length(polarization_names)
    polarization_str = char(polarization_names{pol_prop_index});
    [values, x_values, g_values] = deal(NaN(max_samples, 3));
    for diag_index = length(dbts):-1:1
        samples = height(dbts(diag_index).table);
        x = 1:samples;
        values(1:samples, diag_index) = dbts(diag_index).table.(polarization_str);
        x_values(1:samples, diag_index) = x;
        g_values(1:samples, diag_index) = diag_index;
    end
    gscatter(x_values(:), values(:), g_values(:));
    xlabel('Deposits');
    title(strrep(polarization_str,'_',' '));
    legend({dbts.name});
    print([scatter_directory, '\Scatter_', polarization_str ],'-dpng')
    close
    h = boxplot(values, 'Labels', {dbts.name});
    title(strrep(polarization_str,'_',' '));
%%% 
set( gca                       , ...
    'FontName'   , 'Helvetica',...
'XDir','reverse');
%%%
    
    print([boxplot_directory, '\BoxPlot_', polarization_str ],'-dpng')
    close
end
