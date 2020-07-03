function [output] = vsm_feature_roughen(input, seed)

if nargin==1

else
  rng(seed);
end

tmp = cat(2,input.trial{:});
tmp(~isfinite(tmp)) = [];
utmp = unique(tmp);
dtmp = diff(utmp);
q    = min(dtmp);

output = input;
for k = 1:numel(input.trial)
  output.trial{k} = input.trial{k} + rand(1,numel(input.time{k})).*q;
end
