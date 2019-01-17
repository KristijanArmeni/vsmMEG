
ft_hastoolbox('cellfunction', 1);


% subj = {'s02','s03','s04','s07','s08','s10',...
%         's11','s12','s13','s14','s15','s16',...
%         's17','s18','s19','s20','s21','s22',...
%         's23','s24','s25','s26','s27','s28'};
subj = {'s02','s03','s04','s07',...
        's11','s12','s13','s14','s15','s16',...
        's17','s18','s19','s20','s21','s22',...
        's23','s24','s25','s26','s27','s28'};

subj = vsm_subjinfo(subj);

      
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
    load(fullfile('/project/3011044.02/vsm/data/preproc',sprintf('%s_meg',subj(k).name)));
    load(fullfile('/project/3011044.02/vsm/data/preproc',sprintf('%s_aud',subj(k).name)));
    load(fullfile('/project/3011044.02/vsm/data/preproc',sprintf('%s_lng-box',  subj(k).name)));
    load(fullfile('/project/3011044.02/vsm/data/preproc',sprintf('%s_lcmv-filt',subj(k).name)));
    
    source_parc.filterlabel = data.label; % for checking channel order, assumes same order in the filters
    
    subjectdata{1,k} = vsm_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
    
    cfg = [];
    cfg.channel = 'audio_avg';
    audio = ft_selectdata(cfg, audio);
    
    cfg.channel = {'entropy';'entropy_c';'perplexity';'perplexity_c'};
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
    cfg.channel = {'audio_avg';'entropy';'entropy_c';'perplexity';'perplexity_c'};
    audiodata{1,k} = ft_selectdata(cfg, subjectdata{1,k});
    audiodata{1,k} = removefields(audiodata{1,k}, 'audiofile');
    audiodata{1,k}.time = audiodata{1}.time;
    
    audiofile = subjectdata{k}.audiofile;
    cfg = [];
    cfg.method = 'acrosschannel';
    cfg.channel = subjectdata{k}.label(1:5);
    subjectdata{k} = ft_channelnormalise(cfg, subjectdata{1,k});
    subjectdata{k}.audiofile = audiofile;
  end
  
  rng('default'); % reset the number generator, in order to be able to compare across parcels
  tmpdata              = vsm_multisetcca_groupdata2singlestruct(subjectdata, {subj.name});
  [W, A, rho, C, comp] = vsm_multisetcca(tmpdata, {1 2 3 4 5}, 1, .1,false);
  [comp, rho]          = vsm_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
  comp.audiofile       = subjectdata{1}.audiofile;
  [tlck, stimdata]     = vsm_extractwords(comp);
  
  % now also extract the the 'tlck' for tmpdata (first component only)
  tmpcfg = [];
  tmpcfg.channel = tmpdata.label(1:5:end); % hard coded
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
  
  %cfg = [];
  %cfg.avgoverchan = 'yes';
  %cfg.nanmean = 'yes';
  %audiodata = ft_selectdata(cfg, audiodata);
  
  cfg = [];
  cfg.method     = 'mlrridge';
  cfg.threshold  = [0.5 0];
  cfg.reflags    = (-5:74)./100;
  cfg.refchannel = audiodata.label([1 2]);
  cfg.demeandata = 'yes';
  cfg.demeanrefdata = 'yes';
  cfg.standardisedata = 'yes';
  cfg.standardiserefdata = 'yes';
  cfg.performance = 'r-squared';
  cfg.output      = 'model';
  cfg.testtrials  = mat2cell(1:numel(comp.trial),1,ones(1,numel(comp.trial)));
  trf     = ft_denoise_tsr(cfg, removefields(comp,        {'audiofile' 'trialinfo'}), removefields(audiodata,'audiofile'));
  trf_pca = ft_denoise_tsr(cfg, removefields(tmpdata_tmp, {'audiofile' 'trialinfo'}), removefields(audiodata,'audiofile'));
  
  trf     = removefields(ft_struct2single(trf), {'time' 'trial'});
  trf_pca = removefields(ft_struct2single(trf_pca), {'time' 'trial'});
  
  save(sprintf('/project/3011044.02/dump/mscca_parcel%03d',parcel_indx),'trc','trc_pca', 'trf', 'trf_pca');
  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  %-------TOBEDONE----------
  switch shuftype
    
    case 'conservative'
      % unfold the audio data to maintain word onsets across modalities,
      % but after swapping sentences
            
      selaudio = find(strncmp(subj, 'sub-2', 5));
      selvis   = find(strncmp(subj, 'sub-1', 5));
      groupdatashuf = groupdata;
      
      cnt = 0;
      Cshufstim = zeros(81,2,numel(nrand));
      Cshuf     = zeros(81,3,numel(nrand));
      for m = nrand(:)'
        fprintf('performing permutation %d/%d\n',find(m==nrand),numel(nrand));
        cnt = cnt + 1;
        paramdir = '/project/3011020.09/jansch/mscca_group/';
        load(fullfile(paramdir,'params',sprintf('shuff_sce%d_indx%04d%s',scenario,m,suffix))); % use precomputed ordering for consistency across parcels
        
        groupdatashuf(selaudio) = mous_multisetcca_reorderaudio(subj(selaudio), subjectdata(selaudio), subjecttiming(selaudio), groupinfo, reorder, stimid, shift, stretch);
        
        for k = 1:numel(groupdatashuf)
          for kk = 1:numel(groupdatashuf{1,k}.trial)
            sel = nearest(groupdatashuf{1,k}.time{kk},-0.1);
            groupdatashuf{1,k}.trial{kk} = groupdatashuf{1,k}.trial{kk}(:,sel:end);
            groupdatashuf{1,k}.time{kk}  = groupdatashuf{1,k}.time{kk}(sel:end);
          end
        end
        % perform the cca
        tmpdata                              = mous_multisetcca_groupdata2singlestruct(groupdatashuf, subj);
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(tmpdata, nfold, 4, [], false);
        [compshuf, rhoshuf]         = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        
        % compute coherence etc
        [cohshufstim, cohshuf] = mous_multisetcca_coh(compshuf);
        trctmp                 = mous_multisetcca_trc(compshuf, stimuli);
        Rshuf(1,1,cnt)         = single(mean(mean(rhoshuf(selvis,selvis,1))))-1./numel(selvis);
        Rshuf(1,2,cnt)         = single(mean(mean(rhoshuf(selvis,selaudio,1))));
        Rshuf(2,1,cnt)         = single(mean(mean(rhoshuf(selaudio,selvis,1))));
        Rshuf(2,2,cnt)         = single(mean(mean(rhoshuf(selaudio,selaudio,1))))-1./numel(selaudio);
        
        if cnt==1
          trcshuf = trctmp;
        else
          trcshuf.rho(:,:,cnt) = trctmp.rho;
        end
                
        tmpCshuf       = cohshuf.cohspctrm;
        Cshuf(:,1,cnt) = mean(mean(tmpCshuf(selvis,selvis,:,:)))-1./numel(selvis);
        Cshuf(:,2,cnt) = mean(mean(tmpCshuf(selaudio,selaudio,:,:)))-1./numel(selaudio);
        Cshuf(:,3,cnt) = mean(mean(tmpCshuf(selvis,selaudio,:,:)));
      
        tmpCshufstim       = cohshufstim.cohspctrm;
        Cshufstim(:,1,cnt) = mean(abs(tmpCshufstim(selvis,:,:)));
        Cshufstim(:,2,cnt) = mean(abs(tmpCshufstim(selaudio,:,:)));
      end
      
      
      foi   = cohshuf(1).freq;
      savedir = sprintf('/project/3011020.09/jansch/mscca_group/scenario%d',scenario);
      filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf2%s',scenario,parcel_indx,suffix));
      if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        Cshuf = cat(3,tmp.Cshuf,Cshuf);
        Rshuf = cat(3,tmp.Rshuf,Rshuf);
        Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
        trcshuf.rho = cat(3,tmp.trcshuf.rho, trcshuf.rho);
      end
      save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim','trcshuf');
    
  end
end
%--------------------------------------------------------------------------

