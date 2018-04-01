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
    set(gcf,'renderer','Painters')
    
    % First loop through each property
    polarization_str = char(polarization_names{pol_prop_index});
    [values, x_values, g_values, subject_num] = deal(NaN(max_samples, 3));
    clear data
    for diag_index = length(dbts):-1:1
        % For each diagnosis get the index (x), values and which diagnosis
        samples = height(dbts(diag_index).table);
        x = 1:samples;
        values(1:samples, diag_index) = dbts(diag_index).table.(polarization_str);
        subject_num(1:samples, diag_index) = dbts(diag_index).table.SubjectIdx;
        x_values(1:samples, diag_index) = x;
        g_values(1:samples, diag_index) = diag_index;
        
        data_structure = struct('name',          dbts(diag_index).name, ...
                'valid',        ~isnan(g_values(:,diag_index)), ...
                'group',        g_values(:,diag_index), ...
                'x_values',     x_values(:,diag_index), ...
                'values',        values(:,diag_index), ...
                'SubjectIdx',   subject_num(:,diag_index));
         
        data(diag_index) = data_structure;
    end
    
    %% Scatter Graph
    figure('visible','off');
    gscatter(x_values(:), values(:), g_values(:), diagnosis_colours,'.', 16);
    xlabel('Deposits');
    title(strrep(polarization_str,'_',' '));
    legend({dbts.name});
    
    set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3])
    set(gcf, 'PaperPositionMode', 'auto');
    
    print([scatter_directory, '\Scatter_', polarization_str ],'-dpng', '-r300')
    print([scatter_directory, '\EPS_Scatter_', polarization_str ],'-depsc2', '-r300')
    close
     
    %% Boxplots
    figure('visible','off');
    h = boxplot(values, 'Labels', {dbts.name});
    title(strrep(polarization_str,'_',' '));
    set( gca,'FontName'   , 'Helvetica','XDir','reverse');
    
    set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3])
    set(gcf, 'PaperPositionMode', 'auto');
    
    print([boxplot_directory, '\BoxPlot_', polarization_str ],'-dpng', '-r300')
    print([boxplot_directory, '\EPS_BoxPlot_', polarization_str ],'-depsc2', '-r300')
    close
    
    h = notBoxPlot(values);
    for k = 1:length(dbts)
        set(h(k).data,'color', diagnosis_colours(k,:),...
            'markerfacecolor', diagnosis_colours(k,:),...
            'MarkerSize',2.5)
    end
    title(strrep(polarization_str,'_',' '));
    set( gca,'FontName'   , 'Helvetica','XDir','reverse');
    set(gca,'XTickLabel',{data(:).name}); % set the labels of the groups
        set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3])
	set(gcf, 'PaperPositionMode', 'auto');

    print([boxplot_directory, '\BoxPlot_v2_', polarization_str ],'-dpng', '-r300')
    print([boxplot_directory, '\EPS_BoxPlot_v2_', polarization_str ],'-depsc2', '-r300')
    close
    
    %% Histograms
    
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
        unique_subjects = unique(data(i).SubjectIdx);
        unique_subjects = unique_subjects(~isnan(unique_subjects));
        
        [hist_data, hist_data_stacked] = deal(NaN(length(unique_subjects), length(edges) - 1));
        subject_data_stack = {};
        for j = 1:length(unique_subjects);
            subject = unique_subjects(j);
            subject_bool = subject == data(i).SubjectIdx;
            subject_data = data(i).values(subject_bool);
            subject_data_stack(end+1) = {subject_data'};
            hist_data(j, :) = histcounts(subject_data, edges);
            % here we want to not sum the first iteration, but sum all the
            % rest. Not elegant, but it'll work
            if j == 1;
                hist_data_stacked = hist_data;
            else
                hist_data_stacked(j, :) = sum(hist_data(1:j,:));
            end
        end
        data(i).subject_data = subject_data_stack;
        data(i).unique_subjects = unique_subjects;
        data(i).hist_per_subject = hist_data;
        data(i).hist_stacked = hist_data_stacked;
        
        centers = edges(1:end-1) + diff(edges) / 2;
    end
    % Diagnoisis Based Histogram
    
    for i = 1:length(data)
        hist_struct.(data(i).name) = data(i).values;
    end
    figure('visible','off');
    nhist(hist_struct, 'number', 'color', 'colormap', ...
        'xlabel', 'Metric Value');
    title(strrep(polarization_str,'_',' '))
     set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3])

    print([hist_directory, '\Histogram_', polarization_str ],'-dpng', '-r300')
    print([hist_directory, '\EPS_Histogram_', polarization_str ],'-depsc2', '-r300')
    close
    
    figure('visible','off');
    nhist(hist_struct,'smooth', 'proportion', 'color', 'colormap', ...
        'xlabel', 'Metric Value');
    title([strrep(polarization_str,'_',' '),' Normalized'])
     set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3])

    print([hist_directory, '\Histogram_Normalized_', polarization_str ],'-dpng', '-r300')
    print([hist_directory, '\EPS_Histogram_Normalized_', polarization_str ],'-depsc2', '-r300')
    close
    
    figure('visible','off');
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
        
        set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'ZMinorTick', 'on', 'ZGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3], 'ZColor', [.3 .3 .3])
        view(-91,11)
        print([hist_directory, '\Histogram_3d_',postpend,'_', polarization_str ],'-dpng', '-r300')
        print([hist_directory, '\EPS_Histogram_3d_',postpend,'_', polarization_str ],'-depsc2', '-r300')
        close
    end
    
    % Try a subject based histogram
    subject_hist_structure = struct();
    colours_to_choose = {'Greens','Reds','Blues','Oranges', 'Purples', 'Spectral'};
    colour_chart = [];
    for i = 1:length(data)
        diagnosis = data(i).name;
        num_of_subs = length(data(i).unique_subjects);
        for j = 1:num_of_subs
            subject_number = data(i).unique_subjects(j);
            subject_hist_structure.([diagnosis, '_', num2str(subject_number)]) = data(i).subject_data{j};           
        end
        colour_chart = [colour_chart; cbrewer('seq', colours_to_choose{i}, num_of_subs)];
    end
    
    %subject_colours = linspecer(length(subject_hist_structure), 'sequential');
    set(0,'DefaultFigureColormap',colour_chart);
    figure('visible','off');
    
    nhist(subject_hist_structure, 'number','smooth', 'color', 'colormap', ...
        'xlabel', 'Metric Value');
    
    title(['Subject ',strrep(polarization_str,'_',' ')])
     set(gca, 'Box', 'off', 'TickDir', 'out', 'TickLength', [.02 .02], ...
    'XMinorTick', 'on', 'YMinorTick', 'on', 'YGrid', 'on', ...
    'XColor', [.3 .3 .3], 'YColor', [.3 .3 .3])

    print([hist_directory, '\Subject_Histogram_Normalized_', polarization_str ],'-dpng', '-r300')
    print([hist_directory, '\EPS_Subject_Histogram_Normalized_', polarization_str ],'-depsc2', '-r300')
    close
       
    
    
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
