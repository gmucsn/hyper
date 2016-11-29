// Hyper HUD tree.0

// Working Notes
// 11.29
// - player number has to be declared by the masterbox, according to the position in the player-key list. 1-9 players, 10-12 gov't
// - target_coord also can't be hard coded in the HUD script - needs to be received from master
// - for the teleport: have a list of the teleport vectors, in the order of the player numbers, then after the key list is shuffled, they will correspond with the player number.
// - DECIDED: 4 periods non-government

integer player = 1;

// Teleport
vector sim_coord;      // global coordinates for this sim
vector target_coord = <69.977379, 91.265106,22.053162>;  // global coordinates for teleport - need to receive this fomr the master box
string RLV_coord;      // coordinates in RLV format for teleport

// DO NOT CHANGE BELOW THIS LINE
integer running = TRUE;
// Link Variables

list temporary_list = []; // Clear list for memory purposes.
integer message_type;

// Input Buttons - Is there a way to generalize this? i.e. having these generate via the HUD initiation itself
integer button_1 = 10;
integer button_2 = 11;
integer button_3 = 12;
integer button_4 = 13;
integer button_5 = 14;
integer button_6 = 15;
integer button_7 = 16;
integer button_8 = 17;
integer button_9 = 18;
integer button_0 = 19;
integer button_clear = 23;
integer button_submit = 24;

//Inventory
integer quantity_sphere = 32;
integer quantity_cube = 31;
integer quantity_ring = 33;

//Market Selectors
integer buy_sphere = 30;
integer sell_sphere = 29;
integer buy_cube = 23;
integer sell_cube = 25;
integer buy_ring = 24;
integer sell_ring = 28;

//Market Prices
integer bid_sphere = 27;
integer ask_sphere = 26;
integer bid_cube = 20;
integer ask_cube = 21;
integer bid_ring = 22;
integer ask_ring = 34;

// Text Displays
integer time_disp = 4;
integer input_disp = 6;
integer market_disp = 5;
integer token_disp = 7;
integer point_disp = 3;
integer message_disp = 2;

//Communication Variables
integer EXP_CONTROL;
integer TO_MASTER = -606006;
integer HUD_MESSAGES = -909009; //HUD debug channel.

// Inventory Variables
list inv_array = []; // Master inventory array.
integer inv1;
integer inv2;
integer inv3;
integer tokens;
float points;

// Market Variables
integer market = 0; // 1 = Buy Sphere, -1 = Sell Sphere, etc.
integer item1bid; // Standing bid for good 1.
integer item1bidder; // Standing bidder for good 1.
integer item1ask; // Standing ask for good 1.
integer item1asker; // Standing asker for good 1.
integer item2bid; // Standing bid for good 2.
integer item2bidder; // Standing bidder for good 2.
integer item2ask; // Standing ask for good 2.
integer item2asker; // Standing asker for good 2.
integer item3bid; // Standing bid for good 3.
integer item3bidder; // Standing bidder for good 3.
integer item3ask; // Standing ask for good 3.
integer item3asker; // Standing asker for good 3.
list standing_agents; //List of standing agents.

//Input Values for Prices - Each of the letters corresponds to a character in the price that is input
string a = "";
string b = "";
string c = "";
string d = "";
string e = "";
string f = "";
string g = "";
string h = "";
string i = "";

//Functions
teleport_agent(vector destination)
{
    llSay(0,"Teleporting...");
    target_coord = sim_coord + destination;   
    RLV_coord = (string)((integer)target_coord.x) + "/" +
    (string)((integer)target_coord.y) + "/" +
    (string)((integer)target_coord.z);
    llOwnerSay("@tpto:" + RLV_coord + "=force");    
}

