#!/usr/bin/env python3
"""Read PNG alpha bounds and write Godot atlas/pivot metadata. PNGs stay intact."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "godot" / "assets"

def bands(indices, gap):
    result = []
    for item in indices:
        if not result or item-result[-1][-1] > gap:
            result.append([int(item)])
        else:
            result[-1].append(int(item))
    return result

def frame_info(alpha, x0, y0, x1, y1):
    crop = alpha[y0:y1, x0:x1]
    ys, xs = np.where(crop > 128)
    left, right = int(xs.min())+x0, int(xs.max())+x0+1
    top, bottom = int(ys.min())+y0, int(ys.max())+y0+1
    height = bottom-top
    head = alpha[top+int(height*.14):top+int(height*.34), left:right].astype(float)
    center = left+float((head*np.arange(head.shape[1])).sum()/max(head.sum(), 1))
    bounds = [max(x0,left-3),max(y0,top-3),min(x1,right+3),min(y1,bottom+3)]
    return dict(region=[bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]],
                pivot=[round(center-bounds[0],3),bottom-bounds[1]],height=height)

def register(name):
    source = np.asarray(Image.open(ASSETS/"animation"/(name+".png")).convert("RGBA"))[:,:,3]
    rows = bands(np.where((source > 128).sum(axis=1) > 5)[0],1)
    assert len(rows)==4, f"Expected four direction rows in {name}"
    path=ASSETS/"animation"/(name+"_frames.json")
    previous=json.loads(path.read_text(encoding="utf-8"))
    result = dict(target_height=previous["target_height"],fps=previous["fps"],directions={})
    for row,direction in enumerate(("down","left","right","up")):
        top,bottom=rows[row][0],rows[row][-1]+1
        columns=bands(np.where((source[top:bottom]>128).sum(axis=0)>3)[0],8)
        assert len(columns)==4, f"Expected four phases for {name}/{direction}"
        frames=[frame_info(source,c[0],top,c[-1]+1,bottom) for c in columns]
        # The runtime uses walk[0] for idle, with the same body/head proportions.
        result['directions'][direction]=dict(walk=frames,idle=frames[0].copy(),reference_height=max(f['height'] for f in frames))
    path.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(f'{name}: registered16 walking frames; source PNG and target height/FPS preserved.')

def main():
    import argparse
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sheet",choices=["hero_walk","hero_walk_unarmed"])
    args=parser.parse_args()
    for name in ([args.sheet] if args.sheet else ["hero_walk","hero_walk_unarmed"]):
        register(name)

if __name__=='__main__':
    main()
