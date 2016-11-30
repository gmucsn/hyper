// Hyperinflation ver.three-P-0

// Working Notes
// 11.29 
// - New working copy made
// - Non-working training state removed for brevity
// - Need to include 3 extra players for the government. global government boolean to trigger government players
// - Remove gov't bot? - removed: if needed, refer to the previous version
// - With no government, should player 1 now be player index 0? - seems like an obvious yes, but debugging the dependencies will be a bitch...
// 11.30
// - Contract function updated for the human-government using boolean government_buyer connected to buyer_number

// Authorized users
list ADMIN_LIST = ["Chris CSN15", "Chris CSN 00", "Bob BobCSN00","Kevin McCabe", "Kathleen CSN00", "Peter Twieg"]; //List of Admin Users for verification.

// Notecard Read
list treatment_list = []; // list of different treatments, populated on state_entry
string notecard_name; // treatment name
integer treatment_line = 0; // line of the notecard
key treatment_id; // query id for notecard

// Set by notecard read - see the dataserver event at end of default state
string treatment_name; // Line 0 - Name of the treatment
integer players; // Line 1 - Number of players
float govt_buy_prob; // Line 2 - Probability of a government purchase.
float govt_buy_range; // Line 3 - Percentage range of government purchase amount.
float timer_length = 0.0; // Line 4 - Length of timer cycle in seconds.
integer generate_frequency; // Line 5 - When timer cycle = gen_cycle, then a generate message is sent to harvesters.
integer initial_good_1; // Line 6 - Initial endowment of good 1.
integer initial_good_2; // Line 7 - Initial endowment of good 2.
integer initial_good_3; // Line 8 - Initial endowment of good 3.
integer initial_tokens; // Line 9 - Initial endowment of cash.
float exchange_rate; // Line 10 - Multiplier for Utility Scores.
list utility_list = []; // Line 11 - List of theta values for every player, [0.33,0.33,0.33] is the current standard

// Recording variables
key admin = NULL_KEY; // Establishes the key of avatar running the experiment.
integer money_supply; // Total amount of tokens in the experiment.
integer gov_buys; // Total number of gov't purchases.
integer timer_cylce; // Counter for timer cylce. Incremented by 1 after each timer event.

// Boolean Values for experiment phase.
integer training = FALSE; // Set to true when the training session is intitiated. 
integer running = FALSE; // Set to TRUE when the experimental session is initiated.
integer treatment = FALSE; // Set to TRUE after treatment is defined.

// Communication Variables
integer EXP_CONTROL = -101001; // Channel for Masterbox Commands
integer HUD_COMM = -909009; // Used to send messages to player HUDs.
integer GENERATE = -303003; // Used to send messages to generators.
integer RECEIVER = -606006; // Used for incoming messages.
integer MARKET_ANNOUNCE = 505005; // Used to send Market information to HUDs.

//Market Variables
// Here we use a 2D pseudo array for player inventories. 
// For players 0 to n, where 0 is the governent, and n is the total nubmer of players. 
// Player n quantitiy good 1, player n quantitiy good 2, player n quantitiy good 3, player n quantity tokens, player n utility ... so on, so forth.
list inventory_list = []; 


// Holding variables for populating the inventories - updated in the data server event.
integer quantity_good_1; // Holding quantities.
integer quantity_good_2;
integer quantity_good_3;
integer gov_quantity_good_1; // Holding quantities for gov't.
integer gov_quantity_good_2;
integer gov_quantity_good_3;
integer gov_token_amount;
integer GOOD_1_INDEX = 1; // Index position in inventory list.
integer GOOD_2_INDEX = 2; // Index position in inventory list.
integer GOOD_3_INDEX = 3; // Index position in inventory list.
integer TOKEN_INDEX = 4; // Index position of tokens in inventory list.
integer UTILITY_INDEX = 5; // Index position of utility in inventory list.
float new_utility; // Holding value to update utility in inventory list.

list market_list = [0,0,0,0,0,0,0,0,0,0,0,0]; // Indexes as follows: standing bid, standing bidder, standing ask, standing asker for all 3 goods.
integer standing_bid_good_1 = 0;
integer standing_bidder_good_1 = 0;
integer standing_ask_good_1 = 0;
integer standing_asker_good_1 = 0;
integer standing_bid_good_2 = 0;
integer standing_bidder_good_2 = 0;
integer standing_ask_good_2 = 0;
integer standing_asker_good_2 = 0;
integer standing_bid_good_3 = 0;
integer standing_bidder_good_3 = 0;
integer standing_ask_good_3 = 0;
integer standing_asker_good_3 = 0;

