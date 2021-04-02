function dirs = vsm_dir()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
%
% dirs.home
% dirs.home.data
% dirs.home.data.raw
% dirs.home.data.preproc

dirs.home       = '/project/3011085.04';
dirs.streams    = fullfile(dirs.home, 'streams');

% data directories
dirs.data       = fullfile(dirs.home, 'data');
dirs.raw        = fullfile('/.repo/dccn/DAC_3011044.02_628:v1/raw');
dirs.meg        = fullfile(dirs.data, 'derived');
dirs.preproc    = dirs.meg;
dirs.audio      = fullfile(dirs.data, 'stim', 'audio');
dirs.result     = fullfile(dirs.home, 'results');
dirs.anatomy    = fullfile(dirs.streams, 'preproc', 'anatomy');

% analysis outputs
dirs.analysis = fullfile(dirs.home, 'analysis');
dirs.trf      = fullfile(dirs.analysis, 'trf');

% results
dirs.results  = fullfile(dirs.home, 'results');

% atlases
dirs.atlas = {fullfile('/project/3011085.05/data/atlas','atlas_subparc374_8k.mat');
              fullfile(dirs.streams, 'preproc', '/atlas/atlas_MSMAll_8k_subparc.mat');
              fullfile(dirs.streams, 'preproc', '/atlas/cortex_inflated_shifted.mat');
              fullfile(dirs.streams, 'preproc', '/atlas/cortex_inflated.mat')};

end

