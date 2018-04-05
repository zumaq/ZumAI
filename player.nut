/**
 * @author Michal Zopp
 * @file player.nut
 */

require("towns.nut");
 
 /** TODO: LOAD AND SAVE THE PLAYERS WITH POINTS
  * @brief class Player, don't be fooled by the name. The name just states and handles
  *  one company as a one player. But in reality you can cooperate with other players
  *  in the same company. Currently Maximum Number of companies that can be on a server is 15.
  */
class Player
{
	static MAX_KARMA_POINTS = 200; // Maximum points you can have
	static DEFAULT_KARMA_POINTS = 100; // Default poins for karma
	static MIN_KARMA_POINTS = 0; // Minimum points you can have
	_player_id=null;
	_road_blockade_tiles = null; //this is a array of blocked tiles by the particular player
	_karma_points=null;
	_quotient = null; //quotient that represents how much the player gets points, depending
					  //on previous actions.
	_towns=null;
	
	constructor(id){
		this._player_id = id;
		this._road_blockade_tiles = array(0);
		this._towns = Towns();
		this._karma_points = DEFAULT_KARMA_POINTS;
		_quotient = 1;
	}
	
	function AddKarmaPoints(points);
	
	function ResetKarmaPoints();
	
	function AddRoadBlockedTile(tile);
	
	function AddTown(townId);
	
	function ClearTowns();
	
	function PunishPlayer();
	
	function MorePunishPlayer();
	
	function CheckRoadBlockedTiles();
	
	function RemoveRoadBlockedTile(tile);
	
	function IsRoadBlockedTileSet(tile);
}

function Player::AddKarmaPoints(points){
	this._karma_points = this._karma_points + (points * _quotient);
	
	// distribute the points
	if(this._karma_points > MAX_KARMA_POINTS){
		this._karma_points = MAX_KARMA_POINTS;
	}
	if(this._karma_points < MIN_KARMA_POINTS){
		this._karma_points = MIN_KARMA_POINTS;
	}
	
	//calculate new _quotient based on the points gained.
	if (points < 0){
		_quotient = _quotient * 1.2
	} else {
		_quotient = _quotient * 0.8
	}
	return this._karma_points
}

function Player::ResetKarmaPoints(){
	this._karma_points = DEFAULT_KARMA_POINTS;
	return true;
}

function Player::AddRoadBlockedTile(tile){
	if (Player.IsRoadBlockedTileSet(tile)) {
		AILog.Info("This tile was already set.");
		return false;
	}
	this._road_blocked_tile.push(tile);
	return true;
}

function Player::AddTown(townId){
	local rating = AITown.GetRating(townId, this._player_id);
	return this._towns.AddTown(townId, rating);
}

function Player::ClearTowns(){
	this._towns.EmptyList();
}

function Player::CheckAndPunish(){
	if (this._karma_points >= 150){
		AILog.Info("Player has > 150 karma points, he is ok");
		return false;
	}
	
	if (this._karma_points >= 100 || this._quotient > 1){
		AILog.Info("Player has > 100 karma points, he gets light punish");
		this.LightPunishPlayer();
		return true;
	}
	
	AILog.Info("Player has >50 & <100 karma points, he gets more punish");
	this.MorePunishPlayer();
	return true;
}

function Player::LightPunishPlayer(){
	this._towns.DecideAndPunish(this._karma_points);
}

function Player::MorePunishPlayer(){
	this._towns.DecideAndPunishMore(this._karma_points);
}

function Player::CheckRoadBlockedTiles(){
	local count = this._road_blockade_tiles.len();
	for(local i = 0; i < count; ++i) {
		if (!AIRail.IsRailTile(this._road_blockade_tiles[i])) {
			this.RemoveRoadBlockedTile(this._road_blockade_tiles[i]);
		}
	}
}

function Player::RemoveRoadBlockedTile(tile){
	local index = Player.IsRoadBlockedTileSet(tile);
	AILog.Info("Removeing Tile: " + tile + " with index: " + index);
	this._road_blockade_tiles.remove(index);
	this.AddKarmaPoints(30); //player has removed blockade so he deserves points.
	return true;
}

function Player::IsRoadBlockedTileSet(tile){
	local count = this._road_blockade_tiles.len();
	for(local i = 0; i < count; ++i) {
		//AILog.Info("Checking tiles: " + this._road_blockade_tiles[i] + " tile: " + tile);
		if (this._road_blockade_tiles[i] == tile) {
			return i;
		}
	}
	return false;
}
