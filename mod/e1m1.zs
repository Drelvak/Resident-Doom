// Hand-authored Hangar zones, camera anchors and look points. Static for each zone.
class HangarCameras : Object
{
 static int Zone(Vector3 p)
 {
  // Original shotgun alcove needs its own view; the neighbouring room camera
  // cannot see through its walls. Anchor is the original medikit floor position.
  if(p.X>=3200&&p.X<3328&&p.Y> -3968&&p.Y< -3744)return 16;
  // The shotgun approach is east of the bridge wall, not in its camera room.
  if(p.X>=3328&&p.X<3520&&p.Y> -3968&&p.Y< -3800)return 34;
  if(p.X>=3328&&p.X<3520&&p.Y>= -3800&&p.Y< -3520)return 33;
  // Show the whole straight bridge corridor before/after its midpoint.
  // The old view at y=-3888 faced away from Jill on the northern approach.
  if(p.X>=2944&&p.X<=3072&&p.Y< -3616&&p.Y> -3824)return 31;
  if(p.X>=2944&&p.X<=3072&&p.Y<= -3824&&p.Y> -4016)return 32;
  if(p.Y < -4650)return 14;
  if(p.Y < -4100)return 13;
  // East secret exit: separate lower bend and upper steps. Switch only
  // after Jill clears the bend; show the native doorway at x2912.
  if(p.X>=2752&&p.X<2912&&p.Y< -3776&&p.Y> -3904)return 29;
  if(p.X>=2536&&p.X<2752&&p.Y< -3776&&p.Y> -3968)return 30;
  // Secret entrance bends around sectors80/79 before the stairs. Each leg
  // has its own in-sector camera rather than looking through the corner wall.
  if(p.Z< -80&&p.X>=2368&&p.X<2688&&p.Y< -3770&&p.Y> -4100)return 27;
  if(p.Z< -80&&p.X>=2240&&p.X<2368&&p.Y< -3968&&p.Y> -4100)return 28;
  // Secret stairs/corridor: anchors fit their actual low ceilings.
  if(p.X>=2048&&p.X<=2240&&p.Y< -3890&&p.Y> -4096)return 24;
  if(p.X>=2048&&p.X<=2176&&p.Y< -3680&&p.Y>= -3890)return 23;
  if(p.X>=1376&&p.X<2048&&p.Y< -3648&&p.Y> -3776)return 22;
  if(p.X>=2048&&p.X<=2240&&p.Y< -3648&&p.Y> -3776)return 25;
  if(p.Z< -40&&p.X>1376&&p.X<2688&&p.Y>= -3648&&p.Y< -2912)return 26;
  if(p.Y < -3770)return p.X<2480?11:12;
  // Window sector45 is x[-336,-320], y[-3296,-3168]. Keep the
  // interior pedestal view through the entire herb interaction (x=-224).
  if(p.X< -336)return 21;
  if(p.X<= -320&&p.X>= -336&&p.Y> -3296&&p.Y< -3168&&p.Z>=132)return 9;
  if(p.X < 128)return 7;
  if(p.X < 650)return 6;
  if(p.X>=2448&&p.Y> -2800&&p.Y< -2536)return 19;
  if(p.X>1408&&p.X<=1640&&p.Y> -2776)return 18;
  if(p.Y > -2750 && p.X>1600)return (p.X>2288&&p.Y<-2608)||p.X>2336?17:4;
  if(p.Y > -2912 && p.X<1640)return 3;
  if(p.X<1344)return p.Y<-3370?0:1;
  if(p.X<2060)return 2;
  if(p.X<2688)return 5;
  if(p.Y<= -3072&&p.Y> -3600)return 20;
  if(p.Y>-3072)return 10;
  return 15;
 }
 static Vector3 Anchor(int zone)
 {
  switch(zone)
  {
   case 0:return (928,-3500,88);case 1:return (1264,-2950,116);
   case 2:return (1420,-3580,112);case 3:return (1230,-2780,100);
   case 4:return (1680,-2416,88);case 5:return (2460,-3580,112);
   case 6:return (624,-3216,96);case 7:return (-112,-3160,232);
   case 8:return (-680,-2890,112);case 9:return (-600,-3232,184);
   case 10:return (3024,-2912,116);case 11:return (2110,-3870,96);
   case 12:return (3008,-3888,120);case 13:return (2752,-4480,40);
   case 31:return (3008,-3976,144);case 32:return (3008,-3640,136);
   case 33:return (3456,-3840,88);case 34:return (3464,-3672,88);
   case 17:return (2208,-2720,112);
   case 18:return (1408,-2504,72);case 19:return (2352,-2520,96);
   case 20:return (2784,-3032,152);
   case 21:return (-720,-3536,176);
   case 22:return (2000,-3720,16);case 23:return (2112,-3708,4);
   case 24:return (2176,-4048,-64);case 25:return (2144,-3744,4);
   case 26:return (2608,-3568,176);
   case 29:return (2720,-3810,32);case 30:return (2496,-3896,-56);
   case 27:return (2416,-4032,-64);case 28:return (2400,-4032,-64);
   case 14:return (2992,-4688,64);case 16:return (3232,-3808,96);default:return (3008,-3536,128);
  }
 }
 static Vector3 Look(int zone)
 {
  switch(zone)
  {
   case 0:return (1080,-3550,26);case 1:return (1060,-3310,28);
   case 2:return (1810,-3300,28);case 3:return (1410,-2540,28);
   case 4:return (2208,-2432,16);case 5:return (2180,-3300,28);
   case 6:return (288,-3232,68);case 7:return (-224,-3232,150);
   case 8:return (-260,-3100,28);case 9:return (-224,-3232,150);
   case 10:return (2800,-2856,0);case 11:return (2310,-3840,28);
   case 12:return (2976,-4096,8);case 13:return (3008,-4310,4);
   case 31:return (3008,-3656,0);case 32:return (3008,-4000,0);
   case 33:return (3384,-3640,-16);case 34:return (3312,-3860,-16);
   case 17:return (2496,-2512,28);
   case 18:return (1576,-2552,32);case 19:return (2592,-2640,20);
   case 20:return (3096,-3328,-8);
   case 21:return (-480,-3296,24);
   case 22:return (1656,-3700,-32);case 23:return (2112,-3860,-104);
   case 24:return (2108,-3888,-88);case 25:return (2000,-3720,-32);
   case 26:return (2200,-3264,-24);
   case 29:return (2904,-3840,0);case 30:return (2696,-3840,-84);
   case 27:return (2472,-3944,-104);case 28:return (2200,-4024,-104);
   case 14:return (3008,-4816,0);case 16:return (3264,-3936,2);default:return (2992,-3680,8);
  }
 }
}
