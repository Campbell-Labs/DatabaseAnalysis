function [ dbt_AD, dbt_PosCon, dbt_Con , dbt_subjects, dbt_s ] = FilterData( dbt, nameAD, namePosCon, nameCon,...
                                            indexAD, indexPosCon, indexCon)
%FILTERDATA Takes database table and filters for matching deposits
%   args:
%       dbt = database table created by Erik's Database analysis scripts
%       nameAD = A cellstr of AD patients under study
%       namePosCon = A cellstr of Positive Control patients names under study
%       namePosCon = A cellstr of Control patients names under study
%       indexAD = A list of deposit location lists corresponding to 
%       	the AD spot numbers to be matched  
%       indexPosCon = A list of deposit location lists corresponding to 
%           the Positive Control spot numbers to be matched  
%       indexCon = A list of deposit location lists corresponding to 
%           the Control spot numbers to be matched  
%   returns:
%       dbt_AD = A table of AD patient data in order of matching
%       dbt_PosCon = A table of Postive Control patient data in order of matching
%       dbt_Con = A table of Control patient data in order of matching
%       dbt_subjects = A table of subjects under study
%       dbt_s = A table of all unique subjects


% Data conversion to cell str
nameAD = cellstr(nameAD)';
namePosCon = cellstr(namePosCon)';
nameCon = cellstr(nameCon)';

subject_names = [nameAD, namePosCon, nameCon];

entries = length(nameAD);

[unique_names, unique_indicies] = unique(dbt.SubjectId);

dbt_subjects = []; % initiating empty subject table
dbt_locations = [];

for i = [subject_names;{'AD','PosCon','Con'};{indexAD',indexPosCon',indexCon'}];
    name_cond = i(1:entries);
    cond = i(entries + 1);
    cond_indexer = cell2mat(i(entries + 2));
    entries = length(name_cond);
    
    [~,subject_unique_indicies]  = find_sorted_intersection(unique_names,name_cond);
    subject_indicies = unique_indicies(subject_unique_indicies);
    
    dbt_subject_cond = dbt(subject_indicies,:);
    dbt_subject_cond.Condition = repmat(categorical(cond), entries, 1);
    dbt_subjects = [dbt_subjects; dbt_subject_cond];
    
    for index = 1:length(name_cond)
        name = name_cond(index);
        location_indicies = cond_indexer(:, index);
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
dbt_AD = dbt_locations(dbt_locations.Condition == 'AD',:);
dbt_PosCon = dbt_locations(dbt_locations.Condition == 'PosCon',:);
dbt_Con = dbt_locations(dbt_locations.Condition == 'Con',:);

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
