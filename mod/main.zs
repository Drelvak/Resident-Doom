// Authoritative sources and exceptions: docs/FIDELITY.md.
class JillPlayer : REDeathPlayer
{
 int ids[8]; int qty[8]; int used; int equipped;int examinedItems;
 REJointVisual jointVisual;
 int behavior; int phase; int motion; int animframe; int clock33; int prevpad; int pad; int pressed;
 int visibleWeapon;int animTiming;int animBank;bool visibleArmed;
 int speedRE; int runStop; int idleTicks; int aimflags; int blend;
 Actor menuCamera;Actor menuBackdrop;REItemView menuItemModel;int viewerItem;int viewerStep;int viewerMode;bool viewerExiting;bool viewerDescription;
 int msgPageStart; int msgStream[256];int msgLength;int msgOffset;int msgState;int msgTimer;int msgBlink;
 bool sourcePrompt;int messageItem;
 int menuFade;int menuFadeMode;bool menuClosing;int cursorBlink;int actionDelay;bool actionClosing;int healSweep;int ecgSweep;int ecgSecondary;int ecgWave;int ecgOldWave;
 int rawPad;int prevRaw;int rawEdge; int reTicks; int shownFrame; bool reversePose; Actor aimTarget; bool aimLock;
 bool statusOpen; int selected; int combineFrom; String message;String contextText;
 // BioCard.h: shared item-box bank, 48 ItemSlot records (0x00be98e4).
 int boxIds[48];int boxQty[48];bool boxOpen;int boxState;int boxSelected;
 int boxSlide;int boxDirection;int boxRepeatTimer;int boxRepeatMask;bool boxContinueScroll;
 bool actionMenu;int actionOption;int promptKind;int choice;int promptA;int promptB;
 REPickup pendingPickup;bool cacheUnlocked;
 Actor cinema; JillPose pose; int camzone;int startupCover;
 Default { Player.DisplayName "Jill Valentine"; Player.SoundClass "re1jill"; Player.StartItem "Pistol"; Health 96; RenderStyle "Normal"; +NOTIMEFREEZE }
 // Hide only the native sprite. Keep a normally rendered, targetable player actor.
 States { Spawn: TNT1 A -1; Stop; See: TNT1 A 1; Loop; Pain: TNT1 A 4; TNT1 A 4 A_Pain; Goto Spawn; Missile: TNT1 A 1; Goto Spawn; Death: TNT1 A -1; Stop; }
 override int DamageMobj(Actor inflictor,Actor source,int damage,Name mod,int flags,double angle)
 {
  // Explicit mashup balance: twice native Doom monster damage; hazards unchanged.
  if(source&&source.bIsMonster)damage*=2;
  return Super.DamageMobj(inflictor,source,damage,mod,flags,angle);
 }
 void RESound(String name,int channel=CHAN_AUTO)
 {
  A_StartSound("re1/"..name,channel,CHANF_FORCE,1.0,ATTN_NONE);
  if(CVar.FindCVar("re_debug_audio").GetBool())Console.Printf("REAUDIO %s playing=%d",name,IsActorPlayingSound(CHAN_AUTO));
 }
 override void PostBeginPlay()
 {
  Super.PostBeginPlay();startupCover=3;
  MaxHealth=96; if(player){player.fixedcolormap=PlayerInfo.NOFIXEDCOLORMAP;player.fixedlightlevel=-1;player.extralight=0;}
  ids[0]=2; qty[0]=15; used=1; equipped=0; combineFrom=-1; camzone=-1;
  message="HANGAR / Find the sword key. Conserve ammunition.";
  visibleArmed=true;pose=JillPose(Spawn("JillPose",Pos));
  SyncWeaponModel();
 }
 // No Doom acceleration, strafe or mouse turn. Native gravity/enemy collision remain.
 override void MovePlayer()
 {
  int raw=rawPad;
  vel.X=0;vel.Y=0;
  // PlayerPad_Update 0x0044e000, config 0 table 0x004bf2a0.
  static const int remap[]={0x1000,0x2000,0x4000,0x8000,0x1000,0x4000,0x80,0x80,8,0x40,8,4,2,1,0x80,0x40};
  pad=0; for(int i=0;i<16;i++)if(raw&remap[i])pad|=1<<i;
  if(pad&1)pad&=~4; if(pad&2)pad&=~8;
  clock33+=1000;
  if(clock33<1155)return; // 35 ticks * 33ms. Drift-free rational scheduler.
  clock33-=1155; pressed=pad&~prevpad; prevpad=pad;
  rawEdge=raw&~prevRaw;prevRaw=raw;reTicks++;
  if(health<=0||deathStage>=3){DeathStep();return;}
  if((statusOpen||boxOpen)&&promptKind==0&&viewerItem==0&&menuFadeMode==0)
  {
   if(rawEdge&0xf000)RESound("cursor");
   if(pressed&0x4000)RESound("decide");
   else if(pressed&0x8000)RESound("cancel");
  }
  if(statusOpen||boxOpen||promptKind>0||menuFadeMode>0)
  {
   MenuVisualStep();
   if(menuFadeMode>0)return;
  }
  if(saveState>0){if(pressed&0x4000)RESound("type-b");else if(pressed&0x8000)RESound("cancel");TypewriterStep();return;}
  if(viewerItem>0){ItemViewStep();return;}
  if(promptKind>0){PromptStep();return;}
  if(boxOpen){BoxStep();return;}
  if(statusOpen)
  {
   if(pressed&0x8000){CancelStatus();return;}
   if(actionMenu)
   {
    if(actionClosing){if(--actionDelay<=0){actionMenu=false;actionClosing=false;}return;}
    if(actionDelay>0){actionDelay--;return;}
    if(pressed&1)actionOption=max(0,actionOption-1);
    if(pressed&4)actionOption=min(2,actionOption+1);
    if(pressed&0x4000)StatusAction();return;
   }
   int cursor=selected*2+8;
   if(rawEdge&0xa000)cursor^=2;
   if(rawEdge&0x1000){if((cursor&252)==0)cursor+=20;else cursor-=4;}
   else if(rawEdge&0x4000){cursor+=4;if(cursor>22)cursor&=2;}
   selected=(cursor-8)/2;
   if(rawEdge&0xf000)cursorBlink=0;
   if(pressed&0x4000)
   {
    if(selected==-1){ToggleStatus();return;}
    if(selected<0)return; // MAP/FILE/RADIO systems outside the E1M1 slice.
    if(combineFrom>=0)CombineSelected();
    else if(selected<used){actionMenu=true;actionOption=0;actionDelay=8;actionClosing=false;}
   }
   return;
  }
  if((pressed&0x800)&&behavior<0x12){ToggleStatus();return;}
  if(behavior==0x0d)RunStep();
  else if(behavior>=0x12)GunStep();
  else WalkStep();
  ApplyPose();
 }
 override bool CanTouchItem(Inventory item){return false;}
 override void CheckPitch(){Pitch=0;}
 override void TickPSprites(){} // RE state machine applies Doom hitscan on RE fire frame.
 void ApplyPose()
 {
  if(pose){pose.SetState(pose.FindStateByString(String.Format("Pose%d",shownFrame)));pose.SetOrigin(Pos,true);pose.Angle=Angle;}
  bool enabled=CVar.FindCVar('re_joint_render').GetBool();
  if(pose)pose.bInvisible=enabled;
  if(jointVisual){if(enabled)jointVisual.Draw(self);else jointVisual.Hide();}
 }
 void SyncWeaponModel()
 {
  int weapon=equipped>=0?ids[equipped]:0;bool armed=weapon==2||weapon==3;
  if(weapon!=visibleWeapon||armed!=visibleArmed||!pose)
  {
   if(pose)pose.Destroy();
   pose=JillPose(Spawn(weapon==3?"JillShotgunPose":armed?"JillPose":"JillUnarmedPose",Pos));visibleArmed=armed;visibleWeapon=weapon;
  }
  behavior=0;phase=0;aimflags=0;aimLock=false;aimTarget=null;speedRE=0;
  NewMotion(0);JointMove(false,true);blend=0;ApplyPose();
 }
 void NewMotion(int m){motion=m;animframe=0;animTiming=0;blend=3;}
 int JointMove(bool reverse=false,bool body=false,int blendStep=0x400)
 {
  if(animTiming>1){animTiming--;return 0;}
  animBank=body?2:(visibleWeapon==3?3:visibleArmed?0:1);
  int count=body?REAnimations.BodyCounts[motion]:visibleWeapon==3?REAnimations.ShotgunCounts[motion]:visibleArmed?REAnimations.Counts[motion]:REAnimations.UnarmedCounts[motion];
  int start=body?REAnimations.BodyStarts[motion]:visibleWeapon==3?REAnimations.ShotgunStarts[motion]:visibleArmed?REAnimations.Starts[motion]:REAnimations.UnarmedStarts[motion];
  animframe%=count;reversePose=reverse;
  shownFrame=start+(reverse?count-1-animframe:animframe);
  if(!jointVisual)jointVisual=new("REJointVisual");jointVisual.Advance(shownFrame,blend,blendStep);
  animTiming=REAnimations.Timings[shownFrame];
  if(blend>0)blend--;
  animframe++;if(animframe>=count){animframe=0;return 1;}return 0;
 }
 void MenuVisualStep()
 {
  if(menuFadeMode==1)
  {
   menuFade-=0x1800;if(menuFade<0){menuFade=0;menuFadeMode=0;}
  }
  else if(menuFadeMode==2)
  {
   menuFade+=0xc00;if(menuFade>=0x8000)
   {
    menuFade=0x7fff;menuFadeMode=3;statusOpen=false;boxOpen=false;SyncWeaponModel();
   }
  }
  else if(menuFadeMode==3)
  {
   menuFade-=0x1800;if(menuFade<0){menuFade=0;menuFadeMode=0;menuClosing=false;UpdateFreeze();}
  }
  cursorBlink--;
  if(healSweep>0){healSweep-=2;if(healSweep<84){healSweep=0;ecgSweep=132;ecgSecondary=132;}return;}
  ecgSweep++;
  if(ecgSweep>131||ecgSweep<53)
  {
   ecgSweep=53;int variant=random(0,3);if(variant==(ecgWave&3))variant=(variant+1)&3;
   ecgWave=max(0,(health-1)/24)*4+variant;
  }
  ecgSecondary++;if(ecgSecondary>131||ecgSecondary<22){ecgSecondary=ecgSweep-31;ecgOldWave=ecgWave;}
 }
 void ToggleStatus()
 {
  if(promptKind>0)return;
  RESound(statusOpen?"cancel":"decide");
  if(boxOpen){CloseBox();return;}
  if(statusOpen){menuFade=0;menuFadeMode=2;menuClosing=true;return;}
  statusOpen=true;combineFrom=-1;actionMenu=false;actionClosing=false;
  selected=0;cursorBlink=0;ecgSweep=132;ecgSecondary=132;menuFade=0x7fff;menuFadeMode=1;
  UpdateFreeze();
 }
 void UpdateFreeze()
 {
  bool frozen=deathStage>=3||saveState>0||statusOpen||boxOpen||promptKind>0||menuFadeMode>0||viewerItem>0;
  Level.SetFrozen(frozen);player.timefreezer=frozen?1:0;
 }
 void CancelStatus()
 {
  if(actionMenu){actionClosing=true;actionDelay=8;return;}
  if(combineFrom>=0){combineFrom=-1;return;}
  ToggleStatus();
 }
 void StatusAction()
 {
  actionClosing=true;actionDelay=8;
  if(selected<0)return;
  if(actionOption==0)UseSelected();
  else if(actionOption==1){actionMenu=false;StartItemView(ids[selected],1);}
  else CombineSelected();
 }
 void RotateRE(int increment){Angle-=increment*360.0/4096;}
 void TranslateRE(int distance,bool backwards=false)
 {
  double a=Angle+(backwards?180:0);
  Vector2 delta=AngleToVector(a,distance*56.0/1800);
  if(!TryMove(Pos.XY+delta,1))
  {
   // Doom walls replace RE SCA primitives; native sliding approximation is explicit.
   if(!TryMove((Pos.X+delta.X,Pos.Y),1))TryMove((Pos.X,Pos.Y+delta.Y),1);
  }
 }
 void WalkStep()
 {
  // player_input_to_behavior 0x004956a0: interaction before aim before direction.
  if(pressed&0x80){Interact();if(promptKind>0||boxOpen)return;}
  if((pad&0x100)&&equipped>=0){behavior=0x12;phase=0;return;}
  // The source resets on a fresh forward/back press, not on diagonal changes.
  switch(pad&15)
  {
   case 1:behavior=1;if(pressed&1)phase=0;break;
   case 3:behavior=2;if(pressed&1)phase=0;break;
   case 9:behavior=3;if(pressed&1)phase=0;break;
   case 2:if(behavior!=4)phase=0;behavior=4;break;
   case 8:if(behavior!=5)phase=0;behavior=5;break;
   case 6:behavior=6;if(pressed&4)phase=0;break;
   case 12:behavior=7;if(pressed&4)phase=0;break;
   case 4:behavior=8;if(pressed&4)phase=0;break;
   default:break;
  }
  // frame2 0x00495330: fixed increments, no angular acceleration.
  if(behavior==2||behavior==6)RotateRE(0x28);
  if(behavior==3||behavior==7)RotateRE(-0x28);
  if(behavior==4)RotateRE(0x60);
  if(behavior==5)RotateRE(-0x60);
  if(behavior>=1&&behavior<=3)
  {
   if(!(pad&1)){behavior=0;phase=0;return;}
   if(phase==0){NewMotion(2);phase=1;}
   if(pad&0x200){behavior=0x0d;phase=0;}
   // Jill walk table 0x00495a70, animation BEFORE Joint_move.
   int f=animframe;speedRE=0x5d;
   if(f>=20&&f<27)speedRE=0x5d-15;
   if(f>=7&&f<14)speedRE-=15;
   if(f>=22&&f<25)speedRE-=15;
   if(f>=9&&f<12)speedRE-=15;
   if(animTiming<=1&&(f==8||f==22))RESound(f==8?"step-a":"step-b",CHAN_BODY);
   JointMove();TranslateRE(speedRE);return;
  }
  if(behavior==4||behavior==5)
  {
   if(!(pad&10)){behavior=0;phase=0;return;}
   if(!phase){NewMotion(2);phase=1;}JointMove();return;
  }
  if(behavior>=6&&behavior<=8)
  {
   if(!(pad&4)){behavior=0;phase=0;return;}
   // player_ctrl_behavior_run is actually backing up. Enemy proximity changes pose/speed.
   bool nearEnemy=false;let it=ThinkerIterator.Create("Actor");Actor a;
   while(a=Actor(it.Next()))if(a.bIsMonster&&a.health>0&&Distance2D(a)<8000*56.0/1800&&abs(deltaangle(Angle,AngleTo(a)))<45&&CheckSight(a)){nearEnemy=true;break;}
   int m=nearEnemy?2:3;
   if(motion!=m||!phase){NewMotion(m);phase=1;}
   speedRE=nearEnemy?0x3c:0x40;if(animTiming<=1&&(animframe==8||animframe==22))RESound(animframe==8?"step-a":"step-b",CHAN_BODY);JointMove(false,true);TranslateRE(speedRE,true);return;
  }
  if(behavior==0)
  {
   if(!phase){NewMotion(0);phase=1;idleTicks=100;}
   if(phase==1){JointMove(false,true);if(--idleTicks==0){phase=2;NewMotion(0);}}
   else if(phase==2){if(JointMove()){phase=3;NewMotion(1);}}
   else JointMove();
  }
 }
 void RunStep()
 {
  if(pressed&0x80){Interact();if(promptKind>0||boxOpen)return;}
  if(phase<2&&(!(pad&1)||((pad&0x100)&&equipped>=0)))phase=2;
  if(pad&2)RotateRE(0x30);if(pad&8)RotateRE(-0x30);
  if(phase==0){int f=animframe;NewMotion(3);animframe=(f>9&&f<25)?12:1;speedRE=0xd2;phase=1;}
  if(phase==1)
  {
   speedRE=0xd2;if(animTiming<=1&&(animframe==0||animframe==10))RESound(animframe==0?"step-a":"step-b",CHAN_BODY);JointMove();
   if(!(pad&0x200)){behavior=1;phase=1;int f=animframe;NewMotion(2);animframe=(f!=0&&f<12)?25:10;}
  }
  else
  {
   if(phase==2){NewMotion(0);phase=3;runStop=0;}
   JointMove(false,true);runStop++;if(runStop>3){behavior=0;phase=0;speedRE=0;}
   speedRE-=0x1e;
  }
  TranslateRE(speedRE);
 }
 void GunStep()
 {
  // Source frame3 dispatch 0x00495530; handgun behavior functions 0x004578f0 onward.
  if(equipped<0||(ids[equipped]!=2&&ids[equipped]!=3)){behavior=0;phase=0;return;}
  // Keep held-Aim tracking, but release automatic steering during a shot,
  // directional aim, or manual turning. Original RE turn increments stay intact.
  if((pad&0x100)&&!(pad&10)&&behavior!=0x14&&!(pressed&0x40))
  {if(aimLock)FollowTarget();}
  else {aimLock=false;aimTarget=null;}
  if(behavior==0x12)
  {
   if(phase==0){NewMotion(5);phase=1;aimflags=0;AcquireTarget();aimLock=aimTarget!=null;}
   else if(phase==2){behavior=0x13;phase=0;return;}
   // Fresh action drops initial reticle lock; manual steering still works.
   if(pressed&0x40){aimLock=false;aimTarget=null;}

   phase+=JointMove();
   if(pad&2)RotateRE(0x38);if(pad&8)RotateRE(-0x38);
   if(animframe>9&&(pad&5)){aimflags=(pad&4)?0x20:0x80;behavior=0x15;phase=0;motion=(pad&4)?11:8;}
   return;
  }
  if(behavior==0x13)
  {
   // Raise/hold pose runs BEFORE hold input, as in player_ctrl_frame3.
   int olddir=((aimflags&0x20)>>4)+(aimflags>>7);
   if(phase==0){NewMotion(olddir*3+7);phase=1;JointMove();}
   else if(phase==1)JointMove();
   else if(phase==2)
   {
    if(blend==0){phase=3;NewMotion(visibleWeapon*3+2+olddir);blend=7;}
    else JointMove(false,false,0x200);
   }
   else if(phase==3)
   {
    if(blend!=0){JointMove(false,true,0x200);}
    else {phase=2;NewMotion(olddir*3+7);blend=7;}
   }
   int old=aimflags;aimflags=0x40;
   if(pad&0x10)aimflags=0x80;if(pad&0x20)aimflags=0x20;
   int dir=((aimflags&0x20)>>4)+(aimflags>>7);
   if((aimflags^old)&0xa0){behavior=0x15;phase=0;motion=dir*3+5;}
   if((old&0xa0)&&(aimflags&0x40)){behavior=0x16;phase=0;motion=(((old>>7)&1)+((old>>5)&1)*2)*3+5;}
   if(!(pad&0x100)){behavior=0x17;phase=0;return;}
   if(pad&0x40)
   {
    if(qty[equipped]>0){behavior=0x14;phase=0;return;}
    if(pressed&0x40){message="Empty magazine.";if(FindItem(visibleWeapon+9)>=0){behavior=0x18;phase=0;return;}}
   }
   if(pad&2){RotateRE(0x38);if(phase<2){phase=2;blend=0;}return;}
   if(pad&8){RotateRE(-0x38);if(phase<2){phase=2;blend=0;}return;}
   if(phase>1)phase=0;
   return;
  }
  if(behavior==0x14)
  {
   if(phase==2){behavior=0x13;phase=0;return;}
   if(phase==0){phase=1;NewMotion(((((aimflags&0x20)>>4)+(aimflags>>7))+2)*3);}
   phase+=JointMove();
   if(animframe==(visibleWeapon==3?25:3)){RECasing.Emit(self);}
   if(animframe==1)qty[equipped]--;
   if(animframe==5||(visibleWeapon==3&&(animframe==7||animframe==9)))FireDoom();
   if(visibleWeapon==3&&animframe==22)RESound("pump",CHAN_WEAPON);
   if(animframe>(visibleWeapon==3?24:8)&&!(pad&0x100)){behavior=0x13;phase=0;}
   return;
  }
  if(behavior==0x15||behavior==0x16)
  {
   if(phase==2){behavior=0x13;phase=0;return;}
   if(phase==0){NewMotion(motion);phase=1;}
   phase+=JointMove(behavior==0x16);
   if(pad&5){behavior=0x13;phase=0;}
   return;
  }
  if(behavior==0x17)
  {
   if(pad&2)RotateRE(0x50);if(pad&8)RotateRE(-0x50);
   if(!phase){motion=5;phase=1;blend=3;}
   if(JointMove(true)){behavior=0;phase=0;}
   return;
  }
  if(behavior==0x18)
  {
   if(phase==0){NewMotion(14);phase=1;return;}
   // fire_beretta_fx reads frame BEFORE Joint_move, refill at source frame 0x11.
   if(animTiming<=1)
   {
    if(visibleWeapon==2&&animframe==17){ReloadFromLargestStack();RESound("magazine",CHAN_WEAPON);}
    if(visibleWeapon==3&&(animframe==15||animframe==25||animframe==35))
    {if(animframe==15)ReloadFromLargestStack();RESound("shell-reload",CHAN_WEAPON);}
   }
   if(JointMove()){behavior=0x13;phase=0;}
  }
 }
 void FireDoom()
 {
  // Original RE fire frames and samples drive native Doom combat.
  if(animframe==5)RESound(visibleWeapon==3?"shotgun":"handgun",CHAN_WEAPON);
  let trace=CVar.GetCVar("re_case_trace");int hpBefore=0;
  if(trace&&trace.GetBool()){let scan=ThinkerIterator.Create("Actor");Actor enemy;while(enemy=Actor(scan.Next()))if(enemy.bIsMonster)hpBefore+=max(enemy.health,0);}
  double shootpitch=AimLineAttack(Angle,2048);
  for(int i=0;i<(visibleWeapon==3?7:1);i++)LineAttack(Angle+(visibleWeapon==3?frandom(-5.625,5.625):0),2048,shootpitch,5*random(1,3),"Hitscan","BulletPuff");
  if(trace&&trace.GetBool()){int hpAfter=0;let scan=ThinkerIterator.Create("Actor");Actor enemy;while(enemy=Actor(scan.Next()))if(enemy.bIsMonster)hpAfter+=max(enemy.health,0);Console.Printf("REFIRE weapon=%d frame=%d ammo=%d monsterHPBefore=%d monsterHPAfter=%d",visibleWeapon,animframe,qty[equipped],hpBefore,hpAfter);}
 }
 void AcquireTarget()
 {
  // player_reticle_enemy 0x00496910: nearest visible target; turn_toward_target(0x800)
  // returns zero throughout the 4096-unit circle. Doom sight replaces RDT boundaries.
  aimTarget=null;double dist=1e9;let it=ThinkerIterator.Create("Actor");Actor a;
  while(a=Actor(it.Next()))if(a.bIsMonster&&a.bShootable&&a.health>0&&CheckSight(a)&&Distance2D(a)<=2048&&Distance2D(a)<dist){aimTarget=a;dist=Distance2D(a);}
 }
 void FollowTarget()
 {
  if(!aimTarget||!aimTarget.bShootable||aimTarget.health<=0||!CheckSight(aimTarget)||Distance2D(aimTarget)>2048){aimLock=false;aimTarget=null;return;}
  double delta=deltaangle(Angle,AngleTo(aimTarget));
  int step=abs(delta)<45?0xe0:0x110; // Jill ((id&1)+6)*32 or id*32+0xf0.
  double degrees=step*360.0/4096;
  Angle+=clamp(delta,-degrees,degrees);
 }
 int FindItem(int id){for(int i=0;i<used;i++)if(ids[i]==id)return i;return -1;}
 bool CanAddItem(int id,int count)
 {
  if(used<8)return true;
  // item viewer capacity branch (MainMenu.cpp 0x0044e1b0): a full carried
  // inventory can accept ammo only if an existing stack fits the whole pickup.
  if(id==11||id==12||id==47)for(int i=0;i<used;i++)if(ids[i]==id&&qty[i]+count<251)return true;
  return false;
 }
 bool AddItem(int id,int count)
 {
  // room_event_item_pickup 0x00451700: ammo stacks cap 250, herbs never stack.
  if(!CanAddItem(id,count)){message="You can't carry any more items.";return false;}
  if(id==11||id==12||id==47)for(int i=0;i<used;i++)if(ids[i]==id)
  {
   int merged=qty[i]+count;
   if(merged<251){qty[i]=merged;return true;}
   // Preserve the decomp's decreasing slotCount comparison (8-i), including
   // its late-slot overflow quirk. Quantity is an unsigned byte in RE1.
   if(used<8-i){count=(merged+6)&255;qty[i]=250;break;}
  }
  if(used==8){message="You cannot carry any more items.";return false;}
  ids[used]=id;qty[used]=count;used++;return true;
 }
 void RemoveSlot(int index)
 {
  for(int i=index;i<used-1;i++){ids[i]=ids[i+1];qty[i]=qty[i+1];}
  used--;ids[used]=0;qty[used]=0;
  if(equipped==index)equipped=-1;else if(equipped>index)equipped--;
  if(selected>=used)selected=max(0,used-1);
 }
 void ReloadFromLargestStack()
 {
  int slot=-1;int amount=0;
  for(int i=0;i<used;i++)if(ids[i]==ids[equipped]+9&&qty[i]>amount){slot=i;amount=qty[i];}
  if(slot<0)return;
  qty[equipped]=min(visibleWeapon==3?7:15,amount);qty[slot]-=qty[equipped];if(qty[slot]==0)RemoveSlot(slot);
 }
 void UseSelected()
 {
  if(selected<0||selected>=used)return;
  int id=ids[selected];
  if(id==2||id==3){equipped=(equipped==selected)?-1:selected;message=equipped>=0?"Handgun equipped.":"Handgun unequipped.";}
  else if(id==0x44||id==0x47||id==0x4a)
  {
   // menu_item_use_heal 0x00401260: integer maxHealth/3; refuse at full health.
   if(health>=96){message="You don't need to use it now.";return;}
   int amount=RESliceItems.Healing(id);
   health=min(96,health+96*amount/3);player.health=health;healSweep=175;
   if(--qty[selected]==0)RemoveSlot(selected);message="Herbs used.";
  }
  else if(id==0x33)
  {
   if(AtFinalDoor()&&!cacheUnlocked){statusOpen=false;UseCache();}
   else message="You can't use it here.";
  }
  else message="Combine the clip with the handgun.";
 }
 void CombineSelected()
 {
  if(combineFrom<0){combineFrom=selected;message="Select the second item and press Q.";return;}
  int a=combineFrom;int b=selected;combineFrom=-1;
  if(a>=used||b>=used||a==b)return;
  // The source's cursor is the second selected slot, target is the first.
  int recipe=RESliceItems.Recipe(ids[b],ids[a]);
  if(recipe>=0 && (ids[b]==0x44||ids[b]==0x47))
  {
   promptA=b;promptB=a;BeginPrompt(3,"Will you mix the herbs?");return;
  }
  if(recipe>=0 && ((ids[a]>=2&&ids[a]<=3&&ids[b]==ids[a]+9)||(ids[b]>=2&&ids[b]<=3&&ids[a]==ids[b]+9)))
  {
   int gun=ids[a]<11?a:b;int ammo=ids[a]>=11?a:b;
   int transfer=min((ids[gun]==3?7:15)-qty[gun],qty[ammo]);qty[gun]+=transfer;qty[ammo]-=transfer;
   if(qty[ammo]==0)RemoveSlot(ammo);message="Handgun loaded.";return;
  }
  if(recipe>=0&&ids[a]==ids[b]&&(ids[a]==11||ids[a]==12))
  {
   int transfer=min(250-qty[b],qty[a]);qty[b]+=transfer;qty[a]-=transfer;if(qty[a]==0)RemoveSlot(a);message="Clips combined.";return;
  }
  if((ids[a]==0x44||ids[a]==0x47||ids[a]==0x4a)&&(ids[b]==0x44||ids[b]==0x47||ids[b]==0x4a))
  {message="You can't mix these herbs.";return;}
  promptA=a;promptB=b;BeginPrompt(4,"Will you move the items?");
 }
 // Original IVM model, camera and intro. No enlarged inventory-icon stand-in.
 void StartItemView(int id,int mode)
 {
  if(menuItemModel)menuItemModel.Destroy();
  viewerItem=id;viewerMode=mode;viewerStep=0;viewerExiting=false;viewerDescription=false;
  menuItemModel=REItemView(Spawn(String.Format("REItemView%d",id),(16000,16000,20000)));
  if(!menuCamera)menuCamera=Spawn("REMenuCamera",(16000-15000*56.0/1800,16000,20000));
  menuCamera.Angle=0;menuCamera.Pitch=0;
  TexMan.SetCameraToTexture(menuCamera,"REIVIEW",2*atan(80.0/192));
  TexMan.SetCameraTextureAspectRatio("REIVIEW",1,true);
  UpdateItemViewModel();UpdateFreeze();
 }
 void UpdateItemViewModel()
 {
  if(!menuItemModel)return;
  menuItemModel.SetState(menuItemModel.FindStateByString(String.Format("View%d",viewerStep)));
  int zoom=-0xaf00+viewerStep*0x322;
  menuItemModel.SetOrigin((16000-zoom*56.0/1800,16000,20000),true);
  // Original light fade interval, represented as actor fade until the engine
  // lighting adapter is completed (tracked explicitly in docs/UI_FIDELITY.md).
  menuItemModel.Alpha=clamp((255-(64-viewerStep)*4)/255.0,0.,1.);
 }
 void StopItemView()
 {
  if(menuItemModel)menuItemModel.Destroy();menuItemModel=null;
  viewerItem=0;viewerExiting=false;viewerDescription=false;UpdateFreeze();
 }
 void ItemViewStep()
 {
  if(viewerExiting)
  {
   if(viewerStep>0){viewerStep=max(0,viewerStep-(viewerMode==2?2:1));UpdateItemViewModel();return;}
   int mode=viewerMode;StopItemView();
   if(mode==1){actionMenu=true;actionOption=1;actionDelay=0;actionClosing=false;}
   else if(!statusOpen&&!boxOpen)SyncWeaponModel();
   return;
  }
  if(viewerStep<64)
  {
   viewerStep=min(64,viewerStep+(viewerMode==2?2:1));UpdateItemViewModel();
   if(viewerStep==64&&viewerMode==2){sourcePrompt=true;StartSourceMessage(promptKind==1?0:2);SourceMessageStep();}
   return;
  }
  if(viewerMode==2)
  {
   SourceMessageStep();if(msgState==4||msgState==5)PromptStep();return;
  }
  if(viewerDescription)
  {
   SourceMessageStep();
   if(msgState==5&&(pressed&0xc000)){viewerDescription=false;message="";}return;
  }
  if(pressed&0x8000){RESound("cancel");viewerExiting=true;return;}
  if(pressed&0x4000){RESound("decide");viewerDescription=true;message=ItemDescription(viewerItem);StartDescriptionMessage(message);SourceMessageStep();return;}
  // Free examination rotation still needs the original incremental matrix
  // and extraction code; do not substitute generic Euler tank inputs here.
 }
 // Rendering.cpp UpdateMessageDisplay states 0/1/4/5, for the exact
 // source streams used by pickups. Item-name tags expand without extra delay.
 void StartSourceMessage(int id)
 {
  msgPageStart=0;msgLength=0;msgOffset=0;msgState=0;msgTimer=(viewerMode==2&&viewerItem>0)?1:2;msgBlink=0;
  int table=-1;for(int i=0;i<REMessages.Count;i++)if(REMessages.IDs[i]==id)table=i;
  if(table<0)return;
  for(int i=0;i<REMessages.Lengths[table];i++)
  {
   int code=REMessages.Bytes[REMessages.Starts[table]+i];
   if(code==6)
   {
    i++;String name=ItemName(pendingPickup?pendingPickup.itemId:messageItem?messageItem:viewerItem);
    for(int n=0;n<int(name.Length());n++)msgStream[msgLength++]=REMessages.Glyph(name.CharCodeAt(n));
   }
   else msgStream[msgLength++]=code;
  }
  msgState=1;
 }
 void StartDescriptionMessage(String text)
 {
  msgPageStart=0;msgLength=0;msgOffset=0;msgState=1;msgTimer=(viewerMode==2&&viewerItem>0)?1:2;msgBlink=0;
  for(int i=0;i<int(text.Length())&&msgLength<254;i++)
  {
   int c=text.CharCodeAt(i);msgStream[msgLength++]=c==10?2:REMessages.Glyph(c);
  }
  msgStream[msgLength++]=1;msgStream[msgLength++]=0;
 }
 void SourceMessageStep()
 {
  if(msgState==2){if(pressed&0xc000){msgPageStart=msgOffset;msgState=1;msgTimer=(viewerMode==2&&viewerItem>0)?1:2;}return;}
  if(msgState!=1){msgBlink=(msgBlink-1)&255;return;}
  msgTimer=(msgTimer-1)&255;if(msgTimer!=0)return;
  while(msgOffset<msgLength)
  {
   int code=msgStream[msgOffset];
   if(code==8){msgState=4;return;}
   if(code==1){msgState=5;return;}
   if(code==3){msgOffset+=2;msgState=2;return;}
   if(code==2){msgOffset++;continue;}
   if(code==5){msgOffset+=2;continue;}
   msgOffset++;msgTimer=(viewerMode==2&&viewerItem>0)?1:2;return;
  }
 }
 void BeginPrompt(int kind,String text)
 {
  promptKind=kind;choice=0;message=text;actionMenu=false;UpdateFreeze();
  sourcePrompt=kind==3||kind==5||kind==6||kind==7||kind==8;messageItem=kind==5?0x33:0;
  if(sourcePrompt){StartSourceMessage(kind==7?31:kind==8?30:kind==3?53:kind==5?3:7);SourceMessageStep();}
 }
 void BeginPickup(REPickup item)
 {
  RESound("decide");
  pendingPickup=item;
  if(!CanAddItem(item.itemId,item.quantity)){BeginPrompt(2,"You can't carry any more\nitems.");StartItemView(item.itemId,2);return;}
  BeginPrompt(1,String.Format("Will you take the %s?",ItemName(item.itemId)));
  StartItemView(item.itemId,2);
 }
 void PromptStep()
 {
  if(sourcePrompt&&viewerItem==0)
  {
   SourceMessageStep();if(msgState!=4&&msgState!=5)return;
  }
  // Rendering.cpp UpdateMessageDisplay state 4: left/right edges toggle the
  // choice; only fresh action confirms. V is not a shortcut for No here.
  if(promptKind==2||promptKind==5||promptKind==8)
  {
   if(pressed&0xc000)ConfirmPrompt();return;
  }
  if(pressed&0x4000){ConfirmPrompt();return;}
  if(rawEdge&0xa000){choice^=1;msgBlink=255;}
 }
 void ConfirmPrompt()
 {
  RESound("decide"); // Accepted input only: never during model intro/message reveal.
  if(viewerItem>0){viewerExiting=true;}
  int kind=promptKind;promptKind=0;sourcePrompt=false;
  if(kind==1)
  {
   let item=pendingPickup;pendingPickup=null;
   if(choice==0&&item)
   {
    if(!CanAddItem(item.itemId,item.quantity)){BeginPrompt(2,"You can't carry any more\nitems.");StartItemView(item.itemId,2);return;}
    if(AddItem(item.itemId,item.quantity))
    {message=String.Format("You got the %s.",ItemName(item.itemId));item.Destroy();}
   }
   else message="";
  }
  else if(kind==7&&choice==0){OpenTypewriterMenu();return;}
  else if(kind==2){pendingPickup=null;}
  else if(kind==3&&choice==0)
  {
   int recipe=RESliceItems.Recipe(ids[promptA],ids[promptB]);
   if(recipe>=0)
   {
    ids[promptA]=RESliceItems.NewA[recipe];qty[promptA]=1;
    ids[promptB]=RESliceItems.NewB[recipe];
    if(ids[promptB]==0)RemoveSlot(promptB);
    message="Herbs mixed.";
   }
  }
  else if(kind==4&&choice==0)
  {
   int a=promptA;int b=promptB;int id=ids[a];int n=qty[a];
   ids[a]=ids[b];qty[a]=qty[b];ids[b]=id;qty[b]=n;
   if(equipped==a)equipped=b;else if(equipped==b)equipped=a;message="Items moved.";
  }
  else if(kind==5)
  {
   BeginPrompt(6,"This key is useless now. Discard?");return;
  }
  else if(kind==6&&choice==0)
  {
   int slot=FindItem(0x33);if(slot>=0&&qty[slot]==0)RemoveSlot(slot);
   message="Sword key discarded.";
  }
  UpdateFreeze();
 }
 void OpenBox()
 {
  RESound("box-open");
  // open_itembox 0x0041b990; visual lid animation is an explicit port gap.
  if(promptKind>0||statusOpen||boxOpen||behavior>=0x12)return;
  boxOpen=true;boxState=1;boxSelected=0;selected=min(selected,7);
  boxSlide=0;boxDirection=0;boxRepeatTimer=15;boxRepeatMask=0;boxContinueScroll=false;
  message="Select a carried slot, then a storage slot.";UpdateFreeze();
 }
 void CloseBox(){boxOpen=false;boxState=0;SyncWeaponModel();UpdateFreeze();}
 void BoxStep()
 {
  // MainMenu.cpp menu_itembox_interaction 0x004941f0, states 1 and 2.
  if(boxState<3&&(pressed&0x8000))
  {if(boxState==2)boxState=1;else CloseBox();return;}
  if(boxState==1)
  {
   if(pressed&0x4000)
   {
    if(selected<0){CloseBox();return;}
    boxState=2;boxRepeatTimer=15;boxRepeatMask=0;boxContinueScroll=false;
   }
   else
   {
    int cursor=selected*2+8;
    if((rawEdge&0xa000)&&(cursor&248)!=0)cursor^=2;
    if(rawEdge&0x1000){cursor-=4;if((cursor&252)==0)cursor=(cursor&2)|20;}
    else if(rawEdge&0x4000){cursor+=4;if(cursor>22)cursor=(cursor&2)|4;}
    selected=(cursor-8)/2;
   }
  }
  else if(boxState==2)
  {
   if(pressed&0x4000){if(TransferBox(selected,boxSelected))boxState=1;return;}
   if(!(rawEdge&0x5000)&&!boxContinueScroll)return;
   if(!(rawPad&0x5000)){boxRepeatTimer=15;boxRepeatMask=0;return;}
   RESound("box-scroll");boxState=3;boxContinueScroll=true;
   if(rawPad&0x1000){boxSlide=15;boxDirection=-1;boxSelected=(boxSelected+47)%48;}
   else {boxSlide=0;boxDirection=1;}
   if((boxRepeatMask&(rawPad>>8))&&boxRepeatTimer==0)boxDirection*=3;
   AdvanceBoxSlide();
  }
  else AdvanceBoxSlide();
 }
 void AdvanceBoxSlide()
 {
  // Source state 3 scroll: 15 steps, then three steps after held repeat delay.
  if(!(boxRepeatMask&(rawPad>>8)))
  {boxRepeatTimer=15;boxRepeatMask=(rawPad&0x1000)?0x10:(rawPad&0x4000)?0x40:0;}
  else if(boxRepeatTimer>0)boxRepeatTimer--;
  boxSlide+=boxDirection;if(boxSlide==15)boxSlide=0;
  if(boxSlide==0)
  {boxState=2;if(boxDirection>0)boxSelected=(boxSelected+1)%48;boxDirection=0;}
 }
 bool TransferBox(int carried,int stored)
 {
  if(carried<0||carried>=8||stored<0||stored>=48)return false;
  if(ids[carried]==0&&boxIds[stored]==0)return false;
  // Source exchanges complete ItemSlot records, never merges/splits quantities.
  // An equipped weapon in the selected player slot is explicitly unequipped.
  if(equipped==carried)equipped=-1;
  int id=boxIds[stored];int amount=boxQty[stored];
  boxIds[stored]=ids[carried];boxQty[stored]=qty[carried];
  if(carried<used)
  {
   ids[carried]=id;qty[carried]=amount;if(id==0)RemoveSlot(carried);
  }
  else if(id!=0){ids[used]=id;qty[used]=amount;used++;}
  message="Items exchanged.";return true;
 }
 bool AtCache(){return false;}
 bool AtFinalDoor(){return Pos.X>2944&&Pos.X<3072&&Pos.Y> -4712&&Pos.Y< -4568;}
 void UseCache()
 {
  int key=FindItem(0x33);
  if(key<0){BeginPrompt(2,"It's locked. A carving of a sword.");return;}
  // One required use in this E1M1 event. RE key depletion retains the empty
  // key until the discard choice; unlocking does not silently delete it.
  cacheUnlocked=true;qty[key]=max(0,qty[key]-1);
  // Hangar final door is unlocked; retain depleted key until the source discard choice.
  BeginPrompt(5,"You have used the SWORD KEY.");
 }
 bool CanInteractWorld(Actor item,double range)
 {
  return item&&!item.bInvisible&&Distance2D(item)<range&&abs(Pos.Z-item.Pos.Z)<48&&CheckSight(item);
 }
 void Interact()
 {
  if(promptKind>0||statusOpen||boxOpen||saveState>0)return;
  REPickup nearest;double distance=48;let it=ThinkerIterator.Create("REPickup");REPickup item;
  while(item=REPickup(it.Next()))if(CanInteractWorld(item,distance)){nearest=item;distance=Distance2D(item);}
  if(nearest)
  {
   BeginPickup(nearest);return;
  }
  // These Doom-space interaction circles can overlap. Select the nearest
  // visible original object so the prompt belongs to the object beside Jill.
  Actor station;distance=48;
  let boxes=ThinkerIterator.Create("REItemBox");Actor box;
  while(box=Actor(boxes.Next()))if(CanInteractWorld(box,distance)){station=box;distance=Distance2D(box);}
  let writers=ThinkerIterator.Create("RETypewriter");Actor writer;
  while(writer=Actor(writers.Next()))if(CanInteractWorld(writer,distance)){station=writer;distance=Distance2D(writer);}
  if(station){if(station is "RETypewriter")UseTypewriter(station);else OpenBox();return;}
  if(AtCache())
  {
   if(!cacheUnlocked)UseCache();else message="The supply cache is open.";return;
  }
  player.cmd.buttons|=BT_USE;player.usedown=false;CheckUse();player.cmd.buttons&=~BT_USE;
 }
 clearscope String ItemName(int id)
 {
  int flag=RESliceItems.ExamineFlag(id);
  return RESliceItems.Name(id,flag>=128||(examinedItems&(1<<flag))!=0);
 }
 clearscope String ItemDescription(int id)
 {
  return RESliceItems.Description(id);
 }

}
class RECamera : Actor { Default { +NOGRAVITY +NOINTERACTION +NOBLOCKMAP } States { Spawn: TNT1 A -1; Stop; } }
class REPickup : Actor
{
 int itemId;int quantity; REPickupGlint glint;
 property ItemId:itemId;
 property Quantity:quantity;
 Default { Radius 8;Height 16;+NOGRAVITY +BRIGHT }
 override void PostBeginPlay(){Super.PostBeginPlay();SetOrigin((Pos.X,Pos.Y,floorz),false);glint=REPickupGlint(Spawn("REPickupGlint",Pos+(0,0,6)));glint.master=self;}
 override void Tick(){Super.Tick();Vel=(0,0,0);if(Pos.Z!=floorz)SetOrigin((Pos.X,Pos.Y,floorz),false);}
 States { Spawn: BON1 A -1; Stop; }
}
// CORE00.ESP type0x0b, depth28: eleven source ticks visible, 100..140 hidden.
class REPickupGlint : Actor
{
 int clock33;int phase;int timer;int frame;int delay;
 Default { +NOGRAVITY +NOINTERACTION +NOBLOCKMAP +BRIGHT RenderStyle "Add"; Scale 0.5; }
 override void Tick()
 {
  Super.Tick();if(!master){Destroy();return;}SetOrigin(master.Pos+(0,0,6),false);
  clock33+=1000;if(clock33<1155)return;clock33-=1155;
  static const int frames[]={4,8,4,7,5,9,6,8,4};
  static const int delays[]={1,1,1,1,1,2,2,1,1};
  if(phase==0){phase=1;timer=11;frame=0;delay=1;}
  if(phase==1)
  {
   Alpha=1;SetState(FindStateByString(String.Format("Glint%d",frames[frame])));
   if(--timer==0){phase=2;Alpha=0;return;}
   if(--delay<=0){frame++;delay=delays[frame];}
  }
  else if(phase==2){phase=3;timer=(random(0,4)+10)*10;Alpha=0;}
  else if(--timer==0)phase=0;
 }
 States {
 Spawn: RGLT E -1 Bright; Stop;
 Glint0:RGLT A -1 Bright;Stop;Glint1:RGLT B -1 Bright;Stop;
 Glint2:RGLT C -1 Bright;Stop;Glint3:RGLT D -1 Bright;Stop;
 Glint4:RGLT E -1 Bright;Stop;Glint5:RGLT F -1 Bright;Stop;
 Glint6:RGLT G -1 Bright;Stop;Glint7:RGLT H -1 Bright;Stop;
 Glint8:RGLT I -1 Bright;Stop;Glint9:RGLT J -1 Bright;Stop;
 }
}
class REShells : REPickup { Default { REPickup.ItemId 12;REPickup.Quantity 7; } States { Spawn:RSHL A -1 Bright;Stop;} }
class REClip : REPickup replaces Clip { Default { REPickup.ItemId 11;REPickup.Quantity 15; } States { Spawn: RAMM A -1 Bright; Stop; } }
class REClipBox : REPickup replaces ClipBox { Default { REPickup.ItemId 11;REPickup.Quantity 30; } States { Spawn: RAMM A -1 Bright; Stop; } }
class REHerb : REPickup replaces Stimpack { Default { REPickup.ItemId 0x44;REPickup.Quantity 1; } States { Spawn: RHER A -1 Bright; Stop; } }
class RESwordKey : REPickup { Default { Scale 2.5;REPickup.ItemId 0x33;REPickup.Quantity 1; } States { Spawn: RKEY A -1 Bright; Stop; } }
class REShotgun : REPickup { Default { REPickup.ItemId 3;REPickup.Quantity 7; } States { Spawn: RSHG A -1 Bright; Stop; } }
class REInkRibbon : REPickup { Default { REPickup.ItemId 47;REPickup.Quantity 3; } States { Spawn: RINK A -1 Bright; Stop; } }
class REItemBox : Actor { Default { Radius 24;Height 34;XScale 0.95;YScale 0.65;+SOLID } States { Spawn: RBOX A -1; Stop; } }
class RETypewriter : Actor { Default { Radius 18;Height 60;Scale 0.70;+SOLID } States { Spawn: RTYP A -1; Stop; } }
// Prevent normal Doom monster-dropped weapons entering the RE resource loop.
class REDiscardDoomPickup : Actor { override void PostBeginPlay(){Super.PostBeginPlay();Destroy();} }
class REDiscardShotgun : REDiscardDoomPickup replaces Shotgun {}

