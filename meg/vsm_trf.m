function vsm_trf(subject)

d           = vsm_dir();
savedir     = d.trf;

ft_hastoolbox('cellfunction', 1);

meg         = fullfile(d.preproc, [subject '_lcmv-data.mat']);
audio       = fullfile(d.preproc, [subject '_aud.mat']);
featuredata = fullfile(d.preproc, [subject, '_lng.mat']);
load(meg)
load(audio)
load(featuredata)

do_modelA  = true; % audio envelope
do_modelA1 = false; % semdist alone
do_modelA2 = false; % perplexity alone
do_modelB  = true; % word onsets
do_modelBc = true;
do_modelC  = true; % semantic distance
do_modelCc = true;
do_modelD  = false; % perplexity
do_modelDc = false;
do_modelE  = false; % entropy
do_modelEc = false;
do_w2v     = false;  % w2v

do_test    = false;
testwhat   = 'lambda-training'; % 'lambda', 'delta_pulse';

%% Create Predictor variables


% Audio envelope predictor
cfg         = [];
cfg.channel = 'audio_avg';
audio       = ft_selectdata(cfg, audio);

% Feature 1 = word onset stick predictor
cfg         = [];
cfg.channel = {'semdist2'};
feature2    = ft_selectdata(cfg, featuredata);
cfg.channel = {'perplexity'};
feature3    = ft_selectdata(cfg, featuredata);
cfg.channel = {'entropy'};
feature4    = ft_selectdata(cfg, featuredata);

feature1         = feature3; % build feature1 on the perplexity data struct
onsets           = cellfun(@(x) ~isnan(x), feature1.trial(end, :), 'UniformOutput', 0)'; % create onsets based on 1 channel
onsets           = cellfun(@double, onsets(:), 'UniformOutput', 0)';
feature1.trial   = onsets;
feature1.label   = {'wordon'};
feature1.fsample = data.fsample;

% Feature 1 control predictor
feature1S       = feature1;
feature1S.label = {'wordonS'}; 

for k = 1:numel(feature1.trial)
    half                      = ceil(size(feature1.trial{k}, 2)/2);
    feature1S.trial{k}(:)     = [feature1.trial{k}(half + 1:end), feature1.trial{k}(1:half)];
end

% Semantic distance, entropy, and perplexity mean subtracted
feature2.trial                  = cellfun(@(x) x-nanmean(x), feature2.trial(:), 'UniformOutput', 0)';
feature3.trial                  = cellfun(@(x) x-nanmean(x), feature3.trial(:), 'UniformOutput', 0)';
feature4.trial                  = cellfun(@(x) x-nanmean(x), feature4.trial(:), 'UniformOutput', 0)';

% Replace nans with zeros
for i = 1:numel(feature2.trial)
    feature2.trial{i}(isnan(feature2.trial{i})) = 0;
    feature3.trial{i}(isnan(feature3.trial{i})) = 0;
    feature4.trial{i}(isnan(feature4.trial{i})) = 0;
end

% Feature 2, control predictor
feature2S       = feature2;
feature2S.label = {[feature2.label{1} 'S']};
feature3S       = feature3;
feature3S.label = {[feature3.label{1} 'S']};
feature4S       = feature4;
feature4S.label = {[feature4.label{1} 'S']};

for k = 1:numel(feature2.trial)
    
    % Onset for semantic distance values
    wons    = feature2.trial{k} ~= 0;
    semval  = feature2.trial{k}(wons);% check for feature values at word onsets for all channels
    halfs   = ceil(size(semval, 2)/2);   % determine the size of the circular shift
    semval2 = circshift(semval, halfs);  % shift by 'halfs' positions
    
    feature2S.trial{k}(1, wons) = semval2; % assign shifted values to the same indices
    
    % Onsets for language model values (differs for LM because
    % semdist is not defined for some words)
    wonsLM = feature3.trial{k} ~= 0;
    pval   = feature3.trial{k}(wonsLM); % perplexity values
    eval   = feature4.trial{k}(wonsLM); % entropy values
    halfs2 = ceil(size(pval, 2)/2);     % determine shift size (half the words)
    
    pval2  = circshift(pval, halfs2);
    eval2  = circshift(eval, halfs2);
    
    feature3S.trial{k}(1, wonsLM) = pval2;   % assign shifted values to the same indices as you got them from
    feature4S.trial{k}(1, wonsLM) = eval2; % assign shifted values to the same indices
    
end

