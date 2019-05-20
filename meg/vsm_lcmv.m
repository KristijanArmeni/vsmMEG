function vsm_lcmv(subject)
%
%
% [source, data] = vsm_lcmv(inpcfg, subject)
% 
% INPUT ARGUMENTS:
%
% subject       = string, subject id as specified in subject.name
% 

%% Initialize
d           = vsm_dir();
if ischar(subject)
    subject = vsm_subjinfo(subject);
end

%% Load in data

if ~isempty(subject.preproc.meg)
    load(subject.preproc.meg);
    datatmp = data; clear data
else
    error('No data specified in <subject.preproc.meg>');
end

% add the fsample field it is not there (should be 300 normally)
if isfield(datatmp, 'fsample')
    fsample = datatmp.fsample;
else
    fsample = datatmp.cfg.previous{1}.resamplefs;
end

% remove the elec field
if isfield(datatmp, 'elec')
    datatmp = rmfield(datatmp, 'elec');
end

dataorig = datatmp;

% Remove the nans
for k = 1:numel(datatmp.trial)
  datatmp.trial{k}(:,~isfinite(datatmp.trial{k}(1,:))) = [];
  datatmp.time{k} = (0:(size(datatmp.trial{k},2)-1))./fsample;
end

load(subject.anatomy.headmodel); % headmodel variable
load(subject.anatomy.leadfield); % leadfield variable

%% JM added the next few lines, to avoid recomputing the leadfields
if isfield(leadfield, 'labelorg')
  leadfield.label = leadfield.labelorg;
end
  
%% Parcellate leadfields here

f   = d.atlas{1}; % 1 == 374 Conte atlas, 2 == Glaser et al (2016, Nat neuro)
load(f)


%% Compute spatial filters

cfg                 = [];
cfg.vartrllength    = 2;
%cfg.trials          = inpcfg.trials;
cfg.covariance      = 'yes';
tlck                = ft_timelockanalysis(cfg, datatmp);
tlck.cov            = real(tlck.cov);

cfg                 = [];
cfg.headmodel       = headmodel;
cfg.sourcemodel     = leadfield;
cfg.method          = 'lcmv';
cfg.lcmv.fixedori   = 'yes';
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.lambda     = '100%';
cfg.lcmv.weightnorm = 'unitnoisegain';
source              = ft_sourceanalysis(cfg, tlck);
clear headmodel leadfield cfg

% take the spatial filters
F                  = zeros(size(source.pos,1),numel(tlck.label)); % num sources by MEG channels matrix
F(source.inside,:) = cat(1,source.avg.filter{:});

clear source tlck
%% Parcellate the source time courses

% concatenate data across trials

datatmp.trial  = {cat(2, datatmp.trial{:})};
datatmp.time   = {(0:(size(datatmp.trial{1},2)-1))./fsample};
datatmp.dimord = 'chan_time';

%selparcidx        = find(~contains(atlas.parcellationlabel, '_???'));

%source_parc.label = atlas.parcellationlabel(~contains(atlas.parcellationlabel, '_???'));
selparcidx        = unique(atlas.parcellation); % create column of indices 1-num parcels
source_parc.label = atlas.parcellationlabel; 

source_parc.F     = cell(numel(source_parc.label),1);

tmp     = rmfield(datatmp, {'grad', 'trialinfo'});

cfg        = [];
cfg.method = 'pca';

for k = 1:numel(source_parc.label)

  tmpF      = F(atlas.parcellation==selparcidx(k),:); % select weights for kth parcel
  tmp.trial = {tmpF*datatmp.trial{1}};
  tmp.label = cellstr(string(1:size(tmpF, 1))');
  tmpcomp   = ft_componentanalysis(cfg, tmp);

  source_parc.F{k}     = tmpcomp.unmixing*tmpF;
  
end

clear datatmp tmp tmpcomp F tmpF atlas
%% Beam the sensor data

cfg = [];
cfg.channel = ft_channelselection('MEG',dataorig.label);
data = ft_selectdata(cfg, dataorig);

% create now a 'spatial filter' that concatenates the first components for
% each of the parcels 
for k = 1:numel(source_parc.label)
    F_parc(k,:) = source_parc.F{k}(1,:);
end

% multiply the filter with the sensor data
for k = 1:numel(data.trial)
    data.trial{k} = F_parc*dataorig.trial{k};
end
clear data_sensor

data.label = source_parc.label;

%% Save if specified

%data_sensor = rmfield(data, 'cfg'); % remove the cfg which might be bulky

save(fullfile(d.preproc, [subject.name '_lcmv-filt.mat']), 'source_parc', '-v7.3');
save(fullfile(d.preproc, [subject.name '_lcmv-data.mat']), 'data', '-v7.3');


end
