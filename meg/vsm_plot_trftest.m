function vsm_plot_trftest(trftest)

trial = 1;

if iscell(trftest.weights) % select first trial
    trftest.weights = trftest.weights{trial};
else

time = trftest.weights.time;
    
figure; title('TRF Test (story 1)');

subplot(5, 2, 1);
plot(time, trftest.weights.beta(1,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio+noise ~ audio');

subplot(5, 2, 3);
plot(time, trftest.weights.beta(2,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio ~ audio');

subplot(5, 2, 5);
plot(time, trftest.weights.beta(3,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Semdist ~ audio');

subplot(5, 2, 7);
plot(time, trftest.weights.beta(3,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('semdistS ~ audio');

subplot(5, 2, 9);
plot(time, trftest.weights.beta(3,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio + semdist ~ audio');

subplot(5, 2, 2);
plot(time, trftest.weights.beta(1,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio+noise ~ semdist');

subplot(5, 2, 4);
plot(time, trftest.weights.beta(2,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio ~ semdist');

subplot(5, 2, 6);
plot(time, trftest.weights.beta(3,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Semdist ~ semdist')

subplot(5, 2, 8);
plot(time, trftest.weights.beta(4,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('SemdistS ~ semdist')

subplot(5, 2, 10);
plot(time, trftest.weights.beta(5,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio + semdist ~ semdist')

end