% W2V feature
cfg         = [];
cfg.channel = featuredata.label(contains(featuredata.label, 'embedding'));
feature5    = ft_selectdata(cfg, featuredata);

datain  = ft_appenddata(cfg, data, audio, feature1, feature1S, feature2, feature2S, feature3, feature3S, feature4, feature4S);
datain2 = ft_appenddata(cfg, data, feature5); % append only semantic vectors

clear featuredata


%% FIT models

cfg                     = [];
cfg.channel             = data.label;
cfg.method              = 'mlrridge';
cfg.threshold           = [1 0];      % arbitrary
cfg.reflags             = (-5:74)./100;
cfg.demeandata          = 'yes';
cfg.demeanrefdata       = 'no';       % language predictors are already demeaned
cfg.standardisedata     = 'yes';
cfg.standardiserefdata  = 'yes';
cfg.performance         = 'Pearson';
cfg.output              = 'model';
cfg.testtrials          = mat2cell(1:numel(data.trial), 1, ones(1,numel(data.trial))); % select final trial for testing

if do_modelA
    % Audio predictor
    cfg.refchannel = {'audio_avg'};
    modelA         = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'A' '.mat']), 'modelA', '-v7.3');
    clear modelA
end

if do_modelA1
    % Word onsets alone alone
    cfg.refchannel = {'wordon'};
    modelA1        = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'A1' '.mat']), 'modelA1', '-v7.3');
    clear modelA1
end

if do_modelA2
    % Semdist predictor alone
    cfg.refchannel = {'semdist2'};
    modelA2        = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'A2' '.mat']), 'modelA2', '-v7.3');
    clear modelA2
end

if do_modelB
    % Audio predictor + word onsets
    cfg.refchannel = {'audio_avg', 'wordon'};
    modelB         = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'B' '.mat']), 'modelB', '-v7.3');
    clear modelB
end

if do_modelBc
    % Audio predictor + word onsets shifted
    cfg.refchannel = {'audio_avg', 'wordonS'};
    modelBc        = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'Bc' '.mat']), 'modelBc', '-v7.3');
    clear modelBc
end

if do_modelC
    % Audio, word onsets + feature3
    cfg.refchannel = {'audio_avg', 'wordon', 'semdist2'};
    modelC         = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'C' '.mat']), 'modelC', '-v7.3');
    clear modelC
end

if do_modelCc
    % Audio, word onsets, + feature3 shifted
    cfg.refchannel = {'audio_avg', 'wordon', 'semdist2S'};
    modelCc       = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'Cc' '.mat']), 'modelCc', '-v7.3');
    clear modelCc
end

if do_modelD
    % Audio, perplexity, perplexity reassigned
    cfg.refchannel = {'audio_avg', 'wordon', 'perplexity'};
    modelD       = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'D' '.mat']), 'modelD', '-v7.3');
    clear modelD
end

if do_modelDc
    cfg.refchannel = {'audio_avg', 'wordon', 'perplexityS'};
    modelDc        = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'Dc' '.mat']), 'modelDc', '-v7.3');
    clear modelDc
end

if do_modelE
    cfg.refchannel = {'audio_avg', 'wordon', 'entropy'};
    modelE       = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'E' '.mat']), 'modelE', '-v7.3');
    clear modelE
end

if do_modelEc
    cfg.refchannel = {'audio_avg', 'wordon', 'entropyS'};
    modelEc        = ft_denoise_tsr(cfg, datain);
    save(fullfile(savedir, [subject '_' 'Ec' '.mat']), 'modelEc', '-v7.3');
    clear modelEc
end

if do_w2v
    cfg.refchannel = datain2.label(contains(datain2.label, 'embedding'));
    cfg.reflags    = [0 0.400];
    modelW2V       = ft_denoise_tsr(cfg, datain2);
    save(fullfile(savedir, [subject '_' 'W2V' '.mat']), 'modelW2V', '-v7.3');
    clear modelW2V
end

%% TESTS

