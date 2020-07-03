function [s, f] = vsm_dfi_getsourcedata(subjectname) 

datadir = '/project/3011085.04/data/derived/mscca';
load(fullfile(datadir,sprintf('%s_sourcedata_mscca',subjectname)));
load(fullfile(datadir,'AUDIODATA'))
sourceata = data;

atlasfile = fullfile('/project/3011085.05/data/atlas','atlas_subparc374_4k.mat');
load(atlasfile);

plist = {'L_20';'L_21';'L_22';'L_37';'L_38';'L_39';'L_40';'L_41';'L_42';'L_43';'L_44';'L_45';'L_46';'L_47'};
sel = false(size(atlas.parcellationlabel));
for k = 1:numel(plist)
  sel = startsWith(atlas.parcellationlabel,plist{k})|sel;
  %sel = startsWith(atlas.parcellationlabel,strrep(plist{k},'L','R'))|sel;
end

cfg = [];
cfg.channel = atlas.parcellationlabel(sel);
sourcedata = ft_selectdata(cfg, data);

s  = sourcedata;
f  = audiodata;

selchan = find(contains(f.label,'perpl'));
for k = 1:numel(f.trial)
  f.trial{k}(selchan,:) = log10(f.trial{k}(selchan,:));
end
