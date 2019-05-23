
subj = vsm_subjinfo(subj);
subj = rmfield(subj,'ica'); % save memory


load(fullfile('/project/3011085.04/data/derived',sprintf('%s_meg',subj.name)));
load(fullfile('/project/3011085.04/data/derived',sprintf('%s_aud',subj.name)));
load(fullfile('/project/3011085.04/data/derived',sprintf('%s_lng-box',  subj.name)));
load(fullfile('/project/3011085.04/data/derived',sprintf('%s_lcmv-filt',subj.name)));

source_parc.filterlabel = data.label; % for checking channel order, assumes same order in the filters

sourcedata = vsm_multisetcca_sensor2parcel(data, source_parc, 1:374, 1);


cfg            = [];
cfg.method     = 'di';
cfg.refindx    = 'all';
cfg.di.lags    = (0.02:0.02:0.2);
for k = 1:numel(sourcedata.trial)
  cfgsel.trials = k;
  di(k) = ft_connectivityanalysis(cfg, ft_selectdata(cfgsel, sourcedata));
end

for k = 1:numel(di)
  for m = 1:numel(di(k).time)
    for p = 1:374
      di(k).di(p,p,m)=nan;
    end
  end
end
save([subj.name,'_di'],'di');
