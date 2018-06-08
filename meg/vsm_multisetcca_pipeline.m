
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
domscca_searlight = true;
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
    load(fullfile('/project/3011044.02/vsm/data/preproc',sprintf('%s_lcmv-filt',subj(k).name)));
    
    source_parc.filterlabel = data.label; % for checking channel order, assumes same order in the filters
    
    subjectdata{1,k} = mous_multisetcca_sensor2parcel(data, source_parc, parcel_indx);
  end
    
  for k = 1:numel(subjectdata)
    % align the order of the trials
    [srt,ix] = sort(subjectdata{k}.trialinfo);
    subjectdata{k}.time  = subjectdata{k}.time(ix);
    subjectdata{k}.trial = subjectdata{k}.trial(ix);
    subjectdata{k}.trialinfo = subjectdata{k}.trialinfo(ix,:);
    subjectdata{k}.audiofile = subj(k).audiofile(ix);
    if k==1
      T = subjectdata{k}.trialinfo;
    else
      T = intersect(T, subjectdata{k}.trialinfo);
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
    cfg.trials = find(ismember(subjectdata{k}.trialinfo, T));
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
    audiofile = subjectdata{k}.audiofile;
    cfg = [];
    cfg.method = 'acrosschannel';
    subjectdata{k} = ft_channelnormalise(cfg, subjectdata{1,k});
    subjectdata{k}.audiofile = audiofile;
  end
  
  rng('default'); % reset the number generator, in order to be able to compare across parcels
  tmpdata              = mous_multisetcca_groupdata2singlestruct(subjectdata, {subj.name});
  [W, A, rho, C, comp] = mous_multisetcca(tmpdata, [], 1, [],false);
  [comp, rho]          = mous_multisetcca_postprocess(comp, rho, source_parc.label{parcel_indx});
  comp.audiofile       = subjectdata{1}.audiofile;
  [tlck, stimdata]     = vsm_extractwords(comp);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  %-------TOBEDONE----------
  switch shuftype
    case 'lenient'
      % lenient shuffling, that maintins the timing within sensory
      % modality, but does not obey individual word onsets across
      % modalities
      
      selaudio = find(strncmp(subj, 'sub-2', 5));
      selvis   = find(strncmp(subj, 'sub-1', 5));
      for m = nrand(:)'
        [groupdatashuf, allshufvec] = mous_multisetcca_shuffle(groupdata, {selvis(:)' selaudio(:)'}); % shuffle before folding
        stimdata                    = mous_multisetcca_shufflestimdata(groupdata{1}, allshufvec([selvis(1) selaudio(1)],:));
        T = stimdata{1}.trialinfo;
        cfg = [];
        cfg.operation = 'add';
        cfg.parameter = 'trial';
        stimdata = ft_math(cfg, stimdata{:});
        stimdata.trialinfo = T;
        
        % perform the cca
        [Wshuf, Ashuf, rhoshuf, ~, compshuf] = mous_multisetcca(groupdatashuf, nfold, 4, [], false);
        [compshuf, rhoshuf] = mous_multisetcca_postprocess(compshuf, rhoshuf, source_parc.label{parcel_indx});
        
        % reorder the stimonset data
        reorder = zeros(numel(stimdata.trial),1);
        for k = 1:numel(reorder)
          reorder(k) = find(stimdata.trialinfo(:,end)==compshuf.trialinfo(k));
        end
        stimdata.trialinfo = stimdata.trialinfo(reorder,:);
        stimdata.time      = stimdata.time(reorder);
        stimdata.trial     = stimdata.trial(reorder);
        for k = 1:numel(stimdata.trial)
          stimdata.trial{k}(~isfinite(stimdata.trial{k})) = 0;
        end
        % compute coherence etc
        [cohshufstim(m), cohshuf(m)] = mous_multisetcca_coh(compshuf,stimdata);
        Rshuf(:,:,:,m)              = single(rhoshuf);
      end
      Cshuf = single(cat(4,cohshuf.cohspctrm));
      Cshuf = Cshuf(:,:,1:41,:);
      Cshufstim = single(cat(3,cohshufstim.cohspctrm));
      Cshufstim = Cshufstim(:,1:41,:);
      foi   = cohshuf(1).freq(1:41);
      savedir = '/project/3011020.09/jansch/mscca_group';
      filename = fullfile(savedir, sprintf('mscca_sce%d_parcel%03dshuf',scenario,parcel_indx));
      if exist([filename,'.mat'], 'file')
        tmp = load(filename);
        Cshuf = cat(4,tmp.Cshuf,Cshuf);
        Rshuf = cat(4,tmp.Rshuf,Rshuf);
        Cshufstim = cat(3,tmp.Cshufstim,Cshufstim);
      end
      save(filename,'Rshuf','Cshuf', 'foi', 'Cshufstim');
    
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

