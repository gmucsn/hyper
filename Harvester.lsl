//Functions
integer player_number = 1; // numbered from 1 to 12
integer item_number = 1; // 1 = sphere, 2 = cube, 3 = ring

spawn()
{
    llSetLinkColor(2, <0,1,0>,ALL_SIDES);
    llSetLinkAlpha(7, 1.0,ALL_SIDES);
    count ++;
}

pick()
{
    llSetLinkColor(2, <1,0,0>, ALL_SIDES);
    llSetLinkAlpha(7, 0.0, ALL_SIDES);
}

integer ready = FALSE;
integer count;
integer poke; 

harvest(string msg)
{
    llRegionSay(MASTER, msg);
} 

string position()
{
    vector pos = llGetPos();
    string x = (string)pos.x;
    string y = (string)pos.y;
    string z = (string)pos.z;
    string location = x + "," + y + "," + z;
    return location;
}

//Communication Integers
integer GENERATE = -303003; // Used to send messages to generators.
integer MASTER = -606006; // Used for incoming messages.

default
{
    state_entry()
    {
        pick();
        ready = FALSE;
        llListen(GENERATE, "", NULL_KEY, "");
    }
    touch_start(integer total_number)
    {
        if (llVecDist(llDetectedPos(0), llGetPos()) <= 10.0 && llDetectedName(0) == "T1 CSN")
        {
            if (ready == TRUE)
            {
                string message_content = "0," +(string)player_number + "," + position() + "," + (string)item_number;
                harvest(message_content);//passes comma separated string to harvest function which communicates it to master prim for inventory update
                pick();
                ready = FALSE;
            }
            else
            {
                return;
            }
        }
        else
        {
            return;
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if (ready == FALSE && channel == GENERATE )
        {
                spawn();
                ready = TRUE;
        }
    }
}
