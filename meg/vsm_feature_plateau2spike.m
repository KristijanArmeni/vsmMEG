function output = vsm_feature_plateau2spike(input, val)

if nargin<2
  val = nan;
end

output = input;

assert(numel(input.label)==1);
for k = 1:numel(input.trial)
  tmp = input.trial{k};
  finitevals       = isfinite(tmp);
  tmp(~finitevals) = -2000;
  
  begx = find(diff([-2000 tmp])~=0&diff([-2000 tmp])>-1000);
  
  output.trial{k} = zeros(1,numel(tmp))+nan;
  output.trial{k}(begx) = tmp(begx);
  output.trial{k}(ismember(output.trial{k}, [-2000 -4000])) = val;
end
