sname = {'s02','s03','s04','s05','s07','s08','s10',...
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
  [s, f] = vsm_dfi_getsourcedata(sname{k},0,k);
  
  forig = f;
  for m = 2:4
    tmp = forig;
    tmp.trial = cellrowselect(forig.trial, m);
    tmp.label = tmp.label(m);
    tmp       = vsm_feature_plateau2spike(tmp,0,1);
    forig.trial = cellrowassign(forig.trial, tmp.trial, m);  
  end
  for m = 1:numel(forig.trial)
     tmp.trial{m} = double(forig.trial{m}(2,:)~=0|forig.trial{m}(3,:)~=0|forig.trial{m}(4,:)~=0);
  end
  forig.trial    = cellrowassign(forig.trial,tmp.trial,5);
  forig.label{5} = 'wordonset';
  
  f = forig;
  
  cfg         = [];
  cfg.channel = 'audio_avg';
  fa          = ft_selectdata(cfg, f);
  cfg.channel = 'perplexity';
  fp          = ft_selectdata(cfg, f);
  fp.time     = s.time;
  cfg.channel = 'entropy';
  fe          = ft_selectdata(cfg, f);
  fe.time     = s.time;
  cfg.channel = 'log10wf';
  fl          = ft_selectdata(cfg, f);
  fl.time     = s.time;
  cfg.channel = 'wordonset';
  fw          = ft_selectdata(cfg, f);
  fw.time     = s.time;
  
  if doshuf 
    shiftval = doshuf; % just some number, cause circular shift rather than random shuffle, ensure that it's unique
    fporig = fp;
    [fp, shiftval] = vsm_feature_spike2shuff(fp, rseed, shiftval); % ensure same shuffle
    [fe, dum1]           = vsm_feature_spike2shuff(fe, rseed, shiftval);
    [fl, dum2]           = vsm_feature_spike2shuff(fl, rseed, shiftval);
  end
  
  cfg = [];
  cfg.conv = exp(-(0:0.2:4));
  cfg.conv = [zeros(1,numel(cfg.conv)-1) cfg.conv];%./sum(cfg.conv(:));
  fp = ft_preprocessing(cfg, fp);
  fe = ft_preprocessing(cfg, fe);
  fl = ft_preprocessing(cfg, fl);
  fw = ft_preprocessing(cfg, fw);

  for m = 1:numel(fp.trial)
    fp.trial{m}(fp.trial{m}==0) = nan;
    fe.trial{m}(fe.trial{m}==0) = nan;
    fl.trial{m}(fl.trial{m}==0) = nan;
    fw.trial{m}(fw.trial{m}==0) = nan;
  end
  
  cfg             = [];
  cfg.method      = 'mi';
  cfg.mi.lags    = (-0.1:0.02:0.5);%(-0.1:0.02:0.5);
  cfg.mi.precondition = true;
  
  % univariate a/p/e/l/w
  cfg.refindx     = 375;
  mi(k,1)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fa))), 'cfg');
  mi(k,2)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fp))), 'cfg');
  mi(k,3)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fe))), 'cfg');
  mi(k,4)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fl))), 'cfg');
  mi(k,5)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fw))), 'cfg');
  
  % bivariate aw
  cfg.refindx     = [375 376];
  mi(k,6)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fa, fw))), 'cfg');
  
  % bivariate wp/we/wl
  cfg.refindx     = [375 376];
  mi(k,7)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fw, fp))), 'cfg');
  mi(k,8)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fw, fe))), 'cfg');
  mi(k,9)         = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fw, fl))), 'cfg');
  
  % trivariate awp/awe/awl
  cfg.refindx     = [375 376 377];
  mi(k,10)        = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fa, fw, fp))), 'cfg');
  mi(k,11)        = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fa, fw, fe))), 'cfg');
  mi(k,12)        = rmfield(ft_struct2single(ft_connectivityanalysis(cfg, ft_appenddata([],s, fa, fw, fl))), 'cfg');
  
  % remove the ugly parcels, these are [1 2 188 189 186 373]
  for m = 1:size(mi,2)
    mi(k,m).mi([1 2 188 189 186 373 375],:) = nan;
    mi(k,m).mi = mi(k,m).mi(1:374,:);
  end
end

% compute the co-information terms 
for k = 1:size(mi,1)
  mi(k,13).mi  = mi(k,5).mi+mi(k,2).mi-mi(k,7).mi; % perp, beyond word onset
  mi(k,14).mi  = mi(k,5).mi+mi(k,3).mi-mi(k,8).mi; % entr, beyond word onset
  mi(k,15).mi  = mi(k,5).mi+mi(k,4).mi-mi(k,9).mi; % lexfreq, beyond word onset

  mi(k,16).mi  = mi(k,1).mi+mi(k,5).mi-mi(k,6).mi; % word onset, beyond audio
  mi(k,17).mi  = mi(k,6).mi+mi(k,2).mi-mi(k,10).mi; % perp, beyond audio+word onset
  mi(k,18).mi  = mi(k,6).mi+mi(k,3).mi-mi(k,11).mi; % entr, beyond audio+word onset
  mi(k,19).mi  = mi(k,6).mi+mi(k,4).mi-mi(k,12).mi; % lexfreq, beyond audio+word onset
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
  save(fname, 'M', 'Mz', 'rseed', 'shiftval');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1 I(meg; audio)
% 2 I(meg; perplexity) mean subtracted
% 3 I(meg; entropy)    mean subtracted
% 4 I(meg; lexfreq)    mean subtracted
% 5 I(meg; word onset)
% 6 I(meg; audio, word onset)
% 7 I(meg; word onset, perplexity)
% 8 I(meg; word onset, entropy)
% 9 I(meg; word onset, lexfreq)
% 10 I(meg; audio, word onset, perplexity)
% 11 I(meg; audio, word onset, entropy)
% 12 I(meg; audio, word onset, lexfreq)
% 13 coI(meg; perplexity, beyond word onset)
% 14 coI(meg; entropy, beyond word onset)
% 15 coI(meg; lexfreq, beyond word onset)
% 16 coI(meg; word onset, beyond audio)
% 17 coI(meg; perplexity, beyond audio + word onset)
% 18 coI(meg; entropy, beyond audio + word onset)
% 19 coI(meg; lexfreq, beyond audio + word onset)


