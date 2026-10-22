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
    bounds = [max(0,left-3),max(0,top-3),min(alpha.shape[1],right+3),min(alpha.shape[0],bottom+3)]
    return dict(region=[bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]],
                pivot=[round(center-bounds[0],3),bottom-bounds[1]],height=height)

def main():
    source = np.asarray(Image.open(ASSETS/"animation"/"hero_walk.png"))[:,:,3]
    rows = bands(np.where((source > 128).sum(axis=1) > 5)[0],4)
    assert len(rows)==4, "Expected four direction rows"
    original = np.asarray(Image.open(ASSETS/"characters.png"))[:,:,3]
    result = dict(target_height=82,fps=8,directions={})
    for row,direction in enumerate(("down","left","right","up")):
        top,bottom=rows[row][0],rows[row][-1]+1
        columns=bands(np.where((source[top:bottom]>128).sum(axis=0)>3)[0],8)
        assert len(columns)==4, f"Expected four phases for {direction}"
        frames=[frame_info(source,c[0],top,c[-1]+1,bottom) for c in columns]
        idle=frame_info(original,row*original.shape[1]//4,0,(row+1)*original.shape[1]//4,original.shape[0]//2)
        result['directions'][direction]=dict(walk=frames,idle=idle,reference_height=max(f['height'] for f in frames))
    path=ASSETS/"animation"/"hero_walk_frames.json"
    path.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('Registered 16 walking frames and 4 idle poses; source PNGs left intact.')

if __name__=='__main__':
    main()
