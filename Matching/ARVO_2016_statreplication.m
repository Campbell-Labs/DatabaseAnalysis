load('Database Tables with Polarization Stats.mat')

nameAD = {'Chris','Kurt'};
namePosCon = {'Tanner', 'Camille'};
nameCon = {'Gertrude','Julius'};

indexAD = [[1,2,3];[1,2,4]];
indexPosCon = [[19,15,16];[24,19,14]];
indexCon = [[4,5,3];[25,24,20]];

[ dbt_AD, dbt_PosCon, dbt_Con , dbt_subjects, dbt_s ] = ...
    FilterData( dbt, nameAD, namePosCon, nameCon, indexAD, indexPosCon, indexCon);

column_names = dbt_AD.Properties.VariableNames;
pol_prop = ~cellfun(@isempty,regexp(column_names,'(Deposit|Background)\w+')); % should check if start of string too
polarization_properties = column_names(pol_prop);
% We now have three databases which contain the loction matched deposits
%polarization_properties = [column_names(pol_prop); [...% List of polarizatioin properties to compare btw subjects
%    ];
table_height = length(polarization_properties);
[p_ADvPC, h_ADvPC, stats_ADvPC, p_ADvC, h_ADvC, p_PCvC, h_PCvC] = deal(zeros(table_height,1));
[AD_values, PC_values, C_values] = deal(cell(table_height,1));
for index = 1:table_height;
    polarization_property = char(polarization_properties(index));
    AD_Prop = dbt_AD.(polarization_property);
    PosCon_Prop = dbt_PosCon.(polarization_property);
    Con_Prop = dbt_Con.(polarization_property);
    try
        [p_ADvPC(index), h_ADvPC(index), stats_ADvPC] = ranksum(AD_Prop, PosCon_Prop);
    catch
        [p_ADvPC(index), h_ADvPC(index), stats_ADvPC] = deal(NaN);
    end
    try 
        [p_ADvC(index), h_ADvC(index), stats_ADvC] = ranksum(AD_Prop, Con_Prop);
    catch
        [p_ADvC(index), h_ADvC(index), stats_ADvC] = deal(NaN);
    end
    try
        [p_PCvC(index), h_PCvC(index), stats_PCvC] = ranksum(PosCon_Prop, Con_Prop);
    catch
        [p_ADvC(index), h_ADvC(index), stats_ADvC] = deal(NaN);
    end
    
    AD_values(index) = num2cell(AD_Prop,1);
    PC_values(index) = num2cell(PosCon_Prop,1);
    C_values(index) = num2cell(Con_Prop,1);
end

comparison_table = table(h_ADvPC, p_ADvPC, h_PCvC, p_PCvC, h_PCvC, p_PCvC, AD_values, PC_values, C_values);
comparison_table.Properties.RowNames = polarization_properties;

writetable(comparison_table, ['Comparison_Table_', strrep(datestr(now),':','_'), '.csv'],'WriteRowNames',true)


