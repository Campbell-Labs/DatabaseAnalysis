function [ comparison_struct, diag_struct , polarization_properties, p_ANOVA_all] = ...
    DepositCompare( dbts, comparisons_values, pre_match, post_match, mid_match, ratio_bool, subtraction_bool, directory)
%DepositCompare - Compares Deposits/Background data
%   Given databases made with FilterData it will take the
%   appropriate properties it will create ttests between each of the 
%   diagnosis buckets.
%   args:
%       dbts = database table created by FilterData
%       diagnosis = The names of the three groups.
%       pre_match = Regex string to catch the begining of stings to choose
%                   properties
%       pre_match = Regex string to catch the end of stings to choose props
%       comparisons_values = Comparisons to run
%   returns:
%       comparison_struct = A structure including the comparisons
%       diag_struct = A structure holding the different diagnoisises
%       comparisons = A list of the comparisons ran
%       polarization_names_full = Names of all polarization properties run
ANOVA_dir = fullfile(directory, 'ANOVA');
mkdir(ANOVA_dir)

if mid_match
    regex_matcher = [pre_match,'.*',mid_match ,'.*', post_match];
else
    regex_matcher = [pre_match, '.*', post_match];
end    

diagnosis = {dbts.name};
largest_of_deposits = max(arrayfun(@(x) height(x.table),dbts));


column_names = dbts(1).table.Properties.VariableNames;

pol_prop = ~cellfun(@isempty,regexp(column_names, regex_matcher));
polarization_properties = struct('name',column_names(pol_prop));

