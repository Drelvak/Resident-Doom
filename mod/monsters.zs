// Doom monsters keep native chase, attacks, sounds and projectiles.
// All-around sight avoids slow tank turns leaving nearby monsters unaware.
class REZombie : ZombieMan replaces ZombieMan
{
 Default { DropItem "REClip", 64; }
 States { Spawn: POSS AB 10 A_LookEx(0,0,0,0,360); Loop; }
}
class RESergeant : ShotgunGuy replaces ShotgunGuy
{
 Default { DropItem "REClip", 64; }
 States { Spawn: SPOS AB 10 A_LookEx(0,0,0,0,360); Loop; }
}
class REImp : DoomImp replaces DoomImp
{
 States { Spawn: TROO AB 10 A_LookEx(0,0,0,0,360); Loop; }
}
