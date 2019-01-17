function trc = vsm_multisetcca_trc(tlck, varargin)

dosmooth = ft_getopt(varargin, 'dosmooth');

if ~isempty(dosmooth)
  % smooth
  for k = 1:size(tlck.trial,1)
    tlck.trial(k,:,:) = ft_preproc_smooth(squeeze(tlck.trial(k,:,:)), dosmooth);
  end
end

% permute and reshape the data into a nchan x nobs x ntime
dat = permute(tlck.trial,[2 1 3]);

% subtract the mean across trials
dat = dat-nanmean(dat,2);
dat(~isfinite(dat)) = 0;

c = nan+zeros(size(dat,1),size(dat,1),size(dat,3));
for k = 1:numel(tlck.time)
  datx=dat(:,:,k);
  datc=datx*datx';
  
  c(:,:,k) = datc./sqrt(diag(datc)*diag(datc)');
end

trc.rho    = c;
trc.label  = tlck.label;
trc.time   = tlck.time;
trc.dimord = 'chan_chan_time';
