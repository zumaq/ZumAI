/**
 * @author Michal Zopp
 * @file towns.nut
 */

 /** TODO: LOAD AND SAVE THE TOWN LIST
  * @brief class Towns, is a representation for each players cities, making construction work, etc.
  */
class Towns
{
	_town_list = null;
	
	constructor(){
		this._town_list = AIList();
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
	* @brief CheckAirportTiles, checks if there is a space around the center tile, with the distance,
	* returns the buildable tile, if not returns the original center tile.
	* @param tile, center tile of the city you want to build
	* @param distance, distance from the center tile you want to check.
	*/
	function CheckAirportTiles(tile, distance);
	
	/**
	* @brief BuildHeliPorts, build heliports in the most city rating a preson has to 
	* avoid him getting to build airports.
	*/
	function BuildHeliPorts();
	
	/**
	* @brief RemoveRoadBeforeDepot, removes the road from the tile you get it from every direction. 
	* @param tile, tile you want to remove completely.
	*/
	function RemoveRoadBeforeDepot(tile);
	
	/**
	* @brief BuildRailOnTile, builds a rail tile you cant build roads on a tile. 
	* @param tile, tile you want to build on.
	*/
	function BuildRailOnTile(tile);
	
	/**
	* @brief DestroyDepoTileInCity, destroys and build rail in a tile that is right in front of depo. 
	*/
	function DestroyDepoTileInCity();
	
	
	/**
	* @brief DecideAndPunish, this function decides what is the best way to punish the oponent
	* @param points, points that the player has to decide how to punish, range(0-100-200)
	*/
	function DecideAndPunish(points);
	
	/**
	* @brief DecideAndPunishMore, this function decides and punishes the player, but more!
	* @param points, points that the player has to decide how to punish, range(0-100-200)
	*/
	function DecideAndPunishMore(points);
	
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
	//_town_list.Valuate(AITown.GetRating); dosent need a valuator, there altredy is a value in the list
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
	while(!AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_BRIBE)){
		candidateTown = this._town_list.Next();
	}
	if(this._town_list.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_BRIBE);
}
	
function Towns::RebuildRoads(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_ROAD_REBUILD)){
		candidateTown = this._town_list.Next();
	}
	if(this._town_list.sIsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_ROAD_REBUILD);
}
	
function Towns::FundBuildings(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_FUND_BUILDINGS)){
		candidateTown = this._town_list.Next();
	}
	if(this._town_list.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, AITown.TOWN_ACTION_FUND_BUILDINGS);
}
	
