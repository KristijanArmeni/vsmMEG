function [vecmat, words] = vsm_readvectors(vector_file)
%vsm_readvectors() reads vectors via readtable() from .txt files provided in vector_file.
% It assumes (space-delimited) .txt file with first column being word strings and the
% rest are vector colums.
%
%  [vecmat, words] = vsm_readvectors(vector_file);

opts             = detectImportOptions(vector_file);
opts.LineEnding  = '\n';

vectab = readtable(vector_file, opts);

vecmat = vectab{:,2:end-1}; % store vectors to a separate matrix (drop the first and last vars)
words  = vectab.Var1;       % the first column are word strings

end

