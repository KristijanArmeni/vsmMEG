function [status, filename] = vsm_util_existfile(filenamein, pathname)

dirs = vsm_dir();

% the assumed path where the files will be looked for is:
if nargin<2
  pathname = dirs.preproc;
end
filename = fullfile(pathname,filenamein);
status   = exist(filename,'file');

if ~status
  d = dir(pathname);
  d(1:2) = [];
  for k = 1:numel(d)
    if d(k).isdir
      filename = fullfile(pathname,d(k).name,filenamein);
      status   = exist(filename,'file');
      if status
        return;
      end
    end
  end
end