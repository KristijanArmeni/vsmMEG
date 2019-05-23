function [data] = vsm_multisetcca_sensor2parcel(data, source, parcel_indx, ncomp)

% this function projects the sensor-level data into source space, for the
% specified parcel

if nargin<4
  ncomp = 5;
end

if numel(parcel_indx)>1 && ncomp~=1
  error('with more than one parcel, ncomp should be 1');
end

hasstim = strncmp(data.label{end},'stim',4);
if hasstim
  cfg = [];
  cfg.channel = data.label(end);
  stim = ft_selectdata(cfg, data);
else
  stim = [];
end

% ensure the channel labels in the data to match the order of the channels
% in the spatial filter, and compute the parcel specific time courses
[a,b]      = match_str(source.filterlabel, data.label);
if numel(parcel_indx)==1
  indx       = 1:min(ncomp,size(source.F{parcel_indx},1));
  data.trial = source.F{parcel_indx}(indx,a)*cellrowselect(data.trial,b);
  data.label = data.label(indx);
else
  F = zeros(numel(parcel_indx),numel(a));
  for k = 1:numel(parcel_indx)
    F(k,:) = source.F{parcel_indx(k)}(1,a);
  end
  data.trial = F*cellrowselect(data.trial,b);
  data.label = source.label(parcel_indx);
end
  
if hasstim
  %stim.fsample = data.fsample;
  data = ft_appenddata([], data, stim);
end

% mean subtract using the pre-sentence average
cfg                = [];
cfg.demean         = 'yes';
cfg.baselinewindow = [-0.5 0];
data               = ft_preprocessing(cfg, data);
data               = removefields(data, {'grad' 'elec'});