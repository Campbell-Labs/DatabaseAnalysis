%% User Entry Section
%Choose your database file
load(fullfile(pwd,'database_tables','Human Ex Vivo - Database Table (Generated 18-03-22)'))
%What will the outputted data file be
folder_name = '18-02-22_gen_test';

% Which diagnosises will be compared
% Options to choose are High, Intermediate, Low and None
diagnosis = {'High', 'Intermediate', 'None' }; 
diagnosis_type = 'Likelihood_of_AD';
% Note that the last property is the ratioed/subtracted property (control)

paired = false;

if paired
    folder_name = [folder_name, '_Paired'];
else
    folder_name = [folder_name, '_UnPaired'];
end

print_graphs = true;

%What should property string start with
mid_match = '(Deposit|Background)';
post_match = '(_Median|Size)'; % And what should it end with

% What should be somewhere in the middle
match_properties = {'Diattenuation_Circ', 'Diattenuation_Lin','DP', 'Retardance_Circ',...
                    'Retardance_Lin', 'Polarizance_Circ','Polarizance_Lin'};
plain_match = {'DepositAreaMicrons2'};

% What should the outputted excel file be filled with
diag_print_to_table = {'mean', 'median', 'std', 'data'};
comp_print_to_table = {'h_unpaired','p_unpaired','normal_unpaired',...
                       'p_ANOVA'...
                        };
if paired;
    comp_paired = {'h_paired','p_paired','normal_paired'};
    comp_print_to_table = [comp_print_to_table, comp_paired];
end
compare_all_way = {'median'};

%Bools to pick which calculated properties should be run
ratio = false; %Divide by control
subtraction = false; %Subtract control from data

% Choose which database subjects to remove
reject_nan = true; % This is to remove properties which have NaN in calculation
remove_rejected = true; % This is to remove properties which are rejected
remove_QuarterArbitrary = false; % This removes deposits which have been flagged as arbitrary quarters
post_automated = true; % Removes subject index < 30 to ensure all data is post automation

%% Script
% First we pull in our helper functions to use later
addpath(genpath('helpers'))

% Find a database of only subjects, 
%IsNewEye and IsNewQuarter can also be split out but are not here
dbt_s = dbt(dbt.IsNewSubject,:);
all_subjects = cellstr(dbt_s.SubjectId);

%% First just reducing the databases to only include VA subjects
% This regular expression simply finds those subjects called VA_###
VA_regex = ['VA', '.*'];

dbt_VA = match_table_regex(dbt, VA_regex ,'SubjectId');
dbt_VA_s = match_table_regex(dbt_s, VA_regex ,'SubjectId');
VA_subjects = cellstr(dbt_VA_s.SubjectId); % This just gives is only the VA subject names

%% Management
pre_match = ['.*(',match_properties{1}];
for i = 2:length(match_properties)
    pre_match = [pre_match,'|', match_properties{i}];
end
pre_match = [pre_match,')'];

plain_mid_match = ['.*(',plain_match{1}];
for i = 2:length(plain_match);
    plain_mid_match = [pre_match,'|', plain_match{i}];
end
plain_mid_match = [plain_mid_match,')'];

%calculate some properties to use later
column_names = dbt_VA.Properties.VariableNames;
regex_matcher = [pre_match,'.*',mid_match ,'.*', post_match];
polarization_properties = column_names(~cellfun(@isempty,regexp(column_names, regex_matcher)));
plain_props = column_names(~cellfun(@isempty,regexp(column_names, plain_mid_match)));

polarization_properties = [polarization_properties, plain_props];

%% Here I will split up the three groups
dbt_VA = cleanup_database(dbt_VA, remove_rejected, remove_QuarterArbitrary, ...
    reject_nan, polarization_properties,  post_automated);

% This uses the diagnosis as a regex and this regex matches the diagnosis
tables = cell(1, length(diagnosis));
for i = 1:length(diagnosis);
    tables(1,i) = {match_table_regex(dbt_VA, [diagnosis{i}, '.*'] , diagnosis_type);};
end

if paired
    % Here I will match the locations of the deposits to send to DataCompare
    [pairing_list, paired_tables] = pairing_function(diagnosis, tables);
    % Values now are paired as stated in paired list
    dbts = struct('name', diagnosis, 'table', paired_tables);
else
    dbts = struct('name', diagnosis, 'table', tables);
end


%% Print/Calculate Data
out_path = CreateFolder(folder_name);

if print_graphs
    DataGraph(dbts, polarization_properties, out_path);
end
[comparison_struct, diag_struct, polarization_properties_struct, p_ANOVA_all] = ...
    DepositCompare(dbts, comp_print_to_table, pre_match, post_match, mid_match, ratio, subtraction, out_path);

dbts = DataPrint(dbts, diagnosis_type, comparison_struct, diag_struct, folder_name, compare_all_way, diag_print_to_table, comp_print_to_table ,diagnosis, polarization_properties_struct, out_path, p_ANOVA_all); 