integer max_price = 0; // highest price of a contract

integer initial_utility = 0; // holding value of 0 for the inventory construction.
integer utility_search_index; // Stride value for utility list search.
float theta1; // Theta value 1 for the utility function.
float theta2; // Theta value 2 for the utility function.
float theta3; // Theta value 3 for the utility function.
float t1;
float t2;
float t3;
float tSum;
float U;

//Listen Control
integer message_type; // Used as a controller of how received messages are handled. 
list temporary_list; // temporary list with the message type handle removed.

// Bid / Ask Variables
integer bidder; // temporary value for player numbers submitting bids. 
integer bid_item; // temporary value for bid items
integer bid_price; // temporary value for bid prices
integer asker; // temporary value for player numbers submitting asks
integer ask_item; // temporary value for ask items.
integer ask_price; // temporary value for ask prices

//Contract Variables
integer price; // Price that the contract is made for.
integer buyer_quantity; // Quantity of the item that the buyer holds.
integer seller_quantity; // Quantity of the item that the seller holds.
integer buyer_tokens; // Quantity of tokens that the buyer holds.
integer seller_tokens; // Quantity of tokens that theseller holds.

//Harvest Variables
integer timer_cycle; // timer cycle for periodic events.
integer harvester; // Player number of the harvester
integer harvest_item; // Good number of the item being harvested.
integer harvest_index; // 
integer harvest_quantity; // Quantity of the item that the player is harvesting.

// Functions
treatments() // Generates a list of treatments from parameter files. 
{
    treatment_list = [];
    integer i = llGetInventoryNumber(INVENTORY_NOTECARD);
    string file_name;
    while(i--)
    {
        file_name = llGetInventoryName(INVENTORY_NOTECARD,i);
        treatment_list += file_name;
    }
    llSay(0, llList2CSV(treatment_list));
}

hud_message(integer message_type, integer player_number) // Sends messages to player HUDs
{
    // If player number is -99, it is a teleport message
    // If player number is -3, it is a start message
    // If player number is -4, it is an end.
    // If player number is -1, it is an inventory update.
    // If player number is -2, it is a market update.
    // If player number is 0 the message is sent to all players.
    // Message type 1 is ___ ***INCLUDE MESSAGE CONTENT IN COMMENT***
    if(message_type == -1)
    {
        llRegionSay(HUD_COMM, (string)message_type + "," + llList2CSV(inventory_list));
    }
    else if(message_type == -2)
    {
        llRegionSay(HUD_COMM, (string)message_type + "," + llList2CSV(market_list));
    }
    else
    {
        llRegionSay(HUD_COMM, (string)message_type + "," + (string)player_number);
    }
}

experiment_toggle(integer experiment_state) // Turns the experiment on and off.
{
    if(experiment_state == 0) // Experiment set to "off"
    {
        running = FALSE;
        treatment = FALSE;
        hud_message(-4, 0);
        llSetTimerEvent(0.0); // Turns the timer off
        announce_market();
        announce_inventory();
        market_reset();
        record(2, ""); // record end message.
    }
    else if(experiment_state == 1)
    {
        running = TRUE;
        hud_message(-99, 0);
        record(1, ""); // record start message.
        build_inventory();
        hud_message(-3, 0);
        announce_inventory();
        announce_market();
        generate();
        llSetTimerEvent(timer_length);
        llSay(0, "Experiment start.");
    }
}

