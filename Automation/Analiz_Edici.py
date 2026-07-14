
import ansys.aedt.core as pyaedt
import numpy as np
from scipy.stats import qmc
import os, glob, re, csv, time

# ================== AYARLAR ==================
PROJE     = r"C:\Users\harun\Desktop\Taguchi.aedt"
DESIGN    = "RMxprtDesign1"
VERSION   = "2024.1"
CIKTI_CSV = r"C:\Users\harun\Desktop\sonuclar.csv"
N         = 1000          
SEED      = 7

THK_ARALIK = (4.0, 8.5)  
EMB_ARALIK = (0.5, 0.9)  
POLESLOT = [(8, 12), (10, 12), (20, 24), (4, 12), (14, 12), (16, 24)]  
SLOTTYPE   = [1, 2, 3]
MAGNET     = ["NdFe35", "Alnico9", "SmCo28"]

rng = np.random.default_rng(SEED)
u = qmc.LatinHypercube(d=2, seed=SEED).random(N)
X = qmc.scale(u, np.array([THK_ARALIK[0], EMB_ARALIK[0]]),
                 np.array([THK_ARALIK[1], EMB_ARALIK[1]]))
thk = np.round(X[:, 0], 2)
emb = np.round(X[:, 1], 3)

def dengeli(secenekler, n):
    base = (secenekler * (n // len(secenekler) + 1))[:n]
    idx = rng.permutation(n)
    return [base[i] for i in idx]

ps_list   = dengeli(POLESLOT, N)
slot_list = dengeli(SLOTTYPE, N)
mag_list  = dengeli(MAGNET, N)


def res_oku(res_dir):
    files = glob.glob(os.path.join(res_dir, "**", "*.res"), recursive=True)
    if not files:
        return None
    latest = max(files, key=os.path.getmtime)
    with open(latest, "r", errors="ignore") as f:
        txt = f.read()
    def bul(etiket):
        m = re.search(re.escape(etiket) + r"\s*[:：]?\s*([-\d.eE]+)", txt)
        return float(m.group(1)) if m else None
    return {
        "AirgapFlux": bul("Air-Gap Flux Density (Tesla)"),
        "Cogging":    bul("Cogging Torque (N.m)"),
        "Efficiency": bul("Efficiency (%)"),
        "Torque":     bul("Rated Torque (N.m)"),
    }


app = pyaedt.Rmxprt(project=PROJE, design=DESIGN, version=VERSION)
gen = app.odesign.GetChildObject(r"Machine\General")
sta = app.odesign.GetChildObject(r"Machine\Stator")
pol = app.odesign.GetChildObject(r"Machine\Rotor\Pole")


with open(CIKTI_CSV, "w", newline="") as f:
    csv.writer(f).writerow(
        ["Nokta", "Pole", "Slot", "SlotType", "MagThk_mm", "Embrace", "Magnet",
         "AirgapFlux_T", "Cogging_Nm", "Efficiency_%", "Torque_Nm", "Durum"])

t0 = time.time()
ok_say = 0
for i in range(N):
    nokta = i + 1
    pole, slot = ps_list[i]
    stype = slot_list[i]
    magnet = mag_list[i]
    t = float(thk[i]); e = float(emb[i])
    try:
        gen.SetPropValue("Number of Poles", int(pole))
        sta.SetPropValue("Number of Slots", int(slot))
        sta.SetPropValue("Slot Type", ["SlotType:=", str(stype)])
        pol.SetPropValue("Magnet Thickness", f"{t}mm")
        pol.SetPropValue("Embrace", e)
        pol.SetPropValue("Magnet Type", ["Material:=", magnet])

        app.analyze()

        s = res_oku(app.results_directory)
        if s and all(v is not None for v in s.values()):
            satir = [nokta, pole, slot, stype, t, e, magnet,
                     s["AirgapFlux"], s["Cogging"], s["Efficiency"], s["Torque"], "OK"]
            durum = "OK"; ok_say += 1
        else:
            satir = [nokta, pole, slot, stype, t, e, magnet, "", "", "", "", "OKUMA_HATA"]
            durum = "OKUMA_HATA"
    except Exception as ex:
        satir = [nokta, pole, slot, stype, t, e, magnet, "", "", "", "", f"HATA"]
        durum = f"HATA: {ex}"

    with open(CIKTI_CSV, "a", newline="") as f:
        csv.writer(f).writerow(satir)

    if nokta % 10 == 0 or nokta <= 5:
        gecen = time.time() - t0
        print(f"[{nokta:3d}/{N}] {pole}p/{slot}Q {magnet} thk={t} emb={e} -> {durum}  "
              f"({gecen:.0f}s, gecerli={ok_say})")

app.release_desktop(close_projects=False, close_desktop=False)
print(f"\nBitti. {ok_say}/{N} gecerli. Sonuclar: {CIKTI_CSV}")