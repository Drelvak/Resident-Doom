// Focused port of original type5 casing interpreter, not native Doom particles.
// RE units and original 24-byte phase records survive until final host projection.
class RECasing : Actor
{
 int h[24];int phase;int gun;int clock33;int age;
 int lastHostTic;
 int rotX;int rotY;int rotZ;int vx;int vy;int vz;int frame;int delay;
 int yaw;bool grounded;bool pendingKill;
 double facing;Vector3 sourceOffset;Vector3 spawnBase;Actor owner;
 Default { Radius 0.124444444; Height 0; +NOGRAVITY +NOINTERACTION +NOBLOCKMAP +THRUACTORS +BRIGHT }
 int SignedWord(int offset){int v=h[offset]|(h[offset+1]<<8);return v>32767?v-65536:v;}
 void LoadPhase(int n)
 {
  phase=n;for(int i=0;i<24;i++)h[i]=RECasingData.Headers[(gun*5+n)*24+i];
  vx=SignedWord(16);vy=SignedWord(18);vz=SignedWord(20);
 }
 static void Emit(JillPlayer p)
 {
  // Effect_CreateBillboard 0x47be30: 64 shared original effect slots.
  int occupied=0;let it=ThinkerIterator.Create("Actor");Actor effect;
  while(effect=Actor(it.Next()))if(effect is "RECasing" || effect is "REPickupGlint")occupied++;
  if(occupied>=64)return;
  let shell=RECasing(Actor.Spawn("RECasing",p.Pos));if(shell)shell.Init(p);
 }
 void Init(JillPlayer p)
 {
  owner=p;gun=p.visibleWeapon==3?1:0;facing=p.Angle;spawnBase=p.Pos;
  yaw=((gun-8)-1)&0x555;
  sourceOffset=gun?(360,-2050,-440):(370,-2570,-220);
  LoadPhase(0);
  // autoaim_fire stores weaponIdx in animHeader[3] (header byte7).
  h[7]=gun;frame=h[4];delay=RECasingData.Frames[frame*4+1];
  int oldPhase=h[7];int branch=random(1,2);LoadPhase(branch);phase=2;h[7]=oldPhase;
  clock33=p.clock33;lastHostTic=Level.time;Place();ShowFrame();if(CVar.FindCVar("re_debug").GetBool())Console.Printf("RECASE spawn weapon=%d frame=%d offset=(%d,%d,%d) branch=%d velocity=(%d,%d,%d)",p.visibleWeapon,p.animframe,int(sourceOffset.X),int(sourceOffset.Y),int(sourceOffset.Z),branch,vx,vy,vz);StepSource();
 }
 void Place()
 {
  // RotMatrixY 0x409aa0 + ApplyMatrixSV 0x409db0; Q14 trig, Q12 matrix.
  double a=(yaw&4095)*0.0015339807880859375*180/3.141592653589793;
  int sr=clamp(int(sin(a)*16384),-16383,16383),cr=clamp(int(cos(a)*16384),-16383,16383);
  int sn=(sr*4096)>>14,cs=(cr*4096)>>14;
  Vector3 rotated=(int((cs*rotX+sn*rotZ)/4096.0),rotY,int((-sn*rotX+cs*rotZ)/4096.0));
  double scale=56.0/1800;Vector3 local=sourceOffset+rotated;
  double x=local.X*scale,y=-local.Z*scale,z=-local.Y*scale/Level.info.pixelstretch;
  if(grounded)z=(owner?owner.Pos.Z:spawnBase.Z)-spawnBase.Z;
  SetOrigin(spawnBase+(cos(facing)*x-sin(facing)*y,sin(facing)*x+cos(facing)*y,z),false);
 }
 void ShowFrame()
 {
  int sprite=RECasingData.Frames[frame*4];
  SetState(FindStateByString(String.Format("Case%d",sprite)));
  Scale=(h[3]*56.0/1800,h[3]*56.0/1800);
 }
 override void Tick()
 {
  Super.Tick();if(lastHostTic==Level.time)return;lastHostTic=Level.time;clock33+=1000;if(clock33<1155)return;clock33-=1155;StepSource();
 }
 void StepSource()
 {
  age++;
  if(pendingKill){if(CVar.FindCVar("re_debug").GetBool())Console.Printf("RECASE cleanup weapon=%d sourceTicks=%d",gun+2,age);Destroy();return;}
  // Behavior8 probes horizontal RDT obstacle bounds, NOT the floor plane.
  // E1M1 has linedefs: native CheckPosition is the corresponding host probe.
  if(h[0]==8&&!CheckPosition(Pos.XY))
  {h[0]=1;h[4]=2;h[6]=1;vx=-vx;ImpactSound();}
  // EffectActor_UpdateAndRender: translate before integrating acceleration.
  Place();
  vx+=SignedWord(8);vy+=SignedWord(10);vz+=SignedWord(12);
  rotX+=vx;rotY+=vy;rotZ+=vz;
  // Behavior10: source uses current player's foot-plane, not a generic bounce.
  double plane=owner?owner.Pos.Z:spawnBase.Z;
  double sourceY=-(Pos.Z-plane)*1800.0/56*Level.info.pixelstretch;
  if(h[1]==10&&sourceY+vy>0)
  {
   int nativeRandom=random(0,h[5]-1);int next=phase+1+nativeRandom;if(next>4){Destroy();return;}
   phase=next;h[1]=RECasingData.Headers[(gun*5+phase)*24+1];
   int offset=(gun*5+phase)*24;
   vx=RECasingData.Headers[offset+16]|(RECasingData.Headers[offset+17]<<8);
   vy=RECasingData.Headers[offset+18]|(RECasingData.Headers[offset+19]<<8);if(vy>32767)vy-=65536;
   vz=RECasingData.Headers[offset+20]|(RECasingData.Headers[offset+21]<<8);if(vz>32767)vz-=65536;
   vz+=nativeRandom*10;yaw+=RECasingData.Headers[offset+22]|(RECasingData.Headers[offset+23]<<8);grounded=true;ImpactSound();if(h[6])vx=-vx;
   rotY=int(-sourceOffset.Y+(spawnBase.Z-plane)*1800/56*Level.info.pixelstretch);
  }
  else if(h[1]==9&&sourceY+vy>0)
  {pendingKill=true;grounded=true;h[1]=0;}
  // Effect_AnimateSprite: byte0 selects UV, byte1 delay; FF jumps in vram table.
  if(delay==0)
  {
   frame++;int offset=frame*4;
   if(RECasingData.Frames[offset]==0&&RECasingData.Frames[offset+1]==0){Destroy();return;}
   if(RECasingData.Frames[offset+1]==255)frame=RECasingData.Frames[offset];
   delay=RECasingData.Frames[frame*4+1];
  }
  delay--;ShowFrame();
  let trace=CVar.GetCVar("re_case_trace");if(trace&&trace.GetBool())Console.Printf("RECASE tick weapon=%d age=%d phase=%d uv=%d yaw=%d position=(%.4f,%.4f,%.4f) velocity=(%d,%d,%d) grounded=%d kill=%d",gun+2,age,phase,RECasingData.Frames[frame*4],yaw,Pos.X,Pos.Y,Pos.Z,vx,vy,vz,grounded,pendingKill);
 }
 void ImpactSound()
 {
  // Play3DSnd bank1 slot10 uses the currently loaded weapon SFX bank.
  let p=JillPlayer(owner);
  if(p&&h[7]-p.visibleWeapon==-2)A_StartSound(p.visibleWeapon==3?"re1/shell-land":"re1/case-land",CHAN_AUTO);
 }
 States {
 Spawn: RCAS A -1 Bright;Stop;
 Case0:RCAS A -1 Bright;Stop;Case1:RCAS B -1 Bright;Stop;
 Case2:RCAS C -1 Bright;Stop;Case3:RCAS D -1 Bright;Stop;
 Case4:RCAS E -1 Bright;Stop;Case5:RCAS F -1 Bright;Stop;
 Case6:RCAS G -1 Bright;Stop;Case7:RCAS H -1 Bright;Stop;
 Case8:RCAS I -1 Bright;Stop;Case9:RCAS J -1 Bright;Stop;
 Case10:RCAS K -1 Bright;Stop;Case11:RCAS L -1 Bright;Stop;
 Case12:RCAS M -1 Bright;Stop;Case13:RCAS N -1 Bright;Stop;
 Case14:RCAS O -1 Bright;Stop;Case15:RCAS P -1 Bright;Stop;
 }
}
