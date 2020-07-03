function [data, trf, trf_pca] = vsm_multisetcca2singlesubject(subjectname)

% hard coded
msccadir = '/project/3011085.04/data/derived/mscca';

pwdir = pwd;
cd(msccadir);

atlasfile = fullfile('/project/3011085.05/data/atlas','atlas_subparc374_4k.mat');
load(atlasfile);

d = dir('*parcel*');
tmp = cell(numel(d),1);
tmp2 = cell(numel(d),1);
tmp3 = cell(numel(d),1);
for k = 1:numel(d)
  k
  load(d(k).name);
  
  sel  = find(contains(comp.label,subjectname));
  comp.trial = cellrowselect(comp.trial, sel);
  comp.label = atlas.parcellationlabel(str2double(d(k).name(13:15)));
  tmp{k} = rmfield(comp, 'audiofile');
  
  sel  = find(contains(trf.label,subjectname));
  b    = cat(3,trf.weights.beta);
  p    = cat(2,trf.weights.performance);
  r    = cat(2,trf.weights.rho);
  
  tmp2{k}.label = comp.label;!rm *.o
  tmp2{k}.time  = trf.weights(1).time;
  tmp2{k}.reflabel    = trf.weights(1).reflabel;
  tmp2{k}.beta        = mean(b(sel,:,:),3);
  tmp2{k}.performance = mean(p(sel,:,:),2);
  tmp2{k}.rho         = mean(r(sel,:,:),2);
  
  sel  = find(contains(trf_pca.label,subjectname));
  b    = cat(3,trf_pca.weights.beta);
  p    = cat(2,trf_pca.weights.performance);
  r    = cat(2,trf_pca.weights.rho);
  
  tmp3{k}.label = comp.label;
  tmp3{k}.time  = trf_pca.weights(1).time;
  tmp3{k}.reflabel    = trf.weights(1).reflabel;
  tmp3{k}.beta        = mean(b(sel,:,:),3);
  tmp3{k}.performance = mean(p(sel,:),2);
  tmp3{k}.rho         = mean(r(sel,:),2);
  
end

cfg = [];
cfg.appenddim = 'chan';
cfg.parameter = {'performance' 'beta' 'rho'};
trf = ft_appendtimelock(cfg, tmp2{:}); % somehow the scalar parameters end up on the diagonal of a matrix
trf.performance = diag(trf.performance);
trf.rho = diag(trf.rho);

cfg = [];
cfg.appenddim = 'chan';
cfg.parameter = {'performance' 'beta' 'rho'};
trf_pca = ft_appendtimelock(cfg, tmp3{:}); % somehow the scalar parameters end up on the diagonal of a matrix
trf_pca.performance = diag(trf_pca.performance);
trf_pca.rho = diag(trf_pca.rho);

data = ft_appenddata([], tmp{:});
clear tmp tmp2 tmp3;

save(sprintf('%s_sourcedata_mscca.mat',subjectname), 'data', 'trf', 'trf_pca');

cd(pwd);
