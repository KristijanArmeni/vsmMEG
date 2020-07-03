
% subj = vsm_subjinfo(subj);
% subj = rmfield(subj,'ica'); % save memory
%subj.name='s14';

load(fullfile('/project/3011085.04/data/derived',sprintf('%s_meg',subj.name)));
load(fullfile('/project/3011085.04/data/derived',sprintf('%s_aud',subj.name)));
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
  sel = startsWith(atlas.parcellationlabel,strrep(plist{k},'L','R'))|sel;
end

cfg = [];
cfg.channel = atlas.parcellationlabel(sel);
sourcedata = ft_selectdata(cfg, sourcedata);

%
% for k = 1:numel(di)
%   if isfield(di(k), 'time')
%     for m = 1:numel(di(k).time)
%       for p = 1:374
%         di(k).di(p,p,m)=nan;
%         % diw(k).di(p,p,m) = nan;
%       end
%     end
%   else
%     for p = 1:374
%       di(k).di(p,p) = nan;
%       % diw(k).di(p,p) = nan;
%     end
%   end
% end
% di  = ft_struct2single(rmfield(di,  'cfg'));
% % diw = ft_struct2single(rmfield(diw, 'cfg'));
% %save([subj.name,'_di_combined'],'di', 'diw');
% save([subj.name,'_di'],'di');

sourcedata_orig  = sourcedata;
featuredata_orig = featuredata;

cfgsel = [];
cfgsel.channel = 'audio_avg';
audio = ft_selectdata(cfgsel, audio);
cfgsel.channel = 'perplexity_c';
featuredata_c = ft_selectdata(cfgsel, featuredata_orig);
cfgsel.channel = 'perplexity';
featuredata = ft_selectdata(cfgsel, featuredata_orig);
cfgsel.channel = 'log10wf';
featuredata_lf = ft_selectdata(cfgsel, featuredata_orig);
cfgsel.channel = 'log10wf_c';
featuredata_lfc = ft_selectdata(cfgsel, featuredata_orig);
cfgsel.channel = 'entropy';
featuredata_e  = ft_selectdata(cfgsel, featuredata_orig);
cfgsel.channel = 'entropy_c';
featuredata_ec = ft_selectdata(cfgsel, featuredata_orig);

rseed = rng;

cfg           = [];
cfg.operation = 'log10';
cfg.parameter = 'trial';
featuredata   = ft_math(cfg, featuredata);
featuredata_c = ft_math(cfg, featuredata_c);
sourcedata    = ft_appenddata([],sourcedata_orig, vsm_feature_roughen(featuredata, rseed), vsm_feature_roughen(featuredata_c, rseed));

cfgsel          = [];
cfgsel.trials   = 1:min(5,numel(sourcedata.trial));
  
cfg             = [];
cfg.method      = 'dfi';
cfg.refindx     = 'all';
cfg.dfi.feature = 'perplexity';
cfg.dfi.lags    = (0.08:0.02:0.6);
cfg.dfi.precondition = true;
% dfi             = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
% cfg.dfi.feature = 'perplexity_c';
% dfi_c           = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
% 
% dfi   = (rmfield(dfi, 'cfg'));
% dfi_c = (rmfield(dfi_c, 'cfg'));
% save([subj.name,'_dfi'],'dfi','dfi_c');
% 
% % compute dfi, but now using log10wf as feature
% sourcedata = ft_appenddata([], sourcedata_orig, vsm_feature_roughen(featuredata_lf), vsm_feature_roughen(featuredata_lfc));
% clear dfi dfi_c;
% 
% cfg.dfi.feature = 'log10wf';
% dfi             = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
% cfg.dfi.feature = 'log10wf_c';
% dfi_c           = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
% 
% dfi   = (rmfield(dfi, 'cfg'));
% dfi_c = (rmfield(dfi_c, 'cfg'));
% save([subj.name,'_dfi_lexfreq'],'dfi','dfi_c');
% 
% % compute dfi, but now using entropy as feature
% sourcedata = ft_appenddata([], sourcedata_orig, vsm_feature_roughen(featuredata_e), vsm_feature_roughen(featuredata_ec));
% clear dfi dfi_c;
% 
% cfg.dfi.feature = 'entropy';
% dfi             = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
% cfg.dfi.feature = 'entropy_c';
% dfi_c           = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
% 
% dfi   = (rmfield(dfi, 'cfg'));
% dfi_c = (rmfield(dfi_c, 'cfg'));
% save([subj.name,'_dfi_entropy'],'dfi','dfi_c');

audio_shift = audio;
for k = 1:numel(audio.trial)
  audio_shift.trial{k} = circshift(audio_shift.trial{k},floor(numel(audio.time{k})./2));
end
audio_shift.label = {'audio_shift'};

% compute dfi, but now using audio envelope as feature
sourcedata = ft_appenddata([], sourcedata_orig, audio, audio_shift);

cfg.dfi.lags    = 0.02:0.02:0.3;
cfg.dfi.feature = 'audio_avg';
dfi             = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));
cfg.dfi.feature = 'audio_shift';
dfi_c           = ft_struct2single(ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata)));

dfi   = (rmfield(dfi, 'cfg'));
dfi_c = (rmfield(dfi_c, 'cfg'));
save([subj.name,'_dfi_audio'],'dfi','dfi_c');

