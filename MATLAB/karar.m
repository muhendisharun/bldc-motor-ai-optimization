clear; clc;

T = readtable('pareto_sonuclar.csv');

%
ESIK_COGGING = 0.3; 
ESIK_VERIM   = 80;   

oncesi = height(T);
mask = (T.Cogging >= ESIK_COGGING) & (T.Efficiency >= ESIK_VERIM);
T = T(mask, :);
fprintf('Filtre uygulandi: %d/%d tasarim kaldi (cogging>=%.1f & verim>=%d)\n', ...
        height(T), oncesi, ESIK_COGGING, ESIK_VERIM);

%%
M = [T.AirgapFlux, T.Cogging, T.Efficiency, T.Torque];
benefit = [1 0 1 1];        


w = [ 0.15   0.25    0.35   0.25 ];

%%
norm = M ./ sqrt(sum(M.^2, 1));       
V = norm .* w;                       

Aplus = zeros(1,4); Aminus = zeros(1,4);
for j = 1:4
    if benefit(j)
        Aplus(j)=max(V(:,j)); Aminus(j)=min(V(:,j));
    else
        Aplus(j)=min(V(:,j)); Aminus(j)=max(V(:,j));
    end
end

Dplus  = sqrt(sum((V - Aplus ).^2, 2));
Dminus = sqrt(sum((V - Aminus).^2, 2));
score  = Dminus ./ (Dplus + Dminus);
T.Skor = score;

%%
[~, idx] = sort(score, 'descend');
Ts = T(idx, :);

ps_map  = ["8p/12Q","10p/12Q","4p/12Q","20p/24Q","16p/24Q"];
mag_map = ["NdFe35","Alnico9","SmCo28"];

fprintf('\n=== EN DENGELI 10 TASARIM (gercekci TOPSIS) ===\n');
fprintf('%-9s %-8s %3s %6s %6s | %6s %6s %6s %6s | %6s\n', ...
    'PoleSlot','Magnet','ST','Thk','Emb','Flux','Cogg','Eff','Torq','Skor');
for i = 1:min(10,height(Ts))
    r = Ts(i,:);
    fprintf('%-9s %-8s %3d %6.2f %6.3f | %6.3f %6.2f %6.2f %6.3f | %6.4f\n', ...
        ps_map(round(r.PoleSlot)), mag_map(round(r.Magnet)), round(r.SlotType), ...
        r.MagThk, r.Embrace, r.AirgapFlux, r.Cogging, r.Efficiency, r.Torque, r.Skor);
end

best = Ts(1,:);
fprintf('\n>> SECILEN EN DENGELI TASARIM:\n');
fprintf('   %s | %s | SlotType=%d | MagThk=%.2fmm | Embrace=%.3f\n', ...
    ps_map(round(best.PoleSlot)), mag_map(round(best.Magnet)), ...
    round(best.SlotType), best.MagThk, best.Embrace);
fprintf('   ANN tahmini: flux=%.3f  cogging=%.3f  verim=%.2f  tork=%.3f\n', ...
    best.AirgapFlux, best.Cogging, best.Efficiency, best.Torque);

writetable(Ts, 'topsis_siralama.csv');
fprintf('\nSiralama kaydedildi: topsis_siralama.csv\n');

%%
fprintf('\n=== AGIRLIK DUYARLILIGI (en iyi tasarim degisiyor mu?) ===\n');
senaryolar = {
    'Esit',          [0.25 0.25 0.25 0.25];
    'Verim agirlikli',[0.15 0.25 0.35 0.25];
    'Cogging agirlikli',[0.15 0.40 0.25 0.20];
    'Tork agirlikli', [0.15 0.20 0.25 0.40];
};
for s = 1:size(senaryolar,1)
    ws = senaryolar{s,2};
    Vs = norm .* ws;
    Ap=zeros(1,4); Am=zeros(1,4);
    for j=1:4
        if benefit(j), Ap(j)=max(Vs(:,j)); Am(j)=min(Vs(:,j));
        else, Ap(j)=min(Vs(:,j)); Am(j)=max(Vs(:,j)); end
    end
    Dp=sqrt(sum((Vs-Ap).^2,2)); Dm=sqrt(sum((Vs-Am).^2,2));
    sc=Dm./(Dp+Dm);
    [~,bi]=max(sc);
    rr=T(bi,:);
    fprintf('%-18s -> %s, %s, ST%d, %.2fmm, emb%.3f\n', senaryolar{s,1}, ...
        ps_map(round(rr.PoleSlot)), mag_map(round(rr.Magnet)), ...
        round(rr.SlotType), rr.MagThk, rr.Embrace);
end