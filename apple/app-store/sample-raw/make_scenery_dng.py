import numpy as np, tifffile, sys, os
from fractions import Fraction
W,H=3000,2000
out=sys.argv[1]
rng=np.random.default_rng(7)
y,x=np.mgrid[0:H,0:W].astype(np.float32)
u,v=x/W,y/H
def srgb2lin(c): c=np.asarray(c,np.float32); return np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4)

def sunset():
    top=srgb2lin([0.15,0.2,0.55]); bot=srgb2lin([1.0,0.55,0.25])
    img=top*(1-v[...,None])+bot*v[...,None]
    d=np.hypot(x-W*0.6,y-H*0.62)
    img+= (np.exp(-(d/180)**2)*4.0)[...,None]*srgb2lin([1,0.85,0.5])
    ridge=H*0.7+80*np.sin(u*9)+40*np.sin(u*23+1)
    img[y>ridge]=srgb2lin([0.05,0.04,0.06])
    return img
def chart():
    cols=[(115,82,68),(194,150,130),(98,122,157),(87,108,67),(133,128,177),(103,189,170),(214,126,44),(80,91,166),(193,90,99),(94,60,108),(157,188,64),(224,163,46),(56,61,150),(70,148,73),(175,54,60),(231,199,31),(187,86,149),(8,133,161),(243,243,242),(200,200,200),(160,160,160),(122,122,121),(85,85,85),(52,52,52)]
    img=np.full((H,W,3),srgb2lin([0.2,0.2,0.2]),np.float32)
    cw,ch=W//6,H//4
    for i,c in enumerate(cols):
        r,k=divmod(i,6); img[r*ch+30:(r+1)*ch-30,k*cw+30:(k+1)*cw-30]=srgb2lin(np.array(c)/255)
    return img
def rings():
    d=np.hypot(x-W/2,y-H/2)
    g=0.5+0.5*np.cos(d**2/4000.0)
    return np.stack([g,g*0.9,g*0.7],-1)*0.6
def bokeh():
    img=np.zeros((H,W,3),np.float32)+srgb2lin([0.02,0.03,0.06])
    for _ in range(60):
        cx,cy,r=rng.uniform(0,W),rng.uniform(0,H),rng.uniform(40,160)
        c=rng.uniform(0.2,1.0,3)*rng.uniform(0.3,1.2)
        m=np.hypot(x-cx,y-cy)<r
        img[m]+=c*0.5
    return img
def forest():
    sky=srgb2lin([0.55,0.75,0.95]); grass=srgb2lin([0.2,0.45,0.15])
    img=np.where((v>0.6)[...,None],grass,sky).astype(np.float32)
    for i in range(18):
        cx=rng.uniform(0,W); base=H*rng.uniform(0.62,0.9); h=rng.uniform(400,900); w=h*0.35
        m=(y<base)&(y>base-h)&(np.abs(x-cx)<w*(y-(base-h))/h)
        img[m]=srgb2lin([0.05,0.2+0.1*rng.random(),0.08])
    return img
def ocean():
    sky=srgb2lin([0.7,0.8,0.95])*(1-v[...,None]*0.4)
    sea=srgb2lin([0.05,0.25,0.4])*(0.7+0.3*np.sin(x/30+np.sin(y/17)*3))[...,None]
    return np.where((v>0.5)[...,None],sea,sky).astype(np.float32)

scenes=[("sunset",sunset),("color-chart",chart),("zone-plate",rings),("bokeh",bokeh),("forest",forest),("ocean",ocean)]
XYZ2sRGB=[[3.2406,-1.5372,-0.4986],[-0.9689,1.8758,0.0415],[0.0557,-0.2040,1.0570]]
def srat(a): return [t for f in a for t in (int(round(f*10000)),10000)]
for i,(name,fn) in enumerate(scenes,1):
    img=np.clip(fn(),0,None)
    img=img/ max(img.max(),1e-6) if img.max()>1 else img
    img=img+rng.normal(0,0.002,img.shape).astype(np.float32)
    img=np.clip(img,0,1)
    black,white=512,16383
    cfa=np.empty((H,W),np.float32)
    cfa[0::2,0::2]=img[0::2,0::2,0]; cfa[0::2,1::2]=img[0::2,1::2,1]
    cfa[1::2,0::2]=img[1::2,0::2,1]; cfa[1::2,1::2]=img[1::2,1::2,2]
    raw=(black+cfa*(white-black)).astype(np.uint16)
    tags=[(50706,'B',4,(1,4,0,0),False),(50707,'B',4,(1,1,0,0),False),
      (50708,'s',0,'Lumiere Sample Generator',False),
      (33421,'H',2,(2,2),False),(33422,'B',4,(0,1,1,2),False),
      (50710,'B',3,(0,1,2),False),
      (50714,'H',1,black,False),(50717,'H',1,white,False),
      (50721,'q',0,None,False),
      (50778,'H',1,21,False),(50728,'2I',3,(1,1,1,1,1,1),False),
      (306,'s',0,f'2026:11:{i:02d} 12:00:00',False),
      (271,'s',0,'Lumiere',False),(272,'s',0,'Synthetic RAW',False)]
    tags=[t for t in tags if t[0]!=50721]+[(50721,'2i',9,tuple(srat(sum(XYZ2sRGB,[]))),False)]
    fn_=os.path.join(out,f"sample-{i:02d}-{name}.dng")
    tifffile.imwrite(fn_,raw,photometric=32803,software='self-generated test data (CC0)',extratags=tags,subfiletype=0,metadata=None)
    print(fn_,os.path.getsize(fn_))
