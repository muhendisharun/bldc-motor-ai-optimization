clear; clc; close all;

load('surrogate_net_onehot.mat','net');  

function inp = kodla(x)
    ps = round(x(1)); mg = round(x(2)); st = round(x(3));
    thk = x(4); emb = x(5);
    PS = zeros(1,5); 
    switch ps
        case 1, PS(5)=1;  
        case 2, PS(1)=1;   
        case 3, PS(4)=1;   
        case 4, PS(3)=1;   
        case 5, PS(2)=1;  
    end
    MG = zeros(1,3);   
    switch mg
        case 1, MG(2)=1; 
        case 2, MG(1)=1; 
        case 3, MG(3)=1; 
    end
    ST = zeros(1,3);
    ST(st)=1;
    inp = [PS, MG, ST, thk, emb]';   
end


function f = amac(x, net)
    inp = kodla(x);
    y = net(inp);            
    y(1) = max(y(1), 0);            
    y(2) = max(y(2), 0);            
    y(3) = min(max(y(3),0), 100);   
    y(4) = max(y(4), 0);           
    f = [ -y(1);             
           y(2);          
          -y(3);            
          -y(4) ];          
    f = f';
end


lb = [  1    1    1    3.2    0.52];
ub = [  5    3    3    8.8    0.88];
intcon = [1 2 3];  

opts = optimoptions('gamultiobj', ...
    'PopulationSize', 200, ...
    'MaxGenerations', 300, ...
    'ParetoFraction', 0.5, ...
    'Display', 'iter', ...
    'PlotFcn', {@gaplotpareto});


fun = @(x) amac(x, net);
[Xopt, Fopt] = gamultiobj(fun, 5, [],[],[],[], lb, ub, [], intcon, opts);

%%
res = array2table([round(Xopt(:,1:3)), Xopt(:,4:5), ...
                   -Fopt(:,1), Fopt(:,2), -Fopt(:,3), -Fopt(:,4)], ...
    'VariableNames', {'PoleSlot','Magnet','SlotType','MagThk','Embrace', ...
                      'AirgapFlux','Cogging','Efficiency','Torque'});

fprintf('\n=== PARETO OPTIMUM TASARIMLAR (%d adet) ===\n', height(res));
disp(res);
writetable(res, 'pareto_sonuclar.csv');
fprintf('Kaydedildi: pareto_sonuclar.csv\n');

%% 
figure('Name','Pareto ikili gorunumler');
subplot(1,3,1); scatter(res.Torque,res.Cogging,25,'filled');
  xlabel('Torque^'); ylabel('Cogging v'); title('Tork vs Cogging'); grid on;
subplot(1,3,2); scatter(res.Efficiency,res.Cogging,25,'filled');
  xlabel('Efficiency^'); ylabel('Cogging v'); title('Verim vs Cogging'); grid on;
subplot(1,3,3); scatter(res.Torque,res.Efficiency,25,'filled');
  xlabel('Torque^'); ylabel('Efficiency^'); title('Tork vs Verim'); grid on;