class REHandler : RESaveHandler
{
 ui bool escapeHeld;
 override bool InputProcess(InputEvent e)
 {
  if(CVar.FindCVar("re_developer_menu").GetBool())return false;
  if(e.KeyScan==InputEvent.Key_Pause)return true;
  if(e.KeyScan!=InputEvent.Key_Escape)return false;
  // Permit native quit/load confirmations; these are not the pause menu.
  if(Menu.GetCurrentMenu()!=null)return false;
  if(e.Type==InputEvent.Type_KeyDown&&!escapeHeld){escapeHeld=true;EventHandler.SendNetworkEvent("re_escape");}
  else if(e.Type==InputEvent.Type_KeyUp)escapeHeld=false;
  return true;
 }

 override void WorldLinePreActivated(WorldEvent e)
 {
  // Original Hangar door faces 320/321 border sector69. Geometry stays unchanged.
  if(e.ActivatedLine.Index()!=320&&e.ActivatedLine.Index()!=321)return;
  let p=JillPlayer(players[0].mo);if(!p)return;
  if(p.cacheUnlocked)return;
  if(p.FindItem(0x33)<0){e.ShouldActivate=false;p.BeginPrompt(2,"It's locked. A carving of a sword.");return;}
  p.UseCache();
 }
 override void WorldLoaded(WorldEvent e)
 {
  let initial=JillPlayer(players[0].mo);if(initial){initial.player.fixedcolormap=PlayerInfo.NOFIXEDCOLORMAP;initial.player.fixedlightlevel=-1;initial.player.extralight=0;}
  if(!e.IsSaveGame&&!e.IsReopen&&initial&&CVar.FindCVar("re_start_title").GetBool())
  {
   CVar.FindCVar("re_start_title").SetBool(false);
   initial.deathStage=4;initial.deathFade=0x7fff;initial.deathTitleOption=0;
   if(initial.jointVisual)initial.jointVisual.Hide();initial.UpdateFreeze();S_ChangeMusic("",0,false);
  }
  if(e.IsSaveGame||e.IsReopen)
  {
   let p=JillPlayer(players[0].mo);if(p)
   {
    p.A_SetRenderStyle(1.0,STYLE_Normal);p.bInvisible=false;p.bNoTarget=false;
    p.saveRequest=0;p.saveState=0;p.activeTypewriter=null;p.rawPad=0;p.prevRaw=0;p.prevpad=0;p.camzone=-1;p.UpdateFreeze();
   }
   return;
  }
  if(initial&&initial.deathStage<3)WorldTick();
  Actor.Spawn("REClip",(1008,-3540,0));Actor.Spawn("RESwordKey",(2544,-3264,0));
  Actor.Spawn("REItemBox",(1120,-3600,0));
  Actor.Spawn("RETypewriter",(1184,-3568,0));Actor.Spawn("REInkRibbon",(976,-3616,0));
  Actor.Spawn("REHerb",(-224,-3232,0));Actor.Spawn("REShotgun",(3264,-3936,0));
  Actor.Spawn("REClip",(2736,-4160,0));
  Actor.Spawn("REHerb",(3072,-4768,0));Actor.Spawn("REHerb",(2880,-4416,0));Actor.Spawn("REShells",(2848,-3584,0));Actor.Spawn("REShells",(3280,-4160,0));
  Actor.Spawn("REHerb",(2224,-2320,0));Actor.Spawn("REClip",(2288,-2544,0));
  Actor.Spawn("REHerb",(2304,-4032,0));
 }
 override void WorldTick()
 {
  let p=JillPlayer(players[0].mo);if(!p)return;
  if(p.deathStage>=3)return;
  if(p.startupCover>0)p.startupCover--;
  p.contextText="";
  let items=ThinkerIterator.Create("REPickup");REPickup item;double nearest=48;
  while(item=REPickup(items.Next()))if(p.Distance2D(item)<nearest&&p.CheckSight(item))
  {nearest=p.Distance2D(item);p.contextText=String.Format("C: EXAMINE %s",p.ItemName(item.itemId));}
  if(p.contextText=="")
  {
   let boxes=ThinkerIterator.Create("REItemBox");Actor box;
   while(box=Actor(boxes.Next()))if(p.CanInteractWorld(box,48)){p.contextText="C: OPEN ITEM BOX";break;}
   if(p.contextText==""&&p.AtCache())p.contextText="C: EXAMINE SUPPLY CACHE";
  }
  if(!p.cinema)p.cinema=Actor.Spawn("RECamera",p.Pos);
  // Static positions/look vectors, zone transitions; never tracks player heading.
  // World lighting stays native. Full-bright flags belong to pickup states only.
  p.player.fixedcolormap=PlayerInfo.NOFIXEDCOLORMAP;p.player.fixedlightlevel=-1;p.player.extralight=0;
  int zone=HangarCameras.Zone(p.Pos);
  if(zone!=p.camzone)
  {
   bool wasHall=p.camzone==0||p.camzone==1;bool hall=zone==0||zone==1;
   if(p.camzone<0||hall!=wasHall)S_ChangeMusic(hall?"REHALL":"REMANS",0,true);
   Vector3 pos=HangarCameras.Anchor(zone);Vector3 look=HangarCameras.Look(zone);
   p.cinema.SetOrigin(pos,false);
   // Fit the static anchor height into its Doom sector; angle still uses fixed look point.
   pos.Z=clamp(pos.Z,p.cinema.floorz+40,p.cinema.ceilingz-8);
   p.cinema.SetOrigin(pos,false);
   Vector3 delta=look-pos;
   p.cinema.Angle=atan2(delta.Y,delta.X);
   p.cinema.Pitch=-atan2(delta.Z,delta.XY.Length());p.camzone=zone;
  }
  p.player.camera=p.cinema;
 }
 override void NetworkProcess(ConsoleEvent e)
 {
  let p=JillPlayer(players[e.Player].mo);if(!p)return;
  if(e.Name=="re_save_request_clear"){p.saveRequest=0;return;}
  if(e.Name=="re_save_row"){if(e.Args[0]>=0&&e.Args[0]<8)p.saveRows[e.Args[0]]=e.Args[1];return;}
  if(e.Name=="re_save_reveal"){p.saveSlot=e.Args[0];p.saveCounter=min(99,e.Args[1]+1);p.saveReveal=0;p.saveRevealTimer=6;p.saveState=6;p.UpdateFreeze();return;}
  if(e.Name=="re_input"){if(e.Args[1])p.rawPad|=e.Args[0];else p.rawPad&=~e.Args[0];return;}
  if(p.health<=0&&(e.Name=="re_escape"||e.Name=="re_menu"))return;
  if(e.Name=="re_death_new")
  {
   p.player.playerstate=PST_REBORN;Level.SetFrozen(false);SetMusicVolume(Level.MusicVolume);
   Level.ChangeLevel("E1M1",0,CHANGELEVEL_NOINTERMISSION|CHANGELEVEL_RESETINVENTORY|CHANGELEVEL_RESETHEALTH);return;
  }
  if(e.Name=="re_escape")
  {
   if(p.menuFadeMode>0)return;
   if(p.saveState>0){if(p.saveState!=6)p.CloseTypewriterMenu();}
   else if(p.viewerItem>0){if(p.msgState==4){p.choice=1;p.ConfirmPrompt();}else if(p.viewerMode==1)p.viewerExiting=true;}
   else if(p.promptKind>0){p.choice=1;p.ConfirmPrompt();}
   else if(p.boxOpen)p.CloseBox();
   else if(p.statusOpen)p.CancelStatus();
   else p.ToggleStatus();return;
  }
  if(e.Name=="re_menu")
  {
   if(p.saveState>0||p.viewerItem>0||p.menuFadeMode>0)return;
   p.ToggleStatus();
  }
  else if(e.Name=="re_use"&&p.statusOpen&&p.promptKind==0)p.UseSelected();
  else if(e.Name=="re_combine"&&p.statusOpen&&p.promptKind==0){p.actionMenu=false;p.CombineSelected();}
  else if(e.Name=="re_examine"&&p.statusOpen&&p.promptKind==0)p.message=p.ItemDescription(p.ids[p.selected]);
 }
 // Every coordinate below is a native RE1 PC pixel. No widescreen reflow.
 ui void Art(String name,double x,double y,double w,double h,double alpha=1,bool preview=false)
 {
  double scale=min(Screen.GetWidth()/320.0,Screen.GetHeight()/240.0);
  double ox=(Screen.GetWidth()-320*scale)/2,oy=(Screen.GetHeight()-240*scale)/2;
  Screen.DrawTexture(TexMan.CheckForTexture(name),false,ox+x*scale,oy+y*scale,DTA_DestWidthF,w*scale,DTA_DestHeightF,h*scale,DTA_LeftOffset,0,DTA_TopOffset,0,DTA_Alpha,alpha,DTA_ClipTop,preview?int(oy+88*scale):0,DTA_ClipBottom,preview?int(oy+118*scale):Screen.GetHeight());
 }
 ui void NativeDim(Color color,double alpha,int x,int y,int w,int h)
 {
  double scale=min(Screen.GetWidth()/320.0,Screen.GetHeight()/240.0);
  Screen.Dim(color,alpha,int((Screen.GetWidth()-320*scale)/2+x*scale),int((Screen.GetHeight()-240*scale)/2+y*scale),int(w*scale),int(h*scale));
 }
 ui void UIArt(String name,double x,double y,double w,double h,double alpha=1){Art("graphics/reui/"..name..".png",x,y,w,h,alpha);}
 ui void NativeText(String text,int x,int y,String tint="")
 {
  int origin=x;
  for(int i=0;i<int(text.Length());i++)
  {
   int ch=text.CharCodeAt(i);
   if(ch==10){x=origin;y+=16;continue;}
   if(ch==32){x+=8;continue;}
   UIArt(String.Format("glyph%d",ch)..tint,x,y,8,14);x+=8;
  }
 }
 ui void NativeMessage(JillPlayer p)
 {
  int x=48,y=186;bool green=false;
  for(int i=p.msgPageStart;i<p.msgOffset;i++)
  {
   int code=p.msgStream[i];
   if(code==2){x=48;y+=16;continue;}
   if(code==5){green=p.msgStream[++i]==1;continue;}
   if(code==0){x+=8;continue;}
   UIArt(String.Format("code%d",code)..(green?"-green":""),x,y,8,14);x+=8;
  }
 }
 ui void NativeItem(int id,int quantity,int x,int y,bool preview=false)
 {
  if(id)Art(ItemIcon(id),x,y,40,30,1,preview);else Art("graphics/reui/empty.png",x,y,40,30,1,preview);
  if(id!=2&&id!=3&&id!=11&&id!=47)return;
  String digits=String.Format("%03d",quantity);int dx=x+(id<11?4:14);bool drawn=false;
  for(int n=0;n<3;n++)
  {
   int digit=digits.CharCodeAt(n)-48;
   if(digit||drawn||n==2){Art("graphics/reui/"..String.Format("digit%d",digit)..".png",dx,y+20,8,8,1,preview);drawn=true;}
   if(drawn||id>10)dx+=8;
  }
 }
 ui int deathSerial;
 ui Actor deathRequestPlayer;
 ui void DrawDeath(JillPlayer p)
 {
  if(p.deathStage==4)
  {
   Screen.Dim("000000",1,0,0,Screen.GetWidth(),Screen.GetHeight());
   Art("graphics/redeath/title-branded.png",0,0,320,240);
   Art("M_DOOM",217,96,100,100*60.0/123);
   Art(String.Format("graphics/redeath/title-option%d.png",p.deathTitleOption),30,p.deathTitleOption==0?182:166,256,p.deathTitleOption==0?54:70);
   if(p.deathFade>0)Screen.Dim("000000",p.deathFade/32768.0,0,0,Screen.GetWidth(),Screen.GetHeight());
   if(deathRequestPlayer!=p){deathRequestPlayer=p;deathSerial=0;}
   if(p.deathRequestSerial!=deathSerial)
   {
    deathSerial=p.deathRequestSerial;
    if(p.deathRequest==1)EventHandler.SendNetworkEvent("re_death_new");
    else if(p.deathRequest==2)Menu.SetMenu("LoadGameMenu");
   }
   return;
  }
  if(p.deathStage==3)
  {
   Screen.Dim("000000",1,0,0,Screen.GetWidth(),Screen.GetHeight());Art("REDEATH",0,0,320,240);
   for(int i=0;i<4;i++)Art(String.Format("graphics/redeath/quad%d.png",i),(i&2)?160:0,(i&1)?120:0,160,120);
   NativeDim("000000",min(255,p.deathRect)/256.0,0,0,320,240);
   if(p.deathMachine>=2)
   {
    int param=p.deathImage,phase=param*param*64,scaleY=((phase>>4)+0x1600)&65535;
    int baseY=-((scaleY*64)>>13),column=0,next;
    do
    {
     int sine=int(sin(phase*360.0/4096)*4096),wave=int((((uint(sine*param*param)>>13)+32768)&65535))-32768;
     int columnY=((baseY-wave+32768)&65535)-32768;
     Art(String.Format("graphics/redeath/column%d.png",column&255),32+column,120+columnY,1,64*scaleY/4096.0);
     next=phase+256;phase=next;column++;
    }while(next<65536);
   }
  }
  if(p.deathFade>=0)Screen.Dim(p.deathFadeType==1?"ffffff":"000000",min(255,p.deathFade>>7)/256.0,0,0,Screen.GetWidth(),Screen.GetHeight());
 }
 override void RenderOverlay(RenderEvent e)
 {
  ProcessSaveRequests();
  let p=JillPlayer(players[consoleplayer].mo);if(!p)return;
  if(e.Camera==p.deathCamera)return;
  if(p.deathStage>0){DrawDeath(p);return;}
  if(p.startupCover>0||!p.cinema||p.camzone<0){Screen.Dim("000000",1,0,0,Screen.GetWidth(),Screen.GetHeight());return;}
  if(e.Camera==p.menuCamera)return; // Do not recursively draw the HUD into its model-view canvas.
  if(p.saveState>0){DrawTypewriter(p);return;}
  if(!p.statusOpen&&!p.boxOpen&&p.promptKind==0&&p.viewerItem==0)
  {
   if(p.menuFadeMode==3)Screen.Dim("000000",p.menuFade/32767.0,0,0,Screen.GetWidth(),Screen.GetHeight());
   return;
  }
  Screen.Dim("000000",1,0,0,Screen.GetWidth(),Screen.GetHeight());
  if(p.viewerItem>0)Art("REIVIEW",32,16,160,120);
  // menu_draw_cursor depth 0x19 is BEHIND the tab/frame records at 20/21.
  // flags 0x01000040 do not enable a blend variant: use the original opaque
  // STATUS plate, then let the original tab art draw over it.
  if(p.selected<0&&!p.boxOpen&&p.promptKind==0&&p.viewerItem==0)
   UIArt("tab-cursor",REUIData.SlotX[p.selected+4],REUIData.SlotY[p.selected+4],48,16);
  for(int i=0;i<63;i++)UIArt(String.Format("part%03d",REUIData.FrameTexture[i]),REUIData.FrameX[i],REUIData.FrameY[i],REUIData.FrameW[i],REUIData.FrameH[i]);
  for(int i=0;i<4;i++)UIArt(i==2?"radio-disabled":String.Format("tab%d",i),REUIData.SlotX[i],REUIData.SlotY[i],48,16);
  for(int i=0;i<8;i++)NativeItem(p.ids[i],p.qty[i],REUIData.SlotX[i+4],REUIData.SlotY[i+4]);
  NativeItem(p.equipped>=0?p.ids[p.equipped]:0,p.equipped>=0?p.qty[p.equipped]:0,160,146);
  UIArt("portrait",22,146,30,30);
  if(p.healSweep==0)
  {
  UIArt(String.Format("ecg-%d-%d-31",p.ecgOldWave,p.ecgSecondary),84,145,48,30);
  UIArt(String.Format("ecg-%d-%d-15",p.ecgWave,p.ecgSweep),84,145,48,30);
  int cv=0;bool word=true;int status=p.ecgWave/4;
  if(status<2)
  {
   static const int thresholds0[]={3,7,33,37,43,47,73,77,80};
   static const int values0[]={0,2,1,2,0,2,1,2,0};
   static const int thresholds1[]={12,17,20,60,63,68,80};
   static const int values1[]={0,3,2,1,2,3,0};
   int n=0,t=p.ecgSweep-53;
   if(status==0){while(n<8&&t>=thresholds0[n])n++;cv=values0[n];}
   else {while(n<6&&t>=thresholds1[n])n++;cv=values1[n];}
   word=cv!=0;cv=cv*8+(status==0?48:24);
  }
  if(word)UIArt(String.Format("condition%d",cv),100,168,32,8);
  }
  else UIArt(String.Format("heal%d",p.healSweep),84,146,48,30);
  if(p.boxOpen)
  {
   // Original three-row storage window and original preview frame.
   for(int i=0;i<8;i++)UIArt(String.Format("boxpart%d",i),REUIData.BoxX[i],REUIData.BoxY[i],REUIData.BoxW[i],REUIData.BoxH[i]);
   for(int row=0;row<(p.boxSlide==0?3:4);row++)
   {
    int slot=(p.boxSelected+47+row)%48;
    NativeText(p.boxIds[slot]?p.ItemName(p.boxIds[slot]):" Nothing ",42,35-p.boxSlide+row*15,p.boxIds[slot]?"":"-gray");
   }
   NativeItem(p.boxIds[p.boxSelected],p.boxQty[p.boxSelected],92,88-p.boxSlide*2,true);
   if(p.boxSlide>0){int slot=(p.boxSelected+1)%48;NativeItem(p.boxIds[slot],p.boxQty[slot],92,118-p.boxSlide*2,true);}
   // draw_rect variant 3 forces black; source RGB112 is its fade weight,
   // not a literal gray fill. The boundary line marks the 48-slot wrap.
   if(((p.boxSelected-1)&255)>44)
    NativeDim("ffef00",1,42,49-p.boxSlide+(p.boxSelected>0?(48-p.boxSelected)*15:0),127,1);
   NativeDim("000000",112.0/255,42,34,126,15);NativeDim("000000",112.0/255,42,64,126,16);
   if(p.boxState<2){NativeDim("000000",112.0/255,42,34,126,46);NativeDim("000000",112.0/255,92,88,40,30);}
   NativeDim("000000",112.0/255,210,16,94,16);NativeDim("000000",112.0/255,210,32,47,16);
   for(int i=0;i<5;i++)NativeDim("000000",1,REUIData.MaskX[i],REUIData.MaskY[i],REUIData.MaskW[i],REUIData.MaskH[i]);
   for(int n=0;n<3;n++)UIArt("box-marker",176,33+(p.boxSelected+47+n+(p.boxDirection<0?1:0))%48,6,1);
  }
  if(p.viewerItem>0&&p.viewerMode==1)
  {
   if(p.viewerDescription)NativeMessage(p);else NativeText(p.ItemName(p.viewerItem),48,186);return;
  }
  if(p.promptKind>0)
  {
   if(p.viewerItem>0&&(p.viewerStep<64||p.viewerExiting))return;
   if(p.viewerItem>0||p.sourcePrompt)
   {
    NativeMessage(p);
    if(p.msgState==2&&(p.msgBlink&24))UIArt("code11",153,216,8,14);
    if(p.msgState==4)
    {
     NativeText("Yes  No",216,202);if(p.msgBlink&48)UIArt("arrow",p.choice==0?208:248,202,8,14);
    }
   }
   else
   {
    NativeText(p.message,48,186);
    if(p.promptKind!=2&&p.promptKind!=5)
    {
     NativeText("Yes  No",216,202);if(p.cursorBlink&48)UIArt("arrow",p.choice==0?208:248,202,8,14);
    }
   }
   if(p.menuFadeMode>0)Screen.Dim("000000",p.menuFade/32767.0,0,0,Screen.GetWidth(),Screen.GetHeight());
   return;
  }
  if(p.selected>=0&&(!p.boxOpen||p.boxState<2))
  {
   int slot=p.selected+4;
   UIArt(String.Format("cursor%d",(p.cursorBlink&32)==0?1:0),REUIData.SlotX[slot],REUIData.SlotY[slot],40,30);
  }
  if(p.actionMenu)
  {
   int amount=p.actionClosing?p.actionDelay:8-p.actionDelay;amount=clamp(amount,1,8);
   for(int i=0;i<3;i++)
   {
    int part=i==0?(p.ids[p.selected]==2?0:1):i+1;
    UIArt(String.Format("action-%s-%d-%d",p.actionClosing?"close":"open",amount,part),p.actionClosing?192-amount*6:144,(p.actionClosing?81-amount*3:57)+i*24,amount*6,amount*3);
   }
   if(p.actionDelay==0)UIArt("action4",144,57+p.actionOption*24,48,24);
  }
  if(p.selected>=0&&!p.boxOpen)NativeText(p.ItemName(p.ids[p.selected]),48,186);
  if(p.menuFadeMode>0)Screen.Dim("000000",p.menuFade/32767.0,0,0,Screen.GetWidth(),Screen.GetHeight());
 }
 ui String ItemIcon(int id)
 {
  if(id==12)return "shells";if(id==3)return "shotgun";if(id==47)return "ribbon";if(id==2)return "handgun";if(id==11)return "ammo";if(id==0x44)return "herb";
  if(id==0x47)return "herb2";if(id==0x4a)return "herb3";return "key";
 }
}
