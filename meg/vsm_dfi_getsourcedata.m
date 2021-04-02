function [s, f] = vsm_dfi_getsourcedata(subjectname, subsetflag, audio_indx) 

if nargin<2 || isempty(subsetflag)
  subsetflag = 1;
end
if nargin<3
  error('an audio_indx should be provided');
end

datadir = '/project/3011085.04/data/derived/mscca';
load(fullfile(datadir,sprintf('%s_sourcedata_mscca',subjectname)));
load(fullfile(datadir,'AUDIODATA_all'))

if subsetflag>0
  
  atlasfile = fullfile('/project/3011085.05/data/atlas','atlas_subparc374_4k.mat');
  load(atlasfile);
  
  plist = {'L_20';'L_21';'L_22';'L_37';'L_38';'L_39';'L_40';'L_41';'L_42';'L_43';'L_44';'L_45';'L_46';'L_47'};
  sel = false(size(atlas.parcellationlabel));
  for k = 1:numel(plist)
    if subsetflag==1
      sel = startsWith(atlas.parcellationlabel,plist{k})|sel;
    elseif subsetflag==2
      sel = startsWith(atlas.parcellationlabel,strrep(plist{k},'L','R'))|sel;
    end
  end
  
  cfg = [];
  cfg.channel = atlas.parcellationlabel(sel);
  sourcedata = ft_selectdata(cfg, data);
else
  sourcedata = data;
end

s  = sourcedata;
%f  = audiodata;
f  = audiodata{audio_indx};
if numel(f.trial)~=numel(s.trial)
  f = vsm_splitlongtrials(f);
end

selchan = find(contains(f.label,'perpl'));
for k = 1:numel(f.trial)
  f.trial{k}(selchan,:) = log10(f.trial{k}(selchan,:));
end

% check the time axes
for k = 1:numel(f.trial)
  begs = nearest(f.time{k}, s.time{k}(1));
  ends = nearest(f.time{k}, s.time{k}(end));
  f.time{k} = f.time{k}(begs:ends);
  f.trial{k} = f.trial{k}(:,begs:ends);
end
