datadir = '/project/3011085.04/jansch';
cd(datadir);

testfeature = 'log10wf';
d = dir(sprintf('s*dfi*%s*.mat', testfeature));
n = {d.name}';
sel = ~contains(n, 'mscca'); % these are not needed here 
d = d(sel);
n = {d.name}';
sel = cellfun(@numel, n);
d = d(sel==26);

% create a table for existence of files
for k = 1:28
  xlabel{k} = sprintf('s%02d',k);
end
for k = 1:25
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
% sel = ~contains({d.name}', 'mscca');
% d = d(sel);
% 
% for k = 1:numel(d)
%   tmp{k} = d(k).name(1:3);
% end
% existmask = false(size(xlabel));
% tmp       = match_str(xlabel, tmp);
% existmask(tmp) = true;

ok   = sum(existfile,2)==25;
selx = xlabel(ok); % these subjects have 40 files for the mask, so results can be combined
for k = 1:numel(selx)
  for m = 1:numel(ylabel)
    d = dir(sprintf('%s*dfi*%s.mat', selx{k}, ylabel{m}));
    d = d(~contains({d.name}','mscca'));
    load(d.name);
    if m==1
      pmask = mask;
      N = nrand;
    else
      pmask = mask+pmask;
      N = nrand + N;
    end
  end
  pmask = (N+1 - pmask)./N;
  fname = [d.name(1:end-8) '_pmask'];
  save(fname, 'pmask');
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