record(integer record_type, string record_message) // Sends information to the recorder.
{
    if(record_type == 0) // Inventory record.
    {
        llMessageLinked(LINK_THIS,record_type,"INVENTORY," + record_message,""); // See list inv_list for the format.
    }
    else if(record_type == 1) // Start record.
    {
        llMessageLinked(LINK_THIS,record_type,"START," + "Treatment: " + treatment_name +", Subjects: " + (string)players + ", Government Buy Probability: " + (string)govt_buy_prob + ", Endowment Good 1: " + (string)initial_good_1 + ", Endowment Good 2: " + (string)initial_good_2 + ", Endowment Good 3: " + (string)initial_good_3 + ", Initial Tokens: " + (string)initial_tokens + ", Exchange Rate: " + (string)exchange_rate + ", Utility Function Coefficients: " + llList2CSV(utility_list),"");
    }
    else if(record_type == 2) // End record.
    {
        llMessageLinked(LINK_THIS,record_type,"END","");
    }
    else if(record_type == 3) // Bid record: Player, Position X, Position Y, Position Z, Good Number, Bid Price.
    {
        llMessageLinked(LINK_THIS,record_type,"BID," + record_message,"");
    }
    else if(record_type == 4) // Ask record: Player, Position X, Position Y, Position Z, Good Number, Ask Price.
    {
        llMessageLinked(LINK_THIS,record_type,"ASK," + record_message,"");
    }
    else if(record_type == 5) // Contract record: Buyer Player Number, Seller Player Number, Good Number, Price.
    {
        llMessageLinked(LINK_THIS,record_type,"CONTRACT," + record_message, "");
    }
    else if(record_type == 6) // Barter record: Buyer Player Number, Seller Player Number, Good Number, Price.   ***BARTER OFFER???***
    {
        llMessageLinked(LINK_THIS,record_type,"CONTRACT," + record_message, "");
    }
    else if(record_type == 7) // Harvest record: Player Number, Position X, Position Y, Position Z, Item Number
    {
        llMessageLinked(LINK_THIS,record_type,"HARVEST," + record_message, "");
    }
    else if(record_type == 8) // Market record
    {
        llMessageLinked(LINK_THIS,record_type,"MARKET," + record_message, ""); // See list market_list for the format.
    }
    else if(record_type == 9) // Market record
    {
        llMessageLinked(LINK_THIS,record_type,"MONEY," + record_message + "," + (string)money_supply + "," + (string)gov_buys,""); // See list market_list for the format.
    }
    else if(record_type == 11)
    {
        llMessageLinked(LINK_THIS,record_type,"TEXT," + record_message, "");
    }
    else if(record_type == 12)
    {
        llMessageLinked(LINK_THIS, record_type, "GENERATE," + record_message, "");
    }
    else // Improper record_type
    {
        llMessageLinked(LINK_THIS, 0, "UNIDENTIFIED," + record_message, "");
    }
}

integer get_index(integer player_number, integer item_number) //function to get index position of an item in the inventory_list
{
    if(player_number == 0)
    {
        integer index = item_number - 1;
        return index;
    }
    else
    {
        integer index = (player_number) * 5 + item_number - 1;
        return index;
    }
}

build_inventory() // Constructs the inventory pseudo-array
{
    inventory_list = [];
    integer items = 5; //the number of items in each player's inventory = 3 goods + cash + utils
    integer i;
    for (i = 0; i <= players ; ++i) //creates initial inventory for 12 players plus government
    {
        inventory_list += initial_good_1;
        inventory_list += initial_good_2;
        inventory_list += initial_good_3;
        inventory_list += initial_tokens;
        inventory_list += initial_utility;
    }
    money_supply = llList2Integer(inventory_list, TOKEN_INDEX) * players;
}

announce_inventory()
{
    integer a = 0;
    for(a; a <= players; ++a) // Update utilities before announcing market
    {
        quantity_good_1 = llList2Integer(inventory_list, get_index(a,1));
        quantity_good_2 = llList2Integer(inventory_list, get_index(a,2));
        quantity_good_3 = llList2Integer(inventory_list, get_index(a,3));
        new_utility = CobbDouglas(a, quantity_good_1, quantity_good_2, quantity_good_3);
        inventory_list = llListReplaceList(inventory_list, new_utility, get_index(a, 5), get_index(a, 5));
    }
    record(0, llList2CSV(inventory_list)); // 0 is the inventory record toggle.
    hud_message(-1,0);
}

announce_market()
{
    market_list = [standing_bid_good_1, standing_bidder_good_1,
					standing_ask_good_1, standing_asker_good_1,
					standing_bid_good_2,standing_bidder_good_2,
					standing_ask_good_2,standing_asker_good_2,
					standing_bid_good_3,standing_bidder_good_3,
					standing_ask_good_3,standing_asker_good_3];
					
    record(8, llList2CSV(market_list)); // 8 is the market record toggle.
    hud_message(-2,0); // Sends updated market information to the player HUDs.
}

market_reset() // returns market values to 0
{
    max_price = 0;
    money_supply = 0;
    standing_bid_good_1 = 0;
    standing_bidder_good_1 = 0;
    standing_ask_good_1 = 0;
    standing_asker_good_1 = 0;
    standing_bid_good_2 = 0;
    standing_bidder_good_2 = 0;
    standing_ask_good_2 = 0;
    standing_asker_good_2 = 0;
    standing_bid_good_3 = 0;
    standing_bidder_good_3 = 0;
    standing_ask_good_3 = 0;
    standing_asker_good_3 = 0;
}

