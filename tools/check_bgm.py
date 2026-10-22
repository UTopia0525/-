#!/usr/bin/env python3
"""Decode the delivered OGGs and check duration, clipping and loop boundaries."""
from pathlib import Path
import json
import subprocess
import numpy as np

ROOT=Path(__file__).resolve().parents[1]/'godot'/'assets'/'music'
manifest=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
assert len(manifest)==5
assert len({item['id'] for item in manifest})==5
for item in manifest:
    path=ROOT/item['file']
    info=json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries',
                    'format=duration:stream=sample_rate,channels','-of','json',str(path)]))
    raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-acodec','pcm_f32le','-'])
    audio=np.frombuffer(raw,dtype='<f4').reshape(-1,2)
    assert abs(float(info['format']['duration'])-60)<.001
    assert len(audio)==2646000
    assert info['streams'][0]['channels']==2 and info['streams'][0]['sample_rate']=='44100'
    assert np.isfinite(audio).all()
    peak=float(np.abs(audio).max())
    rms=float(np.sqrt(np.mean(audio*audio)))
    edge=float(np.abs(audio[0]-audio[-1]).max())
    assert .03<rms<.2 and peak<.95, (path.name,peak,rms)
    assert edge<.025, (path.name,edge)
    print(f'PASS {path.name}: 60.000s, stereo44100, peak={peak:.3f}, RMS={rms:.3f}, edge={edge:.5f}')
