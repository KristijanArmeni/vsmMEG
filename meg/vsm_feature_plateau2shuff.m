function output = vsm_feature_plateau2shuff(input, seed)

% VSM_FEATURE_PLATEAU2SHUFF rearranges the feature values randomly
% but preserve the word timings, which are block-wise represented
% in the time courses. This assumes a data structure with a single
% channel in the input

if nargin==1

else
  rng(seed);
end

output = input;
spikes = vsm_feature_plateau2spike(input, nan);

spike_val = cat(2,spikes.trial{:});
spike_val(~isfinite(spike_val))=[];
spike_val = spike_val(randperm(numel(spike_val)));
n = 0;
for k = 1:numel(spikes.trial)
  n = n+(1:sum(isfinite(spikes.trial{k})));
  spikes.trial{k}(isfinite(spikes.trial{k})) = spike_val(n); 
  n = n(end);
end

assert(numel(input.label)==1);
for k = 1:numel(input.trial)
  tmp = input.trial{k};
  finitevals       = isfinite(tmp);
  tmp(~finitevals) = -2000;
  
  begx = find(diff([-2000 tmp])~=0&diff([-2000 tmp])>-1000);
  endx = find(diff([tmp -2000])~=0&diff([tmp -2000])<1000);
  
  spike_val = spikes.trial{k}(isfinite(spikes.trial{k}));
  assert(isequal(numel(spike_val), numel(begx)));
  
  output.trial{k} = zeros(1,numel(tmp))+nan;
  for m = 1:numel(begx)
    output.trial{k}(begx(m):endx(m)) = spike_val(m);
  end
end
