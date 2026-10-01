"""Original layered synthetic cartoon foley; no external recordings."""
from pathlib import Path
import json, wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio/hippo'
RATE = 44100
report = {}

def make(kind, variant, duration):
    rng = np.random.default_rng(7901 + variant * 37 + sum(map(ord, kind)))
    t = np.arange(int(RATE * duration)) / RATE
    n = rng.normal(0, 1, len(t))
    low = np.convolve(n, np.ones(35) / 35, 'same')
    high = n - np.convolve(n, np.ones(9) / 9, 'same')
    pitch = 1 + (variant - 1) * .055
    def tone(freq, decay):
        phase = np.cumsum(np.broadcast_to(freq, t.shape)) * 2 * np.pi / RATE
        return np.sin(phase) * np.exp(-t * decay)
    if kind == 'impact':
        x = .72*tone((48+105*np.exp(-t*28))*pitch,10)
        x += .17*high*np.exp(-t*85) + .34*low*np.exp(-t*20)
        # Delayed rubber resonance, quieter than the initial body impact.
        q = np.maximum(t-.035, 0)
        x += .13*np.sin(2*np.pi*(145*q-48*q*q)+1.1*np.sin(q*47))*np.exp(-q*11)*(t>.035)
    elif kind == 'step':
        x = .65*tone((62+52*np.exp(-t*40))*pitch,23)+.22*low*np.exp(-t*32)
        x += .055*high*np.exp(-t*80)
    elif kind == 'swish':
        env = np.sin(np.pi*t/duration)**1.7
        x = (high*.10+low*.75)*env
        x += .04*tone((280+1100*(t/duration)**2)*pitch,5)*env
    elif kind in ('grunt','hurt','win'):
        base = {'grunt':94,'hurt':133,'win':108}[kind]*pitch
        f = base*(1+.08*np.sin(t*34))*(1-.23*t/duration)
        phase = np.cumsum(f)*2*np.pi/RATE
        # Voiced harmonics plus a breathy resonant layer, deliberately stylized.
        voiced = np.sin(phase)*.45+np.sin(2*phase)*.19+np.sin(3*phase)*.10+np.sin(5*phase)*.035
        env = np.sin(np.pi*t/duration)**.8
        if kind=='win': env *= .4+.6*np.sin(t*19)**2
        x = (voiced+.18*low)*env
    else:  # Short bell-like dizzy accent; no continuous stun alarm.
        x = tone(680*pitch,12)*.35+tone(1021*pitch,16)*.14+tone(1690*pitch,22)*.08
    x -= x.mean()
    edge = min(int(.006*RATE),len(x)//2)
    x[:edge] *= np.linspace(0,1,edge)
    x[-edge:] *= np.linspace(1,0,edge)
    x *= .72/max(float(np.max(np.abs(x))),.001)
    data = np.round(x*32767).astype('<i2')
    name = f'{kind}_{variant}.wav'
    with wave.open(str(OUT/name),'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(RATE)
        wav.writeframes(data.tobytes())
    report[name] = {'seconds':duration,'peak':float(np.max(np.abs(x))),'rms':float(np.sqrt(np.mean(x*x))),'clipped':int(np.sum(np.abs(data)>=32767))}

for kind, count, duration in [('impact',3,.48),('step',3,.16),('swish',2,.19),('grunt',2,.40),('hurt',2,.22),('win',1,.58),('stun',1,.28)]:
    for variant in range(count): make(kind,variant,duration)
(ROOT/'reports/hippo_audio_samples.json').write_text(json.dumps(report,indent=2))
print(f'Generated {len(report)} WAVs; clipped samples: {sum(r["clipped"] for r in report.values())}')