function Towns::BuyRights(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(!AITown.IsActionAvailable(candidateTown, AITown.TOWN_ACTION_BUY_RIGHTS)){
		candidateTown = this._town_list.Next();
	}
	if(this._town_list.IsEnd()){
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
	while(!AITown.IsActionAvailable(candidateTown, size)){
		candidateTown = this._town_list.Next();
	}
	if(this._town_list.IsEnd()){
		return false;
	}
	return AITown.PerformTownAction(candidateTown, size);
}

function Towns::CheckAirportTiles(tile, distance){
	local candidateTile = tile + AIMap.GetTileIndex(-distance,-distance);
	local moves = distance * 2;
	for (local l = 0; l < 4; l++){
		for (local i = 0; i < moves; i++){
			AILog.Info("CheckAirportTiles cycle: " + i +
						"tile x: " + AIMap.GetTileX(candidateTile) + "tile y: " + AIMap.GetTileY(candidateTile));
			if (AITile.IsBuildable(candidateTile)){
				return candidateTile;
			}
			if(l == 0){
				candidateTile = candidateTile + AIMap.GetTileIndex(0,1);
			}
			if(l == 1){
				candidateTile = candidateTile + AIMap.GetTileIndex(1,0);
			}
			if(l == 2){
				candidateTile = candidateTile + AIMap.GetTileIndex(0,-1);
			}
			if(l == 3){
				candidateTile = candidateTile + AIMap.GetTileIndex(-1,0);
			}
		}
	}
	//this is here so that the for cycle has something to catch the build an continues, 1 tile always is false
	return tile;
}

function Towns::BuildHeliPorts(){
	if (!AIAirport.IsValidAirportType(AIAirport.AT_HELIPORT)){
		AILog.Info("Its not a time to build Helicopters yet");
		return false;
	}
	SortTownList();
	local candidateTown = this._town_list.Begin();
	while(AITown.GetAllowedNoise(candidateTown) == 0){
		candidateTown = this._town_list.Next();
	}
	if(this._town_list.IsEnd()){
		return false;
	}
	local candidateTile = AITown.GetLocation(candidateTown);
	AILog.Info("town with tile: " + candidateTile + " has noise level: " + AITown.GetAllowedNoise(candidateTown));
	for (local i=0; !AIAirport.BuildAirport(candidateTile, AIAirport.AT_HELIPORT, AIStation.STATION_NEW); i++){
		AILog.Info("BuildHeliPorts cycle: " + i);
		candidateTile = Towns.CheckAirportTiles(candidateTile, i);
	}
	return candidateTile;
}

function Towns::CheckDepoTileInCity(tile, distance){
	local candidateTile = tile + AIMap.GetTileIndex(-distance,-distance);
	local moves = distance * 2;
	for (local l = 0; l < 4; l++){
		for (local i = 0; i < moves; i++){
			if (AIRoad.IsRoadDepotTile(candidateTile) 
				&& !AICompany.IsMine(AITile.GetOwner(candidateTile))
				&& !AIRail.IsRailTile(AIRoad.GetRoadDepotFrontTile(candidateTile))){
				return candidateTile;
			}
			if(l == 0){
				candidateTile = candidateTile + AIMap.GetTileIndex(0,1);
			}
			if(l == 1){
				candidateTile = candidateTile + AIMap.GetTileIndex(1,0);
			}
			if(l == 2){
				candidateTile = candidateTile + AIMap.GetTileIndex(0,-1);
			}
			if(l == 3){
				candidateTile = candidateTile + AIMap.GetTileIndex(-1,0);
			}
		}
	}
	return tile;
}

function Towns::RemoveRoadBeforeDepot(tile){
	AIRoad.RemoveRoad(tile, tile + AIMap.GetTileIndex(0, 1));
	AIRoad.RemoveRoad(tile, tile + AIMap.GetTileIndex(1, 0));
	AIRoad.RemoveRoad(tile, tile + AIMap.GetTileIndex(0, -1));
	AIRoad.RemoveRoad(tile, tile + AIMap.GetTileIndex(-1, 0));
	Towns.BuildRailOnTile(tile);
}

function Towns::BuildRailOnTile(tile){
	local types = AIRailTypeList();
	AIRail.SetCurrentRailType(types.Begin());
	AIRail.BuildRailTrack(tile, AIRail.RAILTRACK_NW_NE);
}

function Towns::DestroyDepoTileInCity(){
	SortTownList();
	local candidateTown = this._town_list.Begin();
	if(this._town_list.IsEnd()){
		return false;
	}
	
	local depoTile = AITown.GetLocation(candidateTown);
	for (local l=0; depoTile == AITown.GetLocation(candidateTown) && l < 2; l++){
		AILog.Info("Checking town with name: " + AITown.GetName(candidateTown));
		for (local i=0; depoTile == AITown.GetLocation(candidateTown) && i < 8; i++){
			AILog.Info("Depofinding cycle: " + i);
			depoTile = Towns.CheckDepoTileInCity(depoTile, i);
		}
		if (depoTile == AITown.GetLocation(candidateTown)){ // if you cant find one then check other city
			candidateTown = this._town_list.Next();
			depoTile = AITown.GetLocation(candidateTown);
			if(this._town_list.IsEnd()){
				return false;
			}
		}
	}
	
	if (depoTile != AITown.GetLocation(candidateTown)){
		local tile = AIRoad.GetRoadDepotFrontTile(depoTile);
		AILog.Info("Tile in front of the Depot x: " + AIMap.GetTileX(tile) + " y: " + AIMap.GetTileY(tile));
		Towns.RemoveRoadBeforeDepot(tile);
		return true;
	}
	return false;
}

function Towns::DecideAndPunish(points){
	//points - 0 100 200 case has bad syntax
	if (points > 140) {
		Towns.Advertise((points-140) % 20);
		return;
	} else if (points > 120) {
		Towns.BuildTownStatue();
		return;
	} else if (points > 100) {
		Towns.FundBuildings();
		return;
	} else if (points > 80) {
		Towns.RebuildRoads();
		return;
	} else if (points > 60) {
		Towns.BuyRights();
		return;
	} else if (points > 40) {
		Towns.BribeTown();
		return;
	}
}

function Towns::DecideAndPunishMore(points){
	if (points > 120) {
		Towns.BuildHeliPorts();
		return;
	} else if (points > 100) {
		Towns.DestroyDepoTileInCity();
		return;
	} else if (points > 80) {
		//Towns.RebuildRoads();
		return;
	} else if (points > 60) {
		//Towns.BuyRights();
		return;
	} else if (points > 40) {
		//Towns.BribeTown();
		return;
	}
}

function Towns::PrintTownRatings(){
	for(local l = this._town_list.Begin(); !this._town_list.IsEnd(); l = this._town_list.Next()) {
		AILog.Info("- -> Town Name: " + AITown.GetName(l) + " has rating: " + this._town_list.GetValue(l));
	}
}
