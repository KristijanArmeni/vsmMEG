function [d] = vsm_vec2dist(cfg, vectors)
% vsm_vec2dist() computes distance d between the current word and the 
% sum over the preceeding <order - 1> vectors in the story. It discards
% the first word due to undefined context and adjusts the context length
% c while c < order. 
% 
%   d                = vsm_vec2distance(cfg, vectors);
%   
%   INPUT
%   vectors          = matrix, numwords X numdimensions (a vector per every word)
%   cfg              = structure, fields specify OPTIONS
%
%   OUTPUT
%   d                = 1 x numel(words) vector, (1-cosine) per entry
%   
%   OPTIONS
%   cfg.words        = string array, words for which distances are computed
%
%   cfg.sentences    = vector, numel(words) X 1, each elements gives
%                      current sentence index 
%   cfg.context      = 'sentence' or 'moving_window'. Determines the amount of
%                       words to be summed in the context vector.
%   cfg.order        = integer, number of past words (= order - 1) to consider for computing d
%   cfg.selection    = logical vector or [], defines words to be selected,  if [] all words are selected

words      = ft_getopt(cfg, 'words');
word_idx   = ft_getopt(cfg, 'word_idx');
context    = ft_getopt(cfg, 'context');
order      = ft_getopt(cfg, 'order');
selection  = ft_getopt(cfg, 'selection');

nwrd = size(vectors, 1); % number of words, punctuation

if isempty(selection)
   selection = true(nwrd, 1); % if no selection is provided, choose all words 
end

if nwrd ~= numel(words) || nwrd ~= numel(selection)
    error('Number of feature vectors and words/subselection do not match')
end

d           = zeros(1, nwrd); % preallocate output vector
window_size = nan(1, nwrd);   % preallocate, make it nan by default

%% First determine the context windows depending on the strategy
switch context
    
    case 'moving_window'

        % loop over words
        for k = 1:nwrd            
            num_preceeding_words = word_idx(k);          
            % adjust context window for story onset dependendent on available context
            if num_preceeding_words == 0          % discard sentence initial word                
                window_size(k) = nan;           
            elseif num_preceeding_words < order   % when the available context is too short w.r.t. what is desired              
                window_size(k) = num_preceeding_words;           
            else               
                window_size(k) = order - 1; % user-specified context window (order = window + current word            
            end
        end
        
    case 'sentence'
        % loop over words
        for k = 1:nwrd  % determine distance within the loop
            window_size(k) = word_idx(k);
        end
        
        window_size(window_size == 0) = nan; % turn 0s into nans        
end

%% Now subselect context vectors, sum them and compute distance

for k = 1:nwrd
    
    % Compute window index
    if ~isnan(window_size(k))
        window_idx = (k-window_size(k)):k-1; % index context window relative to position in the story
    else
        window_idx = []; % make it empty if 
    end
    
    % if possible, determine the context vector
    context_vector = [];
    
    if ~isempty(window_idx)
        all_vectors          = vectors(window_idx, :);                % select all vectors in the window
        selected_vectors     = all_vectors(selection(window_idx),:);  % apply subselection (e.g. content words)
        
        if ~isempty(selected_vectors)
            context_vector       = sum(selected_vectors, 1);          % sum the vectors
        end
    end
    
    % Compute distances
    current_vector = vectors(k,:);
    
    if isempty(context_vector) % if there are no content words in the context, make it nan
        d(k) = nan;
    else 
        % compute 1 - the cosine (following Broderick et al, 2018, Curr Biol)
        d(k)            = (1-vsm_cosine(context_vector, current_vector)); 
    end

end