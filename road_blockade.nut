/**
* @author Michal Zopp
* @file road_blockades.nut
*/

/**
* @brief class Road Blockades
*/
class RoadBlockade
{
	_available_trains=array(0);
	_blocking_trains=array(0);
	
	constructor(){
	}
	
	/**
	* @brief BuildRoadBlockade, builds a interception to prevent cars from going in that road.
	* @param buildTile, the tile where you want to build the interception.
	* @param roadDirection, direction in which you want to build, 1 for x-axes, 0 for y-axes. 
	*/
	function BuildRoadBlockade(buildTile, roadDirection);
	
	/**
	* @brief BuildTrain, builds a train in given depo
	* @param depoTile, tile of the depo where you build the Train
	*/
	function BuildTrain(depoTile);
	
	/**
	* @brief MakeBlockadePassable, makes the alredy built blockade passable again
	* //TODO: make so that the train for the person with good karma gets sent to depo.
	*/
	function MakeBlockadePassable();
	
	/**
	* @brief WhoDidTheBlockade, decited who did the blockade based on depo/tracks.
	* Returns false if it could no be decited.
	* @param tile, the tile where the blockade starts.
	* @param roadDirection, the direction where the road goes, so it can be determined.
	*/
	function WhoDidTheBlockade(tile, roadDirection);
	
    /**
    * @brief IsBlockadeOnPath, finds and returns tile if there is a blockade on given path
    * if not return false.
    * @param path, the path you want to check
    */
    function IsBlockadeOnPath(path);

	/**
	* @brief GetAroundBlockade, calls functions to get around the blockade.
	* @param startTile, starting tile
	* @param endTile, ending tile
	*/
	function GetAroundBlockade(startTile, endTile);
	
	/**
	* @brief BuildBridge
	* @param startTile
	* @param endTile
	*/
	function BuildBridge(startTile, endTile);
	
	/**
	* @brief BuildTunnel
	* @param startTile
	* @param endTile
	*/
	function BuildTunnel(startTile, endTile);
	
	/**
	* @brief BuildRoad, builds the road based on the path
	* @param path, best path
	*/
	function BuildRoad(path);
	
	/**
	* @brief FindBestPath Finds the best path around the blockade
	* @param startTile, first tile
	* @param endTile, last tile
	*/
	function FindBestPath(startTile, endTile);
	
}

function RoadBlockade::BuildRoadBlockade(buildTile, roadDirection){
	local types = AIRailTypeList();
	AIRail.SetCurrentRailType(types.Begin());
	//1 is S to N, 0 is W to E
	if(roadDirection){
		AIRail.BuildRailTrack(buildTile, AIRail.RAILTRACK_NE_SW);
		AIRail.BuildRailDepot(buildTile - AIMap.GetTileIndex(1,0), buildTile)
		RoadBlockade.BuildTrain(buildTile - AIMap.GetTileIndex(1,0));
	}else{
		AIRail.BuildRailTrack(buildTile , AIRail.RAILTRACK_NW_SE);
		AIRail.BuildRailDepot(buildTile - AIMap.GetTileIndex(0,1), buildTile)
		RoadBlockade.BuildTrain(buildTile - AIMap.GetTileIndex(0,1));
	}
	return true;
}

function RoadBlockade::MakeBlockadePassable(){
	local locomotive = _blocking_trains.pop();
	AIVehicle.StartStopVehicle(locomotive);
	AIVehicle.SendVehicleToDepot(locomotive);
	_available_trains.push(locomotive);
}

function RoadBlockade::BuildTrain(depoTile){
	local vl = AIEngineList(AIVehicle.VT_RAIL);
	vl.Valuate(AIEngine.IsValidEngine);
	vl.KeepValue(1);
	vl.Valuate(AIEngine.IsBuildable);
	vl.KeepValue(1);
	vl.Valuate(AIEngine.IsWagon);
	vl.KeepValue(0);
	local locomotive_engine = vl.Begin();
	
	local locomotive = AIVehicle.BuildVehicle(depoTile, locomotive_engine);
	AIVehicle.StartStopVehicle(locomotive);
	AIController.Sleep(10);
	AIVehicle.StartStopVehicle(locomotive);
	_blocking_trains.push(locomotive);
	return true;
}

function RoadBlockade::WhoDidTheBlockade(tile, roadDirection) {
	local candidateTile = tile;
	local x_coordinate = -1;
	local y_coordinate = -1;
	//1 is S to N, 0 is W to E
	if(roadDirection){
		while(AIRail.IsRailTile(candidateTile) && !AIRoad.IsRoadTile(candidateTile)){
			candidateTile = candidateTile + AIMap.GetTileIndex(x_coordinate,0);
			if(AIRail.IsDepoTile(candidateTile)){
				break;
			}
			if(!AIRail.IsRailTile(candidateTile)){
				x_coordinate = 1;
			}
		}
	}else{
		while(AIRail.IsRailTile(candidateTile) && !AIRoad.IsRoadTile(candidateTile)){
			candidateTile = candidateTile + AIMap.GetTileIndex(0,y_coordinate);
			if(AIRail.IsDepoTile(candidateTile)){
				break;
			}
			if(!AIRail.IsRailTile(candidateTile)){
				y_coordinate = 1;
			}
		}
	}
	local owner = AITile.GetOwner(candidateTile);
	return (owner > -1 && owner < 16) ? owner : false;
}

function RoadBlockade::IsBlockadeOnPath(path) {
	if (path == null) {
		AILog.Error("path is null");
		return false;
	}
	while (path != null) {
		local par = path.GetParent();
		if (par != null) {
			if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
				if (AIRail.IsLevelCrossingTile(par.GetTile())) {
					//TODO: punish with vehicles rather than by the tile that it is there, cuz you can punish yourselve.
					AILog.Info("Road is and intersection, punish the creator" + AITile.GetOwner(path.GetTile()));
					return par.GetTile();
				}
			}
		}
	}
	return false;
}

function RoadBlockade::GetAroundBlockade(startTile, endTile){
	local path = RoadBlockade.FindBestPath(startTile, endTile);
	RoadBlockade.BuildRoad(path);
}

function RoadBlockade::BuildBridge(startTile, endTile){

}

function RoadBlockade::BuildTunnel(startTile, endTile){

}

function RoadBlockade::BuildRoad(roadPath){
	local path = roadPath;
	lastTile = null;
	while (path != null) {
		local par = path.GetParent();
		
		if (par != null) {
		  lastTile = path.GetTile();
			if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
			  AILog.Info("Problem, cant build road, maybe it is built.");
			}
		}
		path = par;
	}
}

function RoadBlockade::FindBestPath(startTile, endTile){
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	
	local pathfinder = RoadPathFinder();
	pathfinder.cost.tile=1;
	pathfinder.cost.no_existing_road=-10;
	pathfinder.cost.turn=1;
	
	pathfinder.InitializePath([startTile], [endTile]);
	local path = false;
	while (path == false) {
		path = pathfinder.FindPath(50);
		this.Sleep(1);
	}
	
	if (path == null) {
		AILog.Error("pathfinder.FindPath return null");
		return false;
	}
	return path;
}
