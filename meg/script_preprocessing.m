function script_preprocessing(subject)

d = vsm_dir();

%% Preprocessing

do_stick = false;
do_box   = true;

%stories = streams_util_stories();

%NOTE: JM changed bpfreq to [1 40] (was [1 8]), and removed the dftfreq, as well as the 'semdist1/2' business on May 15 2019
inpcfg  = {'audiofile', 'all', ...
          'dospeechenvelope', 1, ...
          'dofeature', 1, ...
          'feature', {'entropy', 'perplexity', 'embedding', 'log10wf', 'duration'}, ...
          'bpfreq', [1 40], ...
          'lpfreq', [], ...
          'hpfreq', [], ...
          'word_quantify', 'all', ...
          'fsample', 100};

if do_stick

    [data, audio, featuredata] = vsm_preprocessing(subject, inpcfg);

    save(fullfile(d.preproc, [subject '_meg.mat']), 'data', '-v7.3');
    save(fullfile(d.preproc, [subject '_aud.mat']), 'audio', '-v7.3');
    save(fullfile(d.preproc, [subject '_lng.mat']), 'featuredata', '-v7.3');

end

if do_box
    % For this call, the cfg.shape in vsm_preprocessing must set to 'box'
    % prior to internal call to <get_time_series.m>
    
    [~, ~, featuredata] = vsm_preprocessing(subject, inpcfg);
    save(fullfile(d.preproc, [subject '_lng-box.mat']), 'featuredata', '-v7.3');

end
end