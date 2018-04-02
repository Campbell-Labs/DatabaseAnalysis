function [ dbt ] = cleanup_database(dbt, remove_rejected, remove_QuarterArbitrary, remove_nan, properties, post_automated, legacy_table )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if remove_nan;
    bad_bool = false(height(dbt), 1);
    for i = 1:length(properties)
        property = char(properties(i));
        bad_bool = bad_bool | isnan(dbt.(property));
    end
    dbt_good = dbt(not(bad_bool),:);
    % This is checking what database entries have bad data but are not rejected
    % This is possibly useful for sanity checks
    try
        if legacy_table
            dbt.NewRejected(isnan(dbt.NewRejected)) = 1;
            not_rejected_bad_bool = and(not(dbt.NewRejected), bad_bool);
        else
            rejected_bool = (dbt.NewRejected == '0');
            not_rejected_bad_bool = and(rejected_bool, bad_bool);
        end
        dbt_notreject = dbt(not_rejected_bad_bool,:);
    catch
    end
end

if remove_rejected
    if legacy_table
        dbt.NewRejected(isnan(dbt.NewRejected)) = 1; % Convert NaN's into rejected
        dbt = dbt(~dbt.NewRejected, :);
    else
        dbt = dbt(dbt.NewRejected == '0', :);
    end
end

if remove_QuarterArbitrary
    dbt = dbt(dbt.QuarterArbitrary == '0', :);
end

% It has to be processed to use calculated properties
dbt = dbt(dbt.IsProcessed, :);

%% Ensure it is post automated stage?
if post_automated
    dbt = dbt(dbt.SubjectIdx > 30, :);
end
%% Custom database management for fixing Human errors
% %% Unrejecting Subject:
% % Subject with only dust and particulate measured, for the
% % background images, since we can segment this out, low deposits will not
% % be accurate though
% un_reject_bool = dbt.SubjectId == 'VA14-105';
% dbt(un_reject_bool,:).NewRejected = zeros(sum(un_reject_bool),1);
% 
% %% Changing diagnoisis of subject which was improperly labelled on import 
% % Pretty messy, but converting in and out of categorical seems non-trivial
% mislabelled_diagnosis_bool = ...dbt_VA.SubjectId == 'VA12-55';
% (dbt.SubjectId == 'VA12-55' | dbt.SubjectId == 'VA15-41'); %rename
% %low or none too?
% replace_array = categorical(zeros(sum(mislabelled_diagnosis_bool),1), [0, 1, 2, 3,4], categories(dbt.Likelihood_of_AD), 'Ordinal', true);
% replace_array(:) = 'low';
% dbt(mislabelled_diagnosis_bool,:).Likelihood_of_AD = replace_array;

end