float CobbDouglas(integer player_number, integer good_1, integer good_2, integer good_3) // For subject earnings
{
	// Cobb-Douglas Utility Function  U = exchange_rate * ( num1 ^ theta * num2 ^ theta) * num3 ^ theta
    utility_search_index = player_number * 3;
    theta1 = llList2Float(utility_list, utility_search_index);
    theta2 = llList2Float(utility_list, utility_search_index + 1);
    theta3 = llList2Float(utility_list, utility_search_index + 2);
    t1 = llPow(good_1, theta1);
    t2 = llPow(good_2, theta2);
    t3 = llPow(good_3, theta3);
    tSum = t1 * t2 * t3;
    U = exchange_rate * tSum;
    return U;
}

generate()
{
    if(timer_cycle == generate_frequency)
    {
        llRegionSay(GENERATE, "1"); // Sends the generate message to the generators.
        record(12, "");
        timer_cycle = 0; // Resets the timer cycle.
    }
    else
    {
        timer_cycle++; // Put in timer event?
    }
}

harvest(list harvest_list)
{
    harvester = llList2Integer(harvest_list, 0); // Player number of the harvester
    // index positions 1,2, and 3 are position values.
    harvest_item = llList2Integer(harvest_list, 4); // Good number of the item being harvested.
    harvest_index = get_index(harvester, harvest_item); // index value of the 
    harvest_quantity = llList2Integer(inventory_list, harvest_index); // Quantity of the item that the player is harvesting.
    harvest_quantity++; // increases the player's quantitiy by 1.
    inventory_list = llListReplaceList(inventory_list,(list)harvest_quantity,harvest_index,harvest_index); // Replaces the item quantity with the updated quantity.
    record(7,llList2CSV(harvest_list));
    announce_inventory();
}

bid(list bid_list) // Place a bid
{
    bidder = llList2Integer(bid_list, 0); // player number
    // index values 1,2, and 3 are position values.
    bid_item = llList2Integer(bid_list, 4); // good number
    bid_price = llList2Integer(bid_list, 5); // bid value.
    if(bid_item == 1 && bid_price <= llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX)) && llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX)) > 0) // Tests to make sure the bidder has enough tokens to make the bid.
    {
        if(bid_price > standing_bid_good_1 && bidder != standing_asker_good_1 && bidder != standing_bidder_good_2 && bidder != standing_bidder_good_3) // Varifies that the bid increases the bid value, and the bidder is not the current standing asker, or the standing bidder in other markets.
        {
            standing_bid_good_1 = bid_price; // Makes the bid the new standing bid.
            standing_bidder_good_1 = bidder; // Makes the bidder the new standing bidder.
            record(3,llList2CSV(bid_list)); // records the bid
            if (standing_bid_good_1 >= standing_ask_good_1) // tests whether or not the market clears.
            {
                contract(bid_item, standing_bidder_good_1, standing_asker_good_1, standing_bid_good_1, standing_ask_good_1); // Enforces the contract. 
            }
        }
        else if(bid_price <= standing_bid_good_1) // is the bid too low?
        {
            hud_message(1, bidder); // message saying the bid was too low. 
        }
        else if(bidder == standing_bidder_good_2 || bidder == standing_bidder_good_3) // does the bidder have a standing bid in another market?
        {
            hud_message(3, bidder); // message saying the bidder has a standing bidder in another market.
        }
        else if(bidder == standing_asker_good_1) // does the bidder have the satnding ask in this market?
        {
            hud_message(19, bidder); // message saying the bidder has the standing ask in this market
        }
    }
    else if(bid_item == 1 && bid_price > llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX))) // Test to see if the bidder does not have enough tokens to make the bid. 
    {
        hud_message(5, bidder); // message saying the bidder does not have enough tokens to make the bid.
    }
    else if(bid_item == 2 && bid_price <= llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX))&& llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX)) > 0) // Tests to make sure the bidder has enough tokens to make the bid.
    {
        if(bid_price > standing_bid_good_2 && bidder != standing_asker_good_2 && bidder != standing_bidder_good_1 && bidder != standing_bidder_good_3) // Varifies that the bid increases the bid value, and the bidder is not the current standing asker, or the standing bidder in other markets.
        {
            standing_bid_good_2 = bid_price; // Makes the bid the new standing bid.
            standing_bidder_good_2 = bidder; // Makes the bidder the new standing bidder.
            record(3,llList2CSV(bid_list)); // records the bid
            if (standing_bid_good_2 >= standing_ask_good_2) // tests whether or not the market clears.
            {
                contract(bid_item, standing_bidder_good_2, standing_asker_good_2, standing_bid_good_2, standing_ask_good_2); // Enforces the contract. 
            }
        }
        else if(bid_price <= standing_bid_good_2) // is the bid too low?
        {
            hud_message(1, bidder); // message saying the bid was too low. 
        }
        else if(bidder == standing_bidder_good_1 || bidder == standing_bidder_good_3) // does the bidder have a standing bid in another market?
        {
            hud_message(3, bidder); // message saying the bidder has a standing bidder in another market.
        }
        else if(bidder == standing_asker_good_2) // does the bidder have the satnding ask in this market?
        {
            hud_message(19, bidder); // message saying the bidder has the standing ask in this market
        }
    }
    else if(bid_item == 2 && bid_price > llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX))) // Test to see if the bidder does not have enough tokens to make the bid. 
    {
         hud_message(5, bidder); // message saying the bidder does not have enough tokens to make the bid.
    }
    else if(bid_item == 3 && bid_price <= llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX))&& llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX)) > 0) // Tests to make sure the bidder has enough tokens to make the bid.
    {
        if(bid_price > standing_bid_good_3 && bidder != standing_asker_good_3 && bidder != standing_bidder_good_1 && bidder != standing_bidder_good_2) // Varifies that the bid increases the bid value, and the bidder is not the current standing asker, or the standing bidder in other markets.
        {
            standing_bid_good_3 = bid_price; // Makes the bid the new standing bid.
            standing_bidder_good_3 = bidder; // Makes the bidder the new standing bidder.
            record(3,llList2CSV(bid_list)); // records the bid
            if (standing_bid_good_3 >= standing_ask_good_3) // tests whether or not the market clears.
            {
                contract(bid_item, standing_bidder_good_3, standing_asker_good_3, standing_bid_good_3, standing_ask_good_3); // Enforces the contract. 
            }
        }
        else if(bid_price <= standing_bid_good_3) // is the bid too low?
        {
            hud_message(1, bidder); // message saying the bid was too low. 
        }
        else if(bidder == standing_bidder_good_1 || bidder == standing_bidder_good_2) // does the bidder have a standing bid in another market?
        {
            hud_message(3, bidder); // message saying the bidder has a standing bidder in another market.
        }
        else if(bidder == standing_asker_good_3) // does the bidder have the satnding ask in this market?
        {
            hud_message(19, bidder); // message saying the bidder has the standing ask in this market
        }
    }
    else if(bid_item == 3 && bid_price > llList2Integer(inventory_list, get_index(bidder, TOKEN_INDEX))) // Test to see if the bidder does not have enough tokens to make the bid. 
    {
        hud_message(5, bidder); // message saying the bidder does not have enough tokens to make the bid.
    }
    announce_market();
}

