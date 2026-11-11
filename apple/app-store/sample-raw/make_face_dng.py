import numpy as np, tifffile, sys, os
from PIL import Image
src,out=sys.argv[1],sys.argv[2]
items=[("07-portrait-a","examples_obama.jpg","2026:11:07 10:00:00"),
       ("08-podium-a","examples_obama2.jpg","2026:11:07 11:00:00"),
       ("09-portrait-b","examples_biden.jpg","2026:11:08 10:00:00"),
       ("10-pair-a-b","examples_two_people.jpg","2026:11:08 11:00:00"),
       ("11-blue-room-a","tests_test_images_obama3.jpg","2026:11:08 12:00:00")]
XYZ2sRGB=[3.2406,-1.5372,-0.4986,-0.9689,1.8758,0.0415,0.0557,-0.2040,1.0570]
def srat(a): return tuple(t for f in a for t in (int(round(f*10000)),10000))
for name,f,dt in items:
    im=Image.open(os.path.join(src,f)).convert('RGB')
    w,h=im.size; im=im.resize((w*2,h*2))  # 2x so the sizes look like camera RAWs; even dims for the Bayer mosaic
    a=np.asarray(im,np.float32)/255
    lin=np.where(a<=0.04045,a/12.92,((a+0.055)/1.055)**2.4)
    H,W,_=lin.shape; cfa=np.empty((H,W),np.float32)
    cfa[0::2,0::2]=lin[0::2,0::2,0]; cfa[0::2,1::2]=lin[0::2,1::2,1]
    cfa[1::2,0::2]=lin[1::2,0::2,1]; cfa[1::2,1::2]=lin[1::2,1::2,2]
    black,white=512,16383
    raw=(black+np.clip(cfa,0,1)*(white-black)).astype(np.uint16)
    tags=[(50706,'B',4,(1,4,0,0),False),(50707,'B',4,(1,1,0,0),False),
      (50708,'s',0,'Lumiere Sample Generator',False),
      (33421,'H',2,(2,2),False),(33422,'B',4,(0,1,1,2),False),(50710,'B',3,(0,1,2),False),
      (50714,'H',1,black,False),(50717,'H',1,white,False),
      (50721,'2i',9,srat(XYZ2sRGB),False),(50778,'H',1,21,False),(50728,'2I',3,(1,1,1,1,1,1),False),
      (306,'s',0,dt,False),(271,'s',0,'Lumiere',False),(272,'s',0,'Synthetic RAW',False),
      (33432,'s',0,'Public domain: official White House photograph (US federal government work)',False)]
    p=os.path.join(out,f"sample-{name}.dng")
    tifffile.imwrite(p,raw,photometric=32803,software='converted to DNG for test data',extratags=tags,subfiletype=0,metadata=None)
    print(p,raw.shape,os.path.getsize(p))