is_deposit = num2cell(~cellfun(@isempty,regexp({polarization_properties.name},'(?:Deposit).*'))');
[polarization_properties(:).is_deposit] = is_deposit{:};
split_name = regexp({polarization_properties.name},pre_match, 'split');
split_name = vertcat(split_name{:});
split_name = split_name(~cellfun('isempty',split_name));
[match_array, split_array] = regexp(split_name, post_match, 'match','split');

% Pulling first cell within each cell, solution may be inoptimal
split_array_org = vertcat(split_array{:});
split_array_org = split_array_org(:,1);

[polarization_properties(:).type] = match_array{:};
[polarization_properties(:).property] = split_array_org{:};

%% Make a calculated data fields, if they exist
fields = {};
if ratio_bool
    fields{length(fields) + 1} = 'Ratio';
end
if subtraction_bool
    fields{length(fields) + 1} = 'Subtraction';
end

calculated_names = [];
calculated_indicies = [];
calculated_type = [];
for index = 1:length(polarization_properties);
    if polarization_properties(index).is_deposit
        search_name = polarization_properties(index).property;
        search_type = polarization_properties(index).type;
        for j = 1:length(polarization_properties);
            if ~polarization_properties(j).is_deposit && ...
                    strcmp(polarization_properties(j).property,search_name) && ...
                    strcmp(polarization_properties(j).type,search_type)
                for i = 1:length(fields);
                    field = fields(i);
                    calculated_names = [calculated_names; {[char(field{1}),'_',char(search_name),char(search_type)]}];
                    calculated_indicies = [calculated_indicies; [index,j]];
                    calculated_type = [calculated_type, {field}];
                end
                break
            end
        end
    end
end
%%

% We now have three databases which contain the location matched deposits
%polarization_properties.name = [column_names(pol_prop); [...% List of polarizatioin properties to compare btw subjects
%    ];

    %% Making a data array to pull from later, and create the calculated arrays as well
    og_height = length(polarization_properties);
    calculated_height = length(calculated_names);
    data_width = length(dbts);
    data_array = NaN(og_height + calculated_height, data_width, largest_of_deposits);
    for i = 1:og_height
        for j = 1:data_width
            table_height = height(dbts(j).table);
            data_array(i,j,1:table_height) =  dbts(j).table.(char(polarization_properties(i).name));
        end
    end
    for i = 1:calculated_height
        index = og_height + i;
        for j = 1:data_width
            calculated_i = calculated_indicies(i,:);
            deposit_data = data_array(calculated_i(1),:,:);
            background_data = data_array(calculated_i(2),:,:);
            type_2conv = calculated_type(i);
            type = char(type_2conv{1});
            %Here is where new calculated data fields would be added
            if strcmp(type, 'Ratio');
                data = deposit_data./background_data;
            elseif strcmp(type, 'Subtraction')
                data = deposit_data - background_data;
            else
                error([type,' is not a valid field name'])
            end
            data_array(index,:,:) = data;
        end
    end
    
    %%
    
% This section is just some uninteresting data management, creating the
% data structures and initalizing arrays for all of them
polarization_names_full = [{polarization_properties(:).name}'; calculated_names];
table_height = length(polarization_names_full);

p_ANOVA_all = zeros(1, table_height);

properties = {'mean', 'median', 'std', 'data'};

%comparisons_values = {'p', 'h', 'normal'};

%% Comparing all three diagnoises and creating those labels

compare_index = combnk(1:length(diagnosis),2);
[comparing, comparisons] = deal(cell(length(compare_index),1));

for i = 1:length(compare_index)
    comparing{i} = {diagnosis(compare_index(i,1)), diagnosis(compare_index(i,2))};
    comparisons{i} = strcat(comparing{i}{1},'v',comparing{i}{2});
end 

comparison_struct = struct('name',comparisons, ...
                           'indices', num2cell(compare_index,2),...
                           'elements', comparing);
prop_all_way = {'ANOVA'};

%% Just initalizing structres and arrays of zeros
diag_struct = struct('name', diagnosis);
for j = 1:length(diagnosis);
    for i = 1:length(properties);
        if strcmp(properties(i), 'props'); dealer = cell(table_height,1);
        elseif strcmp(properties(i), 'data'); dealer = NaN(table_height,largest_of_deposits);
        else dealer = zeros(table_height,1);
        end
        diag_struct(j).(char(properties(i))) = deal(dealer);
    end
end
for j = 1:length(comparisons_values)
    [comparison_struct(:).(char(comparisons_values(j)))] = deal(zeros(table_height,1));
end
% This just pushes the data which was in structures into analysis and
% saves them back into structures. It looks a bit messy but means its very
% simple to add in new calculations and print them out if needs be.

for index = 1:table_height;
    polarization_property = char(polarization_names_full(index));
    is_deposit = any(regexp(polarization_property,'(Deposit)\w+'));
    for dig_index = 1:length(diagnosis);
        diagnosis_str = char(diagnosis(dig_index));
        data = squeeze(data_array(index, dig_index, :));
        % This section replaces the control deposit field with it's
        % respective background signal, as the control will not have a
        % deposit...
%         if strcmp(diagnosis_str,diagnosis{3}) && is_deposit;
%             try data = dbts(1).(strrep(polarization_property,'Deposit','Background'));
%             catch
%             end
%         end
        diag_struct(dig_index).data(index,:) = data;
        data(isnan(data)) = [];
        diag_struct(dig_index).mean(index) = mean(data);
        diag_struct(dig_index).median(index) = median(data);
        diag_struct(dig_index).std(index) = std(data);
%        diag_struct(dig_index).values(index) = num2cell(data,1);
        
        % Here the calculations of the properties based off of diagnosis
        % sorted data is done, like the mean value of the AD deposits
    end
    for comp_index = 1:length(comparison_struct)
        prop_1 = diag_struct(comparison_struct(comp_index).indices(1)).data(index,:);
        prop_2 = diag_struct(comparison_struct(comp_index).indices(2)).data(index,:);
        [comparison_struct(comp_index).h_paired(index), ... 
         comparison_struct(comp_index).p_paired(index), ... 
         comparison_struct(comp_index).normal_paired(index)...
         ] = CompareData(prop_1, prop_2, 1);
        % Here are the calculations for comparing data sets lie. Right
        % now all that is done is to run the compare data function
        [comparison_struct(comp_index).h_unpaired(index), ... 
         comparison_struct(comp_index).p_unpaired(index), ... 
         comparison_struct(comp_index).normal_unpaired(index)...
         ] = CompareData(prop_1, prop_2, 0);
     %%
     try
         comparison_ANOVA = anova1([prop_1;prop_2]',[], 'off');
     catch
         comparison_ANOVA = NaN;
     end
     comparison_struct(comp_index).p_ANOVA(index) = comparison_ANOVA;
     % Should add in groupings to tell diff between different subjects
     % as we have that grouping data.
    end
    %% trying to do ANOVA with the all groups
    ANOVA_values = NaN(largest_of_deposits, length(diag_struct));
    for i = length(diag_struct):-1:1
        ANOVA_values(:,i) = diag_struct(i).data(index,:);
    end
    [p_ANOVA_all(:, index), tbl] = anova1(ANOVA_values, fliplr(diagnosis), 'on');
    
    % Saving ANOVA data to file here
    fileID = fopen([ANOVA_dir, '\ANOVA_data_', polarization_property,'.txt'],'w');
    
    formatSpec = '%s \t %1.5f \t %u \t %1.5f \t %1.2f \t %1.2f \n';
    [nrows,ncols] = size(tbl);
    fprintf(fileID,'%s \t\t %s \t\t %s \t\t %s \t\t %s \t\t %s \n',tbl{1,:});
    for row = 2:nrows
        fprintf(fileID,formatSpec,tbl{row,:});
    end
    fclose(fileID);
    title(strrep(polarization_property,'_',' '));
    print([ANOVA_dir, '\ANOVA_', polarization_property ],'-dpng')
    close all
end

function [ h, p, normal ] = CompareData( x, y, paired)
    %CompareData Completes a comparison of data to check if data is
    %differentiable between subjects. We will complete different statsicial
    %studies based off if the data is normal or not or if the data is paired or
    %unpaired.

    % First we should check if the datasets are normal
    if paired 
        if all(~isnan(x)) && all(~isnan(y));
            x_h = kstest(x);
            y_h = kstest(y);
            normal = y_h && x_h;
            [h,p] = signrank(x,y, 'method','exact');    
        else
            [p,h, normal] = deal(nan);
        end

    %     if paired && normal
    %         [h,p] = ttest(x,y);    
    %     end
    else
        x(isnan(x)) = [];
        y(isnan(y)) = [];
        x_h = kstest(x);
        y_h = kstest(y);
        normal = y_h && x_h;

        if normal
            [h,p] = ttest2(x,y, 'Vartype','unequal');    
        else
            [p, h] = ranksum(x,y);  
        end

    end

end

end