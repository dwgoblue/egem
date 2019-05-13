%% Code to run modules
initCobraToolbox;
changeCobraSolver('gurobi');

load ./../models/eGEM.mat % minimal eGEM model 
load ./../models/acetyl2.mat % new acetylation model

load ./../models/recon1
model = metabolicmodel;

%load supplementary_software_code acetylation_model
%model = acetylation_model; %Shen et al., 2019

%% Correlation values between histone markers and metabolic flux
%histone_corr(model, 'amet', [], 'n', 1, 1E-2, 1, 1E-3, 0);
%rxnpos  = [find(ismember(model.rxns, 'EX_KAC'));];

%% Heatmap of metabolic reactions vs excess/depletion of medium coponents

% Use params for testing 
%compartment = 'n';
%epsilon2 = 1E-3;
%scaling = [];
%[excess_flux, depletion_flux, excess_redcost, depletion_redcost,...
%    excess_shadow, depletion_shadow] = make_heatmap(model, 'n',...
%    epsilon2, []);

epsilon2 = [1E-4, 1E-3, 1E-2, 0.1, 1];
%compartment = ['n', 'c', 'm'];
for n = 1:length(epsilon2)
    %for m = 1:length(compartment)
    [excess_flux, depletion_flux, excess_redcost, depletion_redcost,...
    excess_shadow, depletion_shadow] = make_heatmap(model, 'c',...
    epsilon2(n), []);
    %end
end