sname = {'s02','s03','s04','s07',...
        's11','s12','s13','s14','s15','s16',...
        's17','s18','s19','s20','s21','s22',...
        's23','s24','s25','s26','s27','s28'};
      
if ~exist('doshuf', 'var')
  doshuf = 0;
end
if ~exist('rseed', 'var')
  rseed = rng('shuffle');
end
rng(rseed);

for k = 1:numel(sname)
  [s, f] = vsm_dfi_getsourcedata(sname{k},0);
  
  cfg         = [];
  cfg.channel = 'perplexity';
  fp          = ft_selectdata(cfg, f);
  fp.time     = s.time;
  cfg.channel = 'entropy';
  fe          = ft_selectdata(cfg, f);
  fe.time     = s.time;
  cfg.channel = 'log10wf';
  fl          = ft_selectdata(cfg, f);
  fl.time     = s.time;
   
  if doshuf 
    fp = vsm_feature_plateau2shuff(fp);
    fe = vsm_feature_plateau2shuff(fe);
    fl = vsm_feature_plateau2shuff(fl);
  end
  
  fp = vsm_feature_roughen(fp);
  fe = vsm_feature_roughen(fe);
  fl = vsm_feature_roughen(fl);
  
  cfg             = [];
  cfg.method      = 'mi';
  cfg.mi.lags    = (-0.1:0.02:0.5);
  cfg.mi.precondition = true;
  
  % univariate p/e/l
  cfg.refindx     = 375;
  mi(k,1)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fp))), 'cfg');
  mi(k,2)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fe))), 'cfg');
  mi(k,3)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fl))), 'cfg');
  
  % bivariate pe/pl/el
  cfg.refindx     = [375 376];
  mi(k,4)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fp, fe))), 'cfg');
  mi(k,5)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fp, fl))), 'cfg');
  mi(k,6)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fe, fl))), 'cfg');
  
  % remove the ugly parcels, these are [1 2 188 189 186 373]
  for m = 1:size(mi,2)
    mi(k,m).mi([1 2 188 189 186 373 375],:) = nan;
    mi(k,m).mi = mi(k,m).mi(1:374,:);
  end
end

% compute the information terms for 4/5/6
for k = 1:size(mi,1)
  mi(k,4).mi = mi(k,1).mi+mi(k,2).mi-mi(k,4).mi; 
  mi(k,5).mi = mi(k,1).mi+mi(k,3).mi-mi(k,5).mi;
  mi(k,6).mi = mi(k,2).mi+mi(k,3).mi-mi(k,6).mi;
end

D = zeros([size(mi) size(mi(1).mi)]);
for k = 1:size(mi,1)
  for m = 1:size(mi,2)
    D(k,m,:,:) = mi(k,m).mi;
  end
end
M = squeeze(nanmean(D,1));

% zscore individual subjects with the std of the 'observed' data
if ~doshuf
  siz   = size(D);
  tmp   = reshape(permute(D, [3 4 1 2]), [siz(3)*siz(4) siz(1) siz(2)]);
  denom = nanstd(tmp,[],1);
else
  fname = sprintf('groupT_mi_mscca');
  load(fname, 'denom');
end
D     = D./shiftdim(denom);
Mz    = squeeze(nanmean(D,1));
%S     = nanstd(D,[],3)./sqrt(numel(mi));
%Tz    = M./S;

fname = sprintf('groupT_mi_mscca');
if ~doshuf
  save(fname, 'M', 'Mz', 'mi', 'denom', 'rseed');
else
  fname = sprintf('%s_%03d',fname,doshuf);
  save(fname, 'M', 'Mz', 'rseed');
end
