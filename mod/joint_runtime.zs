// Joint_move / fp_lerp: original integer state, independent of mesh rendering.
// Host Euler rendering cannot represent the small nonorthogonal Q12 matrix
// residual; measured error is recorded in docs/UI_FIDELITY.md.
class REJointVisual : Object play
{
 int angles[45];int root[3];int local[135];int world[135];int translation[45];bool resolved[15];
 Actor parts[15];bool initialized;int lastWeapon;
 static int ShortValue(int v){return ((v+32768)&65535)-32768;}
 static int Q14(int a,int b){return a*b/16384;}
 void Advance(int frame,int blend,int step)
 {
  if(!initialized)
  {
   for(int i=0;i<45;i++)angles[i]=REJointData.Angles[frame*45+i];
   for(int i=0;i<3;i++)root[i]=REJointData.Roots[frame*3+i];initialized=true;return;
  }
  root[0]=REJointData.Roots[frame*3];root[2]=REJointData.Roots[frame*3+2];
  if(blend==0)
  {
   root[1]=REJointData.Roots[frame*3+1];for(int i=0;i<45;i++)angles[i]=REJointData.Angles[frame*45+i];return;
  }
  int inverse=4096/step-blend,wc=blend*step,wt=inverse*step;
  root[1]=REJointData.Roots[frame*3+1]*wt/4096+root[1]*wc/4096;
  for(int i=0;i<45;i++)
  {
   int target=REJointData.Angles[frame*45+i],current=angles[i];
   if(inverse==1)
   {
    int diff=(target-current+2048)&65535;
    if(diff>4096)current=ShortValue(current+((diff&32768)==0?4096:-4096));
   }
   angles[i]=ShortValue(target*wt/4096+current*wc/4096);
  }
 }
 void Rotation(int joint)
 {
  int a=joint*3,o=joint*9,x=(-angles[a])&4095,y=angles[a+1]&4095,z=(-angles[a+2])&4095;
  int sx=REJointData.Sin[x],sy=REJointData.Sin[y],sz=REJointData.Sin[z];
  int cx=REJointData.Cos[x],cy=REJointData.Cos[y],cz=REJointData.Cos[z];
  local[o]=Q14(cz,cy)/4;local[o+1]=-Q14(cy,sz)/4;local[o+2]=sy/4;
  local[o+3]=(Q14(Q14(sx,sy),cz)+Q14(cx,sz))/4;
  local[o+4]=(Q14(cx,cz)-Q14(Q14(sx,sz),sy))/4;local[o+5]=-Q14(sx,cy)/4;
  local[o+6]=(Q14(sx,sz)-Q14(Q14(cx,sy),cz))/4;
  local[o+7]=(Q14(Q14(sz,sy),cx)+Q14(sx,cz))/4;local[o+8]=Q14(cx,cy)/4;
 }
 void Resolve(int joint)
 {
  if(resolved[joint])return;resolved[joint]=true;Rotation(joint);
  int parent=REJointData.Parents[joint],o=joint*9,t=joint*3;
  if(parent<0)
  {
   for(int i=0;i<9;i++)world[o+i]=local[o+i];for(int i=0;i<3;i++)translation[t+i]=root[i];return;
  }
  Resolve(parent);int p=parent*9,pt=parent*3;
  for(int row=0;row<3;row++)for(int col=0;col<3;col++)
  {
   int sum=0;for(int k=0;k<3;k++)sum+=world[p+row*3+k]*local[o+k*3+col]/4096;
   world[o+row*3+col]=sum;
  }
  int tx=REJointData.Translations[t],ty=REJointData.Translations[t+1],tz=REJointData.Translations[t+2];
  translation[t]=translation[pt]+world[p]*tx/4096-world[p+1]*ty/4096+world[p+2]*tz/4096;
  translation[t+1]=translation[pt+1]-world[p+3]*tx/4096+world[p+4]*ty/4096-world[p+5]*tz/4096;
  translation[t+2]=translation[pt+2]+world[p+6]*tx/4096-world[p+7]*ty/4096+world[p+8]*tz/4096;
 }
 void Hide(){for(int j=0;j<15;j++)if(parts[j])parts[j].bInvisible=true;}
 void Draw(JillPlayer player)
 {
  Vector3 origin=player.deathStage==3?(16000,16000,20000):player.Pos;
  double c=cos(player.Angle),s=sin(player.Angle),scale=56.0/1800;
  for(int j=0;j<15;j++)resolved[j]=false;
  for(int j=0;j<15;j++)
  {
   if(j==14&&lastWeapon!=player.visibleWeapon&&parts[j]){parts[j].Destroy();parts[j]=null;}
   if(!parts[j])parts[j]=Actor.Spawn(String.Format("REJointPart%d",j==14?(player.visibleWeapon==3?16:player.visibleArmed?15:14):j),player.Pos);
   Resolve(j);int o=j*9,t=j*3;
   // C*D*R*D*C^-1, followed by the owner's yaw. Host ZYX convention is
   // verified against r_data/models.cpp, including CorrectPixelStretch.
   // Q12 hierarchy is slightly nonorthogonal. Gram-Schmidt keeps its first
   // axis and avoids independently decomposing noisy axes near pitch 90.
   Vector3 ex=(world[o],-world[o+6],world[o+3]);ex/=ex.Length();
   Vector3 ey=(-world[o+2],world[o+8],-world[o+5]);
   ey-=ex*(ex.X*ey.X+ex.Y*ey.Y+ex.Z*ey.Z);ey/=ey.Length();
   double ezZ=ex.X*ey.Y-ex.Y*ey.X;
   double u0=c*ex.X-s*ex.Y,v0=s*ex.X+c*ex.Y;
   parts[j].Angle=atan2(v0,u0);parts[j].Pitch=atan2(-ex.Z,sqrt(u0*u0+v0*v0));parts[j].Roll=atan2(ey.Z,ezZ);
   double tx=translation[t]*scale,ty=-translation[t+2]*scale,tz=-translation[t+1]*scale/Level.info.pixelstretch;
   parts[j].SetOrigin(origin+(c*tx-s*ty,s*tx+c*ty,tz),true);parts[j].bInvisible=false;
  }
  lastWeapon=player.visibleWeapon;
 }
}
