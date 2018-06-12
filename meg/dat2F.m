function [F, R0, R, n, p1, p2, B] = dat2F(alldat, design, col0, lambda, B)

if nargin<3 || isempty(col0)
  col0 = 1;
end

if nargin<4 || isempty(lambda)
  lambda = 0;
end

if nargin<5
  B = [];
end

n  = size(design,1);
p2 = size(design,2);
p1 = numel(col0);

siz = size(alldat);
dat = reshape(permute(alldat,[1 3 2]),[siz(1) siz(2)*siz(3)]);
%dat = dat - nanmean(dat,1);
%dat = normc(dat);
design = demean(design);
if isempty(B)
  if ~lambda
    B   = design\dat;
  else
    B   = ((design'*design+lambda.*eye(size(design,2)))\design')*dat;
  end
elseif iscell(B)
  numfolds = numel(B);
  Bout     = cell(1, numfolds); % for fold-specific output
  
  % assume that B is a cell-array containing the indices of the test-folds.
  for k = 1:numfolds
    
    fprintf('Estimating fold %d out of %d ... \n', k, numfolds)
    
    ix = B{k};                         % test fold indices
    iy = setdiff(1:size(alldat,1),ix); % estimation set indices
    
    % demean all regressors, apart from the constant one
    design(iy,:) = demean(design(iy,:)); %
    design(ix,:) = demean(design(ix,:));
    
    % 
    [~, ~, ~, ~, ~, ~, Btmp] = dat2F(alldat(iy,:,:), design(iy,:), col0, lambda); 
    [~, tmpR0, tmpR]         = dat2F(alldat(ix,:,:), design(ix,:), col0, lambda, Btmp);
    
    Bout{k} = Btmp; % save training set betas per fold
    
    if k==1
      R0 = tmpR0.*numel(ix);
      R  =  tmpR.*numel(ix);
      n  =        numel(ix);
    else
      R0 = tmpR0.*numel(ix) + R0;
      R  = tmpR .*numel(ix) + R;
      n  =        numel(ix) + n;
    end
  end
  F = (R0-R)./R;
  B = Bout; clear Bout
  return;
else
  % use the pre-supplied weights
  B = reshape(permute(B, [1 3 2]), [size(B,1) size(B,2)*size(B,3)]);
end

R0 = permute(reshape(sum((dat-design(:,col0)*B(col0,:)).^2,1),[siz(3) siz(2)]),[2 1]);
R  = permute(reshape(sum((dat-design*B).^2,1),[siz(3) siz(2)]),[2 1]);
F  = ((R0-R)./(p2-p1))./(R./(n-p2));
B  = permute(reshape(B,[size(B,1) siz(3) siz(2)]),[1 3 2]);

function out = demean(in)

out = in - repmat(nanmean(in,1), size(in,1), 1);
sel = all(sum(out==0),1);
out(:,sel) = in(:,sel);

