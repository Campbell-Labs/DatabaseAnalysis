load('Database Tables with Polarization Stats.mat')

nameAD = {'Chris','Kurt'};
namePosCon = {'Tanner', 'Camille'};
nameCon = {'Gertrude','Julius'};

indexAD = [[1,2,3];[1,2,4]];
indexPosCon = [[19,15,16];[24,19,14]];
indexCon = [[4,5,3];[25,24,20]];

[ dbt_AD, dbt_PosCon, dbt_Con , dbt_subjects, dbt_s ] = ...
    FilterData( dbt, nameAD, namePosCon, nameCon, indexAD, indexPosCon, indexCon);

% We now have three databases which contain the loction matched deposits
polarization_properties = [% List of polarizatioin properties to compare btw subjects...
    ];

for polarization_property = polarization_properties;
    AD_Prop = dbt_AD.(polarization_property);
    PosCon_Prop = dbt_PosCon.(polarization_property);
    Con_Prop = dbt_Con.(polarization_property);
    
    [p_ADvPC, h_ADvPC, stats_ADvPC] = ranksum(AD_Prop, PosCon_Prop);
    [p_ADvC, h_ADvC, stats_ADvC] = ranksum(AD_Prop, Con_Prop);
    [p_PCvC, h_PCvC, stats_PCvC] = ranksum(PosCon_Prop, Con_Prop);
end
