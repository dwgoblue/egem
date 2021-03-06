function model = medium_LB_constraints(model, queried_medium)

file = 'final_medium2.xlsx';

if verLessThan('matlab', '9.6.0.1072779')
    [~, sheetNames] = xlsfinfo(file);
    for sheets = 1:length(sheetNames)
        if ismember(string(sheetNames(sheets)), queried_medium)
            [adjustedLB, rxn_ids] = xlsread(file, string(sheetNames{sheets}));
            rxn_ids(1, :) = [];
            rxn_ids(:, 1) = [];

            for rxn=1:length(rxn_ids)
                model.lb(find(ismember(string(model.rxns), string(rxn_ids(rxn, 5))))) = ...
                        adjustedLB(rxn, 2);
            end

        elseif ismember({'nan'}, queried_medium)
            [adjustedLB, rxn_ids] = xlsread(file, 'RPMI');
            rxn_ids(1,:) = [];
            rxn_ids(:,1) = [];

            for rxn=1:length(rxn_ids)
                model.lb(find(ismember(string(model.rxns), string(rxn_ids(rxn, 5))))) = ...
                        adjustedLB(rxn, 2);
            end

        end
    end
        
else
    [~, sheetNames] = xlsfinfo(file);
    for sheets = 1:length(sheetNames)
        if ismember(string(sheetNames(sheets)), string(queried_medium))
            dataArray = readcell(file, 'Sheet', string(sheetNames(sheets)));
            dataArray(1,:) = [];
            dataArray(:,1) = [];

            for rxn=1:length(dataArray)
                model.lb(find(ismember(string(model.rxns), string(dataArray(rxn, 4))))) = ...
                        cell2mat(dataArray(rxn, 2));
            end

        elseif ismember({'nan'}, queried_medium)
            dataArray = readcell(file, 'Sheet', 'RPMI');
            dataArray(1,:) = [];
            dataArray(:,1) = [];

            for rxn=1:length(dataArray)
                model.lb(find(ismember(string(model.rxns), string(dataArray(rxn, 4))))) = ...
                        cell2mat(dataArray(rxn, 2));
            end

        end
    end
end

end