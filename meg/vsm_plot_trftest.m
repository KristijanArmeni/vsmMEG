function vsm_plot_trftest(trftest)

trial = 1;
time = trftest.weights{1}.time;

figure; title('TRF Test (story 1)');

subplot(2, 3, 1);
plot(time, trftest.weights{trial}.beta(1,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio ~ audio+noise');

subplot(2, 3, 2);
plot(time, trftest.weights{trial}.beta(2,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio ~ audio');

subplot(2, 3, 3);
plot(time, trftest.weights{trial}.beta(3,:,1))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Audio ~ semdist');

subplot(2, 3, 4);
plot(time, trftest.weights{trial}.beta(1,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Semdist ~ audio+noise');

subplot(2, 3, 5);
plot(time, trftest.weights{trial}.beta(2,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Semdist ~ audio');

subplot(2, 3, 6);
plot(time, trftest.weights{trial}.beta(3,:,2))
ylabel('beta weight (a.u.)');
xlabel('lag predictor vs. response (sec)')
title('Semdist ~ semdist')

end