ask(list ask_list)
{
    asker = llList2Integer(ask_list, 0); // player number
    // index values 1,2, and 3 are position values.
    ask_item = llList2Integer(ask_list, 4); // good number
    ask_price = llList2Integer(ask_list, 5); // bid value.
	
    if (ask_item == 1 && llList2Integer(inventory_list, get_index(asker, GOOD_1_INDEX)) > 0) // Tests to see if the asker has an item to sell.
    {    
        integer new_low_ask = 0; // Used for test below
        integer only_standing_asker = 0; // Used for test below
        if(ask_price < standing_ask_good_1 || standing_ask_good_1 == 0) new_low_ask = 1; // Tests to see if the ask is below the current standing, or if the current standing is 0.
        if(asker != standing_asker_good_2 && asker != standing_asker_good_3 && asker != standing_bidder_good_1) only_standing_asker = 1; // Tests to see if the asker is not the current standing asker, or if there is no current standing asker.
        if(new_low_ask && only_standing_asker) // if both of the above are true. 
        {
            standing_ask_good_1 = ask_price; // sets the standing ask to the ask_price
            standing_asker_good_1 = asker; // sets the standing asker to the asker
            record(4,llList2CSV(ask_list)); // records the ask
            if(standing_bid_good_1 >= standing_ask_good_1) // Test to see if the market clears
            {
                contract(ask_item, standing_bidder_good_1, standing_asker_good_1, standing_bid_good_1, standing_ask_good_1); // Enforces the contract. 
            }
            else
            {
            }
        }
        else if(new_low_ask == 0) // test to see if the ask is below the current standing ask.
        {
            hud_message(asker, 5); // message saying the ask was too high.
        }
        else if(only_standing_asker == 0) // Test to see if the asker has another standing ask, or the standing bid in this market
        {
            hud_message(asker, 6); // message saying the asker has an ask in another market.
        }
    }
    else if(ask_item == 1 && llList2Integer(inventory_list, get_index(asker, GOOD_1_INDEX)) <= 0) // Test to see if the asker does not have enough of the item to sell.
    {
        hud_message(6, asker); // message saying the asker does not have enough of the item to sell.
    }
    else if (ask_item == 2 && llList2Integer(inventory_list, get_index(asker, GOOD_2_INDEX)) > 0) // Tests to see if the asker has an item to sell.
    {    
        integer new_low_ask = 0; // Used for test below
        integer only_standing_asker = 0; // Used for test below
        if(ask_price < standing_ask_good_2 || standing_ask_good_2 == 0) new_low_ask = 1; // Tests to see if the ask is below the current standing, or if the current standing is 0.
        if(asker != standing_asker_good_1 && asker != standing_asker_good_3 && asker != standing_bidder_good_2) only_standing_asker = 1; // Tests to see if the asker is not the current standing asker, or if there is no current standing asker.
        if(new_low_ask && only_standing_asker) // if both of the above are true. 
        {
            standing_ask_good_2 = ask_price; // sets the standing ask to the ask_price
            standing_asker_good_2 = asker; // sets the standing asker to the asker
            record(4, llList2CSV(ask_list)); // records the ask
            if(standing_bid_good_2 >= standing_ask_good_2) // Test to see if the market clears
            {
                contract(ask_item, standing_bidder_good_2, standing_asker_good_2, standing_bid_good_2, standing_ask_good_2); // Enforces the contract. 
            }
            else
            {
            }
        }
        else if(new_low_ask == 0) // test to see if the ask is below the current standing ask.
        {
            hud_message(2, asker); // message saying the ask was too high.
        }
        else if(only_standing_asker == 0) // Test to see if the asker has another standing ask, or the standing bid in this market
        {
            hud_message(4, asker); // message saying the asker has an ask in another market.
        }
    }
    else if(ask_item == 2 && llList2Integer(inventory_list, get_index(asker, GOOD_2_INDEX)) <= 0) // Test to see if the asker does not have enough of the item to sell.
    {
        hud_message(6, asker); // message saying the asker does not have enough of the item to sell.
    }
    else if (ask_item == 3 && llList2Integer(inventory_list, get_index(asker, GOOD_3_INDEX)) > 0) // Tests to see if the asker has an item to sell.
    {    
        integer new_low_ask = 0; // Used for test below
        integer only_standing_asker = 0; // Used for test below
        if(ask_price < standing_ask_good_3 || standing_ask_good_3 == 0) new_low_ask = 1; // Tests to see if the ask is below the current standing, or if the current standing is 0.
        if(asker != standing_asker_good_1 && asker != standing_asker_good_2 && asker != standing_bidder_good_3) only_standing_asker = 1; // Tests to see if the asker is not the current standing asker, or if there is no current standing asker.
        if(new_low_ask && only_standing_asker) // if both of the above are true. 
        {
            standing_ask_good_3 = ask_price; // sets the standing ask to the ask_price
            standing_asker_good_3 = asker; // sets the standing asker to the asker
            record(4,llList2CSV(ask_list)); // records the ask
            if(standing_bid_good_3 >= standing_ask_good_3) // Test to see if the market clears
            {
                contract(ask_item, standing_bidder_good_3, standing_asker_good_3, standing_bid_good_3, standing_ask_good_3); // Enforces the contract. 
            }
            else
            {
            }
        }
        else if(new_low_ask == 0) // test to see if the ask is below the current standing ask.
        {
            hud_message(2, asker); // message saying the ask was too high.
        }
        else if(only_standing_asker == 0) // Test to see if the asker has another standing ask, or the standing bid in this market
        {
            hud_message(4, asker); // message saying the asker has an ask in another market.
        }
    }
    else if(ask_item == 3 && llList2Integer(inventory_list, get_index(asker, GOOD_3_INDEX)) <= 0) // Test to see if the asker does not have enough of the item to sell.
    {
        hud_message(6, asker); // message saying the asker does not have enough of the item to sell.
    }
    announce_market();
}

