function stat = vsm_plot_accuracy(model)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

ft_hastoolbox('cellfunction', 1);

rho = cell(numel(model.trial), 1);

for k=1:numel(model.trial)
    rho{k} = model.weights{k}.pearson; %  say model based on 'audio_avg only'}
end

% average trial specific r
rhoavg = cellmean(rho', 2);
stat   = rhoavg;

d = vsm_dir;
load(d.atlas{1}); % atlas variable
load(d.atlas{3}); % inflated cortex

atlas.pos = ctx.pos;
atlas.tri = ctx.tri;

source               = [];
source.brainordinate = atlas;
source.label         = atlas.parcellationlabel;
source.dimord        = 'chan';
source.stat          = zeros(size(atlas.parcellationlabel, 1), 1);
source.stat          = rhoavg;

cmap = flipud(brewermap(65, 'RdBu'));

cfgp               = [];
cfgp.method        = 'surface';
cfgp.funparameter  = 'stat';
cfgp.funcolormap   = cmap;
cfgp.maskparameter = 'stat';
cfgp.maskstyle     = 'colormix';
cfgp.colorbar      = 'no';
cfgp.camlight      = 'no';

ft_sourceplot(cfgp, source);
view([90, 10]);
l = camlight;
material dull;
h = colorbar;
ylabel(h, 'corr. coef.');
set(h, 'Position', [0.8 0.6 0.02 0.15])

end

