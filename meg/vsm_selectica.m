function compsel = vsm_selectica(subject)

if ischar(subject)
    subject       = vsm_subjinfo(subject);
end

d = vsm_dir();

compsel = cell(numel(subject.ica.comp), 1);

[status, filename] = vsm_util_existfile([subject.name '_compsel.mat']);

if status
    load(filename)
else
   
    eogcorrf = fullfile(d.preproc, [subject.name '_eogcorr.mat']);
    load(eogcorrf); % eoghcor and eogvcor variables
    
    for k = 1:numel(subject.ica.comp) % number of components = number of stories
        
        fprintf('Ploting components for subject %s, story %d ...\n\n', subject.name, k)
        
        comp   = subject.ica.comp{k};
        trltmp = subject.trl(k,:);
        
        cfg          = [];
        cfg.fsample  = [];
        cfg.trl      = trltmp;
        [eogh, eogv] = vsm_eeg(cfg, subject.name);
        
        cfg1             = [];
        cfg1.viewmode    = 'component';
        cfg1.continuous  = 'yes';
        cfg1.blocksize   = 10;
        cfg1.component   = 1:10;
        cfg1.layout      = 'CTF275_helmet.mat';
        
        figure;
        ft_topoplotIC(cfg1, comp);
        set(gcf, 'Name', sprintf('%s ICA comps story %d', subject.name, k), 'NumberTitle', 'off')
        
        figure;
        cfg1.component  = 11:20;
        ft_topoplotIC(cfg1, comp);
        set(gcf, 'Name', sprintf('%s ICA comps story %d', subject.name, k), 'NumberTitle', 'off')
        
        ft_databrowser(cfg1, comp);
        set(gcf, 'Name', sprintf('%s ICA comps story %d', subject.name, k), 'NumberTitle', 'off')
             
        cfg3                 = cfg1;
        cfg3.viewmode        = 'butterfly';
        cfg3.preproc.demean  = 'yes';
        ft_databrowser(cfg3, eogv); 
        set(gcf, 'Name', sprintf('EOGv %s, story %d', subject.name, k), 'NumberTitle', 'off')
        
        figure; imagesc(eogvcor{k}(1:end-1, end)); %select final column first 20 rows
        colorbar;
        title('Correlations coefs ICA-eogv');
        set(gcf, 'Name', sprintf('%s correlations, story %d', subject.name, k), 'NumberTitle', 'off')
        
        [v, c] = max(abs(eogvcor{k}(1:end-1, end)));
        fprintf('Maximal EOGv-ICA correlation of %d has the component %d.\n\n', v, c)

        ft_databrowser(cfg3, eogh); 
        set(gcf, 'Name', sprintf('EOGh %s, story %d', subject.name, k), 'NumberTitle', 'off')
        
        figure; imagesc(eoghcor{k}(1:end-1, end)); %select final column first 20 rows
        colorbar;
        title('Correlation coefs (ICA-eogh)');
        set(gcf, 'Name', sprintf('%s correlations, story %d', subject.name, k), 'NumberTitle', 'off')
        
        [v, c] = max(abs(eoghcor{k}(1:end-1, end)));
        fprintf('Maximal EOGh-ICA correlation of %d has the component %d.\n\n', v, c)
        
        % select components
        compsel{k}.eye   = input(sprintf('Which eye components should be rejected for story %d? Type vector: ', k));
        compsel{k}.heart = input(sprintf('Which heart components should be rejected for story %d? Type vector: ', k));
        
        close all
       
        fprintf('Saving %s ...\n\n ', [subject.name '_compseltmp.mat']);
        ftmp = fullfile(d.preproc, [subject.name '_compseltmp.mat']);
        save(ftmp, 'compsel');
        
    end
    
    fprintf('Saving %s ...\n\n ', filename);
    save(filename, 'compsel');
    
end


end