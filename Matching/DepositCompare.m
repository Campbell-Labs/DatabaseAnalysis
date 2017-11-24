function [ comparison_struct, diag_struct, comparisons , polarization_names_full] = ...
    DepositCompare( dbts, num_of_deposits, diagnosis, pre_match, post_match, comparisons_values, mid_match)
%DepositCompare - Compares Deposits/Background data
%   Given databases made with FilterData it will take the
%   appropriate properties it will create ttests between each of the 
%   diagnosis buckets.
%   args:
%       dbts = database table created by FilterData
%       num_of_deposits = number of deposits, should be depreciated
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

column_names = dbts.(diagnosis{1}).Properties.VariableNames;
if mid_match
    regex_matcher = [pre_match,'.*',mid_match ,'.*', post_match];
else
    regex_matcher = [pre_match, '.*', post_match];
end
pol_prop = ~cellfun(@isempty,regexp(column_names, regex_matcher));
polarization_properties.name = column_names(pol_prop);
polarization_properties.is_deposit = ~cellfun(@isempty,regexp(polarization_properties.name,...
    '(?:Deposit).*'));
split_name = cellfun(@(c) strrep(c{1,2}, '_', ''), ...
    regexp(polarization_properties.name,pre_match, 'split'), 'UniformOutput',false);
[match_array, split_array] = regexp(split_name, post_match, 'match','split');

polarization_properties.type = cellfun(@(c) c{1},match_array ,'UniformOutput',false);
polarization_properties.property = cellfun(@(c) c{1,1},split_array ,'UniformOutput',false);

%% Attempting to make a calculated data fields
fields = {'Ratio', 'Subtraction'};
calculated_names = [];
calculated_indicies = [];
calculated_type = [];
for index = 1:length(polarization_properties.name);
    if polarization_properties.is_deposit(index)
        search_name = polarization_properties.property(index);
        search_type = polarization_properties.type(index);
        for j = 1:length(polarization_properties.name);
            if ~polarization_properties.is_deposit(j) && ...
                    strcmp(polarization_properties.property(j),search_name) && ...
                    strcmp(polarization_properties.type(j),search_type)
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
    og_height = length(polarization_properties.name);
    calculated_height = length(calculated_names);
    data_width = length(diagnosis);
    data_array = zeros(og_height + calculated_height, data_width, num_of_deposits);
    for i = 1:og_height
        for j = 1:data_width
            data_array(i,j,:) =  dbts.(char(diagnosis(j))).(char(polarization_properties.name(i)));
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
polarization_names_full = [polarization_properties.name'; calculated_names];
table_height = length(polarization_names_full);

properties = {'mean', 'median', 'std', 'values', 'props'};

%comparisons_values = {'p', 'h', 'normal'};

% Comparing all three diagnoises and creating those labels

comparing = {{diagnosis{1},diagnosis{2}},...
            {diagnosis{1},diagnosis{3}},...
            {diagnosis{2},diagnosis{3}}};

comparisons = {[comparing{1}{1},'v',comparing{1}{2}],...
               [comparing{2}{1},'v',comparing{2}{2}],...
               [comparing{3}{1},'v',comparing{3}{2}]};

%Just initalizing structres and arrays of zeros
for j = 1:length(diagnosis);
    diag_struct.(char(diagnosis(j))) = struct();
    for i = 1:length(properties);
        if strcmp(properties(i), 'values'); dealer = cell(table_height,1);
        elseif strcmp(properties(i), 'props'); dealer = zeros(table_height,num_of_deposits);
        else dealer = zeros(table_height,1);
        end
        diag_struct.(char(diagnosis(j))).(char(properties(i))) = deal(dealer);
    end
end

for j = 1:length(comparisons)
     comparison_struct.(char(comparisons(j))) = struct();
     for i = 1:length(comparisons_values);
        comparison_struct.(char(comparisons(j))).(char(comparisons_values(i))) =  deal(zeros(table_height,1));
     end
     comparison_struct.(char(comparisons(j))).('comparing') = comparing{j};
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
        if strcmp(diagnosis_str,diagnosis{3}) && is_deposit;
            try data = dbts.(diagnosis_str).(strrep(polarization_property,'Deposit','Background'));
            catch
            end
        end
        diag_struct.(diagnosis_str).('prop')(index,:) = data;
        diag_struct.(diagnosis_str).('mean')(index) = mean(data);
        diag_struct.(diagnosis_str).('median')(index) = median(data);
        diag_struct.(diagnosis_str).('std')(index) = std(data);
        diag_struct.(diagnosis_str).('values')(index) = num2cell(data,1);
        % Here the calculations of the properties based off of diagnosis
        % sorted data is done, like the mean value of the AD deposits
    end
    for comp_index = 1:length(comparisons)
        comparison = char(comparisons(comp_index));
        prop_1 = diag_struct.(comparison_struct.(comparison).comparing{1}).prop(index,:);
        prop_2 = diag_struct.(comparison_struct.(comparison).comparing{2}).prop(index,:);
        [comparison_struct.(comparison).h_paired(index), ... 
         comparison_struct.(comparison).p_paired(index), ... 
         comparison_struct.(comparison).normal_paired(index)...
         ] = CompareData(prop_1, prop_2, 1);
        % Here are the calculations for comparing data sets lie. Right
        % now all that is done is to run the compare data function
        [comparison_struct.(comparison).h_unpaired(index), ... 
         comparison_struct.(comparison).p_unpaired(index), ... 
         comparison_struct.(comparison).normal_unpaired(index)...
         ] = CompareData(prop_1, prop_2, 0);
     %% This is the graphing section for good paired data
     try
         graph_paired = 0;
         if strcmp(comparison, 'ADvPC') && comparison_struct.(comparison).h_paired(index) && graph_paired
             figure
             property_array = zeros(length(prop_1), length(diagnosis));
             for k = 1:length(diagnosis)
                 diag = char(diagnosis(k));
                 property_array(:,k) = diag_struct.(diag).prop(index,:);
             end
             for j = 1:length(property_array)
                 plot(1:3,property_array(j,:), 'b' ); hold on
                 title([strrep(polarization_property, '_', ' ') ,' p: ', num2str(comparison_struct.(comparison).p_paired(index))]);
             end
         end
     catch
     end
     %%
     try
         comparison_ANOVA = anova2([prop_1;prop_2],1, 'off');
     catch
         comparison_ANOVA = NaN(2,1);
     end
     comparison_struct.(comparison).p_ANOVA(index) = comparison_ANOVA(2);
     % Should add in groupings to tell diff between different subjects
     % as we have that grouping data.
    end
end

end

