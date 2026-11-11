import rawpy,sys,glob,os
from PIL import Image
for f in sorted(glob.glob(sys.argv[1]+'/*.dng')):
    with rawpy.imread(f) as r:
        rgb=r.postprocess(use_camera_wb=True,no_auto_bright=False,output_bps=8)
    print(os.path.basename(f),rgb.shape,r.raw_pattern.tolist() if False else '', rgb.mean(axis=(0,1)).round(1))
    Image.fromarray(rgb).resize((600,400)).save(sys.argv[2]+'/'+os.path.basename(f)+'.png')
