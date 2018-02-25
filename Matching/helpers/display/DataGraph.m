function [ new_directory ] = DataGraph( dbts, diagnosis, polarization_names, pre_match, dump_directory, pre_name)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if exist( 'pre_name','var' ) == 0
    pre_name = 'Data_Directory_';
end

if exist( 'dump_directory','var' ) == 0
    dump_directory = fullfile(pwd, 'data_dump_folder');
end

%%First make a dump directory
new_folder = [pre_name, datestr(now, 'yy-mm-dd-HH-MM-SS')];
new_directory = fullfile(dump_directory, new_folder);

scatter_directory = fullfile(new_directory, 'Scatter');
boxplot_directory = fullfile(new_directory, 'BoxPlot');
mkdir(new_directory)
mkdir(scatter_directory)
mkdir(boxplot_directory)

polarization_names = regexp(polarization_names, [pre_match, '.*'], 'match');
polarization_names = polarization_names(~cellfun('isempty',polarization_names));

samples = height(dbts(1).table);
x = 1:samples;
for pol_prop_index = 1:length(polarization_names)
    polarization_str = char(polarization_names{pol_prop_index});
    [values, x_values, g_values] = deal(zeros(samples, 3));
    for diag_index = length(diagnosis):-1:1
        values(:, diag_index) = dbts(diag_index).table.(polarization_str);
        x_values(:, diag_index) = x;
        g_values(:, diag_index) = diag_index;
    end
    gscatter(x_values(:), values(:), g_values(:));
    xlabel('Deposits');
    title(strrep(polarization_str,'_',' '));
    legend(diagnosis);
    print([scatter_directory, '\Scatter_', polarization_str ],'-dpng')
    close
    h = boxplot(values, 'Labels', diagnosis);
    title(strrep(polarization_str,'_',' '));
%%% 
set( gca                       , ...
    'FontName'   , 'Helvetica',...
'XDir','reverse');
%%%
    
    print([boxplot_directory, '\BoxPlot_', polarization_str ],'-dpng')
    close
end