hud_message (integer display_msg)
{
    string blank = "";
    //ERRORS
    string message_1 = "Bids must be higher than the standing bid.";
    string message_2 = "Asks must be lower than the standing ask.";
    string message_3 = "You have a standing bid in another market.";
    string message_4 = "You have a standing ask in another market";
    string message_5 = "You do not have enough credits to make that bid.";
    string message_6 = "You do not have enough of this good to sell.";
	
    //ALERTS
    string message_7 = "Your Sphere purchase was successful!";
    string message_8 = "Your Cube purchase was successful!";
    string message_9 = "Your Ring purchase was successful!";
    string message_10 = "Your Sphere sale was successful!";
    string message_11 = "Your Cube sale was successful!";
    string message_12 = "Your Ring sale was successful!";
	
    //GOV'T
    string message_13 = "Thank you. - G";
	
    //TRAINING
    string message_14 = "Harvest an item from your generator.";
    string message_15 = "Now, place a bid for a cube.";
    string message_16 = "Submit an ask of 10 for a ring.";
	
    //EXPERIMENT START/END
    string message_17 = "The experiment has begun.";
    string message_18 = "The experiment has ended.";
	
    //ERROR OVERFLOW
    string message_19 = "You have the standing ask in this market.";
    string message_20 = "You have the standing bid in this market.";
    
    if(display_msg==0)
    {
        update_str(message_disp,blank);
        llSetTimerEvent(0.0);
    }
    else if(display_msg == 1)
    {
        update_str(message_disp, message_1);
    }
    else if(display_msg == 2)
    {
        update_str(message_disp, message_2);
    }
    else if(display_msg == 3)
    {
        update_str(message_disp, message_3);
    }
    else if(display_msg == 4)
    {
        update_str(message_disp, message_4);
    }
    else if(display_msg == 5)
    {
        update_str(message_disp, message_5);
    }
    else if(display_msg == 6)
    {
        update_str(message_disp, message_6);
    }
    else if(display_msg == 7)
    {
        update_str(message_disp, message_7);
    }
    else if(display_msg == 8)
    {
        update_str(message_disp, message_8);
    }
    else if(display_msg == 9)
    {
        update_str(message_disp, message_9);
    }
    else if(display_msg == 10)
    {
        update_str(message_disp, message_10);
    }
    else if(display_msg == 11)
    {
       update_str(message_disp, message_11);
    }
    else if(display_msg == 12)
    {
        update_str(message_disp, message_12);
    }
    else if(display_msg == 13)
    {
        update_str(message_disp, message_13);
    }
    else if(display_msg == 19)
    {
        update_str(message_disp, message_19);
    }
    else if(display_msg == 20)
    {
        update_str(message_disp, message_20);
    }
    else if(display_msg == -3)
    {
       update_str(message_disp, message_17);
    }
    else if(display_msg == -4)
    {
       update_str(message_disp, message_18);
    }
    else if(display_msg == -11)
    {
       update_str(message_disp, message_14);
    }
    else if(display_msg == -12)
    {
        update_str(message_disp, message_15);
    }
    else if(display_msg == -13)
    {
        update_str(message_disp, message_16);
    }
    else
    {
        return;
    }
}

//Pseudo-Array Index Search
integer get_index(integer player, integer item) //function to get inventory item from pseudo array
{
    integer index = (player)*5 + item - 1;
    return index;
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

string format(float number, integer precision)
{    
    float roundingValue = llPow(10, -precision)*0.5;
    float rounded;
    if (number < 0) rounded = number - roundingValue;
    else            rounded = number + roundingValue;
 
    if (precision < 1) // Rounding integer value
    {
        integer intRounding = (integer)llPow(10, -precision);
        rounded = (integer)rounded/intRounding*intRounding;
        precision = -1; // Don't truncate integer value
    }
 
    string strNumber = (string)rounded;
    return llGetSubString(strNumber, 0, llSubStringIndex(strNumber, ".") + precision);
}

//Inventory List
inv_update(list info)
{
    inv1 = llList2Integer(info,get_index(player,1));
    inv2 = llList2Integer(info,get_index(player,2));
    inv3 = llList2Integer(info,get_index(player,3));
    tokens = llList2Integer(info,get_index(player,4));
    points = llList2Float(info,get_index(player,5));
    update_num(quantity_sphere, inv1);
    update_num(quantity_cube, inv2);
    update_num(quantity_ring, inv3);
    update_num(token_disp, tokens);
    update_str(point_disp, "$" + format(points, 2));
}

// Market Lists
price_info (list market_info) // produces a list of standing prices
{
    item1bid = llList2Integer(market_info,0);
    item1ask = llList2Integer(market_info,2);
    item2bid = llList2Integer(market_info,4);
    item2ask = llList2Integer(market_info,6);
    item3bid = llList2Integer(market_info,8);
    item3ask = llList2Integer(market_info,10);
    // Text Updates
    update_num(bid_sphere, item1bid);
    update_num(ask_sphere, item1ask);
    update_num(bid_cube, item2bid);
    update_num(ask_cube, item2ask);
    update_num(bid_ring, item3bid);
    update_num(ask_ring, item3ask);
}

standing_indicator (list agents)
{
    standing_agents = agents;
    if ( llList2Integer(standing_agents, 0) != player)
    {
        llSetLinkPrimitiveParamsFast (buy_sphere, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
    }
    else if ( llList2Integer(standing_agents, 0) == player)
    {
        llSetLinkPrimitiveParamsFast (buy_sphere, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.5]);
    }
    if ( llList2Integer(standing_agents, 1) !=  player)
    {
        llSetLinkPrimitiveParamsFast (sell_sphere, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
    }
    else if ( llList2Integer(standing_agents, 1)  == player)
    {
        llSetLinkPrimitiveParamsFast (sell_sphere, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.5]);
    }
    if ( llList2Integer(standing_agents, 2)  != player)
    {
        llSetLinkPrimitiveParamsFast (buy_cube, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
    }
    else if ( llList2Integer(standing_agents, 2)  == player)
    {
        llSetLinkPrimitiveParamsFast (buy_cube, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.5]);
    }
    if ( llList2Integer(standing_agents, 3)  != player)
    {
        llSetLinkPrimitiveParamsFast ( sell_cube, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
    }
    else if ( llList2Integer(standing_agents, 3)  == player)
    {
        llSetLinkPrimitiveParamsFast (sell_cube, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.5]);
    }
    if (llList2Integer(standing_agents, 4) != player)
    {
        llSetLinkPrimitiveParamsFast (buy_ring, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
    }
    else if ( llList2Integer(standing_agents, 4)  == player)
    {
        llSetLinkPrimitiveParamsFast (buy_ring, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.5]);
    }
    if ( llList2Integer(standing_agents,5)  != player)
    {
        llSetLinkPrimitiveParamsFast (sell_ring, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0]);
    }
    else if ( llList2Integer(standing_agents,5)  == player)
    {
        llSetLinkPrimitiveParamsFast (sell_ring, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.5]);
    }
}

