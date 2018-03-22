function [comp]  = vsm_fastica(subject)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if ischar(subject)
    subject = vsm_subjinfo(subject);
end

d = vsm_dir();

[status, filename] = vsm_util_existfile([subject.name '_comp.mat']);

if status
    
  load(filename);

else
    
    num_trl = size(subject.trl, 1);
    comp    = cell(num_trl, 1);    % return separate components per story as cell array
    eogvcor = cell(num_trl, 1);
    eoghcor = cell(num_trl, 1);
    
    for k = 1:num_trl
    
    fprintf('computing EOGv topographies for subject %s, story %d\n', subject.name, k)
    
    trl = subject.trl(k, :);
    
    % Read in the
    cfg0                  = [];
    cfg0.dataset          = subject.dataset;
    cfg0.trl              = trl;
    cfg0.channel          = 'MEG';
    cfg0.continuous       = 'yes';
    cfg0.demean           = 'yes';

    dat0                  = ft_preprocessing(cfg0);    
    
    cfgtmp                = [];
    cfgtmp.trl            = trl;
    cfgtmp.fsample        = [];
    [eogh, eogv]          = vsm_eeg(cfgtmp, subject);
    
    % Make sure ICA is performed on trial with squids and muscle removed
    cfg1                  = [];
    cfg1.artfctdef        = subject.artfctdef;
    cfg1.artfctdef.reject = 'nan';
    
    dat1                  = ft_rejectartifact(cfg1, dat0);
    eogh                  = ft_rejectartifact(cfg1, eogh);
    eogv                  = ft_rejectartifact(cfg1, eogv);

    % downsample to 300 Hz
    cfg2            = [];
    cfg2.demean     = 'no';
    cfg2.detrend    = 'no';
    cfg2.resamplefs = 300;
    dat2            = ft_resampledata(cfg2, dat1);   
    eogh            = ft_resampledata(cfg2, eogh);
    eogv            = ft_resampledata(cfg2, eogv);
    clear dat1
    
    % Perform component analysis
    cfg                 = [];
    cfg.method          = 'fastica';
    cfg.fastica.lastEig = 80;
    cfg.fastica.g       = 'tanh';
    cfg.channel         = 'MEG';
    cfg.numcomponent    = 20;
    comp{k}             = ft_componentanalysis(cfg, dat2);
    
    % compute eogv-ica correlation
    x = eogv.trial{:};
    y = comp{k}.trial{:};
    c = [y; x];
    eogvcor{k} = corrcoef(c', 'rows', 'pairwise');
    
    x = eogh.trial{:};
    c = [y; x];
        
    % compute eogv-ica correlation
    eoghcor{k} = corrcoef(c', 'rows', 'pairwise');
    
    end

fprintf('Saving to %s\n', filename);
save(filename, 'comp');

save(fullfile(d.preproc, [subject.name, '_eogcorr']), 'eogvcor', 'eoghcor');

end

end

 