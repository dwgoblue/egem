%% histone_corr calculates the correlation value between various histone
...markers and the metabolic flux obtained from the iMAT algorithm
function [STRUCT] = histone_corr(model, reactions_of_interest,...
    eps_struct, mode, epsilon, rho, kappa, minfluxflag, exp,...
    dataset, fva_grate, type)

%% INPUTS:
    % model: A structure representing the initial genome scale model
    % dat: A numerical array containing proteomics data used for the correlation
    % reactions_of_interest: A cell array containing reactions that will be studied
    % compartment: A character specifying the subcellular compartment of interest based on BiGG classifications
    % mode: describes the input list for constrain flux regulation
        % 0 =  genes
        % 1 = reactions
    % epsilon: The parameter for the minimum flux of on-reactions for constrain flux regulation. The default value is 1E-3
    % epsilon2: The array of objective coefficients for reaction of interest
    % rho: The relative weight for on-reactions. Used as a parameter for constrain flux regulation
    % kappa: The relative weight for off-reactions. Used as a parameter for constrain flux regulation
    % minfluxflag: Binary input for parsimonious flux balance analysis
        % 0 = no pFBA
        % 1 = pFBA

%% OUTPUTS:
    % correl: A numerical array of correlation values associated with each histone marker/rxn
    % pval: A numerical array of the p-value associated from the pearson correlation computation
    % cell_line_match: A cell array containing the cell lines that matched between gene expression and proteomics

%% histone_corr

switch dataset
    case 'CCLE'
        % Load the relative H3 proteomics dataset from the CCLE
        path1 = './../new_var/';
        path2 = './../vars/';
        vars = {...
            [path1 'h3_ccle_names.mat'],... % CCLE cellline names for H3 proteomics, 
            [path1 'h3_marks.mat'],... % H3 marker IDs
            [path1 'h3_media.mat'],... % H3 growth media
            [path1 'h3_relval.mat'],...% H3 proteomics data, Z-transformed
            }; 

        for kk = 1:numel(vars) 
            load(vars{kk})
        end
        
        cell_names = h3_ccle_names;
        marks = h3_marks;
        medium = h3_media;
        proteomics = h3_relval;
        
    case 'LeRoy'
        path1 = './../new_var/';
        path2 = './../vars/';
        vars = {...
            [path1 'leroy_cellline.mat'],... % CCLE cellline names for H3 proteomics, 
            [path1 'leroy_mark.mat'],... % Marker IDs
            [path1 'leroy_val.mat'],...% Average values
            }; 
        
        for kk = 1:numel(vars) 
            load(vars{kk})
        end
        
        cell_names = cell(:,1);
        medium = cell(:,2);
        marks = leroy_mark;
        proteomics = leroy_val;
        proteomics = proteomics';
end

switch type
    case 'all'
        load('./../vars/metabolites.mat')
        rxnname = char(metabolites(:, 1));
    case 'hist'
        load('./../vars/metabolites.mat')
        rxnname = char(metabolites(:, 1));
end
        
load ./../vars/supplementary_software_code...
    celllinenames_ccle1... % CCLE cellline names
    ccleids_met... % Gene symbols
    ccle_expression_metz % Z-transformed gene expression

BIOMASS_OBJ_POS = find(ismember(model.rxns, 'biomass_objective')); % biomass rxn position in eGEM model
%obj_coefs = epsilon2{:};
%obj_coefs = cell2mat(obj_coefs);

% impute missing values using KNN and scale from [0,1]
proteomics = knnimpute(proteomics);
proteomics = normalize(proteomics, 'range');

% Match data from gene expression and histone proteomics to get proteomics
% data that will be used downstream
idx = find(ismember(cell_names, celllinenames_ccle1));
tmp = length(idx);
proteomics = proteomics(idx, :);
cell_names = cell_names(idx,1);

