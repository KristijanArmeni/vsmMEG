function [subject] = vsm_subjinfo(name)

% STREAMS_SUBJINFO gets the subject specific information
%
% Use as
%   subject = streams_subjinfo(name), where name is a string representing the subject
%   name

if iscell(name)
  for k = 1:numel(name)
    subject(k,1) = vsm_subjinfo(name{k});
  end
  return;
end

vsmdir = vsm_dir();

subject.name = name;
subjectdir = sprintf('sub-%0.3d', str2double(name(2:end)));

subject.montage          = [];
subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
subject.montage.labelnew = {'EOGh';  'EOGv';  'ECG'};
subject.montage.tra      = eye(3);

subject_rawdir   = fullfile('/project/3011085.04/data/raw/', subjectdir);
subject.mridir    = '/project/3011044.02/data/mri';
subject.audiodir  = vsmdir.audio;

% check for meg sessions subfolders in the /project/3011044.02/raw/sub-XXX
meg_sessions = dir(fullfile(subject_rawdir, 'ses-meg*'));
meg_sessions = {meg_sessions.name}';
mri_sessions = dir(fullfile(subject_rawdir, 'ses-mri*'));
mri_sessions = {mri_sessions.name}';
if isempty(meg_sessions) && isempty(mri_sessions)
    error('Cannot find meg and mri subdirectories in %s. Check please.', subject_rawdir)
elseif isempty(meg_sessions)
    error('Cannot find meg subdirectory in %s. Check please.', subject_rawdir)
elseif isempty(mri_sessions)
    warning('Cannot find mri subdirectories in %s.', subject_rawdir)
end

if numel(meg_sessions) == 1
    subject.datadir = char(fullfile(subject_rawdir, meg_sessions{1}));
else
    subject.datadir = subject_rawdir; % enter sessions manually later in the code
    warning('More than one meg sessions in %s. Specify manually', subject_rawdir)
end

% check for mri sessions subfolders in /project/3011044.02/raw/sub-XXX
if numel(mri_sessions) == 1
    subject.mridir = char(fullfile(subject_rawdir, mri_sessions{1}));
else
    subject.mridir = subject_rawdir; % enter sessions manually later in the code
end

