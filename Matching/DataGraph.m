function [ new_directory ] = DataGraph( dbts, diagnosis, polarization_names, pre_match)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%%First make a dump directory
new_folder = ['Data_Directory_', datestr(now, 'yy-mm-dd-HH-MM-SS')];
new_directory = [pwd,'\', new_folder];

mkdir(new_directory)

polarization_names = regexp(polarization_names, [pre_match, '.*'], 'match');
polarization_names = polarization_names(~cellfun('isempty',polarization_names));

samples = height(dbts.(diagnosis{1}));
x = 1:samples;
for polarization_prop = polarization_names'
    polarization_str = char(polarization_prop{1});
    [values, x_values, g_values] = deal(zeros(samples, 3));
    for diag_index = length(diagnosis):-1:1
        diagnosis_str = char(diagnosis(diag_index));
        values(:, diag_index) = dbts.(diagnosis_str).(polarization_str);
        x_values(:, diag_index) = x;
        g_values(:, diag_index) = diag_index;
    end
    gscatter(x_values(:), values(:), g_values(:));
    xlabel('Subject Number');
    title(strrep(polarization_str,'_',' '));
    legend(diagnosis);
    print([new_directory, '\Scatter_', polarization_str ],'-dpng')
    h = boxplot(values, 'Labels', diagnosis);
    title(strrep(polarization_str,'_',' '));
%%% 
set( gca                       , ...
    'FontName'   , 'Helvetica',...
'XDir','reverse');
%%%
    
    print([new_directory, '\BoxPlot_', polarization_str ],'-dpng')
end
