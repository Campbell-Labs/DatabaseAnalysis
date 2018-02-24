function [matched_table, matched_bool] = match_table_regex(table, regex, field)
%Match Table Regex - Simply a function which gets the table and field which
%is being filtered and filters it based off of the regex expression given.
%   Args:
%   table - Table which is being filtered
%   regex - regular expression which can be used to filter the data
%   field -  The field which is being searched through
%   RETURNS:
%   matched_table - table which only includes the items which passed the
%   regex check
%   matched_bool - a list of bools as long as the original table, which
%   verifies which data passed the check.
    matched_bool = ~cellfun(@isempty,regexp(cellstr(table.(field)),regex));
    matched_table = table(matched_bool,:);
end

