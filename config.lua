Config = {}

--Debug
Config.Debug = false
-- --

--Bee Hive Shop
Config.model = 's_m_m_migrant_01'
Config.Coords = vector4(-695.56, 5802.11, 17.33, 72.08)
-- --

-- Model Names
Config.BeehiveModel = 'np_beehive'
Config.BeehiveModelFinish = 'np_beehive03'
-- --
--Progress Bar Durations
Config.PlacingDuration = 3000
Config.QueenBeeDuration = 2000
Config.DestroyDuration = 3000
Config.HoneyDuration = 10000
Config.FeedDuration = 6000
Config.HoneyCombDuration = 6000
-- --
--Interval Settings
Config.Hours = '' --(1-23) Time in hours to update beehives for feed degredation and progress increase.(if you want to keep it empty please put '')

Config.Mins = '15' --(1-59) Time in mins to update beehives for feed degredation and progress increase.(if you want to keep it empty please put '')
-- --

--Math
Config.MaxWorkerBees = 20

Config.WorkforceMultiplier = 5 -- This is multiplied by the amount of worker bees / total worker bees to get the amount increased

Config.FoodMultiplier = 5 -- Multiplier for food degradation for max number of bees

Config.NoFoodMultiplier = 0.25 -- A mulitplier when food for beed = 0

Config.WorkerBeeKillPercent = 25  -- Percentage chance to kill a worker bee when the bees havent been fed

Config.KillWorker = math.random(3) --How many worker bees gets killed every interval if food = 0 when Config.WorkerBeeKillPercent is met.

Config.ReduceQueenHealth = math.random(3) --How much health gets reduced from queen bee every interval if food = 0 when Config.WorkerBeeKillPercent is met.

Config.HoneyCombAmount = 5 -- Number of honeycombs which can be recieved after harvest

Config.QueenHealthAfterHarvest = 20 --After harvest how much health from the queen should be removed

Config.HoursTakenToDegrade = 2 * 60 * 60  --Time taken for a honey comb to degrade to honey in stash (in terms of seconds)
-- --

--Soil Hash
Config.SoilHash = {
    [951832588] = true,
    [-461750719] = true,
    [-1286696947] = true,
    [-1942898710] = true,
    [1333033863] = true,
    [-1885547121] = true,
    [510490462] = true,
    [223086562] = true,
    [1144315879] = true,
    [-700658213] = true,
    [-1907520769] = true,
    [-124769592] = true,
    [1109728704] = true,
    [2128369009] = true,
}
-- --