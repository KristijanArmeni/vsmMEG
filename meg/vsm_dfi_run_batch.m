sname = {'s02','s03','s04','s07',...
        's11','s12','s13','s14','s15','s16',...
        's17','s18','s19','s20','s21','s22',...
        's23','s24','s25','s26','s27','s28'};
      
      
%testfeature = 'entropy';
% nrand = 25;
% for k = 1:numel(sname)
%   subj.name = sname{k};
%   qsubfeval('vsm_execute_pipeline','vsm_dfi_mscca', {'subj' subj}, {'computethr' true}, {'testfeature' testfeature}, {'nrand' nrand}, 'memreq',16*1024^3,'timreq',300*60,'batchid',sprintf('%s_%03d',subj.name,subindx));
% end
      
nrand = 40;
subs = (1:50);
for k = 1:numel(sname)
  subj.name = sname{k};
  for subindx = subs
    qsubfeval('vsm_execute_pipeline','vsm_dfi_mscca', {'subj' subj}, {'loadthr' true}, {'testfeature' testfeature}, {'nrand' nrand}, {'subindx' subindx}, 'memreq',16*1024^3,'timreq',300*60,'batchid',sprintf('%s_%03d',subj.name,subindx));
  end
end

 

% testfeature = 'log10wf';
% nrand = 20;
% subindx = [];
% computethr = true;
% for k = 1:numel(sname)
%   subj.name = sname{k};
%   qsubfeval('vsm_execute_pipeline','vsm_dfi_mscca',{'subj' subj},{'testfeature' testfeature}, {'nrand' nrand}, {'subindx' subindx}, {'computethr', true}, 'memreq',16*1024^3,'timreq',120*60,'batchid',sprintf('%s_%03d',subj.name,subindx));
% end
% 
  
