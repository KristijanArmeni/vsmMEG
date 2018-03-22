function [source, data] = vsm_lcmv(inpcfg, subject)
%
%
% [source, data] = vsm_lcmv(inpcfg, subject)
% 
% INPUT ARGUMENTS:
%
% subject       = string, subject id as specified in subject.name
% inpcfg.trials = integer, number of trials to use
% inpcfg.save   = logical, whether or not to save the data in prepoc folder
%                 as specified in vsm_dir()
% 

%% Initialize
d           = vsm_dir();
if ischar(subject)
    subject = vsm_subjinfo(subject);
end

if isempty(inpcfg.trials) || ~isfield(inpcfg, 'trials')
    inpcfg.trials = 'all';
end

%% Load in data

if ~isempty(subject.preproc.meg)
    load(subject.preproc.meg);
else
    data = inpcfg.data;
end
data_sensor = data; clear data

% if isfield(data, 'elec')
%     data = rmfield(data, 'elec');
% end

load(subject.anatomy.headmodel); % headmodel variable
load(subject.anatomy.leadfield); % leadfield variable

%% Compute spatial filters

cfg                 = [];
cfg.vartrllength    = 2;
cfg.trials          = inpcfg.trials;
cfg.covariance      = 'yes';
tlck                = ft_timelockanalysis(cfg, data_sensor);
tlck.cov            = real(tlck.cov);

cfg                 = [];
cfg.headmodel       = headmodel;
cfg.grid            = leadfield;
cfg.grid.label      = tlck.label;
cfg.method          = 'lcmv';
cfg.lcmv.fixedori   = 'yes';
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.lambda     = '100%';
source              = ft_sourceanalysis(cfg, tlck);
clear headmodel tlck

%% Beam the data if requested in the call

if nargout > 1 % return the beamed data if required
    
    data = ft_selectdata(data_sensor, 'channel', ft_channelselection('MEG', data_sensor.label));
    data = ft_selectdata(inpcfg, data); % select trials if needed
    
    % right multiply the filter with the sensor data
    for k = 1:numel(data.trial)
        data.trial{k} = cat(1, source.avg.filter{:})*data_sensor.trial{k};
    end
    clear data_sensor
    
    data.label = leadfield.label;
    
end

%% Save if specified

if inpcfg.save
    save(fullfile(d.preproc, [subject.name '_lcmv1.mat']), 'source');
    save(fullfile(d.preproc, [subject.name '_lcmv2.mat']), 'data');
end

end