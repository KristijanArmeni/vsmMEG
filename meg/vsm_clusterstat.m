function s = vsm_clusterstat(dfi, thr)

% Helper function to create a cluster-based test statistic for dfi data.
% Input dfi should be NxNxMxM (Nsource x Ntarget x Nlag x Nlag)
% If thr is a scalar, then it's used as a global threshold, otherwise thr
% should be N^2 element vector, then a threshold per source-target pair is
% used

ft_hastoolbox('spm12',1);

siz = size(dfi);
assert(siz(1)==siz(2));
assert(siz(3)==siz(4));

dat = reshape(dfi, [siz(1)^2 siz(3:4)]);
if numel(thr)==1
  dat_thr = dat>thr;
else
  dat_thr = dat>repmat(thr(:),[1 siz(3) siz(3)]);
end

pw_dir = pwd;
cd ~/matlab/fieldtrip/private
[c,num] = findcluster(dat_thr, eye(siz(1)^2));

skip = 1:(siz(1)+1):siz(1)^2;
for k = 1:size(c,1)
  % skip the auto combinations
  if any(k==skip)
    %skip
  else
    this_c  = squeeze(c(k,:,:));
    thisdat = squeeze(dat(k,:,:));
    u_this = unique(this_c(:));
    u_this(~isfinite(u_this)) = [];
    tmps = zeros(numel(u_this)-1,1);
    cnt = 0;
    for m = 1:numel(u_this)
      if u_this(m)~=0
        cnt = cnt+1;
        tmps(cnt) = nansum(nansum(double(thisdat).*double(this_c==u_this(m))));
      end
    end
    s(1:numel(tmps),k) = tmps;
  end
end
s(:,k) = 0; % the last one is always an auto combination
s = s';
cd(pw_dir);