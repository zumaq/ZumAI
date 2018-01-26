require("RouteManager.nut");
require("Route.nut");

require("TownManager.nut");
require("BuildManager.nut");
require("Utils.nut");

require("WrightAI.nut");

class LuDiAI extends AIController {
    MAX_TOWN_VEHICLES = 500;
    MIN_DISTANCE = 40;
    MAX_DISTANCE = 115;
    MAX_DISTANCE_INCREASE = 1.2;

    townManager = null;
    routeManager = null;
    buildManager = null;

    cargoClass = null;

    bestRoutesBuilt = null;
    allRoutesBuilt = null;
    loanPayed = null;

    wrightAI = null;

    constructor() {
        townManager = TownManager();
        routeManager = RouteManager();
        buildManager = BuildManager();

        if(!AIController.GetSetting("select_town_cargo")) {
            cargoClass = AICargo.CC_PASSENGERS;
        }
        else {
            cargoClass = AICargo.CC_MAIL;
        }

        bestRoutesBuilt = false;
        allRoutesBuilt = false;
        loanPayed = false;

        wrightAI = WrightAI(cargoClass);
    }

    function Start();
    function airRoute();

    function updateVehicles() {
        for(local i = 0; i < routeManager.m_townRouteArray.len(); ++i) {
            AIController.Sleep(1);

            routeManager.m_townRouteArray[i].updateEngine();

            if((AICompany.GetBankBalance(AICompany.COMPANY_SELF) > 12000) &&
                (MAX_TOWN_VEHICLES > routeManager.getRoadVehicleCount())){
                routeManager.m_townRouteArray[i].addVehicleToRoute();
            }

            if(MAX_TOWN_VEHICLES == routeManager.getRoadVehicleCount() - 1) {
                routeManager.m_townRouteArray[i].sendLowProfitVehiclesToDepot();
            }

            routeManager.m_townRouteArray[i].sendNegativeProfitVehiclesToDepot();
            routeManager.m_townRouteArray[i].renewVehicles();
            routeManager.m_townRouteArray[i].sellVehiclesInDepot();

            if(AICompany.GetBankBalance(AICompany.COMPANY_SELF) > 10000) {
                if(routeManager.m_townRouteArray[i].expandStations()) {
                    AILog.Info("Expanded stations in " + AITown.GetName(routeManager.m_townRouteArray[i].m_cityFrom) + " and " + AITown.GetName(routeManager.m_townRouteArray[i].m_cityTo));
                }
            }
        }
    }

    function Save() {
        AILog.Warning("Saving...");

        local table = {};
        table.rawset("town_manager", townManager.saveTownManager());
        table.rawset("route_manager", routeManager.saveRouteManager());
        table.rawset("build_manager", buildManager.saveBuildManager());

        table.rawset("best_routes_built", bestRoutesBuilt);
        table.rawset("all_routes_built", allRoutesBuilt);
        table.rawset("loan_payed", loanPayed);

        table.rawset("wrightai", wrightAI.save());

        AILog.Warning("Saved!");

        return table;
    }

    function Load(version, data) {
        AILog.Info("Loading...");

        if(data.rawin("town_manager")) {
            townManager.loadTownManager(data.rawget("town_manager"));
        }

        if(data.rawin("route_manager")) {
            routeManager.loadRouteManager(data.rawget("route_manager"));
        }

        if(data.rawin("build_manager")) {
            buildManager.loadBuildManager(data.rawget("build_manager"));
        }

        if(data.rawin("best_routes_built")) {
            bestRoutesBuilt = data.rawget("best_routes_built");
        }

        if(data.rawin("all_routes_built")) {
            allRoutesBuilt = data.rawget("all_routes_built");
        }

        if(data.rawin("loan_payed")) {
            loanPayed = data.rawget("loan_payed");
        }

        if(buildManager.hasUnfinishedRoute()) {
            AILog.Warning("Unfinished route between " + AITown.GetName(buildManager.m_cityFrom) + " and " + AITown.GetName(buildManager.m_cityTo) + " detected!");
        }

        if(data.rawin("wrightai")) {
            wrightAI.load(data.rawget("wrightai"));
        }

        AILog.Warning("Game loaded.");
    }

}

