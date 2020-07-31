function [output] = vsm_feature_roughen(input, seed)

if nargin==1

else
  rng(seed);
end

tmp = cat(2,input.trial{:});
q = zeros(size(tmp,1),1);
for k = 1:size(tmp,1)
  this_tmp = tmp(k,:);
  this_tmp(~isfinite(this_tmp)) = [];
  utmp = ft_preproc_smooth(unique(this_tmp),5);
  dtmp = diff(utmp);
  q(k,1) = min(dtmp);
end

output = input;
for k = 1:numel(input.trial)
  output.trial{k} = input.trial{k} + rand(1,numel(input.time{k})).*q(:,ones(1,numel(input.time{k})));
end
