clear; clc; close all;

%%
T = readtable('ann_veri_onehot.csv');
M = table2array(T);


Y = M(:, end-3:end);     
X = M(:, 1:end-4);       

fprintf('Veri: %d satir | %d giris | %d cikis\n', size(X,1), size(X,2), size(Y,2));

Xn = X';  Yn = Y';   

%% 
net = feedforwardnet([25 20 10], 'trainlm');
net.divideParam.trainRatio = 0.70;
net.divideParam.valRatio   = 0.15;
net.divideParam.testRatio  = 0.15;
net.trainParam.epochs = 1000;
net.trainParam.max_fail = 25;
net.trainParam.showWindow = true;

%%
[net, tr] = train(net, Xn, Yn);

%%
Yp = net(Xn)';  Yt = Y;
cikislar = {'AirgapFlux','Cogging','Efficiency','Torque'};

fprintf('\n=== TUM VERI ===\n');
for k=1:4
    R2=corr(Yt(:,k),Yp(:,k))^2; rmse=sqrt(mean((Yt(:,k)-Yp(:,k)).^2));
    fprintf('%-12s R2=%.4f RMSE=%.4f\n',cikislar{k},R2,rmse);
end
ti=tr.testInd;
fprintf('\n=== TEST KUMESI (asil onemli) ===\n');
for k=1:4
    yt=Yt(ti,k); yp=Yp(ti,k);
    R2=corr(yt,yp)^2; rmse=sqrt(mean((yt-yp).^2));
    fprintf('%-12s R2=%.4f RMSE=%.4f\n',cikislar{k},R2,rmse);
end

%%
figure('Name','Tahmin vs Gercek (one-hot)');
for k=1:4
    subplot(2,2,k);
    scatter(Yt(:,k),Yp(:,k),12,'filled'); hold on;
    lim=[min(Yt(:,k)) max(Yt(:,k))];
    plot(lim,lim,'r--','LineWidth',1.5);
    xlabel('Gercek (RMxprt)'); ylabel('ANN tahmini');
    title(cikislar{k}); grid on; axis tight;
end

%% 
save('surrogate_net_onehot.mat','net');
fprintf('\nModel kaydedildi: surrogate_net_onehot.mat\n');