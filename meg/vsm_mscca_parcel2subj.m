datadir = '/project/3011085.04/data/derived/mscca';
cd(datadir);

d = dir('mscca*');
sel = ~contains({d.name},'perpl');
d = d(sel);

atlasfile = fullfile('/project/3011085.05/data/atlas','atlas_subparc374_4k.mat');
load(atlasfile);

plist = {'L_20';'L_21';'L_22';'L_37';'L_38';'L_39';'L_40';'L_41';'L_42';'L_43';'L_44';'L_45';'L_46';'L_47'};
sel = false(size(atlas.parcellationlabel));
for k = 1:numel(plist)
  sel = startsWith(atlas.parcellationlabel,plist{k})|sel;
  sel = startsWith(atlas.parcellationlabel,strrep(plist{k},'L','R'))|sel;
end
d = d(sel);
label = atlas.parcellationlabel(sel);

for k = 2:22
  cfgsel = [];
  for m = 1:numel(d)
    load(d(m).name,'comp');
    if m==1
      cfgsel.channel = comp.label{k};
      audiofile = comp.audiofile;
      subname   = comp.label{k}(end-2:end);
    end
    data{1,m} = ft_selectdata(cfgsel,comp);
    data{1,m}.label = label(m);
    data{1,m} = rmfield(data{1,m},'audiofile');
  end 
  data = ft_appenddata([], data{:});
  data.audiofile = audiofile;
  save([subname,'_sourcedata_mscca'], 'data');
  clear data;
end

    