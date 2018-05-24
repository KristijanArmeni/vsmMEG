function script_preprocessing(subject)

d = vsm_dir();

%% Preprocessing

do_stick = false;
do_box   = true;

%stories = streams_util_stories();

inpcfg  = {'audiofile', 'all', ...
          'dospeechenvelope', 1, ...
          'dofeature', 1, ...
          'feature', {'semdist1', 'semdist2', 'entropy', 'perplexity', 'embedding', 'log10wf', 'duration'}, ...
          'bpfreq', [1 8], ...
          'lpfreq', [], ...
          'hpfreq', [], ...
          'dftfreq', [49 51; 99 101; 149 151], ...
          'word_quantify', 'all', ...)
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