list agent_info (list market) // produces a list of standing buyers and sellers. 
{
    item1bidder = llList2Integer(market,1);
    item1asker = llList2Integer(market,3);
    item2bidder = llList2Integer(market,5);
    item2asker = llList2Integer(market,7);
    item3bidder = llList2Integer(market,9);
    item3asker = llList2Integer(market,11);
    list agent_list = [item1bidder, item1asker, item2bidder, item2asker, item3bidder, item3asker];
    return agent_list;
}

update_num(integer link, integer update) //this only works for integers now
{  
    llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, (string)update, <0,0,0>, 1.0]);    
}

update_str(integer link, string update) //this only works for integers now
{  
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXT, update, <0,0,0>, 1.0]); 
}

//Market Interface Functions
clear () // clears the HUD displays
{
    a = "";
    b = "";
    c = "";
    d = "";
    e = "";
    f = "";
    g = "";
    h = "";
    i = "";
    llSetLinkPrimitiveParamsFast(input_disp,[PRIM_TEXT, "0", <0.0,0.0,0.0>, 1.0]);
}

display ()
{
    string price = a + b + c + d + e + f + g + h + i;
    integer num = (integer)price;
    llSetLinkPrimitiveParamsFast(input_disp,[PRIM_TEXT, (string)num, <0.0,0.0,0.0>, 1.0]);
}

display_market (integer link, integer mkt)
{
    if (mkt == 0)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "...", <0.0,0.0,0.0>, 1.0]);
    }
    if (mkt == 1)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "Buy Sphere", <0.0,0.0,1.0>, 1.0]);
    }
    else if (mkt == -1)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "Sell Sphere", <0.0,0.0,1.0>, 1.0]);
    }
    else if (mkt == 2)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "Buy Cube", <1.0,0.0,0.0>, 1.0]);
    }
    else if (mkt == -2)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "Sell Cube", <1.0,0.0,0.0>, 1.0]);
    }
    else if (mkt == 3)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "Buy Ring", <0.0,1.0,0.0>, 1.0]);
    }
    else if (mkt == -3)
    {
        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXT, "Sell Ring", <0.0,1.0,0.0>, 1.0]);
    }
}

string input(integer button) // Converts a click on the HUD to a string number.
{
    if (button == button_1)
    {
        return "1";
    }
    else if (button == button_2)
    {
        return "2";
    }
    else if (button == button_3)
    {
        return "3";
    }
    else if (button == button_4)
    {
        return "4";
    }
    else if (button == button_5)
    {
        return "5";
    }
    else if (button == button_6)
    {
        return "6";
    }
    else if (button == button_7)
    {
        return "7";
    }
    else if (button == button_8)
    {
        return "8";
    }
    else if (button == button_9)
    {
        return "9";
    }
    else if (button == button_0)
    {
        return "0";
    }
    else
    {
        return "";
    }
}

