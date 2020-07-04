
ft_hastoolbox('cellfunction', 1);


subj = {'s02','s03','s04','s07',...
        's11','s12','s13','s14','s15','s16',...
        's17','s18','s19','s20','s21','s22',...
        's23','s24','s25','s26','s27','s28'};


subj = vsm_subjinfo(subj);
subj = removefields(subj,'ica'); % save memory
      
%--------------------------------------------------------------------------
%The following chunk of code does a 'searchlight' based multisetcca, where
%the searchlight is defined as the 5-component timecourse, describing a
%parcel, indicated with parcel_indx. It uses the same initialization of the
%random number generator, thus allowing identical folding across parcels,
%that can therefore be meaningfully compared post-hoc. The shuffling
%schemes implemented are either 'lenient', and 'conservative', where it has
%been decided that 'conservative' is most meaningful, because it obeys the
%approximate timing information of the word onsets across stimulation
%modalities.

tic;
domscca_searchlight = true;
if domscca_searchlight
  
  if ~exist('nfold', 'var')
    nfold = 5;
  end
  
  if ~exist('shuftype', 'var')
    shuftype = 'none';
  end
  if ~exist('skip_noshuffle', 'var')
    skip_noshuffle = false;
  end
  if ~exist('parcel_indx', 'var')
    error('a parcel index needs to be specified');
  end
  if ~exist('nrand', 'var')
    nrand = 100;
  end
  if numel(nrand)==1
    nrand = 1:nrand;
  end
  % this step does a mscca on a specified parcel, and requires the
  % parcellation to have been computed. Also, it is a bit inefficient,
  % because it processes the data up until the level of a parcellated
  % representation, but that is for memory reasons
  subjectdata = cell(1,numel(subj));
  for k = 1:numel(subj)
    load(fullfile('/project/3011085.04/data/derived',sprintf('%s_meg',subj(k).name)));
    load(fullfile('/project/3011085.04/data/derived',sprintf('%s_aud',subj(k).name)));
    load(fullfile('/project/3011085.04/data/derived',sprintf('%s_lng-box',  subj(k).name)));
    load(fullfile('/project/3011085.04/data/derived',sprintf('%s_lcmv-filt',subj(k).name)));
    
    % NOTE JM JULY 04, 2020: THERE SEEMS SOMETHING CRITICALLY WRONG WITH
    % THE TEMPORAL ALIGNMENT, DUE TO THE DELAY CORRECTION BETWEEN AUDIO
    % TRIGGER AND ACTUAL AUDIO BEING LOST IN THE PREPROCESSING STEP. THE
    % DELAYS NEED TO BE MANUALLY CORRECTED. ASSUMING THAT THE SAME
    % MISALGINMENT APPLIES TO THE FEATUREDATA, DATA, AND AUDIO VARIABLES,
    % BASED ON INSPECTION OF THE AUDIO TIME AXES, IT SEEMS THAT THE DELAYS
    % NEED TO BE SUBTRACTED FROM THE TRIAL SPECIFIC TIME AXES. THIS ALIGNS
    % THE AUDIO ENVELOPES ACROSS SUBJECTS. NOTE, ALSO, THAT THE CODE
    % VSM_PREPROCESSING HAS BEEN FIXED (SO A POTENTIAL NEW ROUND OF
    % PREPROCESSING WOULD YIELD CORRECT DELAY CORRECTION), BUT DUE TO
    % PRACTICAL CONSTRAINTS, THIS STEP HAS NOT BEEN REDONE. THIS MEANS THAT
    % THE CURRENT DATA ON DISK IS NOT CORRECTLY DELAY ADJUSTED AND THE NEXT
    % STEP SHOULD BE APPLIED. IF THIS CURRENT PIPELINE IS TO BE RUN WITH
    % NEWLY COMPUTED DATA, THE FOLLOWING STEP NEEDS TO BE SKIPPED.
    load(fullfile('/project/3011085.04/data/derived',sprintf('%s_delay',subj(k).name)));
    for kk = 1:numel(data.time)
      data.time{kk}        = data.time{kk}        - delay(kk)./1000;
      featuredata.time{kk} = featuredata.time{kk} - delay(kk)./1000;
      audio.time{kk}       = audio.time{kk}       - delay(kk)./1000;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    source_parc.filterlabel = data.label; % for checking channel order, assumes same order in the filters
    
    subjectdata{1,k} = vsm_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
    
    cfg = [];
    cfg.channel = 'audio_avg';
    audio = ft_selectdata(cfg, audio);
    
    cfg.channel = {'entropy';'entropy_c';'perplexity';'perplexity_c';'log10wf';'log10wf_c'};
    featuredata = ft_selectdata(cfg, featuredata);
    
    subjectdata{1,k} = ft_appenddata([], subjectdata{1,k}, audio, featuredata);
    subjectdata{1,k}.fsample = audio.fsample;
    
  end
    
  for k = 1:numel(subjectdata)
    % align the order of the trials
    [srt,ix] = sort(subj(k).audiofile);
    subjectdata{k}.time  = subjectdata{k}.time(ix);
    subjectdata{k}.trial = subjectdata{k}.trial(ix);
    subjectdata{k}.trialinfo = subjectdata{k}.trialinfo(ix,:);
    subjectdata{k}.audiofile = subj(k).audiofile(ix);
    if k==1
      T = subjectdata{k}.audiofile;
    else
      T = intersect(T, subjectdata{k}.audiofile);
    end
    
    % check the sampling of the time axis, and add the extremes to the
    % trialinfo, to be used later
    for m = 1:numel(subjectdata{k}.time)
      time = round(subjectdata{k}.time{m}.*subjectdata{k}.fsample)./subjectdata{k}.fsample;
      subjectdata{k}.trialinfo(m,2) = min(time);
      subjectdata{k}.trialinfo(m,3) = max(time);
    end
  end
  for k = 1:numel(subjectdata)
    % only use the trials that are common across all subjects
    cfg = [];
    cfg.trials = find(ismember(subjectdata{k}.audiofile, T));
    audiofile  = subjectdata{k}.audiofile;
    subjectdata{k} = ft_selectdata(cfg, subjectdata{k});
    subjectdata{k}.audiofile = audiofile(cfg.trials);
    for m = 1:numel(subjectdata{k}.time)
      if k==1
        Tmax(m,1) = subjectdata{k}.trialinfo(m,3);
        Tmin(m,1) = subjectdata{k}.trialinfo(m,2);
      else
        Tmax(m) = max(Tmax(m), subjectdata{k}.trialinfo(m,3));
        Tmin(m) = max(Tmin(m), subjectdata{k}.trialinfo(m,2));
      end
    end
  end
  
  % align the time axes if needed
  for k = 1:numel(subjectdata)
    for m = 1:numel(subjectdata{k}.time)
      tim = (Tmin(m):1./subjectdata{k}.fsample:Tmax(m));
      i1  = nearest(tim, round(subjectdata{k}.time{m}(1).*subjectdata{k}.fsample)./subjectdata{k}.fsample) - 1; % number of padded samples to the left
      i2  = numel(tim) - nearest(tim, round(subjectdata{k}.time{m}(end).*subjectdata{k}.fsample)./subjectdata{k}.fsample) - i1; % number of padded samples to the right
      nchan = numel(subjectdata{k}.label);
      
      subjectdata{k}.time{m} = tim;
      subjectdata{k}.trial{m} = [nan(nchan,i1) subjectdata{k}.trial{m} nan(nchan,i2)];

    end
  end
      
  for k = 1:numel(subjectdata)
    cfg = [];
    cfg.channel = {'audio_avg';'entropy';'perplexity';'log10wf'};
    audiodata{1,k} = ft_selectdata(cfg, subjectdata{1,k});
    audiodata{1,k} = removefields(audiodata{1,k}, 'audiofile');
    audiodata{1,k}.time = audiodata{1}.time;
    
    audiofile = subjectdata{k}.audiofile;
    cfg = [];
    cfg.channel = subjectdata{k}.label(1:5);
    subjectdata{k} = ft_selectdata(cfg, subjectdata{1,k});
    
    cfg = [];
    cfg.method = 'acrosschannel';
    subjectdata{k} = ft_channelnormalise(cfg, subjectdata{1,k});
    subjectdata{k}.audiofile = audiofile;
  end
  
  for k = 1:numel(subjectdata)
    % do the time shifting trick for the hyperalignment
    lags = -6:6;
    subjectdata{k}.trial = cellshift(subjectdata{k}.trial, lags, 2, [], 'overlap');
    subjectdata{k}.time  = cellshift(subjectdata{k}.time, 0, 2, [abs(min(lags)) abs(max(lags))], 'overlap');
    subjectdata{k}.label = repmat(subjectdata{k}.label(1:5),numel(lags),1);
    
    for kk = 1:numel(subjectdata{k}.label)/5
      subjectdata{k}.label{(kk-1)*5+1} = sprintf('%s_shift%03d',subjectdata{k}.label{(kk-1)*5+1}, kk);
      subjectdata{k}.label{(kk-1)*5+2} = sprintf('%s_shift%03d',subjectdata{k}.label{(kk-1)*5+2}, kk);
      subjectdata{k}.label{(kk-1)*5+3} = sprintf('%s_shift%03d',subjectdata{k}.label{(kk-1)*5+3}, kk);
      subjectdata{k}.label{(kk-1)*5+4} = sprintf('%s_shift%03d',subjectdata{k}.label{(kk-1)*5+4}, kk);
      subjectdata{k}.label{(kk-1)*5+5} = sprintf('%s_shift%03d',subjectdata{k}.label{(kk-1)*5+5}, kk);
    end
  end
  
  rng('default'); % reset the number generator, in order to be able to compare across parcels
  tmpdata              = vsm_multisetcca_groupdata2singlestruct(subjectdata, {subj.name});
  tmpdata.cfg          = rmfield(tmpdata.cfg, 'previous'); % this removes a rather big cfg that accumulates across folds
  
  lambda = 5;
  [W, A, rho, C, comp] = vsm_multisetcca(tmpdata, {1 2 3 4 5}, 1, lambda,false);
  [comp, rho]          = vsm_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
  comp.audiofile       = subjectdata{1}.audiofile;
  [tlck, stimdata]     = vsm_extractwords(comp);
  
  % now also extract the the 'tlck' for tmpdata (first component only)
  tmpcfg = [];
  tmpcfg.channel = tmpdata.label(31:65:end); % hard coded
  tmpdata_tmp    = ft_selectdata(tmpcfg, tmpdata);  
  [tlck_pca]     = vsm_extractwords(tmpdata_tmp);
  
  cfg = [];
  cfg.appenddim = 'rpt';
  cfg.parameter = 'trial';
  tlck     = ft_appendtimelock(cfg, tlck{:});
  tlck_pca = ft_appendtimelock(cfg, tlck_pca{:});
  
  trc            = vsm_multisetcca_trc(tlck);
  trc_pca        = vsm_multisetcca_trc(tlck_pca);
  
  tlck = ft_struct2single(tlck);
  tlck_pca = ft_struct2single(tlck_pca);
  
  for k = 1:numel(audiodata)
    for  m = 1:numel(audiodata{k}.label)
      audiodata{k}.label{m} = sprintf('%s%02d',audiodata{k}.label{m},k);
    end
    audiodata{k}.time     = audiodata{1}.time;
  end
  audiodata = ft_appenddata([], audiodata{:});
  
  
  for k = 1:numel(audiodata.trial)
    for i = 1:m
      audiodata.trial{k}(i,:) = nanmean(audiodata.trial{k}(i:m:end,:));
    end
    audiodata.trial{k} = audiodata.trial{k}(1:m,:);
  end
  audiodata.label = audiodata.label(1:m);
  audiodata.label = strrep(audiodata.label,'01','');
  audiodata.cfg   = rmfield(audiodata.cfg, 'previous');
  
  % now we need to match the comp's time with that of the independent
  % variables
  for k = 1:numel(audiodata.time)
    audiodata.time{k} = audiodata.time{k}(7:end-6); % the numbers here should match the lags
    audiodata.trial{k} = audiodata.trial{k}(:,7:end-6); % the numbers here should match the lags
  
  end
  
  audiodata.audiofile = audiofile;
  audiodata.fsample   = comp.fsample;
  [tlck_audio]     = vsm_extractwords(audiodata);
  cfg = [];
  cfg.appenddim = 'rpt';
  cfg.parameter = 'trial';
  tlck_audio    = ft_appendtimelock(cfg, tlck_audio{:});
  audiodata = rmfield(audiodata, 'audiofile');
  
  %cfg = [];
  %cfg.avgoverchan = 'yes';
  %cfg.nanmean = 'yes';
  %audiodata = ft_selectdata(cfg, audiodata);
  
  cfg = [];
  cfg.method     = 'mlrridge';
  cfg.threshold  = [10 0];
  cfg.reflags    = (-5:59)./100;
  cfg.refchannel = audiodata.label([1]);% 3]);
  cfg.demeandata = 'yes';
  cfg.demeanrefdata = 'yes';
  cfg.standardisedata = 'yes';
  cfg.standardiserefdata = 'yes';
  cfg.performance = 'r-squared';
  cfg.output      = 'model';
  cfg.testtrials  = mat2cell(1:numel(comp.trial),1,ones(1,numel(comp.trial)));
  trf     = ft_denoise_tsr(cfg, removefields(comp,        {'audiofile' 'trialinfo'}), removefields(audiodata,'audiofile'));
  trf_pca = ft_denoise_tsr(cfg, removefields(tmpdata_tmp, {'audiofile' 'trialinfo'}), removefields(audiodata,'audiofile'));
  
  trf     = removefields(ft_struct2single(trf),     {'time' 'trial'});
  trf_pca = removefields(ft_struct2single(trf_pca), {'time' 'trial'});
  
  %save(sprintf('/project/3011085.04/data/derived/mscca/mscca_parcel%03d',parcel_indx),'trc','trc_pca', 'trf', 'trf_pca', 'comp');
  save(sprintf('/project/3011085.04/data/derived/mscca/mscca_parcel%03d',parcel_indx),'trc','trc_pca', 'trf', 'trf_pca', 'comp', 'lambda', 'rho');

end
%--------------------------------------------------------------------------
toc;
