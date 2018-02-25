function [ dbt_good ] = reject_bad( dbt, properties )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

bad_bool = false(height(dbt), 1);
for i = 1:length(properties)
    property = char(properties(i));
    bad_bool = bad_bool | isnan(dbt.(property));
end
dbt_good = dbt(not(bad_bool),:);
% This is checking what database entries have bad data but are not rejected
% This is possibly useful for sanity checks
dbt.NewRejected(isnan(dbt.NewRejected)) = 1;
not_rejected_bad_bool = and(not(dbt.NewRejected), bad_bool);
dbt_notreject = dbt(not_rejected_bad_bool,:);
end

