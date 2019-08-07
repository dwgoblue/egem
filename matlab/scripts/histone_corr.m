%% histone_corr calculates the correlation value between various histone
...markers and the metabolic flux obtained from the iMAT algorithm
function [STRUCT] = histone_corr(model, reactions_of_interest,...
    eps_struct, mode, epsilon, rho, kappa, minfluxflag, exp,...
    dataset, fva_grate)

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
        
load ./../vars/supplementary_software_code...
    celllinenames_ccle1... % CCLE cellline names
    ccleids_met... % Gene symbols
    ccle_expression_metz % Z-transformed gene expression

BIOMASS_OBJ_POS = find(ismember(model.rxns, 'biomass_objective')); % biomass rxn position in eGEM model

% impute missing values using KNN and scale from [0,1]
proteomics = knnimpute(proteomics);
proteomics = normalize(proteomics, 'range');

% Match data from gene expression and histone proteomics to get proteomics
% data that will be used downstream
proteomics_CL_match = find(ismember(cell_names, celllinenames_ccle1));
number_of_matched_proteomics = length(proteomics_CL_match);
proteomics = proteomics(proteomics_CL_match, :);
cell_names = cell_names(proteomics_CL_match,1);

% Change idx to map to gene expression array and iterate for all 885 cancer
% cell lines that match between genexp and proteomics dataset
geneExp_CL_match = find(ismember(celllinenames_ccle1, cell_names));
for match = 1:number_of_matched_proteomics
    disp(['Cell line: ', cell_names(match)])
    model2 = model;
    
    ongenes = unique(ccleids_met(ccle_expression_metz(:, geneExp_CL_match(match)) >= 2));
    offgenes = unique(ccleids_met(ccle_expression_metz(:, geneExp_CL_match(match)) <= -2));
    ongenes = intersect(ongenes, model2.rxns);
    offgenes = intersect(offgenes, model2.rxns);
    [ix, pos]  = ismember({'EX_met_L(e)'}, model2.rxns);
    
    disp(medium(match))
    obj_coef = eps_struct.RPMI;
    
    model2.lb(pos) = -0.5;
    model2 = media(model2, medium(match));
    model2.c(BIOMASS_OBJ_POS) = 1;

    [~,~,onreactions,~] =  deleteModelGenes(model2, ongenes);
    [~,~,offreactions,~] =  deleteModelGenes(model2, offgenes);

    rxnname = char(reactions_of_interest(:, 1));
    switch exp
        case 'non-competitive_cfr'
            for rxn = 1:length(reactions_of_interest(:,1))
                model3 = model2;
                rxnpos = [find(ismember(model3.rxns, reactions_of_interest(rxn)))];
                model3.c(rxnpos) = obj_coef(rxn, 1);
                [flux, ~, ~] = constrain_flux_regulation(model3,  ...
                    onreactions, offreactions, kappa, rho, epsilon, mode, [], ...
                    minfluxflag);
                all_flux_values(match,rxn) = flux(rxnpos);
                model3.c(rxnpos) = 0;
            end
        case 'competitive_cfr'
            model3 = model2;
            rxnpos = [find(ismember(model3.rxns, rxnname))];
            model3.c(rxnpos) = obj_coef(:, 1);
            [flux, ~, ~] =  constrain_flux_regulation(model3,...
                onreactions, offreactions, kappa, rho, epsilon, mode , [], ...
                minfluxflag);
            all_flux_values(match,:) = flux(rxnpos);
        case 'fva'
            model3 = model2;
            rxnpos = [find(ismember(model3.rxns, rxnname))];
            model3.c(rxnpos) = obj_coef(:, 1);
            [~, ~, ~, ~, flux, ~] =...
                calc_metabolic_metrics(model3, [], [], fva_grate,...
                'max', reactions_of_interest, [], 'fva');
            all_flux_values(match,:) = flux;
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

for match=1:length(fields)
    STRUCT.(fields{match}) = values{match};
end
end