function [C, label, P, list, lay] = vsm_parcelsofinterest

% this function is meant to keep track how the parcelsofinterest are defined
% for the MEG based connectivity analysis dfi.

atlasfile = fullfile('/project/3011085.05/data/atlas','atlas_subparc374_4k.mat');
load(atlasfile);

plist = {'L_20';'L_21';'L_22';'L_37';'L_38';'L_39';'L_40';'L_41';'L_42';'L_43';'L_44';'L_45';'L_46';'L_47'};
sel = false(size(atlas.parcellationlabel));
for k = 1:numel(plist)
  sel = startsWith(atlas.parcellationlabel,plist{k})|sel;
  sel = startsWith(atlas.parcellationlabel,strrep(plist{k},'L','R'))|sel;
end

label = atlas.parcellationlabel(sel);
label(:,2) = label;
for k = 1:numel(plist)*2
  if k<=numel(plist)
    sel = find(contains(label(:,1),plist{k}));
    kx = k;
  else
    sel = find(contains(label(:,1),strrep(plist{k-numel(plist)},'L','R')));
    kx = k-numel(plist);
  end
  
  switch plist{kx}(3:4)
    case '20'
      label(sel([2 4]))   = {[label{sel(1)}(1:5) '01']};
      label(sel([3 6 7])) = {[label{sel(1)}(1:5) '02']};
      label(sel([1 5]))   = {[label{sel(1)}(1:5) '03']};
    case '21'
      label(sel(1)) = {[label{sel(1)}(1:5) '01']};
      label(sel(2)) = {[label{sel(1)}(1:5) '02']};
      label(sel(3)) = {[label{sel(1)}(1:5) '03']};
    case '22'
      label(sel([2]))      = {[label{sel(1)}(1:5) '01']};
      label(sel([1 3 7]))  = {[label{sel(1)}(1:5) '02']};
      label(sel([4 8 10])) = {[label{sel(1)}(1:5) '03']};
      label(sel([5 6 9]))  = {[label{sel(1)}(1:5) '04']};
    case '37'
      label(sel([2 3]))   = {[label{sel(1)}(1:5) '01']};
      label(sel([5 7]))   = {[label{sel(1)}(1:5) '02']};
      label(sel([1 4 6])) = {[label{sel(1)}(1:5) '03']};
    case '38'
      label(sel([1 3]))   = {[label{sel(1)}(1:5) '01']};
      label(sel([2 4]))   = {[label{sel(1)}(1:5) '02']};    
    case '39'
      label(sel([3 4 5]))   = {[label{sel(1)}(1:5) '01']};
      label(sel([1 2 6]))   = {[label{sel(1)}(1:5) '02']};
    case '40'
      label(sel([3 4 5]))   = {[label{sel(1)}(1:5) '01']};
      label(sel([1 2 6]))   = {[label{sel(1)}(1:5) '02']};
    case '41'
      label(sel(2)) = {[label{sel(1)}(1:5) '01']};
      label(sel(1)) = {[label{sel(1)}(1:5) '02']};
    case '42'
      label(sel(3)) = {[label{sel(1)}(1:5) '01']};
      label(sel(2)) = {[label{sel(1)}(1:5) '02']};
      label(sel(1)) = {[label{sel(1)}(1:5) '03']};
    case '43'
      label(sel(1)) = {[label{sel(1)}(1:5) '01']};
      label(sel(2)) = {[label{sel(1)}(1:5) '02']};
    case '44'
      label(sel) = {[label{sel(1)}(1:5) '01']};
    case '45'
      label(sel) = {[label{sel(1)}(1:5) '01']};
    case '46'
      label(sel) = {[label{sel(1)}(1:5) '01']};
    case '47'
      label(sel) = {[label{sel(1)}(1:5) '01']};
    otherwise
  end
end
label = sortrows(label);

% re-code the atlas
ulabel = unique(label(:,1));
p = zeros(size(atlas.parcellation));
for k = 1:numel(ulabel)
  sel = match_str(atlas.parcellationlabel, label(strcmp(label(:,1),ulabel{k}),2));
  p(ismember(atlas.parcellation,sel)) = k;
end
p(p==0) = numel(ulabel)+1;

newatlas = atlas;
newatlas.parcellationlabel = [ulabel;{'???'}];
newatlas.parcellation = p;


% the following list is the ordered list

cfg = [];
cfg.channel = {
    'R_46'
    'R_44'
    'R_45'
    'R_47'
    'R_39_01'
    'R_39_02'
    'R_40_01'
    'R_40_02'    
    'R_41_01'
    'R_41_02'
    'R_42_01'
    'R_42_02'
    'R_42_03'
    'R_43_01'
    'R_43_02'
    'R_38_01'
    'R_38_02'
    'R_20_01'
    'R_20_02'
    'R_20_03'
    'R_21_01'
    'R_21_02'
    'R_21_03'
    'R_22_01'
    'R_22_02'
    'R_22_03'
    'R_22_04'
    'R_37_01'
    'R_37_02'
    'R_37_03'
    'L_37_03'
    'L_37_02'
    'L_37_01'
    'L_22_04'
    'L_22_03'
    'L_22_02'
    'L_22_01'
    'L_21_03'
    'L_21_02'
    'L_21_01'
    'L_20_03'
    'L_20_02'
    'L_20_01'
    'L_38_02'
    'L_38_01'
    'L_43_02'
    'L_43_01'
    'L_42_03'
    'L_42_02'
    'L_42_01'
    'L_41_02'
    'L_41_01'
    'L_40_02'
    'L_40_01'
    'L_39_02'
    'L_39_01'
    'L_47'
    'L_45'
    'L_44'
    'L_46'
    };

cfg.rho = [6:5:21 31:5:46 56:5:86 96:5:151 161:5:171];
cfg.rho = [cfg.rho 360-flip(cfg.rho)];
cfg.layout = 'circular';
lay = ft_prepare_layout(cfg);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subfunction
function C = makeconnections(label, node1, node2, hierarchy)

% hierarchy is [1 2], meaning node1 is lower in the hierarchy,
% or hierarchy is [2 1], meaning node2 is lower in the hierarchy
% or hierarchy is [1 1], meaning equal

C = zeros(numel(label));

sel1 = ~cellfun('isempty',strfind(label, node1));
sel2 = ~cellfun('isempty',strfind(label, node2));

if isequal(hierarchy,[1 2])
  C(sel1, sel2) = 1; % feedforward
  C(sel2, sel1) = 2; % feedback
elseif isequal(hierarchy,[2 1])
  C(sel1, sel2) = 2; % feedback
  C(sel2, sel1) = 1; % feedforward
elseif isequal(hierarchy,[1 1])
  C(sel1, sel2) = 3; 
  C(sel2, sel1) = 3; 
else
  error('unknown hierarch specified');
end

