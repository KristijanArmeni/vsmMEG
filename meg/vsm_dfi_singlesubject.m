
% subj = vsm_subjinfo(subj);
% subj = rmfield(subj,'ica'); % save memory
%subj.name='s14';

load(fullfile('/project/3011085.04/data/derived',sprintf('%s_meg',subj.name)));
load(fullfile('/project/3011085.04/data/derived',sprintf('%s_lng-box',  subj.name)));
load(fullfile('/project/3011085.04/data/derived',sprintf('%s_lcmv-filt',subj.name)));
source_parc.filterlabel = data.label; % for checking channel order, assumes same order in the filters

sourcedata = vsm_multisetcca_sensor2parcel(data, source_parc, 1:374, 1);

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
sourcedata = ft_selectdata(cfg, sourcedata);

sourcedata_orig  = sourcedata;
featuredata_orig = featuredata;

selchan = find(contains(featuredata_orig.label,'perpl'));
for k = 1:numel(featuredata_orig.trial)
  featuredata_orig.trial{k}(selchan,:) = log10(featuredata_orig.trial{k}(selchan,:));
end

%rseed = rng;

if ~exist('testfeature', 'var')
  testfeature = 'perplexity';
end
if ~exist('nrand', 'var')
  nrand = 100;
end
if ~exist('subindx', 'var')
  subindx = [];
end

cfgsel1.channel = testfeature;
featuredata     = ft_selectdata(cfgsel1, featuredata_orig);
sourcedata      = ft_appenddata([],sourcedata_orig, vsm_feature_roughen(featuredata));

rng('shuffle');

cfg             = [];
cfg.method      = 'dfi';
cfg.refindx     = 'all';
cfg.dfi.feature = testfeature;
cfg.dfi.lags    = (0.08:0.02:0.5);
cfg.dfi.precondition = true;
dfi             = ft_struct2single(ft_connectivityanalysis(cfg, sourcedata));
for k = 1:nrand
  sourcedata      = ft_appenddata([],sourcedata_orig, vsm_feature_roughen(vsm_feature_plateau2shuff(featuredata)));
  dfi_c           = ft_struct2single(ft_connectivityanalysis(cfg, sourcedata));
  if k==1
    mask = double(dfi.dfi>dfi_c.dfi);
  else
    mask = mask + double(dfi.dfi>dfi_c.dfi);
  end
end
if nrand==0
  mask = zeros(size(dfi.dfi));
end

dfi   = (rmfield(dfi, 'cfg'));
fname = sprintf('%s_dfi_%s',subj.name,testfeature);
if ~isempty(subindx)
  fname = sprintf('%s_%03d',fname, subindx);
  save(fname, 'mask','nrand');
else
  save(fname, 'dfi', 'mask','nrand');
end
