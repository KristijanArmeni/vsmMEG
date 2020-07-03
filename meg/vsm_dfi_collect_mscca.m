atlasfile = fullfile('/project/3011085.05/data/atlas','atlas_subparc374_4k.mat');
load(atlasfile);

plist = {'L_20';'L_21';'L_22';'L_37';'L_38';'L_39';'L_40';'L_41';'L_42';'L_43';'L_44';'L_45';'L_46';'L_47'};
sel = false(size(atlas.parcellationlabel));
for k = 1:numel(plist)
  sel = startsWith(atlas.parcellationlabel,plist{k})|sel;
%  sel = startsWith(atlas.parcellationlabel,strrep(plist{k},'L','R'))|sel;
end

cd /project/3011085.04/jansch/;
d = dir('*_dfi_perplexity_mscca.mat');

for k = 1:numel(d)
  k
  load(d(k).name);
  
  [a,b]     = match_str(atlas.parcellationlabel,dfi.label);
  dfi.dfi   = real(  dfi.dfi(b,b,:,:));
  dfi_c.dfi = real(dfi_c.dfi(b,b,:,:));
  
  dfi.dfi   = dfi.dfi(sel(a),sel(a),:,:);
  dfi.label = dfi.label(sel(a));
  dfi.dimord = 'chan_chan_time_time';
  dfi_c.dfi = dfi_c.dfi(sel(a),sel(a),:,:);
  dfi_c.label = dfi_c.label(sel(a));
  dfi_c.dimord = 'chan_chan_time_time';
  
  save([d(k).name(1:end-4), '_pruned'], 'dfi', 'dfi_c');
  clear dfi dfi_c;
  
end

d    = dir('*perplexity_mscca_pruned.mat');
nsubj = numel(d);
load(d(1).name);
indx = tril(ones(numel(dfi.time)),2)>0; % these are the nan-valued dfi estimates

D  = zeros(sum(sel),sum(sel),sum(indx(:)==0),nsubj);
Dc = D;
for k = 1:nsubj
  load(d(k).name);
  alldat(:,:,:,:,k) = dfi.dfi;
  if k==1, alldat(:,:,:,:,nsubj) = 0; end
  D(:,:,:,k)  = dfi.dfi(  :,:,~indx);
  Dc(:,:,:,k) = dfi_c.dfi(:,:,~indx);  
end
siz = size(D);

D   = reshape(D,  [prod(siz(1:end-1)) nsubj]);
Dc  = reshape(Dc, [prod(siz(1:end-1)) nsubj]);

D(~isfinite(D))   = 0;
Dc(~isfinite(Dc)) = 0;

design = [ones(1,nsubj) ones(1,nsubj)*2;1:nsubj 1:nsubj];

cfg      = [];
cfg.ivar = 1;
cfg.uvar = 2;
cfg.tail = 1;
cfg.statistic = 'ft_statfun_depsamplesTJM';
%cfg.correctm = 'max';
cfg.numrandomization = 1000;
s        = ft_statistics_montecarlo(cfg, [D Dc], design);
T        = reshape(s.stat, siz(1:3));
p        = reshape(s.prob, siz(1:3));
label = atlas.parcellationlabel;
tim   = dfi.time;
save('stats_dfi_perplexity_mscca', 'p', 'T', 'sel', 'indx', 'tim', 'label');

P = zeros(sum(sel),sum(sel),numel(tim),numel(tim));
Tstat = P;
for k = 1:sum(sel)
  for m = 1:sum(sel)
    tmp    = squeeze(p(k,m,:));
    if k==m
      tmp(:) = 1;
    end
    tmptmp = nan+zeros(numel(tim));
    tmptmp(~indx) = tmp;
    P(k,m,:,:) = tmptmp;
    tmp    = squeeze(T(k,m,:));
    if k==m
      tmp(:) = 0;
    end
    tmptmp = nan+zeros(numel(tim));
    tmptmp(~indx) = tmp;
    Tstat(k,m,:,:) = tmptmp;
  end
end

P    = sum(sum(P<0.005,4),3);
dat  = zeros(374,374);
dat(sel,sel) = P-diag(diag(P));

