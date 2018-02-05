/**
 * @author Michal Zopp
 * @file towns.nut
 */

 /** TODO: LOAD AND SAVE THE TOWN LIST
  * @brief class Towns, is a representation for each players cities, making construction work, etc.
  */
class Towns
{
	_town_list=null;
	
	constructor(){
		this._town_list=AIList();
	}
	
	/**
	* @brief AddTown, adds the town to the list of towns and ratings
	* @param townId, id of the town you want to add
	* @param rating, rating the town has
	*/
	function AddTown(townId, rating);
	
	/**
	* @brief SortTownList, sorts the town list in order to pick the most for the
	* rating and make decisions based on that.
	*/
	function SortTownList();
	
	/**
	* @brief EmptyList, empties the list of towns and ratigins
	*/
	function EmptyList();
	
	/**
	* @brief BuildTownStatue, this chooses the most rating from towns(where can be applied)
	* and builds statue in town to increase rating.
	*/
	function BuildTownStatue();
	
	/**
	* @brief BribeTown, this chooses the most rating from towns(where can be applied)
	* and Bribes the town to increase rating.
	*/
	function BribeTown();
	
	/**
	* @brief RebuildRoads, this chooses the most rating from towns(where can be applied)
	* and funds the rebuilding of roads to increase rating and trap busses to enter city.
	*/
	function RebuildRoads();
	
	/**
	* @brief FundBuildings, this chooses the most rating from towns(where can be applied)
	* and funds the expanstion of buildings to increase rating.
	*/
	function FundBuildings();
	
	/**
	* @brief BuyRights, this chooses the most rating from towns(where can be applied)
	* and buys rights for building.
	*/
	function BuyRights();
	
	/**
	* @brief Advertise, this chooses the most rating from towns(where can be applied)
	* and funds a advertisement to increase rating.
	* @param size, size of advertisement, 0 = SMALL, 1 = MEDIUM, 2 = LARGE
	*/
	function Advertise(size);
	
	/**
	* @brief Decide, this fuction decides what is the best way to punish the oponent
	* @param points, points that the player has to decite how to punish range(0-100-200)
	*/
	function DecideAndPunish(points);
	
	/**
	* @brief PrintTownRaiting, prints the town raiting and town names for the
	* particular player
	*/
	function PrintTownRatings();
}

function Towns::AddTown(townId, rating){
	if(!AITown.IsValidTown(townId)){
		return false;
	}
	this._town_list.AddItem(townId, rating);
	return true;
}

function Towns::SortTownList(){
	this._town_list.Valuate(AITown.GetRating);
	this._town_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
}

function EmptyList(){
	this._town_list.Clear();
}

function Towns::BuildTownStatue(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while (HasStatue(candidateTown)) {
		candidateTown = this._town_list.Next();
	}
	if (AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_BUILD_STATUE)){
		return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_BUILD_STATUE);
	}
	return false;
}

function Towns::BribeTown(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!candidateTown.IsEnd() 
		  && !AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_BRIBE)){
		candidateTown = this._town_list.Next();
	}
	if(candidateTown.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_BRIBE);
}
	
function Towns::RebuildRoads(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!candidateTown.IsEnd() 
		  && !AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_ROAD_REBUILD)){
		candidateTown = this._town_list.Next();
	}
	if(candidateTown.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_ROAD_REBUILD);
}
	
function Towns::FundBuildings(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!candidateTown.IsEnd() 
		  && !AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_FUND_BUILDINGS)){
		candidateTown = this._town_list.Next();
	}
	if(candidateTown.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_FUND_BUILDINGS);
}
	
function Towns::BuyRights(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!candidateTown.IsEnd() 
		  && !AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_BUY_RIGHTS)){
		candidateTown = this._town_list.Next();
	}
	if(candidateTown.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_BUY_RIGHTS);
}
	
function Towns::Advertise(size){
	if (size != 0 || size != 1 || size != 2){
		return false;
	}
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!candidateTown.IsEnd() 
		  && !AITown.IsActionAvailable(candidateTown, size)){
		candidateTown = this._town_list.Next();
	}
	if(candidateTown.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, size);
}

function Towns::DecideAndPunish(points){
	//points -0 100 200 case has bad syntax
	if (points > 140) {
		Towns.Advertise((points-140) % 20);
	} else if (points > 120) {
		Towns.BuildTownStatue();
	} else if (points > 100) {
		Towns.FundBuildings();
	} else if (points > 80) {
		Towns.RebuildRoads();
	} else if (points > 60) {
		Towns.BuyRights();
	} else if (points > 40) {
		Towns.BribeTown();
	}
}

function Towns::PrintTownRatings(){
	for(local l = this._town_list.Begin(); !this._town_list.IsEnd(); l = this._town_list.Next()) {
		AILog.Info("- -> Town Name: " + AITown.GetName(l) + " has rating: " + this._town_list.GetValue(l));
	}
}
