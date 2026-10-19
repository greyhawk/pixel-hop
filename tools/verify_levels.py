import json
from collections import deque
maps=json.load(open('maps.json'))
T=16;DT=1/60
RUN=120;ACC_G=900;DEC_G=1200;ACC_A=600;DEC_A=400
G_UP=900;G_DOWN=1300;JUMP=-300;CUT=0.5;MAXF=320
PW,PH=10,14
def check(name,rows,verbose=True):
    assert len(rows)==12 and all(len(r)==40 for r in rows),name
    def tile(c,r):
        if c<0 or c>=40: return '#'   # world bounds
        if r<0 or r>=12: return '.'
        return rows[r][c]
    def solid_hit(x,y):
        for r in range(int(y//T),int((y+PH-0.001)//T)+1):
            for c in range(int(x//T),int((x+PW-0.001)//T)+1):
                if tile(c,r)=='#': return True
        return False
    def hazard(x,y):
        if y>12*T+8: return True
        for r in range(int(y//T),int((y+PH-0.001)//T)+1):
            for c in range(int(x//T),int((x+PW-0.001)//T)+1):
                if tile(c,r)=='^':
                    if x<c*T+14 and x+PW>c*T+2 and y+PH>r*T+8: return True
        return False
    def goal(x,y):
        for r in range(12):
            for c in range(40):
                if rows[r][c]=='F':
                    if x<c*T+12 and x+PW>c*T+4 and y<(r+1)*T and y+PH>(r-2)*T: return True
        return False
    def step(x,y,vx,vy,d,jumpheld,grounded):
        acc=(ACC_G if d else DEC_G) if grounded else (ACC_A if d else DEC_A)
        tgt=d*RUN
        if vx<tgt: vx=min(tgt,vx+acc*DT)
        elif vx>tgt: vx=max(tgt,vx-acc*DT)
        g=G_UP if vy<0 else G_DOWN
        vy=min(MAXF,vy+g*DT)
        nx=x+vx*DT
        if solid_hit(nx,y):
            # snap
            if vx>0: nx=(int((nx+PW)//T))*T-PW
            else: nx=(int(nx//T)+1)*T
            vx=0
        x=nx
        ny=y+vy*DT; g2=False
        if solid_hit(x,ny):
            if vy>0: ny=int((ny+PH)//T)*T-PH; g2=True
            else: ny=(int(ny//T)+1)*T
            vy=0
        elif vy>0:
            # one-way
            for c in range(int(x//T),int((x+PW-0.001)//T)+1):
                r=int((ny+PH)//T)
                if tile(c,r)=='=' and y+PH<=r*T+0.01:
                    ny=r*T-PH; vy=0; g2=True
        y=ny
        return x,y,vx,vy,g2
    def on_ground(x,y):
        for c in range(int(x//T),int((x+PW-0.001)//T)+1):
            t=tile(c,int((y+PH+1)//T))
            if t in '#=' and abs((y+PH)-int((y+PH+1)//T)*T)<0.5: return True
        return False
    # start
    for r in range(12):
        for c in range(40):
            if rows[r][c]=='P': sx,sy=c*T+3,(r+1)*T-PH
    start=(sx,sy,0.0)
    seen=set();q=deque([(start,[])])
    def key(s): return (round(s[0]/2),round(s[1]),round(s[2]/60))
    seen.add(key(start))
    while q:
        (x,y,vx),path=q.popleft()
        for d in (-1,0,1):
            for jh in (None,4,10,60):
                X,Y,VX,VY=x,y,vx,0.0
                if jh is not None: VY=JUMP
                held=jh is not None
                ok=True;landed=False
                for f in range(240):
                    if held and f>=jh and VY<0: VY*=CUT; held=False
                    X,Y,VX,VY,g=step(X,Y,VX,VY,d,held,f==0 and jh is None or (jh is None and on_ground(X,Y)))
                    if hazard(X,Y): ok=False;break
                    if goal(X,Y):
                        if verbose: print(name,'REACHABLE; actions',len(path)+1)
                        return True
                    if jh is None and f>=8 and on_ground(X,Y): landed=True;break
                    if f>2 and g: landed=True;break
                if ok and landed:
                    s=(X,Y,VX); k=key(s)
                    if k not in seen: seen.add(k); q.append((s,path+[(d,jh)]))
    print(name,'NOT reachable; explored',len(seen)); return False
res={k:check(k,v) for k,v in maps.items()}
# sanity: physics derived numbers
h=JUMP**2/(2*G_UP); tu=-JUMP/G_UP; td=(2*h/G_DOWN)**0.5
print('max jump height px',h,'tiles',h/16,'apex t',tu,'air t flat',tu+td,'flat dist px',RUN*(tu+td),'tiles',RUN*(tu+td)/16)
vmin=JUMP*CUT; print('min hop (release at once) px', vmin**2/(2*G_UP))
