// RE1 PC: check_typewriter 0x0041bed0, check_typewriter_state 0x0041c330,
// LoadSaveGameState 0x00493310. GZDoom file serialization stays native.
class RESavePlayer : DoomPlayer
{
 int saveState;int saveSlot;int saveChoice;int saveDelay;int saveBlink;int saveBlinkTimer;
 int saveRows[8];int saveCounter;int saveReveal;int saveRevealTimer;int saveFade;
 int saveRequest;int saveRequestSerial;int saveWriteSlot;int saveWriteCount;
 Actor activeTypewriter;
 void UseTypewriter(Actor writer)
 {
  let p=JillPlayer(self);
  if(p.health<=0||saveState>0||p.promptKind>0||p.statusOpen||p.boxOpen||p.viewerItem>0)return;
  if(!p.CanInteractWorld(writer,48))return;
  activeTypewriter=writer;
  p.BeginPrompt(p.FindItem(47)>=0?7:8,"");
 }
 void OpenTypewriterMenu()
 {
  let p=JillPlayer(self);
  if(!p.CanInteractWorld(activeTypewriter,48)||p.FindItem(47)<0)return;
  saveState=7;saveFade=0;saveSlot=0;saveChoice=0;saveDelay=0;saveBlink=0;saveBlinkTimer=5;
  for(int i=0;i<8;i++)saveRows[i]=-1;
  p.UpdateFreeze();saveRequest=1;saveRequestSerial++;
 }
 void CloseTypewriterMenu()
 {
  let p=JillPlayer(self);saveState=0;saveFade=0;activeTypewriter=null;p.UpdateFreeze();
 }
 bool ConsumeSaveRibbon()
 {
  let p=JillPlayer(self);int slot=p.FindItem(47);
  if(!p.CanInteractWorld(activeTypewriter,48)||slot<0||p.health<=0)return false;
  p.qty[slot]--;if(p.qty[slot]==0)p.RemoveSlot(slot);return true;
 }
 void TypewriterStep()
 {
  let p=JillPlayer(self);
  if(saveState==7){saveFade+=0x1000;if(saveFade>=0x10000){saveState=1;saveFade=0;}return;}
  if(saveState==6)
  {
   if(--saveRevealTimer==0){p.RESound("type-b");saveReveal++;saveRevealTimer=6;if(saveReveal>28)CloseTypewriterMenu();}return;
  }
  if(saveBlinkTimer==0){saveBlink^=1;saveBlinkTimer=5;}else saveBlinkTimer--;
  if(saveState==2)
  {
   if(!(p.rawPad&0x5000))saveDelay=0;
   if(saveDelay==0)saveState=1;else saveDelay--;return;
  }
  if(saveState==3)
  {
   if(p.pressed&0x8000){saveState=1;return;}
   if(!(p.rawPad&0x5000))saveDelay=0;
   if(saveDelay>0){saveDelay--;return;}
   if(p.rawPad&0xa000){saveChoice=(p.rawPad&0x8000)?0:1;saveDelay=6;saveBlink=0;saveBlinkTimer=5;}
   if(p.pressed&0x4000){if(saveChoice==0)CommitTypewriterSave();else saveState=1;}return;
  }
  if(p.pressed&0x8000){CloseTypewriterMenu();return;}
  if(p.rawPad&0x1000){saveSlot=(saveSlot+8)%9;p.RESound("type-a");saveState=2;saveDelay=6;saveBlink=0;saveBlinkTimer=5;}
  if(p.rawPad&0x4000){saveSlot=(saveSlot+1)%9;p.RESound("type-a");saveState=2;saveDelay=6;saveBlink=0;saveBlinkTimer=5;}
  if(p.pressed&0x4000)
  {
   if(saveSlot==8){CloseTypewriterMenu();return;}
   if(saveRows[saveSlot]>=0){saveState=3;saveChoice=0;saveBlink=1;saveDelay=0;}
   else CommitTypewriterSave();
  }
 }
 void CommitTypewriterSave()
 {
  if(!ConsumeSaveRibbon()){CloseTypewriterMenu();return;}
  // Source spends one ribbon before writing; cancellation never enters here.
  int selected=saveSlot,count=saveCounter;saveRows[selected]=count;
  let p=JillPlayer(self);saveState=0;p.UpdateFreeze();
  saveWriteSlot=selected;saveWriteCount=count;saveRequest=2;saveRequestSerial++;
  // UI bridge queues the native save after this unpaused snapshot; reveal is
  // activated by a subsequent event and is not written as an open save menu.
 }
}
class RESaveHandler : EventHandler
{
 ui int lastSaveRequest;
 ui Actor saveRequestPlayer;
 ui void ProcessSaveRequests()
 {
  let p=JillPlayer(players[consoleplayer].mo);
  if(!p)return;
  if(saveRequestPlayer!=p){saveRequestPlayer=p;lastSaveRequest=-1;}
  if(p.saveRequest==0||p.saveRequestSerial==lastSaveRequest)return;
  lastSaveRequest=p.saveRequestSerial;
  EventHandler.SendNetworkEvent("re_save_request_clear");
  let manager=SavegameManager.GetManager();manager.ReadSaveStrings();
  if(p.saveRequest==1)
  {
   for(int slot=0;slot<8;slot++)
   {
    int count=-1;String prefix=String.Format("RE1 E1M1 %d ",slot+1);
    for(int i=0;i<manager.SavegameCount();i++)
    {
     String title=manager.GetSavegame(i).SaveTitle;
     if(title.IndexOf(prefix)==0&&title.Length()>=13)count=(title.CharCodeAt(11)-48)*10+title.CharCodeAt(12)-48;
    }
    EventHandler.SendNetworkEvent("re_save_row",slot,count);
   }
   return;
  }
  if(p.saveState!=0||!p.activeTypewriter)return;
  String prefix=String.Format("RE1 E1M1 %d ",p.saveWriteSlot+1);String title=prefix..String.Format("%02d",p.saveWriteCount);
  manager.InsertNewSaveNode();int index=0;
  for(int i=1;i<manager.SavegameCount();i++)if(manager.GetSavegame(i).SaveTitle.IndexOf(prefix)==0){index=i;break;}
  manager.DoSave(index,title);manager.RemoveNewSaveNode();
  EventHandler.SendNetworkEvent("re_save_reveal",p.saveWriteSlot,p.saveWriteCount);
 }
 ui void DrawTypewriter(JillPlayer p)
 {
  let h=REHandler(self);
  if(p.saveState==7){Screen.Dim("000000",min(1.,p.saveFade/65535.),0,0,Screen.GetWidth(),Screen.GetHeight());return;}
  Screen.Dim("000000",1,0,0,Screen.GetWidth(),Screen.GetHeight());h.UIArt("typewriter",0,0,320,240);
  h.NativeText("SAVE GAME",124,13);
  for(int i=0;i<8;i++)
  {
   String row=p.saveRows[i]<0?"-----\\--\\  -----------------":String.Format("JILL \\%02d\\  HANGAR",p.saveRows[i]);
   if(p.saveState==6&&p.saveSlot==i)row=row.Left(p.saveReveal);
   h.NativeText(row,55,45+i*16);
  }
  h.NativeText("DO NOT SAVE",55,173);
  if(p.saveState==3)
  {
   h.NativeText("OK TO OVERWRITE THE DATA?",49,193,"-green");h.NativeText(" YES  NO ",118,209);
   h.UIArt("code2",47,45+p.saveSlot*16,8,14);
   if(p.saveBlink==0)h.UIArt("code2",118+p.saveChoice*40,209,8,14);
  }
  else if(p.saveState!=6&&p.saveBlink==0)h.UIArt("code2",47,45+p.saveSlot*16,8,14);
 }
}
// Native Doom save menu is deliberately unavailable during normal play.
// Console `save` is a developer bypass in the host and cannot be vetoed by
// GZDoom 4.14's EventHandler API; documented in WORLD_SAVE_FIDELITY.md.
class RETypewriterOnlyMenu : SaveMenu
{
 override void Init(Menu parent,ListMenuDescriptor desc){Super.Init(parent,desc);}
 override bool MenuEvent(int key,bool fromcontroller){if(key==MKEY_Back){Close();return true;}return true;}
 override void Ticker(){}
 override void Drawer(){Screen.Dim("000000",1,0,0,Screen.GetWidth(),Screen.GetHeight());Screen.DrawText(SmallFont,Font.CR_WHITE,20,40,"Use a typewriter to save.");}
}

// GZDoom consumes Escape in its menu responder before EventHandler.InputProcess.
// Intercept the actual MainMenu entry, render no host UI, close its pause state,
// then route exactly one event into the original RE status state machine.
class REGameplayMenuGate : ListMenu
{
 bool redirect;
 override void Init(Menu parent,ListMenuDescriptor desc)
 {
  Super.Init(parent,desc);
  redirect=!CVar.FindCVar("re_developer_menu").GetBool()&&JillPlayer(players[consoleplayer].mo)!=null;
  if(redirect){DontDim=true;DontBlur=true;}
 }
 override void Ticker()
 {
  if(!redirect){Super.Ticker();return;}
  redirect=false;Close();EventHandler.SendNetworkEvent("re_escape");
  Console.Printf("REINPUT native MainMenu redirected to RE status");
 }
 override void Drawer(){if(!redirect)Super.Drawer();}
 override bool MenuEvent(int key,bool fromcontroller){if(redirect)return true;return Super.MenuEvent(key,fromcontroller);}
}