contract(integer item, integer buyer_number, integer seller_number, integer buy_price, integer sell_price)
{
	
	// There needs to be some way to control for each of the different government players
	// - Simple boolean for government? i.e. if buyer_number == 4, 8, 12 then government_buyer = 1
	// - This assumes there are set player numbers for government.
	
	integer government_buyer = 0;
	
	if(buyer_number == 4 || buyer_number == 8 || buyer_number == 12) government_buyer = 1; // If the buyer is a government player, then it will skip the cash requirement.
	
	llSay(0, (string)government_buyer);
	
    price = (buy_price + sell_price) / 2; // Average of buy and sell prices
	
    if (llList2Integer(inventory_list, get_index(seller_number, item)) > 0 
		&& (llList2Integer(inventory_list, get_index(buyer_number, TOKEN_INDEX)) >= price || government_buyer = 1)
		&& buy_price != 0 
		&& sell_price != 0) // Retest conditions in bid & ask functions.
    {
		
		llSay(0, (string)government_buyer);
		
        record(6,(string)buyer_number + "," + (string)seller_number + "," + (string)item + "," + (string)price);
		
        buyer_quantity = llList2Integer(inventory_list, get_index(buyer_number,item)) + 1; // Quantity of the item that the buyer holds.
        inventory_list = llListReplaceList(inventory_list, buyer_quantity, get_index(buyer_number, item), get_index(buyer_number, item)); 
        seller_quantity = llList2Integer(inventory_list, get_index(seller_number, item)) - 1; // Quantity of the item that the seller holds.
        inventory_list = llListReplaceList(inventory_list, seller_quantity, get_index(seller_number, item), get_index(seller_number, item));
        buyer_tokens = llList2Integer(inventory_list, get_index(buyer_number, TOKEN_INDEX)) - price; // Quantity of tokens that the buyer holds.
        inventory_list = llListReplaceList(inventory_list, buyer_tokens, get_index(buyer_number, TOKEN_INDEX), get_index(buyer_number, TOKEN_INDEX));
        seller_tokens = llList2Integer(inventory_list, get_index(seller_number, TOKEN_INDEX)) + price; // Quantity of tokens that the seller holds.
        inventory_list = llListReplaceList(inventory_list, seller_tokens, get_index(seller_number, TOKEN_INDEX), get_index(seller_number, TOKEN_INDEX));
		
		if(government_buyer == 1)
		{
			print_money(price, buyer_number)
		}
		
		
        if(price >= max_price)
        {
            max_price = price;
        }
		
        if (item == 1)
        {
            standing_bid_good_1 = 0;
            standing_bidder_good_1 = 0;
            standing_ask_good_1 = 0;
            standing_asker_good_1 = 0;
            if(buyer_number == 0)
            {
                hud_message(10, seller_number);
            }
            else
            {
                hud_message(7, buyer_number);
                hud_message(10, seller_number);
            }
        }
        else if (item == 2)
        {
            standing_bid_good_2 = 0;
            standing_bidder_good_2 = 0;
            standing_ask_good_2 = 0;
            standing_asker_good_2 = 0;
            if(buyer_number == 0)
            {
                hud_message(11, seller_number);
            }
            else
            {
                hud_message(8, buyer_number);
                hud_message(11, seller_number);
            }
        }
        else if (item == 3)
        {
            standing_bid_good_3 = 0;
            standing_bidder_good_3 = 0;
            standing_ask_good_3 = 0;
            standing_asker_good_3 = 0;
            if(buyer_number == 0)
            {
                hud_message(12, seller_number);
            }
            else
            {
                hud_message(9, buyer_number);
                hud_message(12, seller_number);
            }
        }
        announce_inventory();
        announce_market();
    }
}

