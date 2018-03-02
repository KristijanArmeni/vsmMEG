function [d, stat] = vsm_vec2dist(words, vectors, order, selection)
% vsm_vec2dist() computes distance d between the current word and the 
% sum over the preceeding <order - 1> vectors in the story. It discards
% the first word due to undefined context and adjusts the context length
% c while c < order. 
% 
%   d         = vsm_vec2distance(words, vectors, order, selection);
%
%   d         = 1 x numel(words) vector, (1-cosine) per entry
%   
%   words     = string array, words for which distances are computed
%   vectors   = matrix, nuel(words) X vector dimension (i.e. vector per word)
%   order     = integer, number of past words (= order - 1) to consider for computing d
%   selection = logical vector or [], defines words to be selected,  if [] all words are selected

    dimf = size(vectors, 2); % dimension of feature vectors
    nwrd = size(vectors, 1); % number of words, punctuation
    
    if isempty(selection)
       selection = true(nwrd, 1); % if no selection is provided, choose all words 
    end
    
    if nwrd ~= numel(words) || nwrd ~= numel(selection)
        error('Number of feature vectors and words/subselection do not match')
    end
    
    d    = zeros(1, nwrd); % preallocate output vector
    stat = cell(nwrd, 3); % FIXME (remove this after testing)
    
    % loop over words
    for k = 1:nwrd
        
        delta          = diff([1, k]); % determine distance within the loop
        current_vector = vectors(k,:);
        
        % adjust context window for story onset dependendent on available context
        if delta == 0          % discard sentence initial word
            window = nan; 
        elseif delta < order   % when the available context is too short w.r.t. what is desired
            window = delta;
        else
            window = order - 1; % user-specified context window (order = window + current word)
        end
        
        if ~isnan(window)
            window_idx = (k-window):k-1; % if possible, determine indices for selecting context vectors
        else
            window_idx = nan;
        end
        
        stat{k, 1} = window;
        stat{k, 2} = window_idx;
        
        % if possible, determine the context vector
        if ~isnan(window_idx)
            
            unselected_vectors = vectors(window_idx, :);                       % select all vectors in a window
            selected_vectors   = unselected_vectors(selection(window_idx),:); % apply subselection (e.g. content words)
            context_vector     = sum(selected_vectors, 1);                    % sum the vectors
        
            if ~any(context_vector) % if there are no content words in the context, make it nan
                d(k) = nan;
            else 
                % compute 1 - the cosine (following Broderick et al, 2017, bioRxiv)
                d(k)            = (1-vsm_cosine(context_vector, current_vector)); 
            end
            
        else
            
            selected_vectors = nan;
            d(k)             = nan;
            
        end
        
        stat{k, 3} = size(selected_vectors, 1);
        
    end

    
end