% Change idx to map to gene expression array and iterate for all 885 cancer
% cell lines that match between genexp and proteomics dataset
idx = find(ismember(celllinenames_ccle1, cell_names));
for i = 1:tmp
    disp(['Cell line: ', cell_names(i)])
    model2 = model;
    
    ongenes = unique(ccleids_met(ccle_expression_metz(:,idx(i)) >= 2));
    offgenes = unique(ccleids_met(ccle_expression_metz(:,idx(i)) <= -2));
    ongenes = intersect(ongenes, model2.rxns);
    offgenes = intersect(offgenes, model2.rxns);
    [ix, pos]  = ismember({'EX_met_L(e)'}, model2.rxns);
    
    disp(medium(i))
    if string(medium(i)) == 'RPMI'
        obj_coef = eps_struct.RPMI;
    elseif string(medium(i)) == 'DMEM'
        obj_coef = eps_struct.DMEM;
    elseif string(medium(i)) == 'L15'
        obj_coef = eps_struct.L15;
    elseif string(medium(i)) == 'McCoy5A'
        obj_coef = eps_struct.McCoy5A;
    elseif string(medium(i)) == 'Iscove'
        obj_coef = eps_struct.Iscove;
    elseif string(medium(i)) == 'alphaMEM'
        obj_coef = eps_struct.alphaMEM;
    elseif string(medium(i)) == 'Waymouth'
        obj_coef = eps_struct.Waymouth;
    elseif string(medium(i)) == 'DMEMF12'
        obj_coef = eps_struct.DMEM_F12;
    elseif string(medium(i)) == 'HAMF12'
        obj_coef = eps_struct.HamF12;
    elseif string(medium(i)) == 'alphaMEM'
        obj_coef = eps_struct.alphaMEM;
    elseif string(medium(i)) == 'RPMIwGln'
        obj_coef = eps_struct.RPMIgln;
    elseif string(medium(i)) == 'HAMF10'
        obj_coef = eps_struct.HamF10;
    elseif string(medium(i)) == 'DMEMRPMI21'
        obj_coef = eps_struct.DMEM2_RPMI1;
    elseif string(medium(i)) == 'MCDB105M199'
        obj_coef = eps_struct.MCDB105_M199;
    elseif string(medium(i)) == 'Williams'
        obj_coef = eps_struct.Williams;
    elseif string(medium(i)) == 'ACL4'
        obj_coef = eps_struct.DMEM;
    elseif string(medium(i)) == 'RPMIF12'
        obj_coef = eps_struct.RPMI_F12;
    elseif string(medium(i)) == 'DMEMIscove'
        obj_coef = eps_struct.DMEM_Iscove;
    elseif string(medium(i)) == 'RPMIIscove'
        obj_coef = eps_struct.RPMI_Iscove;
    end
    
    model2 = media(model2, medium(i));
    model2.lb(pos) = -0.5;
    model2.c(BIOMASS_OBJ_POS) = 1;

    [~,~,onreactions,~] =  deleteModelGenes(model2, ongenes);
    [~,~,offreactions,~] =  deleteModelGenes(model2, offgenes);

    % Get the demand reaction positions of interest and calculate metabolic
    % flux for each cell line using the iMAT algorithm
    switch exp
        case 'non-competitive_cfr'
            for rxn = 1:length(reactions_of_interest(:,1))
                model3 = model2;
                rxnpos = [find(ismember(model3.rxns, reactions_of_interest(rxn,1)))];
                model3.c(rxnpos) = obj_coef(rxn, 1);
                [flux, ~, ~] = constrain_flux_regulation(model3,  ...
                    onreactions, offreactions, kappa, rho, epsilon, mode, [], ...
                    minfluxflag);
                all_flux_values(i,rxn) = flux(rxnpos);
                model3.c(rxnpos) = 0;
            end
        case 'competitive_cfr'
            model3 = model2;
            rxnpos = [find(ismember(model3.rxns, reactions_of_interest(:,1)))];
            model3.c(rxnpos) = obj_coef(:, 1);
            [flux, ~, ~] =  constrain_flux_regulation(model3,...
                onreactions, offreactions, kappa, rho, epsilon, mode , [], ...
                minfluxflag);
            all_flux_values(i,:) = flux(rxnpos);
        case 'fva'
            for rxn = 1:length(reactions_of_interest(:,1))
                model3 = model2;
                rxnpos = [find(ismember(model3.rxns, reactions_of_interest(rxn,1)))];
                model3.c(rxnpos) = obj_coef(:, 1);
                [~, ~, ~, ~, flux, ~] =...
                    calc_metabolic_metrics(model3, rxnpos, [], fva_grate,...
                    'max', reactions_of_interest, obj_coef(:, 1), 'fva');
                all_flux_values(i,:) = flux;
            end
    end
end

% Calculate the pearson correlation coefficients for every demand reaction
[rho, pval] = corr(all_flux_values, proteomics);
rxns = reactions_of_interest(:, 3);

%% Save data in struct
STRUCT = struct('Name', dataset);

fields = {...
        'HistoneMark'; 'Reaction'; ...
        'R'; 'Pvalue'; 'Flux'; 'Proteomics'
    };

values = {...
    marks; rxns; ...
    rho; pval; all_flux_values; proteomics
    };

for i=1:length(fields)
    STRUCT.(fields{i}) = values{i};
end
end
