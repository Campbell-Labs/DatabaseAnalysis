function [] = DataGraph( dbts, polarization_names, output_directory)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Inside that directory, the subdirectories of graphs
scatter_directory = fullfile(output_directory, 'Scatter');
boxplot_directory = fullfile(output_directory, 'BoxPlot');
hist_directory = fullfile(output_directory, 'Histogram');

mkdir(scatter_directory)
mkdir(boxplot_directory)
mkdir(hist_directory)

subject_hist = false;
three_graph = false;

%Find largest number of samples in subject
%Brute force approach
max_samples = 0;
for diag_index = 1:length(dbts)
    local_max = height(dbts(diag_index).table);
    if max_samples < local_max;
        max_samples = local_max;
    end
end

for pol_prop_index = 1:length(polarization_names)
    diagnosis_colours = linspecer(length(dbts), 'qualitative');
    set(0,'DefaultFigureColormap',diagnosis_colours);
        
    % First loop through each property
    polarization_str = char(polarization_names{pol_prop_index});
    [values, x_values, g_values, subject_num] = deal(NaN(max_samples, length(dbts)));
    subject_name = cell(max_samples, length(dbts));
    clear data
    for diag_index = length(dbts):-1:1
        % For each diagnosis get the index (x), values and which diagnosis
        samples = height(dbts(diag_index).table);
        x = 1:samples;
        values(1:samples, diag_index) = dbts(diag_index).table.(polarization_str);
        subject_num(1:samples, diag_index) = dbts(diag_index).table.SubjectIdx;
        subject_name(1:samples, diag_index) = cellstr(dbts(diag_index).table.SubjectId);
        x_values(1:samples, diag_index) = x;
        g_values(1:samples, diag_index) = diag_index;
        data_structure = struct('name',          dbts(diag_index).name, ...
                'valid',        ~isnan(g_values(:,diag_index)), ...
                'group',        g_values(:,diag_index), ...
                'x_values',     x_values(:,diag_index), ...
                'values',        values(:,diag_index),  ...
                'SubjectId',    {subject_name(:,diag_index)},...
                'SubjectIdx',   subject_num(:,diag_index));
        data(diag_index) = data_structure;
    end
    % Also creating data array, mainly used for histograms and subject
    % analysis.
    % First figure out the number of bins
    [total_counts, edges] = histcounts(values(:) );%, 'BinMethod','fd');
    
    % First split the diagnoises
    largest_subject = 0;
    sum_subject = 0;
    for i = length(dbts):-1:1
        %get the total histogram
        data(i).hist_total = histcounts(data(i).values, edges);
        data(i).hist_total_normed = data(i).hist_total/ sum(data(i).hist_total);
        
        %get unique subjects to stack on one another (remove NaN)
        [unique_subjects, unique_indices] = unique(data(i).SubjectIdx);
        unique_subjects = unique_subjects(~isnan(unique_subjects));
        
        [hist_data, hist_data_stacked] = deal(NaN(length(unique_subjects), length(edges) - 1));
        subject_data_stack = {};
        subject_name = {};
        for j = 1:length(unique_subjects);
            subject = unique_subjects(j);
            subject_name(end+1) = cellstr(data(i).SubjectId(unique_indices(j)));
            subject_bool = subject == data(i).SubjectIdx;
            subject_data = data(i).values(subject_bool);
            subject_data_stack(end+1) = {subject_data'};
            hist_data(j, :) = histcounts(subject_data, edges);
            % here we want to not sum the first iteration, but sum all the
            % rest. Not elegant, but it'll work
            if largest_subject < length(subject_data)
                largest_subject = length(subject_data);
            end
            if j == 1;
                hist_data_stacked = hist_data;
            else
                hist_data_stacked(j, :) = sum(hist_data(1:j,:));
            end
        end
        sum_subject = sum_subject + length(unique_subjects);
        data(i).subject_data = subject_data_stack;
        data(i).unique_subjects = unique_subjects;
        data(i).subject_names = subject_name;
        data(i).hist_per_subject = hist_data;
        data(i).hist_stacked = hist_data_stacked;
        centers = edges(1:end-1) + diff(edges) / 2;
    end
    
    %% Scatter Graph
    figure('visible','off');
    gscatter(x_values(:), values(:), g_values(:), diagnosis_colours,'.', 16);
    xlabel('Deposits');
    title(strrep(polarization_str,'_',' '));
    legend({dbts.name});

    set_default_graph_properties(false, scatter_directory, ['Scatter_', polarization_str ])
     
    %% Boxplots
    figure('visible','off');
    h = boxplot(values);
    title(strrep(polarization_str,'_',' '));
    set( gca,'XDir','reverse',...
        'XTickLabel',{data(:).name}); % set the labels of the groups
    
    set_default_graph_properties(false, boxplot_directory, ['Boxplot_', polarization_str ])
    
    figure('visible','off');
    h = notBoxPlot(values, 'jitter', .5);
    
    set([h.data],...
    'MarkerFaceColor','k',...
    'markerEdgeColor','k',...
    'SizeData',6,...
    'MarkerFaceAlpha',.2,...
    'MarkerEdgeAlpha',.3)

    for k = 1:length(dbts)
        set(h(k).sdPtch,'FaceColor',diagnosis_colours(k,:),...
                   'EdgeColor','none')
        set(h(k).semPtch,'FaceColor',diagnosis_colours(k,:)*0.3,...
           'EdgeColor','none')
    end
    title(strrep(polarization_str,'_',' '));
    set( gca,'XDir','reverse',...
        'XTickLabel',{data(:).name}); % set the labels of the groups
    set_default_graph_properties(false, boxplot_directory, ['BoxPlot_v2_', polarization_str ])
    
    figure('visible','off');
    x_counter = 0;
    x_values = [];
    subject_names = {};
    sub_values = NaN(sum_subject, largest_subject);
    colour_stack = zeros(sum_subject, 3);
    first_sub_in_diag = [];
    k = 0;
    for i = 1:length(data)
        first_sub_in_diag = [first_sub_in_diag; k+1 ];
        for j = 1:length(data(i).unique_subjects)
            k = k+1;
            x_counter = x_counter + 1;
            subject_names(end+1) = data(i).subject_names(j);
            x_values(end+1) = x_counter;
            subject_data = data(i).subject_data{j};
            sub_values(k, 1:length(subject_data)) =  subject_data;
            colour_stack(k,:) = diagnosis_colours(i,:);
        end
        x_counter = x_counter + 2;
    end
        
    h = notBoxPlot(sub_values', x_values, 'jitter', .5);
        set( gca,'XDir','reverse',...
        'XTickLabel', subject_names); % set the labels of the groups
    
    set([h.data],...
        'MarkerFaceColor','k',...
        'markerEdgeColor','k',...
        'SizeData',6,...
        'MarkerFaceAlpha',.2,...
        'MarkerEdgeAlpha',.3)
    
    for k = 1:sum_subject
        set(h(k).sdPtch,'FaceColor',colour_stack(k,:),...
                   'EdgeColor','none')
        set(h(k).semPtch,'FaceColor',colour_stack(k,:)*0.3,...
           'EdgeColor','none')
    end
    
    title(['Subjects ', strrep(polarization_str,'_',' ')]);
    patches = [h(:).sdPtch];
    legend(patches(first_sub_in_diag), {dbts(:).name})
    set(gca,'XTickLabelRotation',45)
    
    set_default_graph_properties(false, boxplot_directory, ['Subject_BoxPlot_', polarization_str ])
       

    %% Histograms   
    % Diagnoisis Based Histogram
    
    for i = 1:length(data)
        hist_struct.(data(i).name) = data(i).values;
    end
    figure('visible','off');
    nhist(hist_struct, 'number', 'color', 'colormap', ...
        'xlabel', 'Metric Value');
    title(strrep(polarization_str,'_',' '))
    
    set_default_graph_properties(false, hist_directory, ['Histogram_', polarization_str ])

    
    figure('visible','off');
    nhist(hist_struct,'smooth', 'proportion', ...
        'color', 'colormap', ...
        'xlabel', 'Metric Value');
    title([strrep(polarization_str,'_',' '),' Normalized'])

    set_default_graph_properties(false, hist_directory, ['Histogram_Normalized_', polarization_str ])
    
    if three_graph
    hist3d_data = {vertcat(data(:).hist_total)', vertcat(data(:).hist_total_normed)'};
    hist3d_postpend = {'', 'Normalized'};
    hist3d_alpha = {false, true};
    
    for k = 1:length(hist3d_data)
        data_to_graph = hist3d_data{k};
        figure('visible','off');
        h = bar3(centers, data_to_graph);
        alpha_muliplier = 1/(length(data));
        for l = 1:length(data)
            set(h(l),'FaceColor',diagnosis_colours(l,:)) ;
            if hist3d_alpha{k}
                alpha(h(l),.5+ .5*(length(data) - l)*alpha_muliplier);
            end
        end
        title(strrep(polarization_str,'_',' '));
        postpend = hist3d_postpend{k};
        
        zlabel(['Counts ', postpend])
        ylabel('Metric Value')
        title([strrep(polarization_str,'_',' '),' ', postpend]);
        set(gca,'XTickLabel',{data(:).name}); % set the lables of the groups
        set(gca, 'XDir','reverse')
        set(gca,'PlotBoxAspectRatioMode','auto') % make the view wider
        view(-91,11)
        
        set_default_graph_properties(true, hist_directory, ['Histogram_3d_',postpend,'_', polarization_str ])
        
    end
    end
    if subject_hist
    try
    % Try a subject based histogram
    subject_hist_structure = struct();
    colours_to_choose = {'Greens','Reds','Blues','Oranges', 'Purples', 'Spectral'};
    colour_chart = [];
    for i = 1:length(data)
        diagnosis = data(i).name;
        num_of_subs = length(data(i).unique_subjects);
        for j = 1:num_of_subs
            subject_number = data(i).unique_subjects(j);
            %subject_name = data(i).unique_subjects{j};
            %subject_hist_structure.([diagnosis, '_', subject_name]) = data(i).subject_data{j};    
            subject_hist_structure.([diagnosis, '_', num2str(subject_number)]) = data(i).subject_data{j};    
        end
        colour_chart = [colour_chart; cbrewer('seq', colours_to_choose{i}, num_of_subs)];
    end
    
    %subject_colours = linspecer(length(subject_hist_structure), 'sequential');
    set(0,'DefaultFigureColormap',colour_chart);
    figure('visible','off');
    
    nhist(subject_hist_structure, ...
        'number','smooth', ...
        'color', 'colormap', ...
        'xlabel', 'Metric Value');
     title([strrep(polarization_str,'_',' '),' Normalized'])
     
    set_default_graph_properties(false, hist_directory, ['Subject_Histogram_Normalized_', polarization_str])
    catch
    end
    end
%     % I am trying to stack the histograms to show the inter subject
%     % variability
%     data_to_hist = NaN(length(data),length(edges) - 1, largest_subject);
%     for i = 1:length(data);
%         data_to_hist(i, :, 1:length(data(i).unique_subjects)) = data(i).hist_per_subject';
%     end
%     
%     bar3_stacked(data_to_hist);
%     
%     data_to_hist = NaN(length(data),length(edges) - 1, sum_subject);
%     subject_index = 1;
%     for i = 1:length(data);
%         data_to_hist(i, :, subject_index:subject_index+length(data(i).unique_subjects)-1) = data(i).hist_per_subject';
%         subject_index = subject_index + length(data(i).unique_subjects);
%     end
%     
%     bar3_stacked(data_to_hist);
    
end
end

function set_default_graph_properties(three_dee, save_directory, save_name)
    set(gcf,'renderer','Painters')
    set(gca, 'Box', 'off', ...
        'FontName' , 'Helvetica', ...
        'TickDir', 'out', ...
        'TickLength', [.02 .02], ...
        'XMinorTick', 'off', ...
        'YMinorTick', 'on', ...
        'YGrid', 'on', ...
        'XColor', [.3 .3 .3], ...
        'YColor', [.3 .3 .3])
    if three_dee
        set(gca, ...
        'ZMinorTick', 'on', ...
        'ZGrid', 'on', ...
        'ZColor', [.3 .3 .3])
    end

    set(gcf, 'PaperPositionMode', 'auto');
    
    if nargin > 1
        if nargin <3
            error('If save directory is provided, so does save_name')
        end
        % If save name is provided, then we save
        print([save_directory, '\', save_name],'-dpng', '-r600')
        print([save_directory, '\EPS_', save_name],'-depsc2', '-r600')
        close
    end
end
