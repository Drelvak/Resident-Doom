// RE1 PC PlayerAnimations.cpp 0x459be0; GameLoop.cpp death countdown;
// DeathScreen.cpp 0x443090/0x443550. Adapter differences: docs/DEATH_FIDELITY.md.
class REDeathPlayer : RESavePlayer
{
 int deathStage;int deathFall;int deathCountdown;int deathFade;int deathFadeType;
 int deathMachine;int deathImage;int deathRect;int deathHold;int deathStepTick;
 int deathTitleOption;int deathRequest;int deathRequestSerial;int deathSoundFade;
 Actor deathCamera;Actor deathBlood;int deathBloodHalfW;int deathBloodHalfH;int deathBloodTimer;
 override void DeathThink(){MovePlayer();} // No native use-to-respawn / killer tracking.
 void DeathStep()
 {
  let p=JillPlayer(self);
  if(deathStage==0)
  {
   deathStage=1;deathCountdown=90;deathFall=1;
   p.statusOpen=false;p.boxOpen=false;p.promptKind=0;p.actionMenu=false;p.menuFadeMode=0;
   p.saveState=0;p.saveRequest=0;p.pendingPickup=null;p.StopItemView();p.UpdateFreeze();
   p.aimLock=false;p.aimTarget=null;p.NewMotion(4);p.RESound("death",CHAN_VOICE);
   Console.Printf("REDEATH fall begin body=4 countdown=90");
  }
  if(deathStage==1)
  {
   if(deathFall==1)
   {
    if(p.animframe==0x19&&p.animTiming<=1)p.RESound("body-thud",CHAN_BODY);
    if(p.JointMove(false,true,0x400))deathFall=2;
    Vector2 slide=AngleToVector(p.Angle-90,15*56.0/1800);p.TryMove(p.Pos.XY+slide,1);
   }
   if(deathFall==2)
   {
    deathBlood=Spawn("REDeathBlood",p.Pos+(0,0,0.25));deathBloodHalfW=400;deathBloodHalfH=600;deathBloodTimer=0xb4;deathFall=3;
   }
   else if(deathFall==3&&deathBloodTimer>0x20){deathBloodHalfW+=16;deathBloodHalfH+=16;deathBloodTimer--;}
   if(deathBlood)
   {
    deathBlood.Angle=p.Angle;
    deathBlood.Scale=(deathBloodHalfW*2*56.0/1800/26,deathBloodHalfH*2*56.0/1800/29);
   }
   p.ApplyPose();
   if(--deathCountdown==0){deathStage=2;deathFade=0;deathFadeType=1;Console.Printf("REDEATH death flash");}
   return;
  }
  if(deathStage==2)
  {
   deathFade+=0x100;
   if(deathFade>=0x8000)
   {
    if(deathBlood){deathBlood.Destroy();deathBlood=null;}
    deathStage=3;deathMachine=1;deathImage=0x3b;deathRect=0;deathFade=0x7fff;deathFadeType=1;
    deathSoundFade=43;p.UpdateFreeze();
    // Separate standalone corpse scene, exactly the source's relative eye/look
    // (5000,-7000,0) / (0,-1000,0), after RE-to-host axis conversion.
    Vector3 origin=(16000,16000,20000),eye=origin+(5000*56.0/1800,0,7000*56.0/1800/Level.info.pixelstretch);
    deathCamera=Spawn("REMenuCamera",eye);Vector3 delta=origin+(0,0,1000*56.0/1800/Level.info.pixelstretch)-eye;
    deathCamera.Angle=atan2(delta.Y,delta.X);deathCamera.Pitch=-atan2(delta.Z,delta.XY.Length());
    TexMan.SetCameraToTexture(deathCamera,"REDEATH",2*atan(160.0/192));TexMan.SetCameraTextureAspectRatio("REDEATH",1,true);
    Console.Printf("REDEATH original died.tim reveal");
   }
   return;
  }
  if(deathStage==3)
  {
   // The decomp alternates machine steps while drawing/fading each frame.
   // Two display steps per existing 33ms source-control tick (60.606Hz).
   DeathDisplayStep();if(deathStage==3)DeathDisplayStep();p.ApplyPose();return;
  }
  if(deathStage==4)
  {
   if(deathFade>0){deathFade=max(0,deathFade-0x400);return;}
   if(deathTitleOption==0)
   {if(p.pressed&0xc080){deathTitleOption=1;p.RESound("type-b");}return;}
   if(p.rawEdge&0x5000){deathTitleOption=deathTitleOption==1?2:1;}
   if(p.pressed&0x4000)
   {
    p.RESound("title");deathRequest=deathTitleOption;deathRequestSerial++;
   }
  }
 }
 void DeathDisplayStep()
 {
  let p=JillPlayer(self);
  if(deathSoundFade>0){deathSoundFade--;SetMusicVolume(Level.MusicVolume*deathSoundFade/43.0);}
  if(deathFade>=0)
  {
   deathFade+=deathFadeType==1?-0x180:0x180;
   if(deathFade>=0x8000)deathFade=-1;
  }
  deathStepTick^=1;
  if(deathStepTick)
  {
   switch(deathMachine)
   {
    case 1:if(deathFade<0)deathMachine=2;break;
    case 2:
     if(deathRect<255)deathRect+=3;
     if(deathRect>0x3f)deathImage--;
     if(deathImage<4){deathMachine=3;deathHold=0;}break;
    case 3:if(++deathHold>0x30)deathMachine=4;break;
    case 4:deathFadeType=2;deathFade=0;deathImage=4;deathMachine=5;break;
    case 5:deathImage++;if(deathFade<0)DeathTitle();break;
   }
  }
  if(deathStage==3)
  {
   p.Angle-=8*360.0/4096;
   if(p.pad&0x4000)DeathTitle();
  }
 }
 void DeathTitle()
 {
  deathStage=4;deathFade=0x7fff;deathTitleOption=0;
  if(deathCamera){deathCamera.Destroy();deathCamera=null;}
  let p=JillPlayer(self);if(p.jointVisual)p.jointVisual.Hide();
  SetMusicVolume(Level.MusicVolume);S_ChangeMusic("",0,false);
  Console.Printf("REDEATH return original title");
 }
}

// Original KAGE.TIM footprint, flat-projected through GZDoom's sprite API.
class REDeathBlood : Actor
{
 Default {+NOBLOCKMAP +NOGRAVITY +NOINTERACTION +FLATSPRITE RenderStyle "Translucent";Alpha 1;}
 States {Spawn:RBLD A -1 Bright;Stop;}
}
// Dormant native integration test: no manual game-state mutation in production.
class REDeathTests : EventHandler
{
 int ticks;int phase;int startTick;
 override void WorldTick()
 {
  if(!CVar.FindCVar("re_death_test").GetBool())return;
  let p=JillPlayer(players[0].mo);if(!p)return;ticks++;
  if(ticks==5)
  {
   p.DamageMobj(null,null,10000,'None',DMG_FORCED);
   Console.Printf("REDEATHTEST native lethal damage state=%d health=%d",p.player.playerstate,p.health);
  }
  if(ticks%35==0)Console.Printf("REDEATHTEST tick=%d stage=%d fade=%d motion=%d fall=%d machine=%d image=%d",ticks,p.deathStage,p.deathFade,p.motion,p.deathFall,p.deathMachine,p.deathImage);
  if(p.deathStage==4&&phase==0)
  {
   phase=1;startTick=ticks;
   Console.Printf("REDEATHTEST PASS death completed title reached nativeRespawnBlocked=%d",p.player.playerstate==PST_DEAD);
  }
 }
}
