datadir = '/project/3011085.04/jansch';
cd(datadir);

testfeature = 'entropy';
d = dir(sprintf('s*dfi*%s*.mat', testfeature));

% create a table for existence of files
for k = 1:28
  xlabel{k} = sprintf('s%02d',k);
end
for k = 1:50
  ylabel{k} = sprintf('%03d',k);
end

existfile = zeros(numel(xlabel), numel(ylabel));
for m = 1:numel(d)
  xsel = strcmp(xlabel, d(m).name(1:3));
  ysel = strcmp(ylabel, d(m).name((end-6):(end-4)));
  if sum(xsel)&&sum(ysel)
    existfile(xsel,ysel) = true;
  end
end

% d = dir(sprintf('s*dfi*%s*pmask.mat', testfeature));
% for k = 1:numel(d)
%   tmp{k} = d(k).name(1:3);
% end
% existmask = false(size(xlabel));
% tmp       = match_str(xlabel, tmp);
% existmask(tmp) = true;

ok   = sum(existfile,2)==50;
selx = xlabel(ok); % these subjects have 50 files for the mask, so results can be combined


for k = 1:numel(selx)
  k
  R95   = zeros(1,0);
  R99   = zeros(1,0);
  R95b  = zeros(59,59,0);
  R99b  = zeros(59,59,0);

  for m = 1:numel(ylabel)
    d = dir(sprintf('%s*dfi*%s*mscca*%s.mat', selx{k}, testfeature, ylabel{m}));
    load(d.name);
    Rseed(m) = rseed;
    R95 = cat(2, R95, shiftdim(max(max(ref95,[],2),[],1),1));
    R99 = cat(2, R99, shiftdim(max(max(ref99,[],2),[],1),1));
    R95b = cat(3, R95b, ref95b);
    R99b = cat(3, R99b, ref99b);
    
    if m==1
      pmask = mask;
      N = nrand;
    else
      pmask = mask+pmask;
      N = N+nrand;
    end
  end
  
  d = dir(sprintf('%s*dfi*%s*mscca.mat', selx{k}, testfeature));
  load(d.name, 'dfi');
  s95  = sort(vsm_clusterstat(real(dfi.dfi(1:59,1:59,:,:)), thr_global(2)), 2, 'descend');
  s99  = sort(vsm_clusterstat(real(dfi.dfi(1:59,1:59,:,:)), thr_global(4)), 2, 'descend');
  s95b = sort(vsm_clusterstat(real(dfi.dfi(1:59,1:59,:,:)), thr(2)), 2, 'descend');
  s99b = sort(vsm_clusterstat(real(dfi.dfi(1:59,1:59,:,:)), thr(4)), 2, 'descend');
  
  for kk = 1:size(s95,2)
    p95(:,kk) = sum(s95(:,kk)<R95,2)./(size(R95,2)+1);
  end
  for kk = 1:size(s99,2)
    p99(:,kk) = sum(s99(:,kk)<R99,2)./(size(R99,2)+1);
  end
  for kk = 1:size(s95b,2)
    this = reshape(s95b(:,kk),[59 59]);
    p95b(:,:,kk) = sum(this(:,:,ones(1,size(R95b,3)))<R95b,3)./(size(R95b,3)+1);
  end
  for kk = 1:size(s99b,2)
    this = reshape(s99b(:,kk),[59 59]);
    p99b(:,:,kk) = sum(this(:,:,ones(1,size(R99b,3)))<R99b,3)./(size(R99b,3)+1);
  end
  p95 = reshape(p95,[59 59 size(p95,2)]);
  p99 = reshape(p99,[59 59 size(p99,2)]);
  
  pmask = (N+1 - pmask)./(N+1);
  pmask = pmask(1:59,1:59,:,:);
  fname = [d.name(1:end-4) '_pmask'];
  rseed = Rseed; clear Rseed;
  save(fname, 'pmask', 'rseed', 'p95', 'p95b', 'p99', 'p99b', 's95', 's95b', 's99', 's99b');
  clear p95 p99 p95b p99b
end

[ix,iy] = find(~existfile);
uix = unique(ix);
getx = zeros(0,1);
gety = zeros(0,1);
for k = 1:numel(uix)
  if sum(ix==uix(k))==40
    % either the mask already exists, and files have been removed, or
    % subject does not have data, skip
  else
    getx = cat(1,getx,ix(ix==uix(k)));
    gety = cat(1,gety,iy(ix==uix(k)));
  end
end

for k = 1:numel(getx)
  subj.name = xlabel{getx(k)};
  subindx = str2double(ylabel{gety(k)});
  nrand = 25;
  qsubfeval('vsm_execute_pipeline','vsm_dfi_mscca',...
    {'subj' subj},{'testfeature' testfeature}, {'nrand' nrand}, {'subindx' subindx},...
    'memreq',16*1024^3,'timreq',60*60,'batchid',sprintf('%s_%03d',subj.name,subindx));
end





