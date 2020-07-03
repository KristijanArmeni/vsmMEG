sname = {'s02','s03','s04','s07',...
        's11','s12','s13','s14','s15','s16',...
        's17','s18','s19','s20','s21','s22',...
        's23','s24','s25','s26','s27','s28'};
      
if ~exist('testfeature', 'var')
  testfeature = 'perplexity';
end
if ~exist('doshuf', 'var')
  doshuf = 0;
end
if ~exist('rseed', 'var')
  rseed = rng('shuffle');
end
rng(rseed);

for k = 1:numel(sname)
  [s, f] = vsm_dfi_getsourcedata(sname{k});
  
  cfg.channel = testfeature;
  f           = ft_selectdata(cfg, f);
  f.time      = s.time;
  
  if ~doshuf
    s           = ft_appenddata([], s, vsm_feature_roughen(f));
  else
    s           = ft_appenddata([], s, vsm_feature_roughen(vsm_feature_plateau2shuff(f)));
  end
  
  cfg             = [];
  cfg.method      = 'dfi';
  cfg.refindx     = 'all';
  cfg.dfi.feature = testfeature;
  cfg.dfi.lags    = (0.08:0.02:0.5);
  cfg.dfi.precondition = true;
  dfi(k)          = ft_struct2single(ft_connectivityanalysis(cfg, s));
end

for k = 1:numel(dfi)
  dfi(k).dfi = dfi(k).dfi(1:59,1:59,:,:); % this is hard coded
  dfi(k).label = dfi(k).label(1:59);
  for m = 1:59
    dfi(k).dfi(m,m,:,:) = nan;
  end
end
D = cat(5, dfi.dfi);
M = nanmean(D,5);
S = nanstd(D,[],5)./sqrt(numel(dfi));
T = M./S;

% zscore individual subjects with the std of the 'observed' data
if ~doshuf
  tmp   = reshape(D, [], numel(dfi));
  denom = nanstd(tmp,[],1);
else
  fname = sprintf('groupT_dfi_%s_mscca',testfeature);
  load(fname, 'denom');
end
D     = D./shiftdim(denom,-3);
M     = nanmean(D,5);
S     = nanstd(D,[],5)./sqrt(numel(dfi));
Tz    = M./S;

fname = sprintf('groupT_dfi_%s_mscca',testfeature);
if ~doshuf
  dfi = removefields(dfi, 'cfg');
  save(fname, 'T', 'Tz', 'dfi', 'denom', 'rseed');
else
  fname = sprintf('%s_%03d',fname,doshuf);
  save(fname, 'T', 'Tz', 'rseed');
end