print_money(integer token_amount, integer government_number) // needs to be adapted to the new human-gov't
{
    //llSay(0,"Print Money");
    gov_token_amount = llList2Integer(inventory_list, get_index(government_number, TOKEN_INDEX));
    //gov_token_amount += 2 * token_amount; // TODO FIND OUT WHY THE HECK THIS IS MULTIPLED BY 2
	gov_token_amount += token_amount;
    inventory_list = llListReplaceList(inventory_list, gov_token_amount, get_index(government_numbergovernment_number, TOKEN_INDEX), get_index(0, TOKEN_INDEX));
    money_supply += token_amount; // money supply will reflect the sum of all government purchases
    record(9, (string)token_amount);
}

// Main Experiment
default
{
    state_entry()
    {
        treatments();
        llListen(EXP_CONTROL, "", NULL_KEY, "");
        llListen(RECEIVER, "", NULL_KEY, "");
    }
    touch_start(integer number)
    {
        if(llDetectedKey(0) == admin && running == FALSE)
        {
            llDialog (admin, "What would you like to do?", ["Start", "Treatments", "Training"], EXP_CONTROL);
        }
        else if(llDetectedKey(0) == admin && running == TRUE)
        {
            llDialog (admin, "End the experiment?", ["Yes", "No"], EXP_CONTROL);
        }
        else if(llDetectedKey(0) != admin) // admin verification
        {
            integer user = llListFindList(ADMIN_LIST, llKey2Name(llDetectedKey(0))); // Verifies that the user has been granted admin status, by searching the master "admin" list.
            if(user != -1) // user's name is found in admin list
            {
                admin = llDetectedKey(0);
                llInstantMessage(admin, "You have been made the admin of this experiment.");
            }
            else if(user == -1)
            {
                llInstantMessage(llDetectedKey(0), "You are not authorized to use this object.");
            }
        }  
    }
    listen(integer channel, string name, key id, string message)
    {
        if(channel == RECEIVER && running == TRUE)
        {
            temporary_list = []; // Clear list for memory purposes.
            temporary_list = llCSV2List(message);
            message_type = llList2Integer(temporary_list, 0); // First position in the message is the message type.
            temporary_list = llDeleteSubList(temporary_list, 0, 0); // Removes the message type for message processing.
            // message types
            // 0 - Harvest
            // 1 - Bid
            // 2 - Ask
            if(message_type == 0) // Harvest
            {
                harvest(temporary_list);
            }
            else if(message_type == 1) // Bid
            {
                bid(temporary_list);
            }
            else if(message_type == 2) // Ask
            {
                ask(temporary_list);
            }
            else if(message_type == -100)
            {
                record(11,message);
            }
        }
        else if(channel == EXP_CONTROL)
        {
            if(running == TRUE)
            {
                if(message == "Yes") // Experiment Ends
                {
                    experiment_toggle(0); // Turns the experiment off
                }
            }
            else if(message == "Treatments")
            {
                llDialog (admin, "Which treatment file would you like to use?\n\nClick again to start the experiment.", treatment_list, EXP_CONTROL);
            }
            else if(llListFindList(treatment_list, (list)message) != -1) // If the message is found to be in the treatment list.
            {
                notecard_name = llList2String(treatment_list, llListFindList(treatment_list,(list)message));
                treatment = TRUE;
            }
            else if(message == "Start" && treatment == TRUE)
            {
                llDialog (admin, "Start the experiment now?", ["Yes","No"], EXP_CONTROL);
            }
            else if(message == "Yes") // Experiment begins
            {
                treatment_id = llGetNotecardLine(notecard_name, treatment_line);  // request the information from the notecard.
                treatment = TRUE;
            }
            else if (message == "Start" && treatment != TRUE)
            {
                llDialog (admin, "You need to select a treatment file.\n\nWhich treatment would you like to use?", treatment_list, EXP_CONTROL);
            }
            else if(message == "Training")
            {
                state training;
            }
        }
    }
    timer()
    {
        generate();
        // government_buy_auto(); left in as a marker for where the government player 'release' message will be broadcast.
        llSetTimerEvent(timer_length);
    }
    dataserver(key id, string data) // This is the card reader for the treatment
    {
        if(id == treatment_id)
        {
            if(data != EOF)
            {
                if(treatment_line == 0) // Line 0 - Name of the treatment
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    treatment_name = data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);                    
                }
                else if(treatment_line == 1)
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    players = (integer)data; // Line 1 - Number of players
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 2) // Line 3 - Length of timer cycle in seconds.
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    timer_length = (float)data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 3) // Line 4 - When timer cycle = gen_cycle, then a generate message is sent to harvesters.
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    generate_frequency = (integer)data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 4) // Line 5 - Initial endowment of good 1.
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    initial_good_1 = (integer)data; // Line 1 - Number of players
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 5) // Line 6 - Initial endowment of good 2.
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    initial_good_2 = (integer)data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 6) // Line 7 - Initial endowment of good 3..
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    initial_good_3 = (integer)data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 7) // Line 8 - Initial endowment of cash.
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    initial_tokens = (integer)data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 8) // Line 9 - exchange rate for payments
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    exchange_rate = (float)data;
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
                else if(treatment_line == 9) // Line 10 - List of theta values for every player [0.33,0.33,0.33] standard
                {
                    llSay(0,"Line " + (string)treatment_line + " data is: " + data);
                    utility_list = llCSV2List(data);
                    treatment_line++;
                    treatment_id = llGetNotecardLine(notecard_name, treatment_line);
                }
            }
            else if(data == EOF)
            {
                llSay(0,"Treatment initialization is complete.");
                treatment_line = 0;
                experiment_toggle(1); // This is where the experiment begins
            }
        }
    }
    changed(integer change)
    {
        if(change == CHANGED_INVENTORY)
        {
            treatments();
        }
    }
}