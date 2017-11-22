function [ dbts, dbt_1, dbt_2, dbt_3 , dbt_subjects, dbt_s ] = ...
    FilterData( dbt, group_names, name_1, name_2, name_3,...
                                            index_1, index_2, index_3)
%FILTERDATA Takes database table and filters for matching deposits
%   args:
%       dbt = database table created by Erik's Database analysis scripts
%       name_# = A cellstr of patients names under study for each #
%       index_# = A list of deposit location lists corresponding to 
%       	the spot numbers to be matched for the group 
%   returns:
%       dbts = A structure including the next three tables
%       dbt_# = A table of patient data in order of matching for group #
%       dbt_subjects = A table of subjects under study
%       dbt_s = A table of all unique subjects

% Data conversion to cell str
name_1 = cellstr(name_1)';
name_2 = cellstr(name_2)';
name_3 = cellstr(name_3)';

subject_names = [name_1, name_2, name_3];

entries = length(name_1);

[unique_names, unique_indicies] = unique(dbt.SubjectId);

dbt_subjects = []; % initiating empty subject table
dbt_locations = [];

for i = [subject_names;{group_names{1},group_names{2},group_names{3}};{index_1',index_2',index_3'}];
    name_cond = i(1:entries);
    cond = i(entries + 1);
    cond_indexer = i(entries + 2);
    cond_indexer = cond_indexer{:}; % Have to pull it out of a 1x1 cell
    entries = length(name_cond);
    
    [~,subject_unique_indicies]  = find_sorted_intersection(unique_names,name_cond);
    subject_indicies = unique_indicies(subject_unique_indicies);
    
    dbt_subject_cond = dbt(subject_indicies,:);
    dbt_subject_cond.Condition = repmat(categorical(cond), entries, 1);
    dbt_subjects = [dbt_subjects; dbt_subject_cond];
    
    for index = 1:length(name_cond)
        name = name_cond(index);
        location_indicies = cond_indexer{index, 1};
        dbt_subject = dbt(dbt.SubjectId == name,:);
        
        % Way of finding the spots, as the old spot numbers
        % should be the indicies of the new array - semi-sketchy
        dbt_sorted_subject = dbt_subject(location_indicies,:);
        
        dbt_sorted_subject.Condition = repmat(categorical(cond), height(dbt_sorted_subject), 1);
        
        dbt_locations = [dbt_locations; dbt_sorted_subject];
            
    end
end

% This now creates three tables, with matched spots in order specified at
% the beginning

dbt_1 = dbt_locations(dbt_locations.Condition == group_names{1},:);
dbt_2 = dbt_locations(dbt_locations.Condition == group_names{2},:);
dbt_3 = dbt_locations(dbt_locations.Condition == group_names{3},:);

dbts = struct(group_names{1}, dbt_1, group_names{2},dbt_2, group_names{3}, dbt_3);

dbt_s = dbt(unique_indicies,:);

subject_indicies  = unique_indicies(ismember(unique_names,subject_names));

dbt_subjects = dbt(subject_indicies,:);

function [sorted_values, sorted_indicies] = find_sorted_intersection(big_list, small_list)
% Find the small list indicies in the big list
    % We automatically get a sorted list, so I make sure its sorted by
    % my method through some confusing indexing
[alpha_list,alpha_indicies]  = intersect(big_list,small_list); % no repeated values
[~, alpha_small_indicies] = sort(small_list);
sorted_indicies = alpha_indicies(alpha_small_indicies);
sorted_values = alpha_list(alpha_small_indicies);