if do_test
    
    refchind = find(ismember(datain.label, {'audio_avg', 'semdist2', 'semdist2S'}));
    
    cfg                 = [];
    cfg.channel         = datain.label([1, 2, 3, 4, 5, refchind']); % create 4-channel test data (end-4 = 'audio_avg')
    datain_test         = ft_selectdata(cfg, datain);
    
    datain_test.trial   = cellrowassign(datain_test.trial, audio.trial, 1);                  % noisy audio
    datain_test.trial   = cellrowassign(datain_test.trial, audio.trial, 2);                  % clear audio
    datain_test.trial   = cellrowassign(datain_test.trial, feature2.trial, 3);               % stick feature
    datain_test.trial   = cellrowassign(datain_test.trial, feature2S.trial, 4);              % control stick feature
    datain_test.trial   = cellrowassign(datain_test.trial, audio.trial + feature2.trial, 5); % stick + audio
    
    % add noise to channel 1
    for k = 1:numel(datain_test.trial)
      datain_test.trial{k}(1,:) = datain_test.trial{k}(1, :) + randn(1, numel(datain_test.time{k}))./100;
    end
    
    % make different labels for test channels
    datain_test.label{1}   = 'test_audio_noise';
    datain_test.label{2}   = 'test_audio_avg';
    datain_test.label{3}   = ['test_' feature2.label{1}];
    datain_test.label{4}   = ['test_' feature2S.label{1}];
    datain_test.label{5}   = ['test_audio_' feature2.label{1}];
    
    cfg                     = [];
    cfg.channel             = datain_test.label(1:5);
    cfg.method              = 'mlrridge';
    cfg.threshold           = [1 0]; % [0.001 0];
    cfg.reflags             = (-5:74)./100;
    cfg.demeanrefdata       = 'no';
    cfg.demeandata          = 'yes';
    cfg.standardisedata     = 'yes';
    cfg.standardiserefdata  = 'yes';
    cfg.performance         = 'Pearson';
    cfg.output              = 'model';
    cfg.testtrials          = 1; %mat2cell(1:numel(datain_test.trial), 1, ones(1,numel(datain_test.trial))) % select final trial for testing

    switch testwhat
    
        case 'delta_pulse'
            
            cfg.refchannel  = {'audio_avg'};
            trftestA        = ft_denoise_tsr(cfg, datain_test);
            cfg.refchannel  = {'semdist2'};
            trftestA2       = ft_denoise_tsr(cfg,datain_test);
            cfg.refchannel  = {'audio_avg', 'semdist2'};
            trftestC        = ft_denoise_tsr(cfg, datain_test);
            cfg.refchannel  = {'audio_avg', 'semdist2S'};
            trftestCc        = ft_denoise_tsr(cfg, datain_test);

            save(fullfile(savedir, [subject '_' 'trftest' '.mat']), 'trftestA', 'trftestA2', 'trftestC', 'trftestCc', '-v7.3');
        
        case 'lambda-training'
            cfg = rmfield(cfg, 'testtrials'); % training data will be used for computing performance
            
            cfg.refchannel  = {'audio_avg', 'semdist2'};
            
            cfg.threshold   = [0.001 0]; 
            trftestL10e_3   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold   = [0.01 0]; 
            trftestL10e_2   = ft_denoise_tsr(cfg, datain_test);
     
            cfg.threshold   = [0.1  0];
            trftestL10e_1   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [1  0];
            trftestL10e0   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [10  0];
            trftestL10e1   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [100  0];
            trftestL10e2   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [1000  0];
            trftestL10e3   = ft_denoise_tsr(cfg, datain_test);

            save(fullfile(savedir, [subject '_' 'trftestL' '.mat']), ...
                           'trftestL10e_3', ...
                           'trftestL10e_2', ...
                           'trftestL10e_1', ...
                           'trftestL10e0', ...
                           'trftestL10e1', ...
                           'trftestL10e2', ...
                           'trftestL10e3', ...
                           '-v7.3');
                       
        case 'lambda-test'
            
            cfg.testtrials  = 1; % one story will be used as a held out set
            cfg.refchannel  = {'audio_avg', 'semdist2'};
            
            cfg.threshold   = [0.001 0]; 
            trftestLT10e_3   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold   = [0.01 0]; 
            trftestLT10e_2   = ft_denoise_tsr(cfg, datain_test);
     
            cfg.threshold   = [0.1  0];
            trftestLT10e_1   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [1  0];
            trftestLT10e0   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [10  0];
            trftestLT10e1   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [100  0];
            trftestLT10e2   = ft_denoise_tsr(cfg, datain_test);
            
            cfg.threshold  = [1000  0];
            trftestLT10e3   = ft_denoise_tsr(cfg, datain_test);

            save(fullfile(savedir, [subject '_' 'trftestLT' '.mat']), ...
                           'trftestLT10e_3', ...
                           'trftestLT10e_2', ...
                           'trftestLT10e_1', ...
                           'trftestLT10e0', ...
                           'trftestLT10e1', ...
                           'trftestLT10e2', ...
                           'trftestLT10e3', ...
                           '-v7.3');
            
            
    end
end

end