submit()
{
    if (market != 0)
    {
        if (market > 0)
        {
            string price = a + b + c + d + e + f + g + h + i;
            if (price != "")
            {
                integer i_price = (integer)price;
                if(i_price != 0)
                {
                    llRegionSay(TO_MASTER, "1," + (string)player + "," + position() + "," + (string)market + "," + price);
                    market = 0;
                    display_market(market_disp, market);
                    clear();
                }
            }
        }
        else if (market < 0)
        {
            string price = a + b + c + d + e + f + g + h + i;
            if (price != "")
            {
                market = market * -1;
                integer i_price = (integer)price;
                if (i_price != 0)
                {
                    llRegionSay(TO_MASTER, "2," + (string)player + "," + position() + "," + (string)market + "," + price);
                    market = 0;
                    display_market(market_disp, market);
                    clear();
                }
            }
        }
    }
}

// HUD Script
default
{
    state_entry()
    {
        llListen(HUD_MESSAGES,"",NULL_KEY,"");
        llListen(0,"",llGetOwner(),"");
        sim_coord = llGetRegionCorner();  //SW corner coordinates for this sim
        running = FALSE;
        clear();
        display_market(market_disp, market);
    }
    attach(key id)
    {
        llSetLinkPrimitiveParamsFast(-1,[PRIM_TEXT, "", <0.0,0.0,0.0>, 0.0]);
        //llSay(0,position());
    }
    listen(integer channel, string name, key id, string message)
    {
        if (channel == HUD_MESSAGES)
        {
            temporary_list = []; // Clear list for memory purposes.
            temporary_list = llCSV2List(message);
            message_type = llList2Integer(temporary_list, 0); // First position in the message is the message type.
            temporary_list = llDeleteSubList(temporary_list, 0, 0); // Removes the message type for message processing.
            if(message_type == -1)
            {
                inv_array = temporary_list;
                inv_update(inv_array);
            }
            else if(message_type == -2)
            {
                price_info(temporary_list);      
                standing_indicator(agent_info(temporary_list));
            }
            else if(message_type == -3)
            {
                hud_message(message_type);
                running = TRUE;
            }
            else if(message_type == -4)
            {
                hud_message(message_type);
                llResetScript();
            }
            else if(message_type == -99)
            {
                teleport_agent(target_coord); // needs to be passed the 
            }
            else if (llList2Integer(temporary_list, 0) == player || llList2Integer(temporary_list, 0) == 0) // Checks to see if the player number index is equal to the player's number, or 0 (all players)
            {
                hud_message(message_type);
                llSetTimerEvent(10.0);
            }
        }
        else if(channel == 0)
        {
            llRegionSay(TO_MASTER, "-100," + (string)player + "," + position() + "," + message);
        }
    }
    timer()
    {
        hud_message(0);
    }
    touch_start(integer number)
    {
        integer j = llDetectedLinkNumber(0);
        string name = llGetLinkName(j);
        if (name == "Clear")// Clear Button
        {
            clear();
        }
        else if (name == "Submit") // Submit Button 
        {
            submit();
        }
        else if (name == "Sphere Buy") // Sphere Bid
        {
            market = 1;
            display_market(market_disp, market);
        }
        else if (name == "Sphere Sell") // Sphere Ask
        {
            market = -1;
            display_market(market_disp, market);
        }
        else if (name == "Cube Buy") // Cube Bid
        {
            market = 2;
            display_market(market_disp, market);
        }
        else if (name == "Cube Sell") // Cube Ask
        {
            market = -2;
            display_market(market_disp, market);
        }
        else if (name == "Ring Buy") // Ring Bid
        {
            market = 3;
            display_market(market_disp, market);
        }
        else if (name == "Ring Sell") // Ring Ask
        {
            market = -3;
            display_market(market_disp, market);
        }
        else
        {
            if(a == "")
            {
                a = input(j);
                display();
            }
            else if(b == "")
            {
                b = input(j);
                display();
            }
            else if(c == "")
            {
                c = input(j);
                display();
            }
            else if(d == "")
            {
                d = input(j);
                display();
            }
            else if(e == "")
            {
                e = input(j);
                display();
            }
            else if(f == "")
            {
                f = input(j);
                display();
            }
            else if(g == "")
            {
                g = input(j);
                display();
            }
            else if(h == "")
            {
                h = input(j);
                display();
            }
            else if(i == "")
            {
                i = input(j);
                display();
            }
            else
            {
            }
        }
    }  
}