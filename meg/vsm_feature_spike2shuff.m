function [output, shiftval] = vsm_feature_spike2shuff(input, seed, flag)

% VSM_FEATURE_SPIKE2SHUFF rearranges the feature values randomly
% but preserve the word timings, which are spike-wise represented
% in the time courses. This assumes a data structure with a single
% channel in the input

if nargin<3
  flag = false;
end

if nargin==1
  seed = [];
elseif ~isempty(seed)
  rng(seed);
end

output = input;
%spikes = vsm_feature_plateau2spike(input, nan);
spikes = input;

spike_val = cat(2,spikes.trial{:});
spike_val(spike_val==0)=[];

if ~isequal(flag, 0)
  % do a circular shift, this preserves the auto correlation sequence
%   if istrue(flag)
%     % random shift
%     shiftval = randi([30 numel(spike_val)-30],1);
%   else
%     shiftval = flag;
%   end
%   spike_val = circshift(spike_val, shiftval);
  if numel(flag)==numel(spikes.trial)
    shiftval = flag;
    n = 0;
    for k = 1:numel(spikes.trial)
      nspikes = sum(spikes.trial{k}~=0);
      n = n+(1:nspikes);
      spike_val(n) = circshift(spike_val(n), shiftval(1,k));
      n = n(end);
    end
  else
    n = 0;
    for k = 1:numel(spikes.trial)
      nspikes = sum(spikes.trial{k}~=0);
      n = n+(1:nspikes);
      shiftval(1,k) = randi([1 nspikes-1],1);
      spike_val(n) = circshift(spike_val(n), shiftval(1,k));
      n = n(end);
    end
  end
else
  % randomize
  randvec   = randperm(numel(spike_val));
  spike_val = spike_val(randvec);
  shiftval  = nan;
end

n = 0;
for k = 1:numel(spikes.trial)
  n = n+(1:sum(spikes.trial{k}~=0));
  spikes.trial{k}(spikes.trial{k}~=0) = spike_val(n); 
  n = n(end);
end

assert(numel(input.label)==1);
for k = 1:numel(input.trial)
  tmp = input.trial{k};
  finitevals       = tmp~=0;
  tmp(~finitevals) = -2000;
  
  begx = find(diff([-2000 tmp])~=0&diff([-2000 tmp])>-1000);
  endx = find(diff([tmp -2000])~=0&diff([tmp -2000])<1000);
  
  spike_val = spikes.trial{k}(spikes.trial{k}~=0);
  assert(isequal(numel(spike_val), numel(begx)));
  
  output.trial{k} = zeros(1,numel(tmp));
  for m = 1:numel(begx)
    output.trial{k}(begx(m):endx(m)) = spike_val(m);
  end
end