% enter information for subject-specific datastructures
switch name
  case 'p01'
    subject.datadir   = '/project/3011044.02/data/raw_old/3011044.02_pilot';
    subject.dataset   = {fullfile(subject.datadir, 'streampilot_1200hz_20120611_01.ds');
      fullfile(subject.datadir, 'streampilot_1200hz_20120611_02.ds');
      fullfile(subject.datadir, 'streampilot_1200hz_20120611_03.ds');
      fullfile(subject.datadir, 'streampilot_1200hz_20120611_04.ds')};
    subject.trl       = [  9824 823638 0 12;
      9291 284257 0 22;
      14013 884990 0 21;
      41607 761265 0 11];
    subject.audiodir  = '/project/3011044.02/lab/pilot/stim/audio/old/20120611/';
    subject.audiofile = {fullfile(subject.audiodir, 'fn000249_dialogue2', 'fn000249_dialog2.wav');
      fullfile(subject.audiodir, 'fn001055_lit2', 'fn001055_lit2.wav');
      fullfile(subject.audiodir, 'fn001163_lit1.wav');
      fullfile(subject.audiodir, 'fn000752_dialog1.wav')};
    subject.awdfile     = {fullfile(subject.audiodir, 'fn000249_dialogue2', 'fn00249.awd');
      fullfile(subject.audiodir, 'fn001055_lit2', 'fn001055.awd');
      fullfile(subject.audiodir, 'fn001163.awd');
      fullfile(subject.audiodir, 'fn000752.awd')};
    subject.streamsfile = {fullfile(subject.audiodir, 'fn00249_dialogue2', 'fn000249.words.donderstest');
      fullfile(subject.audiodir, 'fn001055_lit2', 'fn001055.words.donderstest');
      fullfile(subject.audiodir, 'fn001163.words.donderstest');
      fullfile(subject.audiodir, 'fn000752.words.donderstest')};
    
    
  case 'p02'
    subject.datadir   = '/project/3011044.02/data/raw_old/3011044.02_pilot';
    subject.dataset   = {fullfile(subject.datadir, 'streampilot_1200hz_20120709_02.ds');
      fullfile(subject.datadir, 'streampilot_1200hz_20120709_02.ds');
      fullfile(subject.datadir, 'streampilot_1200hz_20120709_02.ds')};
    subject.trl       = [  35901  710002 0 11;
      869024 1432662 0 21;
      1532322 2346136 0 12];
    subject.audiodir  = '/project/3011044.02/lab/pilot/stim/audio/old/20120709';
    subject.audiofile = {fullfile(subject.audiodir, 'fn000606_dialog1.wav');
      fullfile(subject.audiodir, 'fn001100_lit1.wav');
      fullfile(subject.audiodir, 'fn000249_dialog2.wav')};

    
  case 's01'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130429_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav')};
    subject.id        = 'jansch';
    subject.eogv.badcomps = 12;
    subject.trl       = [  28757  297926 0  1;
      311914  597034 0  2;
      771421 1058574 0 31;
      1068018 1637770 0 32;
      1657392 2235306 0  4;
      2243405 2534693 0  5];
  
    subject.cac = [1 4 6];
    subject.lcmv_voxindx = sort([25533 23261 17180 31868 27772 20644 24226 33094 17221 26532 23537]);
    % subject JM
  case 's02'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130502_01.ds']);
    %subject.trl       = [   9094  278263 0  1;
    %  307261  592369 0  2;
    %  685246  972394 0 31;
    %  997073 1566829 0 32;
    %  1649126 2227042 0  4;
    %  2306239 2597527 0  5;
    %  2632845 3214041 0  6];
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '43513';
    subject.eogv.badcomps = [11 14 15];
    %subject.cac = [1 6];
    subject.cac = [1 4.2 6.6];
    
  case 's03'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130516_01.ds']);
    %subject.trl       = [  17197  286367 0  1;
    %  332065  617174 0  2;
    %  660872  948021 0 31;
    %  1037798 1607556 0 32;
    %  1692193 2270110 0  4;
    %  2310449 2601717 0  5;
    %  2638236 3219433 0  6;
    %  3332969 4251833 0  7];
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav');
      fullfile(subject.audiodir, 'fn001172.wav')};
    subject.id = '78310';
    subject.eogv.badcomps = [1 3 4 6 13];
    %subject.cac = [1 4.5];
    subject.cac = [1 4.4 5.4];
  case 's04'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130517_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '55066';
    subject.eogv.badcomps = 7;
    %subject.cac = [1 5];
    subject.cac = [0.8 3.6 4.2 7];
  case 's05'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130521_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav');
      fullfile(subject.audiodir, 'fn001172.wav')};
    subject.id = '47143';
    subject.eogv.badcomps = 18;
    %subject.cac = [1 5.5];
    subject.cac = [1 4.6 5.6];
  
  case 's07'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130522_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav');
      fullfile(subject.audiodir, 'fn001172.wav')};
    subject.id = '79969';
    subject.eogv.badcomps = [13 15];
    %subject.cac = [1 5.5];
    subject.cac = [1 3.8 4.6 5.6];
  case 's08'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130522_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '46726';
    subject.eogv.badcomps = [12 14];
    %subject.cac = [1.25 5 8];
    subject.cac = [1.2 3.2 5.2];
  case 's09'
    subject.dataset   = {fullfile(subject.datadir, meg_sessions{1}, [name, '_1200hz_20130523_01.ds']);
      fullfile(subject.datadir, meg_sessions{2}, [name, '_1200hz_20130523_02.ds'])};
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav');
      fullfile(subject.audiodir, 'fn001172.wav')};
      
    % this one was lost due to a dsq error? : fullfile(subject.audiodir, 'fn001155.wav');
    
    subject.id = '71926';
    subject.eogv.badcomps = {[1 8], [1 8]};
    %subject.cac = [1 5.5 4.5];
    subject.cac = [1 3.2 4.6 5.4];
  case 's10'
    subject.dataset   = fullfile(subject.datadir, [name, '_1200hz_20130606_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
      fullfile(subject.audiodir, 'fn001155.wav');
      fullfile(subject.audiodir, 'fn001293.wav');
      fullfile(subject.audiodir, 'fn001294.wav');
      fullfile(subject.audiodir, 'fn001443.wav');
      fullfile(subject.audiodir, 'fn001481.wav');
      fullfile(subject.audiodir, 'fn001498.wav');
      fullfile(subject.audiodir, 'fn001172.wav')};
    subject.id = '78250';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG058';'EEG057';'EEG059'};
    %subject.cac  = [1 4.5 10];
    subject.cac = [0.8 3.6 6 11.2];
  
  case 's11' % This is the first subject in the newly acquired dataset. Behavioral Presentation log for this subject was s01-streams.log
    subject.dataset   = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160510_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '105445';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGh';  'EOGv'};
    
  case 's12'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160525_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '79819';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGh';  'EOGv'};
   
  case 's13'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160527_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '116209';
    subject.eogv.badcomps = 6;
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGh';  'EOGv'};
    
  case 's14'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160530_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '115054';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's15'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160530_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '114196';
    subject.eogv.badcomps = [16 18];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's16'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160602_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '116533';
    subject.eogv.badcomps = 17;
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's17'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160602_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '111493';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's18'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160628_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = 'jansch';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's19'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160711_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '95194';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's20'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160712_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '116371';
    subject.eogv.badcomps = 7;
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's21'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160714_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '97753';
    subject.eogv.badcomps = 16;
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's22'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160718_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '93829';
    subject.eogv.badcomps = 10;
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's23'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160725_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                         fullfile(subject.audiodir, 'fn001155.wav')
                         fullfile(subject.audiodir, 'fn001293.wav')
                         fullfile(subject.audiodir, 'fn001443.wav')
                         fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '117349';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's24'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160921_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                         fullfile(subject.audiodir, 'fn001155.wav')
                         fullfile(subject.audiodir, 'fn001293.wav')
                         fullfile(subject.audiodir, 'fn001443.wav')
                         fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '84556';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's25'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20160926_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                         fullfile(subject.audiodir, 'fn001155.wav')
                         fullfile(subject.audiodir, 'fn001293.wav')
                         fullfile(subject.audiodir, 'fn001443.wav')
                         fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '111865';
    subject.eogv.badcomps = 15;
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's26'
    subject.dataset = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20161003_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                        fullfile(subject.audiodir, 'fn001155.wav')
                        fullfile(subject.audiodir, 'fn001293.wav')
                        fullfile(subject.audiodir, 'fn001443.wav')
                        fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '117964';
    subject.eogv.badcomps = [];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's27'
    subject.dataset   = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20161005_01.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                         fullfile(subject.audiodir, 'fn001155.wav');
                         fullfile(subject.audiodir, 'fn001293.wav');
                         fullfile(subject.audiodir, 'fn001443.wav');
                         fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '111121';
    subject.eogv.badcomps = [2 4];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
    
  case 's28'
    subject.dataset   = fullfile(subject.datadir, ['301104402kriarm' name '_1200hz_20161121_02.ds']);
    subject.audiofile = {fullfile(subject.audiodir, 'fn001078.wav');
                         fullfile(subject.audiodir, 'fn001155.wav');
                         fullfile(subject.audiodir, 'fn001293.wav');
                         fullfile(subject.audiodir, 'fn001443.wav');
                         fullfile(subject.audiodir, 'fn001498.wav')};
    subject.id = '122515';
    subject.eogv.badcomps = [8 12];
    subject.montage.labelorg = {'EEG057';'EEG058';'EEG059'};
    subject.montage.labelnew = {'ECG';  'EOGv';  'EOGh'};
end

if ~strcmp(name, 's01')
  % compute trial definition
  subject.trl = streams_definetrial(subject.dataset, name);
end

% reorder audiofile strings in line with which they were presented (applies
% only to subjects s11-s28
if str2double(name(2:end)) >= 11
  subject.audiofile(:, end) = subject.audiofile(subject.trl(:, end)./10); % create one-valued ints
end    
    
% get squid artifacts
cfg = streams_artifact_squidjumps(subject);
if ~iscell(cfg)
  subject.artfctdef.squidjumps = cfg.artfctdef.zvalue;
else
  for k = 1:numel(cfg)
    subject.artfctdef.squidjumps{k} = cfg{k}.artfctdef.zvalue;
  end
end
  
% get muscle artifacts
cfg = streams_artifact_muscle(subject);
if ~iscell(cfg)
  subject.artfctdef.muscle = cfg.artfctdef.zvalue;
else
  for k = 1:numel(cfg)
    subject.artfctdef.muscle{k} = cfg{k}.artfctdef.zvalue;
  end
end

% Do component analysis per story
subject.ica.comp    = vsm_fastica(subject);

% Load selected components
compsel = fullfile(vsmdir.preproc, [subject.name '_compsel.mat']);
if exist(compsel, 'file')
    load(compsel);
    subject.ica.compsel = compsel;
else
    subject.ica.compsel = [];
end

% estimate the delay between the audio signal in the data, and the wav-file
delay         = streams_audiodelay(subject);
subject.delay = delay(:)';

% adjust the timing in the trl with the delay
if isfield(subject, 'delay')
  if ~iscell(subject.trl)
    subject.trl(:,3) = -round(subject.delay.*(1200/1000));
  else
    cnt = 0;
    for m = 1:numel(subject.trl)
      subject.trl{m}(:,3) = -round(subject.delay(cnt+(1:size(subject.trl{m},1))).*(1200/1000));
      cnt = cnt + size(subject.trl{m},1);
    end
  end
end

% add preproc data info, if they exist

subject.preproc.meg         = [];
subject.preproc.aud         = [];
subject.preproc.lng         = [];
subject.anatomy.leadfield   = [];
subject.anatomy.headmodel   = [];

megpreproc = fullfile(vsmdir.preproc, [subject.name, '_meg.mat']);
audpreproc = fullfile(vsmdir.preproc, [subject.name, '_aud.mat']);
lngpreproc = fullfile(vsmdir.preproc, [subject.name, '_lng.mat']);
headmodel  = fullfile(vsmdir.anatomy, [subject.name, '_headmodel.mat']);
leadfield  = fullfile(vsmdir.anatomy, [subject.name, '_leadfield.mat']);

if exist(megpreproc, 'file') == 2; subject.preproc.meg = megpreproc; end
if exist(audpreproc, 'file') == 2; subject.preproc.aud = audpreproc; end
if exist(lngpreproc, 'file') == 2; subject.preproc.lng = lngpreproc; end
if exist(headmodel, 'file') == 2; subject.anatomy.headmodel = headmodel; end
if exist(leadfield, 'file') == 2; subject.anatomy.leadfield = leadfield; end;

end
