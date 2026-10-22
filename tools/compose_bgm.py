#!/usr/bin/env python3
"""Compose five original pentatonic, seamlessly looping game cues.

No external recordings, soundfonts, pretrained audio model or copyrighted melodies.
Requires numpy, scipy and ffmpeg to regenerate; Godot needs only the resulting OGGs.
All note tails and stereo reverb wrap around the 60-second musical period.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import struct
import subprocess
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
SECONDS = 60
N = SR * SECONDS
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot" / "assets" / "music"
MAJOR = (0, 2, 4, 7, 9)
MINOR = (0, 3, 5, 7, 10)

# Eight-bar motifs, in scale degrees and quarter-note lengths. None are quoted tunes.
THEMES = {
    "title": [
        [(0, 1), (2, .5), (3, .5), (4, 1), (3, 1)],
        [(2, 1.5), (1, .5), (0, 2)],
        [(3, 1), (4, .5), (5, .5), (4, 1), (2, 1)],
        [(1, 1), (2, 1), (0, 2)],
        [(5, 1.5), (4, .5), (3, 1), (2, 1)],
        [(1, .5), (2, .5), (3, 1), (1, 2)],
        [(0, 1), (2, .5), (3, .5), (4, 1), (1, 1)],
        [(2, 1), (1, 1), (0, 2)],
    ],
    "dock": [
        [(0, .5), (1, .5), (2, 1), (3, .5), (2, .5), (1, 1)],
        [(2, .5), (3, .5), (4, 1), (3, 1), (2, 1)],
        [(1, .5), (2, .5), (3, .5), (4, .5), (5, 1), (3, 1)],
        [(2, 1), (1, 1), (0, 2)],
        [(3, .5), (4, .5), (5, 1), (4, .5), (3, .5), (2, 1)],
        [(4, 1), (3, .5), (2, .5), (1, 2)],
        [(2, .5), (1, .5), (0, 1), (1, .5), (2, .5), (3, 1)],
        [(1, 1), (2, 1), (0, 2)],
    ],
    "voyage": [
        [(0, 1.5), (3, .5), (4, 2)],
        [(5, 1), (4, 1), (3, 2)],
        [(2, 1), (3, 1), (1, 1.5), (0, .5)],
        [(0, 3), (None, 1)],
        [(3, 1), (4, 1), (5, 1), (7, 1)],
        [(5, 1.5), (4, .5), (3, 2)],
        [(2, 1), (1, 1), (2, 1), (3, 1)],
        [(1, 1), (0, 3)],
    ],
    "ambush": [
        [(0, 1.5), (None, .5), (1, 1), (0, 1)],
        [(3, 1), (2, 1), (1, 2)],
        [(0, 1), (4, 1), (3, 1.5), (2, .5)],
        [(1, 2), (None, 1), (0, 1)],
        [(5, 1.5), (4, .5), (3, 1), (1, 1)],
        [(2, 1), (1, 1), (0, 2)],
        [(3, .5), (2, .5), (1, 1), (0, 1), (None, 1)],
        [(1, 1), (0, 2), (None, 1)],
    ],
    "battle": [
        [(0, .5), (0, .5), (2, .5), (3, .5), (4, 1), (3, 1)],
        [(2, .5), (1, .5), (0, 1), (3, .5), (2, .5), (1, 1)],
        [(3, .5), (4, .5), (5, 1), (4, .5), (3, .5), (2, 1)],
        [(1, .5), (2, .5), (3, 1), (1, 1), (0, 1)],
        [(5, .5), (5, .5), (4, .5), (3, .5), (5, 1), (7, 1)],
        [(5, 1), (4, .5), (3, .5), (2, 1), (1, 1)],
        [(0, .5), (2, .5), (3, .5), (4, .5), (3, 1), (1, 1)],
        [(2, .5), (1, .5), (0, 1), (0, 1), (None, 1)],
    ],
}

TRACKS = [
    dict(id="title", file="01_dawn_of_jianghu.ogg", title="강호의 여명", context="타이틀·회상", bpm=64, bars=16, root=62, minor=False, lead="xiao", density=.5, seed=11),
    dict(id="dock", file="02_morning_at_the_dock.ogg", title="나루의 아침", context="마을·나루터 탐험", bpm=96, bars=24, root=67, minor=False, lead="pipa", density=1, seed=23),
    dict(id="voyage", file="03_escort_on_the_water.ogg", title="물결 위의 표행", context="항해·갑판 탐험", bpm=80, bars=20, root=62, minor=False, lead="xiao", density=1, seed=37),
    dict(id="ambush", file="04_shadows_in_the_reeds.ogg", title="갈대 속의 그림자", context="습격 전 긴장", bpm=96, bars=24, root=62, minor=True, lead="erhu", density=.5, seed=41),
    dict(id="battle", file="05_blades_of_the_black_scale.ogg", title="흑린의 칼끝", context="일반 전투", bpm=128, bars=32, root=62, minor=True, lead="pipa", density=2, seed=59),
]


def degree(root: int, scale: tuple[int, ...], index: int) -> int:
    return root + scale[index % 5] + 12 * (index // 5)


def score(config: dict) -> list[dict]:
    notes = []
    rng = np.random.default_rng(config["seed"])
    scale = MINOR if config["minor"] else MAJOR
    root = config["root"]
    progression = (0, -2, -1, -3) if config["minor"] else (0, -2, -1, -3)
    # Degrees refer to pentatonic chord roots; accompaniment stays inside the mode.
    for bar in range(config["bars"]):
        block = bar // 4
        section = block % 4
        chord = progression[(bar // 2) % 4]
        beat = bar * 4.0
        phrase = THEMES[config["id"]][bar % 8]
        cursor = .12 if config["id"] in ("title", "voyage") else 0.0
        for index, duration in phrase:
            if index is not None:
                octave = 0
                if config["id"] == "battle" and section == 2:
                    octave = 12
                # Breath at phrase ends and alternating arrangements create space.
                if not (config["id"] == "title" and bar in (3, 11)):
                    notes.append(dict(beat=beat+cursor, duration=duration*.88,
                                      note=degree(root, scale, index)+octave,
                                      instrument=config["lead"], gain=.24 if config["id"] != "battle" else .20,
                                      pan=.08, role="melody"))
            cursor += duration

        density = config["density"]
        if config["id"] == "ambush":
            pattern = [0, 3, 0, 2]
            times = [0, 1.5, 2, 3.5]
        else:
            pattern = [0, 2, 3, 4, 3, 2, 4, 2]
            times = list(np.arange(0, 4, 1/density))
        for i, offset in enumerate(times):
            index = chord + pattern[i % len(pattern)]
            notes.append(dict(beat=beat+offset, duration=.55 if density >= 1 else .85,
                              note=degree(root-12, scale, index), instrument="guzheng",
                              gain=.13 * (.9+rng.random()*.16), pan=-.30, role="arpeggio"))
        notes.append(dict(beat=beat, duration=3.65, note=degree(root-24, scale, chord),
                          instrument="sheng", gain=.11 if config["id"] != "ambush" else .075,
                          pan=.03, role="drone"))
        if bar % 2 == 0:
            notes.append(dict(beat=beat+.04, duration=5.8,
                              note=degree(root-12, scale, chord+3), instrument="sheng",
                              gain=.04, pan=.40, role="drone"))

        if config["id"] == "title":
            if bar % 4 == 0:
                notes.append(dict(beat=beat, duration=2, note=74, instrument="bell", gain=.045, pan=.35, role="percussion"))
        elif config["id"] == "dock":
            for offset in (1, 3):
                notes.append(dict(beat=beat+offset, duration=.18, note=77, instrument="wood", gain=.055, pan=.25, role="percussion"))
        elif config["id"] == "voyage":
            if bar % 2 == 0:
                notes.append(dict(beat=beat+2, duration=.8, note=48, instrument="drum", gain=.08, pan=-.1, role="percussion"))
        elif config["id"] == "ambush":
            notes.append(dict(beat=beat, duration=1, note=42, instrument="drum", gain=.105, pan=-.1, role="percussion"))
            for offset in (1.5, 3.5):
                notes.append(dict(beat=beat+offset, duration=.18, note=71, instrument="wood", gain=.045, pan=.35, role="percussion"))
        elif config["id"] == "battle":
            for offset, gain in [(0, .23), (1.5, .13), (2, .18), (3.5, .12)]:
                notes.append(dict(beat=beat+offset, duration=.85, note=44, instrument="drum", gain=gain, pan=-.15, role="percussion"))
            for offset in (.5, 1, 2.5, 3):
                notes.append(dict(beat=beat+offset, duration=.16, note=79, instrument="wood", gain=.07, pan=.30, role="percussion"))
            if bar % 4 == 0:
                notes.append(dict(beat=beat, duration=3, note=57, instrument="gong", gain=.08, pan=.15, role="percussion"))
            if section in (1, 3):
                for offset, index in [(0, 0), (2, 3)]:
                    notes.append(dict(beat=beat+offset, duration=1.6, note=degree(root-12, scale, chord+index),
                                      instrument="erhu", gain=.085, pan=.28, role="countermelody"))
    return sorted(notes, key=lambda item: item["beat"])


def envelope(t: np.ndarray, duration: float, attack: float, release: float) -> np.ndarray:
    return np.minimum(t/max(attack, .001), 1) * np.clip((duration-t)/max(release, .001), 0, 1)


def synth(instrument: str, note: int, duration: float, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frequency = 440 * 2 ** ((note-69)/12)
    if instrument in ("guzheng", "pipa"):
        total = max(1.4, min(5, duration+2.6))
    elif instrument in ("bell", "gong"):
        total = max(3.0, duration+1)
    else:
        total = max(.12, duration)
    t = np.arange(round(total*SR), dtype=np.float64)/SR
    result = np.zeros(t.size, dtype=np.float64)
    if instrument in ("guzheng", "pipa"):
        decay = 1.2 if instrument == "guzheng" else .65
        for k in range(1, 17):
            f = frequency*k*math.sqrt(1+0.000055*k*k)
            if f > SR*.45:
                break
            amplitude = np.sin(np.pi*k*.19)/(k**1.25)
            tau = decay/(1+.13*(k-1))
            result += amplitude*np.sin(2*np.pi*f*t)*np.exp(-t/tau)
        result += .014*rng.standard_normal(t.size)*np.exp(-t/0.014)
        result *= envelope(t,total,.004,.08)
    elif instrument == "xiao":
        phase = 2*np.pi*frequency*t + .038*np.sin(2*np.pi*4.8*t)*np.minimum(t/.4,1)
        result = .72*np.sin(phase)+.14*np.sin(2*phase)+.035*np.sin(3*phase)
        breath = signal.sosfilt(signal.butter(2,[800,4500],btype="bandpass",fs=SR,output="sos"),rng.standard_normal(t.size))
        result += breath*.035
        result *= envelope(t,total,.08,min(.22,total*.22))*(.93+.07*np.sin(2*np.pi*2.3*t))
    elif instrument == "erhu":
        phase = 2*np.pi*frequency*t + .06*np.sin(2*np.pi*5.2*t)*np.minimum(t/.25,1)
        for k in range(1,13):
            result += np.sin(k*phase)*(.65/(k**1.35))
        result *= envelope(t,total,.12,min(.24,total*.25))
    elif instrument == "sheng":
        for detune in (-.0014,.0016):
            phase = 2*np.pi*frequency*(1+detune)*t
            result += .25*np.sin(phase)+.06*np.sin(2*phase)+.025*np.sin(3*phase)
        result *= envelope(t,total,.22,min(.45,total*.2))
    elif instrument == "drum":
        base = max(48,min(90,frequency))
        phase = 2*np.pi*(base*t + 65*.035*(1-np.exp(-t/.035)))
        result = .8*np.sin(phase)*np.exp(-t/.17)+.19*np.sin(1.52*phase)*np.exp(-t/.08)
        noise = signal.sosfilt(signal.butter(2,3500,fs=SR,output="sos"),rng.standard_normal(t.size))
        result += noise*.06*np.exp(-t/.018)
        result *= envelope(t,total,.002,.03)
    elif instrument == "wood":
        result = (np.sin(2*np.pi*frequency*t)+.5*np.sin(2*np.pi*frequency*1.63*t))*np.exp(-t/.025)
        result *= envelope(t,total,.001,.03)
    elif instrument in ("bell","gong"):
        ratios = (1, 2.01, 3.97, 5.4) if instrument == "bell" else (1, 1.48, 2.13, 2.67, 3.92)
        for k, ratio in enumerate(ratios):
            result += np.sin(2*np.pi*frequency*ratio*t)/(1+k)*np.exp(-t/(1.3/(1+k*.3)))
        result *= envelope(t,total,.012,.1)
    return result.astype(np.float32)


def add_wrapped(mix: np.ndarray, audio: np.ndarray, start: int, gain: float, pan: float) -> None:
    angle = (pan+1)*math.pi/4
    weights = np.array([math.cos(angle),math.sin(angle)],dtype=np.float32)*gain
    offset = start % N
    split = min(len(audio),N-offset)
    mix[offset:offset+split] += audio[:split,None]*weights
    if split < len(audio):
        mix[:len(audio)-split] += audio[split:,None]*weights


def render(config: dict, notes: list[dict]) -> np.ndarray:
    mix = np.zeros((N,2),dtype=np.float32)
    seconds_per_beat = 60/config["bpm"]
    cache: dict[tuple, np.ndarray] = {}
    for item in notes:
        key = (item["instrument"],item["note"],round(item["duration"]*seconds_per_beat,4))
        if key not in cache:
            cache[key] = synth(*key,seed=config["seed"]+item["note"]*13+len(key[0]))
        add_wrapped(mix,cache[key],round(item["beat"]*seconds_per_beat*SR),item["gain"],item["pan"])
    del cache
    # Circular early reflections: reverberant tails continue into the next loop.
    dry = mix.copy()
    for delay, gain in [(.073,.08),(.137,.06),(.229,.045),(.347,.035),(.487,.025)]:
        mix += np.roll(dry,round(delay*SR),axis=0)[:,::-1]*gain
    # Gentle periodic high-pass filter, without cold-start transients at sample zero.
    sos = signal.butter(2,35,btype="highpass",fs=SR,output="sos")
    warm = np.concatenate([mix[-SR:],mix],axis=0)
    mix = signal.sosfilt(sos,warm,axis=0)[SR:].astype(np.float32)
    rms = float(np.sqrt(np.mean(mix**2)))
    target_rms = .095 if config["id"] != "battle" else .12
    gain = min(target_rms/max(rms,1e-8),.80/max(float(np.max(np.abs(mix))),1e-8))
    return mix*gain


def varlen(value: int) -> bytes:
    data = [value & 127]
    value >>= 7
    while value:
        data.insert(0,(value & 127)|128)
        value >>= 7
    return bytes(data)


def write_midi(path: Path, config: dict, notes: list[dict]) -> None:
    programs = {"guzheng":107,"pipa":24,"xiao":75,"erhu":110,"sheng":20,"drum":116,"wood":115,"gong":14,"bell":14}
    instruments = list(programs)
    events = []
    tempo = round(60_000_000/config["bpm"])
    events.append((0,b'\xff\x51\x03'+tempo.to_bytes(3,"big")))
    events.append((0,b'\xff\x58\x04\x04\x02\x18\x08'))
    for channel, instrument in enumerate(instruments):
        events.append((0,bytes([0xC0+channel,programs[instrument]])))
    for item in notes:
        channel = instruments.index(item["instrument"])
        start = round(item["beat"]*480)
        end = min(config["bars"]*4*480,round((item["beat"]+item["duration"])*480))
        velocity = max(1,min(110,round(item["gain"]*300)))
        events.append((start,bytes([0x90+channel,item["note"],velocity])))
        events.append((end,bytes([0x80+channel,item["note"],0])))
    events.sort(key=lambda x:x[0])
    track = bytearray()
    previous = 0
    for tick,message in events:
        track.extend(varlen(tick-previous)+message)
        previous=tick
    track.extend(varlen(max(0,config["bars"]*4*480-previous))+b'\xff\x2f\x00')
    path.write_bytes(b'MThd'+struct.pack('>IHHH',6,0,1,480)+b'MTrk'+struct.pack('>I',len(track))+track)


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument('--track',choices=[x['id'] for x in TRACKS])
    args=parser.parse_args()
    OUT.mkdir(parents=True,exist_ok=True)
    sources=OUT/'source'
    sources.mkdir(exist_ok=True)
    manifest=[]
    for config in TRACKS:
        assert config['bars']*4*60/config['bpm']==SECONDS
        manifest.append({**config,'seconds':SECONDS,'sample_rate':SR,'channels':2,'loop':True,'instruments':'synthetic guzheng/pipa/xiao/erhu/sheng and percussion'})
        if args.track and config['id']!=args.track:
            continue
        notes=score(config)
        music=render(config,notes)
        with tempfile.TemporaryDirectory(prefix='murim-bgm-') as temporary:
            wav=Path(temporary)/'master.wav'
            wavfile.write(wav,SR,np.round(np.clip(music,-1,1)*32767).astype(np.int16))
            subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',
                            '-metadata',f'title={config["title"]}','-metadata','artist=Murim RPG original synthesized score',
                            '-metadata','LOOPSTART=0','-metadata',f'LOOPEND={N}',str(OUT/config['file'])],check=True)
        (sources/(Path(config['file']).stem+'.json')).write_text(json.dumps({'track':config,'notes':notes},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        write_midi(sources/(Path(config['file']).stem+'.mid'),config,notes)
        print(f'{config["id"]}: {len(notes)} events; 60.000s; peak={np.max(np.abs(music)):.3f}; RMS={np.sqrt(np.mean(music**2)):.3f}',flush=True)
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


if __name__=='__main__':
    main()
