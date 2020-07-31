function [ time , feature_value_vector, trl] = get_time_series(cfg, combined_data )
% get_time_series() creates a vector and time axis of a specified
% feature from the computational model output, at a specified sampling
% rate.
%
% Use as:
%   [time, data] = get_time_series(cfg, combined_data)
%
% Input arguments:
%   combined_data = struct_array, the output of COMBINE_DONDERS_TEXTGRID
% 
% Configuration (cfg) fields:
%   feature       = string, specifying which feature to use
%   sampling_rate = integer scalar, specifying the sampling rate
%   select        = string, 'all', 'content', 'noonset' or 'content_noonset', 
%                    whether or not to include content and/or onset words in creating the vector
%   shape         = string, 'box' or 'stick' specifying whether feature vector is a stick
%                   function or a box-shaped function (i.e. with plateaus
%                   for word duration)
% 
% Output arguments:
%   time = vector, specifying the time axis
%   data = vector, specifying the feature values as a 'block regressor'
%            (one value per word). missing data are represented as NaN.
%   trl  = Nx4 array, FieldTrip style trl-like matrix containing the
%            begin samples and end samples of each element in
%            combined_data, along with a counter (3d row, indexing the
%            element in combined data), and the value of the feature
%            (4th row). note that the samples are counted in the specified
%            sampling_rate, and are relative to the beginning of the
%            stimulus. note, also, that the samples have an offset of 1.

feature = ft_getopt(cfg, 'feature');
fsample = ft_getopt(cfg, 'fsample');
select  = ft_getopt(cfg, 'select', 'all');
shape   = ft_getopt(cfg, 'shape');

end_time_point       = max([combined_data.end_time]);     % the length of the 
time                 = linspace(0, end_time_point, end_time_point * fsample + 1); 

feature_dim          = size(combined_data(1).(feature), 1);  % determine dimensionality
feature_value_vector = zeros(feature_dim, numel(time))+nan; % initialize as NaN so that missing data takes this value

begtim = [combined_data.start_time]';
endtim = [combined_data.end_time]';

% the '.' seem to have the same begtim as endtim
sel    = find(begtim~=endtim); 
begtim = begtim(sel);
endtim = endtim(sel);

% make sure combineddata has same elements as begtim/endtim vectors
combined_data = combined_data(sel);

%% loop over and create feture vector at MEG sampling rate based on model data

iscontent         = [combined_data(:).iscontent];               % logical, check .iscontent field
isonset           = ismember([combined_data(:).word_], [0, 1]); % logical vector, check if word index is 0 or 1 (indicating onset position)
feature_values    = [combined_data(:).(feature)];               % vector of feature values to be assigned

for k = 1:numel(begtim)
    
  begsmp = nearest(time, begtim(k));
  endsmp = nearest(time, endtim(k));
  value  = feature_values(:,k);
  
  % determine the shape of the function
  switch shape
    case 'stick'
        plateau = begsmp;        % this will create stick function feature vectors (no plateau effectively)
    case 'box'
        plateau = begsmp:endsmp; % this creates a plateau
  end
  
  % if feature is vector-based, create matrix to prevent assignment
  % dimension mismath below
  if ~isscalar(value)
      value = repmat(value, [1, endsmp-begsmp + 1]);
  end
  
  % make sure word selection only operates on model metrics
  if ismember(feature, {'entropy', 'perplexity', 'semdist1', 'semdist2', 'embedding', 'log10wf'})
      switch select

          case 'all' % assign value to all parsed words

          feature_value_vector(:, plateau) = value;

          case 'content' % assign value to the vector only if it is content word

          if iscontent(k)
            feature_value_vector(:, plateau) = value;
          end

          case 'noonset' % select only words not indexed as 0 or 1

          if ~isonset(k)
            feature_value_vector(:, plateau) = value;
          end

          case 'content_noonset' % select content only, sentence-non initial words

          if iscontent(k) && ~isonset(k)
            feature_value_vector(:, plateau) = value;
          end    
      end
  % if it is not complexity score or lex.freq quantify all words
  else     
      
      feature_value_vector(:, plateau) = value;
  
  end    
end

%% 
% create a trl-like matrix for the feature with samples expressed in the
% requested sampling_frequency
for i=1:numel(combined_data)
  existtime(i) = ~isempty(combined_data(i).start_time);
end
trl = zeros(numel(combined_data),4)+nan;
trl(existtime,1) = round([combined_data(existtime).start_time]*fsample);
trl(existtime,2) = round([combined_data(existtime).end_time]*fsample);
trl(existtime,3) = 1:sum(existtime);
%trl(existtime,4) = [combined_data(existtime).(feature)]; FIXME, commenting out, temporary measure

end
