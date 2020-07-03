function stimdata = vsm_stimdata(subject, audiofile)

% streams_preprocessing() 

%% INITIALIZE

if ischar(subject)
  subject = vsm_subjinfo(subject);
end
audiofile = subject.audiofile;

% determine the trials with which the audiofiles correspond
seltrl   = zeros(0,1);
selaudio = cell(0,1);
for k = 1:numel(audiofile)

  tmp = contains(subject.audiofile, audiofile{k}); % check which audiofiles were selected by the user
  if sum(tmp)==1
    seltrl   = cat(1, seltrl, find(tmp));
    selaudio = cat(1, selaudio, subject.audiofile(tmp)); 
  else
    % file is not there
  end
end

% deal with more than one ds-directory per subject
% if iscell(subject.dataset)
%   dataset = cell(0,1);
%   trl     = zeros(0,size(subject.trl{1},2));
%   for k = 1:numel(subject.dataset)
%     trl     = cat(1, trl, subject.trl{k});
%     dataset = cat(1, dataset, repmat(subject.dataset(k), [size(subject.trl{k},1) 1])); 
%     %mixing    = cat(1, mixing,    repmat(subject.eogv.mixing(k), [size(subject.trl{k},1) 1]));
%     %unmixing  = cat(1, unmixing,  repmat(subject.eogv.unmixing(k), [size(subject.trl{k},1) 1]));
%     %badcomps  = cat(1, badcomps,  repmat(subject.eogv.badcomps(k), [size(subject.trl{k},1) 1]));
%     
%   end
%   trl     = trl(seltrl,:);
%   dataset = dataset(seltrl);
%   %mixing  = mixing(seltrl);
%   %unmixing = unmixing(seltrl);
%   %badcomps = badcomps(seltrl);
% else
%   dataset = repmat({subject.dataset}, [numel(seltrl) 1]);
%   trl     = subject.trl(seltrl,:);
%   %mixing    = repmat({subject.eogv.mixing},   [numel(seltrl) 1]);
%   %unmixing  = repmat({subject.eogv.unmixing}, [numel(seltrl) 1]);
%   %badcomps  = repmat({subject.eogv.badcomps}, [numel(seltrl) 1]);
% 
% end

%% PREPROCESSING LOOP PER AUDIOFILE

audiodir                    = '/project/3011085.04/data/stim/audio';
subtlex_table_filename      = '/project/3011085.04/data/raw/stimuli/worddata_subtlex.mat';
subtlex_firstrow_filename   = '/project/3011085.04/data/raw/stimuli/worddata_subtlex_firstrow.mat';
subtlex_data     = [];          % declare the variables, it throws a dynamic assignment error otherwise
subtlex_firstrow = [];

% load in the files that contain word frequency information
load(subtlex_firstrow_filename);
load(subtlex_table_filename);

stimdata = cell(numel(seltrl),1);
for k = 1:numel(seltrl)
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  % LANGUAGE PREPROCESSING %
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  
  [~,f,~] = fileparts(selaudio{k});
  
  % create combineddata data structure
  dondersfile  = fullfile(audiodir, f, [f,'.donders']);
  textgridfile = fullfile(audiodir, f, [f,'.TextGrid']);
  combineddata = combine_donders_textgrid(dondersfile, textgridfile);
  
  % Compute word duration
  for i = 1:numel(combineddata)
    
    if ~isempty(combineddata(i).start_time)
      combineddata(i).duration = combineddata(i).end_time - combineddata(i).start_time;
    else
      combineddata(i).duration = nan;
    end
  end
  
  % add .iscontent field to combineddata structure
  combineddata = streams_combinedata_iscontent(combineddata);
  
  % add subtlex frequency info and word length
  combineddata = add_subtlex(combineddata, subtlex_data,  subtlex_firstrow);
  
  % create semantic distance field in combineddata
  vector_file        = fullfile('/project/3011085.04/data/stim/txt/vectors', [f '.txt']);
  [vecmat, words]    = vsm_readvectors(vector_file);
  
  vec2dist_selection = [combineddata(:).iscontent]';
  
  cfg           = [];
  cfg.words     = words;                    % cell array of word strings
  cfg.word_idx  = [combineddata(:).word_]'; % word indices of word positions in a sentence
  cfg.context   = 'moving_window';
  cfg.order     = 5;
  cfg.selection = vec2dist_selection;
  
  d1       = vsm_vec2dist(cfg, vecmat);
  
  cfg.context   = 'sentence';
  d2      = vsm_vec2dist(cfg, vecmat);
  
  for jj = 1:numel(words)
    combineddata(jj).embedding = vecmat(jj,:)'; % pick the vector row for this word, store as column
    combineddata(jj).semdist1  = d1(jj);        % semantic distance based on moving window
    combineddata(jj).semdist2  = d2(jj);        % semantic distance based on average across sentence
  end
  
  % create language predictor based on language model output
  
  stimdata{k} = combineddata;
  
end

% ADD SUBTLEX INFORMATION 
function [combineddata] = add_subtlex(combineddata, subtlex_data, subtlex_firstrow)

num_words = size(combineddata, 1);

word_column         = strcmp(subtlex_firstrow, 'spelling');
wlen_column         = strcmp(subtlex_firstrow, 'nchar');
frequency_column    = strcmp(subtlex_firstrow, 'Lg10WF');

subtlex_words = subtlex_data(:, word_column);

    % add frequency information to combineddata structure
    for j = 1:num_words

        word = combineddata(j).word;
        word = word{1};
        row = find(strcmp(subtlex_words, word)); % find the row index in subtlex data

        if ~isempty(row) 
            
             combineddata(j).log10wf = subtlex_data{row, frequency_column}; % lookup the according frequency values
             combineddata(j).nchar   = subtlex_data{row, wlen_column};
             
        else % write 'nan' if it is a punctuation mark or a proper name (subtlex doesn't give values in this case)
            
            combineddata(j).log10wf = nan;
            combineddata(j).nchar   = nan;
            
        end

    end
    
end

end
 