function LuDiAI::Start() {
    if (!AICompany.SetName("LuDiAI")) {
        local i = 2;
        while (!AICompany.SetName("LuDiAI #" + i)) {
            ++i;
        }
    }

    if (buildManager.hasUnfinishedRoute()) {
        local cityFrom = buildManager.m_cityFrom;
        local cityTo = buildManager.m_cityTo;

        AILog.Warning("Building unfinished route between " + AITown.GetName(buildManager.m_cityFrom) + " and " + AITown.GetName(buildManager.m_cityTo) + "!");
        local routeResult = routeManager.buildRoute(buildManager, buildManager.m_cityFrom, buildManager.m_cityTo, buildManager.m_cargoClass);

        if (routeResult) {
            AILog.Info("Built route between: " + AITown.GetName(cityFrom) + " and " + AITown.GetName(cityTo));
        }
    }

    local cityFrom = null;
    while (true) {
        //pay loan
        while (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > 500000) {
            AICompany.SetLoanAmount(AICompany.GetLoanAmount() - AICompany.GetLoanInterval());

            if (AICompany.GetLoanAmount() == 0) {
                loanPayed = true;
                break;
            }
        }

        if (!loanPayed) {
            AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
        }

        updateVehicles();

        if ((AICompany.GetBankBalance(AICompany.COMPANY_SELF) > 35000)
            && (routeManager.getRoadVehicleCount() < MAX_TOWN_VEHICLES - 10)
            && (!allRoutesBuilt)) {

            if (cityFrom == null) {
                cityFrom = townManager.getUnusedCity(bestRoutesBuilt);
                if (cityFrom == null) {
                    if (AIController.GetSetting("pick_random")) {
                        townManager.m_usedCities.Clear();
                    } else {
                        if (!bestRoutesBuilt) {
                            bestRoutesBuilt = true;
                            townManager.m_usedCities.Clear();
                            townManager.m_nearCityPairArray = [];
                            AILog.Warning("Best routes have been used! Year: " + AIDate.GetYear(AIDate.GetCurrentDate()));
                            continue;
                        } else {
                            allRoutesBuilt = true;
                            AILog.Warning("All routes have been used!");
                            continue;
                        }
                    }
                }
            }

            AILog.Info("New city found: " + AITown.GetName(cityFrom));

            townManager.findNearCities(cityFrom, MIN_DISTANCE, MAX_DISTANCE, bestRoutesBuilt);
            if (!townManager.m_nearCityPairArray.len()) {
                //second try with increased distance
                townManager.findNearCities(cityFrom, MIN_DISTANCE, MAX_DISTANCE * MAX_DISTANCE_INCREASE, bestRoutesBuilt);
                if (!townManager.m_nearCityPairArray.len()) {
                    AILog.Info("No near city available");
                    cityFrom = null;
                    continue;
                }
            }

            local cityTo = null;
            for (local i = 0; i < townManager.m_nearCityPairArray.len(); ++i) {
                if (cityFrom == townManager.m_nearCityPairArray[i].m_cityFrom) {
                    if (!routeManager.townRouteExists(cityFrom, townManager.m_nearCityPairArray[i].m_cityTo)) {
                        cityTo = townManager.m_nearCityPairArray[i].m_cityTo;

                        if (routeManager.hasMaxStationCount(cityFrom, cityTo)) {
                            cityTo = null;
                            continue;
                        } else {
                            break;
                        }
                    }
                }
            }

            if (cityTo == null) {
                cityFrom = null;
                continue;
            }

            AILog.Info("New near city found: " + AITown.GetName(cityTo));

            local routeResult = routeManager.buildRoute(buildManager, cityFrom, cityTo, cargoClass);
            if (routeResult) {
                AILog.Info("Built route between: " + AITown.GetName(cityFrom) + " and " + AITown.GetName(cityTo));
            }

            //cityFrom = cityTo; // use this line to look for a new town from the last town
            cityFrom = null;

        }

        //****
        //**** WrightAI functions from Wright.nut (https://wiki.openttd.org/AI:WrightAI) with slight modifications
        //****
        if (AIController.GetSetting("air_support")) {
            if (((routeManager.getRoadVehicleCount() > (MAX_TOWN_VEHICLES / 4).tointeger()) ||
                (AIDate.GetYear(AIDate.GetCurrentDate()) > 1955)) &&
                (AICompany.GetBankBalance(AICompany.COMPANY_SELF) > 100000)) {
                wrightAI.BuildAirRoute();
            }
        }
        //****
    }
}




