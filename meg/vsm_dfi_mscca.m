
load(fullfile('/project/3011085.04/data/derived/mscca',sprintf('%s_sourcedata_mscca',subj.name)));
%load(fullfile('/project/3011085.04/data/derived/mscca','AUDIODATA'))
load(fullfile('/project/3011085.04/data/derived/mscca','AUDIODATA_box'))


% This chunk must be uncommented if the AUDIODATA_BOX is loaded
kk = [1 2 3 4 4 5 5];
for k = 1:numel(data.trial)
  sel1 = nearest(audiodata.time{kk(k)}, data.time{k}(1));
  sel2 = nearest(audiodata.time{kk(k)}, data.time{k}(end));
  trial{1,k} = audiodata.trial{kk(k)}(:,sel1:sel2);
  time{1,k}  = audiodata.time{kk(k)}(sel1:sel2); 
end
  
if numel(audiodata.trial)~=numel(data.trial)
  audiodata = vsm_splitlongtrials(audiodata);
end
audiodata.trial = trial;
audiodata.time  = time;

% This chunk must be uncommented if the AUDIODATA is loaded
%if numel(audiodata.trial)~=numel(data.trial)
%  audiodata = vsm_splitlongtrials(audiodata);
%end
% if numel(audiodata.time{1})~=numel(data.time{1})
%   % there was a different number of shifts in the mscca, versus the number
%   % of shifts used to truncate the time axis of the audiodata, this needs
%   % to be adjusted. Here it is assumed that the adjustment is the same for each of the
%   % original trials, i.e. chopping off 2 samples on each end, OF THE
%   % ORIGINAL TRIALS. This means that the originally longer trials need to
%   % be adjusted only on one side.
%   sel1 = 3;
%   sel2 = 2;
%   
%   for k = 1:numel(data.trial)
%     if k==1||k==2||k==3
%       data.trial{k} = data.trial{k}(:,sel1:(end-sel2));
%       data.time{k}  = data.time{k}(sel1:(end-sel2));
%     elseif k==4||k==6
% 
%       data.trial{k} = data.trial{k}(:,3:end);
%       data.time{k}  = data.time{k}(3:end);
%       audiodata.trial{k} = audiodata.trial{k}(:,1:(end-4));
%       audiodata.time{k}  = audiodata.time{k}(1:(end-4));
%     elseif k==5||k==7
%       data.trial{k} = data.trial{k}(:,1:(end-2));
%       data.time{k}  = data.time{k}(1:(end-2));
%       audiodata.trial{k} = audiodata.trial{k}(:,5:end);
%       audiodata.time{k}  = audiodata.time{k}(5:end);
%     end
%   end
% end

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

sourcedata_orig  = sourcedata;
featuredata_orig = audiodata;

selchan = find(contains(featuredata_orig.label,'perpl'));
for k = 1:numel(featuredata_orig.trial)
  featuredata_orig.trial{k}(selchan,:) = log10(featuredata_orig.trial{k}(selchan,:));
  featuredata_orig.trial{k}(selchan,~isfinite(featuredata_orig.trial{k}(selchan,:))) = 0;  
end

if ~exist('testfeature', 'var')
  testfeature = 'perplexity';
end
if ~exist('nrand', 'var')
  nrand = 100;
end
if ~exist('subindx', 'var')
  subindx = [];
end
if ~exist('computethr', 'var')
  computethr = false;
end
if ~exist('loadthr', 'var')
  loadthr = false;
end
if computethr&&loadthr
  error('the threshold cannot be loaded and computed in the same script');
end


cfgsel1.channel = testfeature;
featuredata     = ft_selectdata(cfgsel1, featuredata_orig);
featuredata.time = sourcedata_orig.time;
sourcedata      = ft_appenddata([],sourcedata_orig, vsm_feature_roughen(featuredata));

rseed = rng('shuffle');

cfg             = [];
cfg.method      = 'dfi';
cfg.refindx     = 'all';
cfg.dfi.feature = testfeature;
cfg.dfi.lags    = (0.08:0.02:0.5);
cfg.dfi.precondition = true;
if loadthr
  fname = sprintf('%s_dfi_%s_mscca',subj.name,testfeature);
  load(fname);
else  
  dfi        = ft_struct2single(ft_connectivityanalysis(cfg, sourcedata));
  thr        = [];
  thr_global = [];
end
for k = 1:nrand
  sourcedata      = ft_appenddata([],sourcedata_orig, vsm_feature_roughen(vsm_feature_plateau2shuff(featuredata)));
  dfi_c           = ft_struct2single(ft_connectivityanalysis(cfg, sourcedata));
  if k==1
    mask = double(dfi.dfi>dfi_c.dfi);
  else
    mask = mask + double(dfi.dfi>dfi_c.dfi);
  end
  if ~isempty(thr)
    % also build a reference distribution for thresholded cluster sizes
    s95 = vsm_clusterstat(real(dfi_c.dfi(1:end-1,1:end-1,:,:)), thr_global(2));
    s99 = vsm_clusterstat(real(dfi_c.dfi(1:end-1,1:end-1,:,:)), thr_global(4));
    s95b = vsm_clusterstat(real(dfi_c.dfi(1:end-1,1:end-1,:,:)), thr(:,2));
    s99b = vsm_clusterstat(real(dfi_c.dfi(1:end-1,1:end-1,:,:)), thr(:,4));
    
    % note: the reference distributions will need an extra (double)max,
    % because it requires a single value per randomization
    ref95(:,:,k)  = reshape(max(s95,[],2), [1 1].*sqrt(size(s95, 1)));
    ref95b(:,:,k) = reshape(max(s95b,[],2),[1 1].*sqrt(size(s95b,1)));
    ref99(:,:,k)  = reshape(max(s99,[],2), [1 1].*sqrt(size(s99, 1)));
    ref99b(:,:,k) = reshape(max(s99b,[],2),[1 1].*sqrt(size(s99b,1)));
  end
  if computethr
    dfi_rand(k) = dfi_c;
  end
end
if nrand==0
  mask = zeros(size(dfi.dfi));
end
if computethr
  % estimate for each source-target pair the distribution across the nrand
  % + observed data
  dfi_rand(end+1) = dfi;
  
  indx = triu(ones(numel(dfi.time)),1)>0;
  for k = 1:numel(dfi_rand)
    for m = 1:numel(dfi_rand(k).label)
      % avoid the numerical ill behaviour of self combinations
      dfi_rand(k).dfi(m,m,:,:) = nan;
    end
    dfi_rand(k).dfi = reshape(dfi_rand(k).dfi(1:end-1,1:end-1,:,:),[],numel(dfi.time).^2);
    dfi_rand(k).dfi = dfi_rand(k).dfi(:,indx(:));
  end
  x = cat(2,dfi_rand.dfi);
  thr = prctile(x,[90 95 97.5 99],2);
  thr_global = prctile(x(:),[90 95 97.5 99]);
end

dfi   = removefields(dfi, 'cfg');
fname = sprintf('%s_dfi_%s_mscca',subj.name,testfeature);
if ~isempty(subindx) && ~isempty(thr)
  fname = sprintf('%s_%03d',fname, subindx);
  save(fname, 'mask','nrand','rseed','ref95','ref95b','ref99','ref99b','thr','thr_global');
elseif ~isempty(subindx)
  fname = sprintf('%s_%03d',fname, subindx);
  save(fname, 'mask','nrand','rseed');
elseif computethr
  save(fname, 'dfi', 'thr', 'thr_global');
else
  save(fname, 'dfi', 'mask','nrand');
end
