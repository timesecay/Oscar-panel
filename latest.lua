local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Magnification = nil
local SpawnRate = 1
local UnitLimitOverride = nil
local DelayEnemyCycle = true
local SwitchTeamsAtStart = false
local Custom = { swap = nil, busy = false } -- Misc "Custom Spawner" state (defined further down)

if _G.SandboxMenuCleanup then
	pcall(_G.SandboxMenuCleanup)
end

local FriendlyFolder, BaseFolder, SandboxSettings, SandboxSpawn

local function getRefs()
	if FriendlyFolder and BaseFolder and SandboxSettings and SandboxSpawn then
		return true
	end
	local folders = Workspace:WaitForChild("NPCFolders", 10)
	local events = ReplicatedStorage:WaitForChild("Events", 10)
	if not folders or not events then return false end
	local rf = events:WaitForChild("RemoteFunction", 10)
	if not rf then return false end
	FriendlyFolder = folders:WaitForChild("FriendlyFolder", 10)
	BaseFolder = folders:WaitForChild("BaseFolder", 10)
	SandboxSettings = rf:WaitForChild("SandboxSettings", 10)
	SandboxSpawn = rf:WaitForChild("SandboxSpawn", 10)
	return FriendlyFolder and BaseFolder and SandboxSettings and SandboxSpawn and true or false
end

local function humanoidAlive(base)
	local hum = base:FindFirstChildWhichIsA("Humanoid", true)
	return not hum or hum.Health > 0
end

local function checkBasesValid()
	if not BaseFolder then return false end
	local blue = BaseFolder:FindFirstChild("Blue Base")
	if not blue or not blue:GetAttribute("Sandbox") or not humanoidAlive(blue) then
		return false
	end
	local red = Workspace:FindFirstChild("Red Base", true)
	if red and not humanoidAlive(red) then
		return false
	end
	return true
end

local function countByNames(names)
	local count = 0
	for _, unit in FriendlyFolder:GetChildren() do
		if names[unit.Name] and not unit:GetAttribute("ConfusedTime") then
			local hum = unit:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				count += 1
			end
		end
	end
	return count
end

-- counts living units by their ID attribute (used by stages that cap a unit whose name is not known)
local function countById(id)
	local count = 0
	for _, unit in FriendlyFolder:GetChildren() do
		if tonumber(unit:GetAttribute("ID")) == id and not unit:GetAttribute("ConfusedTime") then
			local hum = unit:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				count += 1
			end
		end
	end
	return count
end

local function aliveEnemies()
	local count = 0
	for _, unit in FriendlyFolder:GetChildren() do
		if not unit:GetAttribute("NoClog") and not unit:GetAttribute("ConfusedTime") then
			local hum = unit:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				count += 1
			end
		end
	end
	return count
end

local IDS, SAPPER, TEAPOT, OSCAR, only, DARK_PELICAN, AWC_BOSSRUSH, CATEGORIES, STAGES, SUBCHAPTERS
do
IDS = {
	PatrolPrincipal = 57,
	DeleterExpunger = 67,
	LittlemanBloodhorn = 65,
	BucketTagger = 31,
	TreasureSeller = nil,
	Terminator = 13,
}

local SNIPER = { ["Paintball Battler"] = true, ["Sniper Battler"] = true }
local HAMMER = { ["Hammer Battler"] = true, ["Banhammer Battler"] = true }
local TITAN = { ["Titan Battler"] = true, ["Telamon Battler"] = true }
local BALLER = { ["Baller Battler"] = true, ["Soccer Battler"] = true }
local ROCKET = { ["Rocket Battler"] = true, ["Crocket Battler"] = true }
local CANNON = { ["Cannonary"] = true, ["Mercenary"] = true }
local GARGANT = { ["Gargant"] = true, ["Gehenna"] = true }
local PATROL = { ["Patrol"] = true, ["Principal"] = true }
SAPPER = { ["Sapper"] = true, ["Stunlock"] = true }
local LITTLEMAN = { ["Littleman"] = true, ["Bloodhorn"] = true }
local DELETER = { ["Deleter"] = true, ["Expunger"] = true }
local FATBOY = { ["Fatboy"] = true, ["Warhead"] = true }
local PIANIST = { ["Pianist"] = true, ["Grandmaster"] = true }
local JESTER = { ["Jester Battler"] = true, ["Terror Battler"] = true }
local BLINDER = { ["Blinder"] = true, ["Confuddler"] = true }
local MONKEY = { ["Monkey Bread"] = true, ["Gorilla Barrel"] = true }
local GHOSTWALKER = { ["Ghostwalker"] = true, ["Dual Ghostwalker"] = true }
local SWINBURNE = { ["Swinburne"] = true, ["Algernon"] = true }
local DRAKOCAGE = { ["Drakocage"] = true, ["Monfined"] = true }
TEAPOT = { ["Teapot Battler"] = true, ["Newell Battler"] = true }
local KNIGHT = { ["Knight"] = true, ["Pwnsalot"] = true }
local GRAPPLER = { ["Grappler"] = true, ["Crusader"] = true }
local VIKING = { ["Viking"] = true, ["Norman"] = true }
local BEACON = { ["Beacon"] = true, ["Ultimate"] = true }
local SPAMBOX = { ["Spambox Battler"] = true, ["Sorcus Battler"] = true }
local SIGNBUDDY = { ["Sign Buddy"] = true, ["Fish Buddy"] = true }
local DOPAMINE = { ["Dopamine"] = true, ["Dendritic"] = true }
local FLOWER = { ["Flower"] = true, ["Depriver"] = true }
OSCAR = { ["Oscar"] = true, ["Edmond"] = true }
local PIZZA = { ["Pizza Pal"] = true, ["Delivery Pal"] = true }
local BEAN = { ["Bean Battler"] = true, ["Burrito Battler"] = true }

function only(name)
	return { [name] = true }
end

local ROCKET_ARENA = {
	name = "Rocket Arena",
	boss = 14,
	limit = 15,
	steps = {
		{ 8, 6, ROCKET, 5 }, { 8, 6, ROCKET, 5 },
		{ 7, 7 },
		{ 5, 2 }, { 3, 2 }, { 3, 2 },
		{ 7, 7 },
	},
}

local DOOMSPIRE = {
	name = "Doomspire Brickbattle",
	boss = 17,
	limit = 20,
	steps = {
		{ 3, 15, HAMMER, 4 }, { 3, 15, HAMMER, 4 },
		{ 2, 3 }, { 2, 3 }, { 2, 3 },
		{ 1, 2 },
		{ 3, 4 }, { 3, 4 },
		{ 5, 6 }, { 5, 6 },
		{ 6, 7 },
		{ 10, 8, TITAN, 2 },
		{ 4, 5, BALLER, 4 }, { 4, 5, BALLER, 4 },
		{ 4, 15, HAMMER, 4 }, { 4, 15, HAMMER, 4 },
	},
}

local ULTIMATE_PAINTBALL = {
	name = "Ultimate Paintball",
	options = { "terminator" },
	boss = 13,
	limit = 10,
	steps = {
		{ 2, 1 }, { 3, 2 }, { 2, 1 }, { 3, 2 },
		{ 9, 9, SNIPER, 2 },
		{ 3, 3 }, { 5, 4 }, { 2, 1 }, { 3, 2 },
	},
}

local GALLONS = {
	name = "Gallons",
	options = { "bucketTagger" },
	boss = 33,
	limit = 10,
	preSkip = false,
	steps = {
		{ 2.5, 32, only("Cannonary"), 4 },
		{ 2.5, 29 },
		{ 2.5, 30 }, { 2.5, 30 },
		{ 2.5, 31, only("Bucket Tagger"), 4 },
		{ 2.5, 32, only("Cannonary"), 4 },
		{ 2.5, 28, only("Arch"), 3 },
		{ 2.5, 30 }, { 2.5, 30 },
		{ 2.5, 32, only("Cannonary"), 4 },
		{ 2.5, 28, only("Arch"), 3 },
		{ 2.5, 32, only("Cannonary"), 4 },
	},
}

local DISCO_PARTY = {
	name = "Disco Party",
	boss = 37,
	limit = 10,
	preSkip = false,
	steps = {
		{ 2.5, 29, only("Gallant"), 4 },
		{ 2.5, 34, only("Bugle Battler"), 1 },
		{ 2.5, 4 }, { 2.5, 4 },
		{ 2.5, 5 },
		{ 2.5, 150, only("Roadbumper"), 3 },
		{ 2.5, 35, only("Guitar Trainee"), 1 },
		{ 2.5, 29, only("Gallant"), 4 },
		{ 2.5, 36, only("Cymbal Boy"), 1 },
		{ 2.5, 4 },
		{ 2.5, 5 }, { 2.5, 5 },
		{ 2.5, 150, only("Roadbumper"), 3 },
	},
}

local ON_THE_HEIGHTS = {
	name = "On the Heights",
	options = { "bucketTagger" },
	boss = 40,
	limit = 22,
	steps = {
		{ 8, 8, TITAN, 3 },
		{ 5, 27 }, { 2, 27 }, { 2, 27 },
		{ 5, 31 },
		{ 5, 38 }, { 3, 38 },
		{ 4, 29 },
		{ 6, 30 }, { 2, 30 }, { 2, 30 },
		{ 4, 31 },
		{ 4, 32, CANNON, 4 },
		{ 14, 39, GARGANT, 2 },
		{ 4, 29 },
		{ 5, 30 }, { 2, 30 }, { 2, 30 },
		{ 5, 38 }, { 2, 38 },
		{ 4, 31 },
		{ 5, 32, CANNON, 4 },
		{ 10, 8, TITAN, 3 },
	},
}

local AREA_51 = {
	name = "Area 51",
	options = { "patrol", "deleter", "bloodhorn" },
	boss = 72,
	limit = 24,
	steps = {
		{ 6, 57, PATROL, 3 },
		{ 6, 68 }, { 2, 68 },
		{ 5, 69, SAPPER, 3 },
		{ 6, 54 }, { 1, 54 },
		{ 12, 65, LITTLEMAN, 3 },
		{ 4, 68 },
		{ 6, 67, DELETER, 4 },
		{ 4, 55 }, { 1, 55 },
		{ 6, 69, SAPPER, 3 },
		{ 5, 68 }, { 2, 68 },
		{ 6, 67, DELETER, 4 },
		{ 18, 70, FATBOY, 3 },
		{ 6, 67, DELETER, 4 },
	},
}

local TALENT_SHOW = {
	name = "Talent Show",
	options = { "patrol", "bloodhorn" },
	boss = 71,
	limit = 22,
	preSkip = false,
	steps = {
		{ 7, 57, PATROL, 3 },
		{ 6, 66, PIANIST, 1 },
		{ 4, 62, JESTER, 4 },
		{ 3, 63, BLINDER, 4 },
		{ 5, 64, MONKEY, 3 },
		{ 6, 62, JESTER, 4 },
		{ 5, 63, BLINDER, 4 },
		{ 3, 56 },
		{ 8, 57, PATROL, 3 },
		{ 4, 64, MONKEY, 3 },
		{ 4, 56 },
		{ 11, 65, LITTLEMAN, 3 },
		{ 5, 62, JESTER, 4 },
		{ 5, 64, MONKEY, 3 },
	},
}

local MISTERMANCER = {
	name = "Haunted Mansion",
	options = { "patrol" },
	boss = 61,
	limit = 10,
	preSkip = false,
	steps = {
		{ 2.5, 57, PATROL, 3 },
		{ 2.5, 55 },
		{ 2.5, 54 },
		{ 2.5, 55 },
		{ 2.5, 54 },
		{ 2.5, 56 },
		{ 2.5, 59 },
		{ 2.5, 58 },
		{ 2.5, 59 },
		{ 2.5, 58 },
		{ 2.5, 60, only("Crazy Chemist"), 2 },
		{ 2.5, 56 },
		{ 2.5, 59 }, { 2.5, 59 },
	},
}

local CARNIVAL_DISASTER = {
	name = "Carnival Disaster",
	boss = 143,
	limit = 24,
	steps = {
		{ 6, 139 }, { 5, 139 }, { 5, 138 }, { 6, 139 },
		{ 6, 134, GHOSTWALKER, 3 },
		{ 3, 141, SWINBURNE, 3 },
		{ 4, 140 }, { 5, 140 }, { 5, 139 },
		{ 15, 142, DRAKOCAGE, 2 },
		{ 6, 134, GHOSTWALKER, 3 },
		{ 10, 134, GHOSTWALKER, 3 },
		{ 8, 140 },
		{ 3, 141, SWINBURNE, 3 },
		{ 6, 138 }, { 5, 140 }, { 6, 131 }, { 5, 139 }, { 5, 140 },
		{ 5, 141, SWINBURNE, 3 },
		{ 2, 131 },
	},
}

local TEAPOTS_OF_UTOPIA = {
	name = "Teapots of Utopia",
	boss = 122,
	limit = 26,
	steps = {
		{ 14, 120, TEAPOT, 3 },
		{ 5, 99 }, { 2, 99 },
		{ 4, 101, KNIGHT, 6 },
		{ 5, 111 }, { 2, 111 },
		{ 5, 113, GRAPPLER, 4 },
		{ 8, 104, VIKING, 4 },
		{ 6, 118 },
		{ 12, 120, TEAPOT, 3 },
		{ 4, 101, KNIGHT, 6 },
		{ 5, 113, GRAPPLER, 4 },
		{ 8, 104, VIKING, 4 },
		{ 6, 118 },
		{ 5, 99 }, { 2, 99 },
		{ 4, 101, KNIGHT, 6 },
		{ 5, 113, GRAPPLER, 4 },
		{ 12, 120, TEAPOT, 3 },
		{ 5, 111 }, { 2, 111 },
		{ 4, 101, KNIGHT, 6 },
		{ 8, 104, VIKING, 4 },
		{ 6, 118 },
		{ 12, 119, BEACON, 1 },
		{ 8, 104, VIKING, 4 },
		{ 6, 118 },
	},
}

local THIRD_TREE = {
	name = "The Third Tree",
	boss = 149,
	limit = 30,
	steps = {
		{ 8, 130 }, { 4, 130 },
		{ 6, 144 },
		{ 8, 146, SPAMBOX, 2 },
		{ 6, 146, SPAMBOX, 2 },
		{ 10, 130 }, { 4, 130 },
		{ 16, 142, DRAKOCAGE, 3 },
		{ 6, 144 },
		{ 6, 146, SPAMBOX, 2 },
		{ 5, 135, SIGNBUDDY, 2 },
		{ 8, 145, DOPAMINE, 2 },
		{ 10, 130 }, { 3, 130 },
		{ 5, 144 },
		{ 6, 147, FLOWER, 3 },
		{ 16, 144 }, { 6, 144 },
		{ 8, 146, SPAMBOX, 2 },
		{ 16, 142, DRAKOCAGE, 3 },
		{ 6, 144 },
		{ 8, 135, SIGNBUDDY, 2 },
		{ 8, 135, SIGNBUDDY, 2 },
		{ 5, 144 },
		{ 10, 130 }, { 3, 130 },
		{ 20, 148, OSCAR, 2 },
		{ 6, 145, DOPAMINE, 2 },
		{ 6, 144 },
		{ 8, 147, FLOWER, 3 },
	},
}

local SARGES_PIZZERIA = {
	name = "Sarge's Pizzeria",
	boss = 137,
	limit = 25,
	steps = {
		{ 11, 136, PIZZA, 3 },
		{ 10, 135, SIGNBUDDY, 3 },
		{ 6, 132 },
		{ 5, 133, BEAN, 4 },
		{ 4, 130 }, { 4, 130 },
		{ 6, 132 },
		{ 4, 131 }, { 4, 131 },
		{ 5, 133, BEAN, 4 },
		{ 5, 134 },
		{ 10, 135, SIGNBUDDY, 3 },
		{ 6, 132 },
		{ 5, 133, BEAN, 4 },
		{ 4, 134 },
		{ 4, 130 }, { 4, 130 },
		{ 5, 133, BEAN, 4 },
		{ 5, 134 },
		{ 6, 132 },
		{ 12, 136, PIZZA, 3 },
		{ 4, 131 }, { 4, 130 },
		{ 5, 133, BEAN, 4 },
		{ 12, 136, PIZZA, 3 },
	},
}

local FLIGHT = { ["Flight"] = true, ["Jolly"] = true }
local MCBURN = { ["McBurn"] = true, ["McBlast"] = true }
local AIRHEAD = { ["Airhead"] = true, ["Skittle"] = true }
local JUDGEMENT = { ["Judgement"] = true, ["Punishment"] = true }
local SINGER = { ["Singer"] = true, ["Vocalist"] = true }

local BLADED_VENGEANCE = {
	name = "Bladed Vengeance",
	boss = 117,
	limit = 20,
	steps = {
		{ 4, 100, FLIGHT, 4 },
		{ 5, 100, FLIGHT, 4 },
		{ 8, 111 }, { 5, 111 },
		{ 8, 112 },
		{ 6, 116, MCBURN, 3 },
		{ 6, 112 },
		{ 6, 102, AIRHEAD, 3 },
		{ 16, 115, JUDGEMENT, 1 },
		{ 4, 114, SINGER, 2 },
		{ 4, 113 },
		{ 3, 100, FLIGHT, 4 },
		{ 10, 116, MCBURN, 3 },
		{ 4, 100, FLIGHT, 4 },
		{ 6, 113 },
		{ 6, 111 }, { 4, 111 },
		{ 6, 102, AIRHEAD, 3 },
	},
}

local MONSALT = {
	name = "Chessmaster",
	boss = 110,
	limit = 18,
	preSkip = false,
	steps = {
		{ 2.5, 104, only("Viking"), 3 },
		{ 2.5, 99 }, { 2.5, 99 },
		{ 2.5, 101, only("Knight"), 4 }, { 2.5, 101, only("Knight"), 4 },
		{ 2.5, 105, only("Henchman"), 4 },
		{ 2.5, 103, only("Mage Battler"), 3 },
		{ 2.5, 104, only("Viking"), 3 },
		{ 2.5, 101, only("Knight"), 4 },
		{ 2.5, 105, only("Henchman"), 4 },
		{ 2.5, 99 }, { 2.5, 99 },
		{ 2.5, 101, only("Knight"), 4 },
		{ 2.5, 103, only("Mage Battler"), 3 },
		{ 2.5, 104, only("Viking"), 3 },
	},
}

local FROST_LEGION = {
	name = "Frost Legion",
	boss = 53,
	limit = 26,
	steps = {
		{ 3, 47 }, { 1.5, 47 },
		{ 4, 52 },
		{ 3, 45 }, { 1.5, 45 },
		{ 3, 46 },
		{ 3, 48 }, { 1.5, 48 },
		{ 3, 46 },
		{ 3, 49 },
		{ 3, 51 }, { 1.5, 51 },
		{ 4, 52 },
		{ 3, 50 }, { 1.5, 50 },
		{ 4, 52 },
	},
}

local COILFRONTATION = {
	name = "Coilfrontation",
	boss = 26,
	limit = 26,
	steps = {
		{ 3, 10 }, { 1.5, 10 }, { 1.5, 10 },
		{ 3, 23 },
		{ 3, 12 }, { 1.5, 12 }, { 1.5, 12 },
		{ 3, 25 },
		{ 3, 11 }, { 1.5, 11 }, { 1.5, 11 },
		{ 3, 24 },
	},
}

local END_OF_BEGINNING = {
	name = "End of Beginning",
	limit = 10,
	steps = {
		{ 2.5, 18 }, { 2.5, 18 }, { 2.5, 18 },
		{ 2.5, 19 }, { 2.5, 19 },
		{ 2.5, 20 }, { 2.5, 20 },
		{ 2.5, 21 }, { 2.5, 21 }, { 2.5, 21 },
		{ 2.5, 22 }, { 2.5, 22 },
	},
}

local BIRTHDAY_BASH = {
	name = "Birthday Bash",
	boss = 44,
	limit = 15,
	preSkip = false,
	steps = {
		{ 2.5, 18 }, { 2.5, 18 },
		{ 2.5, 41 }, { 2.5, 41 },
		{ 2.5, 42, only("Baker Battler"), 3 },
		{ 2.5, 2 },
		{ 2.5, 20 }, { 2.5, 20 },
		{ 2.5, 42, only("Baker Battler"), 3 },
		{ 2.5, 4 }, { 2.5, 4 },
		{ 2.5, 5 },
		{ 2.5, 43 }, { 2.5, 43 },
	},
}

local HUNTER = { ["Hunter"] = true, ["Arbalest"] = true }
local CASTER = { ["Caster"] = true, ["Bloodcaster"] = true }
local ADMIRER = { ["Admirer"] = true, ["Acolyte"] = true }
local CULTIST = { ["Cultist Muffin"] = true, ["Illuminist Muffin"] = true }
local ARMORED = { ["Armored Muffin"] = true, ["Shielded Muffin"] = true }
local CUPCAKE = { ["Cupcake"] = true, ["Cake"] = true }
local TANKMUFFIN = { ["Tank Muffin"] = true, ["Prism Tank Muffin"] = true }
local BAZOOKA = { ["Bazooka Muffin"] = true, ["Robotic Muffin"] = true }
local SPECIALIST = { ["Specialist Muffin"] = true, ["Anarchist Muffin"] = true }

local EXSANGUINATION = {
	name = "Exsanguination",
	boss = 129,
	limit = 26,
	steps = {
		{ 3, 124, HUNTER, 6 }, { 4, 124, HUNTER, 6 },
		{ 2, 125 },
		{ 3, 123 },
		{ 3, 124, HUNTER, 6 },
		{ 2, 123 },
		{ 4, 126, CASTER, 6 },
		{ 2, 127 }, { 2, 127 },
		{ 2, 125 },
		{ 11, 128, ADMIRER, 3 },
		{ 2, 127 }, { 3, 127 },
		{ 2, 123 },
		{ 2, 125 },
		{ 3, 123 },
		{ 3, 124, HUNTER, 6 },
		{ 2, 123 },
		{ 4, 127 }, { 2, 127 },
		{ 11, 128, ADMIRER, 3 },
		{ 2, 126, CASTER, 6 },
		{ 4, 124, HUNTER, 6 },
		{ 4, 125 },
		{ 2, 123 },
		{ 4, 127 }, { 2, 127 }, { 2, 127 }, { 2, 127 },
		{ 6, 126, CASTER, 6 },
	},
}

DARK_PELICAN = {
	name = "Dark Pelican - Fraud of Truth",
	pelican = true,
	boss = 151,
	limit = 25,
	steps = {
		{ 6, 18 }, { 1, 18 }, { 1, 18 },
		{ 6, 19 }, { 2, 19 },
		{ 6, 20 }, { 2, 20 },
		{ 6, 21 }, { 2, 21 }, { 2, 21 },
		{ 6, 22 }, { 2, 22 },
	},
}

local FINAL_JUDGEMENT = {
	name = "Final Judgement",
	boss = 82,
	limit = 22,
	steps = {
		{ 4, 74 }, { 1, 74 },
		{ 5, 80, CULTIST, 4 },
		{ 4, 76, ARMORED, 4 },
		{ 3, 75 }, { 2, 75 },
		{ 4, 76, ARMORED, 4 },
		{ 5, 77, CUPCAKE, 4 },
		{ 3, 75 }, { 2, 75 },
		{ 10, 81, TANKMUFFIN, 2 },
		{ 4, 74 }, { 1, 74 },
		{ 3, 78, BAZOOKA, 4 },
		{ 5, 80, CULTIST, 4 },
		{ 5, 78, BAZOOKA, 4 },
		{ 5, 79, SPECIALIST, 4 },
		{ 3, 74 }, { 1, 74 },
		{ 4, 76, ARMORED, 4 },
		{ 5, 77, CUPCAKE, 4 },
		{ 2, 78, BAZOOKA, 4 },
	},
}

-- AWC Bossrush: one boss at a time, the next one spawns when the current one dies.
-- Order follows the wiki (1 Star): Terminator, Hellfighter, Soulfuse, Scarlet Storm (replaced Bulldozer),
-- Rockstar Radical, Celebration Battler. All use form A for now.
AWC_BOSSRUSH = {
	name = "AWC Bossrush",
	options = { "terminator" },
	limit = 10,
	rush = { 13, 14, 26, 33, 37, 44 },
	steps = {},
}

-- Stages (converted from Delifell's scripts). strength = the stage's own magnification (the Enemy Strength box overrides it).
local THE_BATTLE_BEGINS = {
	name = "The Battle Begins",
	limit = 2,
	preSkip = false,
	steps = {
		{ 7, 1 },
	},
}

local TEA_HEE_TIME = {
	name = "Tea-Hee Time",
	limit = 22,
	preSkip = false,
	steps = {
		{ 4, 68 }, { 2, 68 },
		{ 3, 62 },
		{ 8, 120 },
		{ 2, 111 },
		{ 2, 102 },
		{ 6, 103 },
		{ 2, 68 },
		{ 8, 60 },
		{ 3, 62 },
		{ 2, 102 },
		{ 2, 111 },
		{ 14, 120 },
		{ 2, 68 },
		{ 6, 103 },
		{ 3, 62 },
		{ 2, 111 },
	},
}

local DECLARING_ARMAGEDDON = {
	name = "Declaring Armageddon",
	strength = 12,
	limit = 24,
	preSkip = false,
	steps = {
		{ 7, 120, TEAPOT, 3 },
		{ 4, 99 }, { 2, 99 },
		{ 2, 112 },
		{ 3, 104, VIKING, 4 },
		{ 6, 99 },
		{ 7, 104, VIKING, 4 },
		{ 4, 112 },
		{ 15, 119, BEACON, 1 },
		{ 3, 111 },
		{ 5, 118 },
		{ 3, 111 },
		{ 4, 112 },
		{ 3, 111 },
		{ 8, 118 },
		{ 10, 120, TEAPOT, 3 },
		{ 20, 115, JUDGEMENT, 1 },
		{ 4, 112 },
		{ 8, 104, VIKING, 4 },
		{ 3, 99 }, { 3, 99 },
		{ 5, 104, VIKING, 4 },
		{ 10, 120, TEAPOT, 3 },
		{ 8, 118 },
		{ 2, 118 },
	},
}

local REVOLVE_THE_REVOLT = {
	name = "Revolve The Revolt",
	strength = 1,
	limit = 19,
	preSkip = false,
	steps = {
		{ 1, 119, BEACON, 2 },
		{ 2, 138 },
		{ 2, 139 },
		{ 2, 133 },
		{ 3, 65 },
		{ 6, 139 },
		{ 5, 141, SWINBURNE, 2 },
		{ 6, 115, JUDGEMENT, 1 },
		{ 3, 99 },
		{ 3, 133 },
		{ 2, 119, BEACON, 2 },
		{ 3, 99 },
		{ 3, 65 },
		{ 6, 138 },
		{ 2, 139 },
		{ 3, 133 },
		{ 3, 99 },
	},
}

local BURNOUT = { ["Burnout"] = true, ["Bottled"] = true }
local BOMB_BATTLER = { ["Bomb Battler"] = true, ["Kamikaze Battler"] = true }

local FLARES_OF_DAMNATION = {
	name = "Flares of Damnation",
	credits = "Credits: made by Gerald Broflovski",
	limit = 18,
	preSkip = false,
	steps = {
		{ 3, 88, BURNOUT, 3 },
		{ 2, 83 }, { 2, 83 },
		{ 4, 120, TEAPOT, 2 },
		{ 3, 58 }, { 2, 58 },
		{ 4, 7 },
		{ 3, 125 },
		{ 3, 58 },
		{ 3, 88, BURNOUT, 3 },
		{ 5, 23 },
		{ 2, 83 }, { 2, 83 },
		{ 4, 7 },
		{ 3, 58 }, { 2, 58 },
		{ 3, 125 },
		{ 2, 83 }, { 2, 83 },
	},
}

-- the original runs at spawn rate 1111111, so every delay is 0 and only the unit limit (40) holds it back
local GOD_I_HATE_THIS_GAME = {
	name = "God I hate this game, it's so unbalanced, can we fire the devs please",
	nameSize = 12,
	credits = "Credits: made by mastathegamer",
	noBossless = true, -- shows the Tumored cycle switch (no fixed form) and no Bossless switch
	boss = 150,
	limit = 40,
	steps = {
		{ 0, 8, TITAN, 4 }, { 0, 8, TITAN, 4 },
		{ 0, 22 }, { 0, 22 }, { 0, 22 },
		{ 0, 85 },
		{ 0, 88 }, { 0, 88 },
		{ 0, 10 }, { 0, 10 },
		{ 0, 23 },
		{ 0, 15, HAMMER, 2 },
		{ 0, 7, BOMB_BATTLER, 4 }, { 0, 7, BOMB_BATTLER, 4 },
		{ 0, 8, TITAN, 4 }, { 0, 8, TITAN, 4 },
	},
}

CATEGORIES = {
	{ name = "Chapter 1", chapters = { ROCKET_ARENA, DOOMSPIRE, ULTIMATE_PAINTBALL } },
	{ name = "Chapter 2", chapters = { GALLONS, DISCO_PARTY, ON_THE_HEIGHTS } },
	{ name = "Chapter 3", chapters = { AREA_51, TALENT_SHOW, MISTERMANCER } },
	{ name = "Chapter 4", chapters = { TEAPOTS_OF_UTOPIA, BLADED_VENGEANCE, MONSALT } },
	{ name = "Chapter 5", chapters = { CARNIVAL_DISASTER, THIRD_TREE, SARGES_PIZZERIA } },
}

-- own tabs: put stage tables (like ROCKET_ARENA above) into these lists and they show up as rows
STAGES = {
	{ name = "Stages", chapters = { THE_BATTLE_BEGINS, TEA_HEE_TIME, DECLARING_ARMAGEDDON, REVOLVE_THE_REVOLT, FLARES_OF_DAMNATION, GOD_I_HATE_THIS_GAME } },
}

SUBCHAPTERS = {
	{ name = "Subchapters", chapters = { FROST_LEGION, COILFRONTATION, END_OF_BEGINNING, BIRTHDAY_BASH, EXSANGUINATION, DARK_PELICAN, FINAL_JUDGEMENT } },
}
end


-- FOR AMERICA!!!! (idea by pea gun): 300% on 1 star, unit limit 20.
-- IDs I could not find anywhere in the script: fill in id (and form "A" / "B") for these three.
local FOR_AMERICA_IDS = {
	commander = { id = nil, form = "A" },
	soldierMuffin = { id = nil, form = "A" },
	operator = { id = 81, form = "A" }, -- Tank Muffin, spawned on the ally team
}

local FOR_AMERICA = {
	name = "FOR AMERICA!!!!",
	subtitle = "idea by pea gun",
	flag = true,
	fixedForms = true,
	boss = 108, -- Patriot Warhead (this is what makes the Bossless switch show up)
	options = { "noSupportBosses" },
	limit = 20,
	strength = 3,
	steps = {},
	script = function(ctx)
		local warned = {}
		local function unit(name, id, form, strength, options)
			if not id then
				if not warned[name] then
					warned[name] = true
					warn("FOR AMERICA!!!!: no ID set for " .. name .. " (fill it in FOR_AMERICA_IDS)")
				end
				return true
			end
			return ctx.spawn(id, form, strength, options)
		end

		-- every boss from the other stages, used for the 3 random supporting bosses
		local function bossPool()
			local pool, seen = {}, {}
			for _, list in ipairs({ CATEGORIES, STAGES, SUBCHAPTERS }) do
				for _, category in ipairs(list) do
					for _, chapter in ipairs(category.chapters) do
						if chapter.boss and not chapter.pelican and not seen[chapter.boss] then
							seen[chapter.boss] = true
							table.insert(pool, chapter.boss)
						end
					end
				end
			end
			return pool
		end

		local function callInBosses()
			if ctx.opts.noSupportBosses then return end
			local pool = bossPool()
			if #pool == 0 then return end
			for index = 1, 3 do
				if not ctx.active() then return end
				ctx.spawn(pool[math.random(#pool)], "A", 1, { force = true }) -- 100%
				if index < 3 and not ctx.wait(5) then return end
			end
		end

		-- half health: 3 random bosses, 5 seconds apart. about to explode (10% health or dead): American Fatboy at 150%
		local function watchBoss(before)
			task.spawn(function()
				local boss
				for _ = 1, 40 do
					task.wait(0.1)
					if not ctx.active() then return end
					boss = ctx.findNew(before)
					if boss then break end
				end
				local hum = boss and boss:FindFirstChildOfClass("Humanoid")
				if not hum then return end
				local halfDone, boomDone = false, false
				local function boom()
					boomDone = true
					task.spawn(function()
						ctx.spawn(108, "A", 1.5, { force = true })
					end)
				end
				while ctx.active() and boss.Parent and hum.Parent and not (halfDone and boomDone) do
					local ratio = hum.Health / math.max(hum.MaxHealth, 1)
					if not halfDone and ratio <= 0.5 then
						halfDone = true
						task.spawn(callInBosses)
					end
					if not boomDone and ratio <= 0.1 then
						boom()
					end
					task.wait(0.1)
				end
				if not boomDone and ctx.active() and hum.Health <= 0 then
					boom()
				end
			end)
		end

		local function cycle()
			if not ctx.wait(3) then return false end
			local commander = FOR_AMERICA_IDS.commander
			if not unit("Commander", commander.id, commander.form, nil, { idCap = 1 }) then return false end

			if not ctx.wait(2) then return false end
			for index = 1, 2 do
				if not unit("Mercenary", 32, "B") then return false end
				if index < 2 and not ctx.wait(1) then return false end
			end

			if not ctx.wait(2) then return false end
			local muffin = FOR_AMERICA_IDS.soldierMuffin
			for index = 1, 3 do
				if not unit("Soldier Muffin", muffin.id, muffin.form) then return false end
				if index < 3 and not ctx.wait(2) then return false end
			end

			if not ctx.wait(1) then return false end
			local operator = FOR_AMERICA_IDS.operator
			if not unit("Operator", operator.id, operator.form, nil, { ally = true }) then return false end

			if not ctx.wait(2) then return false end
			for index = 1, 2 do
				if not unit("Mercenary", 32, "B") then return false end
				if index < 2 and not ctx.wait(1) then return false end
			end

			if not ctx.wait(3) then return false end
			for index = 1, 3 do
				if not unit("Crocket Battler", 6, "B") then return false end
				if index < 3 and not ctx.wait(2) then return false end
			end

			if not ctx.wait(2) then return false end
			if not unit("Illuminist Muffin", 80, "B") then return false end

			if not ctx.wait(10) then return false end
			for index = 1, 5 do
				if not unit("Dark Bomber Battler", 22, "B") then return false end
				if index == 3 and not unit("Punishment", 115, "B", nil, { idCap = 2 }) then return false end
				if index < 5 and not ctx.wait(3) then return false end
			end
			return true
		end

		-- Patriot Warhead is the boss: spawned once, then the cycle repeats (Bossless skips him and his gimmicks)
		if not ctx.opts.bossless then
			local before = ctx.snapshot()
			if not ctx.spawn(108, "B") then return end
			watchBoss(before)
		end
		while ctx.active() do
			if not cycle() then return end
			task.wait()
		end
	end,
}

local CUSTOM_STAGES = {
	{ name = "Custom Bosses/Stages", chapters = { FOR_AMERICA } },
}

local spawners = {}

local function newChapterOpts()
	return {
		strength = nil,
		bossless = false,
		swapTerminator = false,
		replaceTaggers = false,
		removePatrol = false,
		removeDeleter = false,
		removeBloodhorn = false,
		noSupportBosses = false,
	}
end

local function createSpawner(chapter, form, opts)
	if chapter.form then form = chapter.form end -- some stages always spawn one form
	local session = 0
	local enabled = false
	local preSkip = chapter.preSkip ~= false

	local function isActive(mySession)
		return enabled and session == mySession and checkBasesValid()
	end

	local function spawnUnit(id, mySession, capNames, cap)
		local spawnForm = form

		if opts.removePatrol and id == IDS.PatrolPrincipal then return true end
		if opts.removeDeleter and id == IDS.DeleterExpunger then return true end
		if opts.removeBloodhorn and id == IDS.LittlemanBloodhorn and spawnForm == "B" then return true end
		if opts.replaceTaggers and (id == IDS.BucketTagger or (IDS.TreasureSeller and id == IDS.TreasureSeller)) then
			id = 1
			spawnForm = "A"
			capNames = nil
		end

		if opts.swapTerminator and id == IDS.Terminator and spawnForm == "B" then
			spawnForm = "A"
		end

		local limit = UnitLimitOverride or chapter.limit
		while aliveEnemies() >= limit do
			task.wait(0.1)
			if not isActive(mySession) then return false end
		end
		if not isActive(mySession) then return false end

		if capNames and countByNames(capNames) >= cap then
			return true
		end

		while Custom.busy do
			task.wait(0.05)
		end
		SandboxSpawn:InvokeServer("Enemy", id, spawnForm, opts.strength or chapter.strength or Magnification, {})
		return true
	end

	local function snapshotUnits()
		local seen = {}
		for _, folderName in ipairs({ "FriendlyFolder", "EnemyFolder" }) do
			local npcRoot = Workspace:FindFirstChild("NPCFolders")
			local folder = npcRoot and npcRoot:FindFirstChild(folderName)
			if folder then
				for _, unit in folder:GetChildren() do
					seen[unit] = true
				end
			end
		end
		return seen
	end

	local function findNewBoss(before)
		local best, bestHealth = nil, -1
		for _, folderName in ipairs({ "FriendlyFolder", "EnemyFolder" }) do
			local npcRoot = Workspace:FindFirstChild("NPCFolders")
			local folder = npcRoot and npcRoot:FindFirstChild(folderName)
			if folder then
				for _, unit in folder:GetChildren() do
					if not before[unit] then
						local hum = unit:FindFirstChildOfClass("Humanoid")
						if hum and hum.MaxHealth > bestHealth then
							best, bestHealth = unit, hum.MaxHealth
						end
					end
				end
			end
		end
		return best
	end

	local function normName(name)
		return (name:lower():gsub("[%s_%-]", ""))
	end

	-- boss name -> names of the units that must ALL die before the next boss spawns
	local RUSH_WAIT = {
		fusecoil = { "firegrind", "sidetoxic", "eurofrost", "fusecoil" },
		soulfuse = { "soulofgravity", "soulofregen", "soulofspeed" },
		djradical = { "radmobile" },
		rockstarradical = { "bombcopter" },
	}

	local function runRush(mySession)
		local index = 1
		while isActive(mySession) do
			local id = chapter.rush[index]
			local before = snapshotUnits()
			if not spawnUnit(id, mySession) then return end

			-- Birthday / Celebration Battler: the rush is over, switch it off
			if id == 44 then
				enabled = false
				session += 1
				if chapter.onStop then
					task.spawn(chapter.onStop)
				end
				return
			end

			local boss
			for _ = 1, 40 do
				task.wait(0.1)
				if not isActive(mySession) then return end
				boss = findNewBoss(before)
				if boss then break end
			end

			local waitNames = boss and RUSH_WAIT[normName(boss.Name)]
			if waitNames then
				local required = {}
				for _, name in ipairs(waitNames) do
					required[name] = true
				end
				local bossHum = boss:FindFirstChildOfClass("Humanoid")
				local seenNames, tracked = {}, {}
				local startTime = os.clock()
				local lastSeen = startTime
				local bossGoneAt = nil
				while isActive(mySession) do
					for _, folderName in ipairs({ "FriendlyFolder", "EnemyFolder" }) do
						local npcRoot = Workspace:FindFirstChild("NPCFolders")
						local folder = npcRoot and npcRoot:FindFirstChild(folderName)
						if folder then
							for _, unit in folder:GetChildren() do
								local key = normName(unit.Name)
								if required[key] and not before[unit] and not tracked[unit] then
									tracked[unit] = true
									seenNames[key] = true
									lastSeen = os.clock()
								end
							end
						end
					end

					local anyAlive = false
					for unit in pairs(tracked) do
						local hum = unit.Parent and unit:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 then
							anyAlive = true
							break
						end
					end

					if not anyAlive then
						if next(tracked) ~= nil then
							-- we saw some of them and they are all dead: done once everything showed up
							-- (or nothing new has shown up for a while)
							local seenAll = true
							for name in pairs(required) do
								if not seenNames[name] then
									seenAll = false
									break
								end
							end
							if seenAll or os.clock() - lastSeen > 15 then
								break
							end
						else
							-- nothing to wait for has appeared yet (e.g. Soulfuse jumping before his souls show up):
							-- keep waiting, only give up if the boss is gone for a long time or after a long cap
							local bossAlive = boss.Parent and bossHum and bossHum.Parent and bossHum.Health > 0
							if bossAlive then
								bossGoneAt = nil
							else
								bossGoneAt = bossGoneAt or os.clock()
								if os.clock() - bossGoneAt > 20 then
									break
								end
							end
							if os.clock() - startTime > 120 then
								break
							end
						end
					end
					task.wait(0.2)
				end
				if not isActive(mySession) then return end
			elseif boss then
				local hum = boss:FindFirstChildOfClass("Humanoid")
				while isActive(mySession) and boss.Parent and hum and hum.Parent and hum.Health > 0 do
					task.wait(0.2)
				end
				if not isActive(mySession) then return end
			end

			task.wait(0.5)
			index = index % #chapter.rush + 1
		end
	end

	-- helpers handed to a stage's own script (chapter.script) so it can spawn with the menu's limits and timing
	local function makeContext(mySession)
		local ctx = {}
		function ctx.active()
			return isActive(mySession)
		end
		-- waits (scaled by the spawn rate) and tells you if the stage is still running
		function ctx.wait(seconds)
			task.wait(DelayEnemyCycle and (seconds / SpawnRate) or 0)
			return isActive(mySession)
		end
		-- options: idCap = max alive of this unit ID, force = ignore the unit limit,
		-- ally = spawn on the ally team (Spawn Teams Swap goes off for the spawn, then back to what it was)
		-- strength nil = the stage's default (Enemy Strength box, else chapter.strength)
		function ctx.spawn(id, form, strength, options)
			options = options or {}
			if not options.force then
				local limit = UnitLimitOverride or chapter.limit
				while aliveEnemies() >= limit do
					task.wait(0.1)
					if not isActive(mySession) then return false end
				end
			end
			if not isActive(mySession) then return false end
			if options.idCap and countById(id) >= options.idCap then
				return true
			end
			while Custom.busy do
				task.wait(0.05)
			end
			local spawnStrength = strength or opts.strength or chapter.strength or Magnification
			if options.ally then
				local previousSwap = Custom.swap
				if previousSwap == nil then previousSwap = SwitchTeamsAtStart and true or false end
				Custom.busy = true -- other spawns wait while swap is off
				Custom.setSwap(false)
				pcall(function()
					SandboxSpawn:InvokeServer("Enemy", id, form, spawnStrength, {})
				end)
				Custom.setSwap(previousSwap)
				Custom.busy = false
				return true
			end
			SandboxSpawn:InvokeServer("Enemy", id, form, spawnStrength, {})
			return true
		end
		ctx.opts = opts
		ctx.snapshot = snapshotUnits
		ctx.findNew = findNewBoss
		return ctx
	end

	local function runCycle(mySession)
		task.spawn(function()
			if SwitchTeamsAtStart then
				SandboxSettings:InvokeServer("SpawnTeamsSwap", true)
				Custom.swap = true
			end
			SandboxSettings:InvokeServer("EnableHealthBars", true)
		end)
		if chapter.rush then
			runRush(mySession)
			return
		end
		if chapter.script then
			chapter.script(makeContext(mySession))
			return
		end
		if chapter.boss and not opts.bossless then
			if not spawnUnit(chapter.boss, mySession) then return end
		end

		while isActive(mySession) do
			for _, step in ipairs(chapter.steps) do
				local delay, id, capNames, cap = step[1], step[2], step[3], step[4]
				local capped = capNames ~= nil

				if preSkip and capped and countByNames(capNames) >= cap then
					continue
				end

				task.wait(DelayEnemyCycle and (delay / SpawnRate) or 0)
				if not isActive(mySession) then return end

				if not spawnUnit(id, mySession, capped and capNames or nil, cap) then return end
			end
			task.wait()
		end
	end

	local function watcher(mySession)
		while enabled and session == mySession do
			if getRefs() and checkBasesValid() then
				task.wait(0.1)
				if enabled and session == mySession and checkBasesValid() then
					runCycle(mySession)
				end
			end
			task.wait(0.5)
		end
	end

	local function setEnabled(on)
		enabled = on
		session += 1
		if on then
			task.spawn(watcher, session)
		end
	end

	table.insert(spawners, setEnabled)
	return setEnabled
end

local STUDS_PER_LENGTH = 2

local cannon = {
	on = false,
	mode = "Cannon",
	cooldown = 45,
	ranges = { Cannon = 100, Slammer = 6 },
	ready = true,
	readyAt = 0,
	visualTimer = false,
	rechargeThread = nil,
}

local destroyed = false

local function npcFolder(name)
	local npc = Workspace:FindFirstChild("NPCFolders")
	return npc and npc:FindFirstChild(name)
end

local function getPlayerSpawn()
	local events = ReplicatedStorage:FindFirstChild("Events")
	local rf = events and events:FindFirstChild("RemoteFunction")
	return rf and rf:FindFirstChild("PlayerSpawn")
end

local function sandboxBlueBase()
	local baseFolder = npcFolder("BaseFolder")
	local blue = baseFolder and baseFolder:FindFirstChild("Blue Base")
	if blue and blue:GetAttribute("Sandbox") then
		return blue
	end
	return nil
end

local function startCannonCooldown()
	if cannon.rechargeThread then
		task.cancel(cannon.rechargeThread)
		cannon.rechargeThread = nil
	end
	cannon.ready = false
	cannon.readyAt = os.clock() + cannon.cooldown
	cannon.rechargeThread = task.delay(cannon.cooldown, function()
		cannon.ready = true
		cannon.rechargeThread = nil
	end)
end

local function fireCannon()
	if not cannon.ready then return end
	local remote = getPlayerSpawn()
	if not remote then return end
	task.spawn(function()
		pcall(function()
			remote:InvokeServer("Cannon")
		end)
	end)
	startCannonCooldown()
end

local function resetCannon()
	cannon.ready = true
	cannon.readyAt = 0
	if cannon.rechargeThread then
		task.cancel(cannon.rechargeThread)
		cannon.rechargeThread = nil
	end
end

task.spawn(function()
	local lastBlue = nil
	while not destroyed do
		task.wait(0.1)

		local blue = sandboxBlueBase()
		if blue ~= lastBlue then
			lastBlue = blue
			resetCannon()
		end

		if not blue or not cannon.on or cannon.mode == "Liberty" or not cannon.ready then continue end

		local enemies = npcFolder("EnemyFolder")
		local hitbox = blue:FindFirstChild("Spawn")
		if not enemies or not hitbox or not hitbox:IsA("BasePart") then continue end

		local range = cannon.ranges[cannon.mode] * STUDS_PER_LENGTH

		for _, enemy in enemies:GetChildren() do
			if enemy:GetAttribute("HiddenTime") or enemy:GetAttribute("ConfusedTime") or enemy:GetAttribute("JailStrength") then
				continue
			end
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			local root = enemy:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and root and (hitbox.Position - root.Position).Magnitude <= range then
				fireCannon()
				break
			end
		end
	end
end)

local liberty = { session = 0, enemyConnections = {}, folderConnections = {} }

local function libertyDisconnectEnemy(enemy)
	local connection = liberty.enemyConnections[enemy]
	if connection then
		connection:Disconnect()
		liberty.enemyConnections[enemy] = nil
	end
end

local function libertyConnectEnemy(enemy, mySession)
	if liberty.enemyConnections[enemy] then return end
	task.spawn(function()
		local humanoid = enemy:FindFirstChildOfClass("Humanoid") or enemy:WaitForChild("Humanoid", 5)
		if not humanoid or not humanoid:IsA("Humanoid") then return end
		if liberty.session ~= mySession or liberty.enemyConnections[enemy] then return end

		local previousHealth = humanoid.Health
		liberty.enemyConnections[enemy] = humanoid.HealthChanged:Connect(function(health)
			if health < previousHealth and health > 0 and sandboxBlueBase() then
				fireCannon()
			end
			previousHealth = health
		end)
	end)
end

local function libertyStop()
	liberty.session += 1
	for enemy in pairs(liberty.enemyConnections) do
		libertyDisconnectEnemy(enemy)
	end
	for _, connection in liberty.folderConnections do
		connection:Disconnect()
	end
	table.clear(liberty.folderConnections)
end

local function libertyStart()
	libertyStop()
	local mySession = liberty.session
	task.spawn(function()
		local folders = Workspace:WaitForChild("NPCFolders", 10)
		local friendly = folders and folders:WaitForChild("FriendlyFolder", 10)
		if not friendly or liberty.session ~= mySession then return end

		for _, enemy in friendly:GetChildren() do
			libertyConnectEnemy(enemy, mySession)
		end
		table.insert(liberty.folderConnections, friendly.ChildAdded:Connect(function(enemy)
			libertyConnectEnemy(enemy, mySession)
		end))
		table.insert(liberty.folderConnections, friendly.ChildRemoved:Connect(libertyDisconnectEnemy))
	end)
end

local function applyCannonMode()
	if cannon.on and cannon.mode == "Liberty" then
		libertyStart()
	else
		libertyStop()
	end
end

local chapterState = {}

-- Custom Spawner (Misc tab): a boss slot plus 25 unit slots, each with its own ID, mode and team.
-- Every spawn uses the "Enemy" type. Those land on the red team, so allies are spawned with the team swap
-- switched on, then the swap goes back to whatever the rest of the script uses.
Custom.FORMS = { casual = "A", tumored = "B" } -- Casual is the normal form
Custom.on = false
Custom.session = 0

function Custom.newDeath()
	return {
		enabled = false,   -- off = nothing happens when the battler dies
		id = 0,
		mode = "casual",
		ally = false,
		strength = nil,
		stats = {},
		outfit = "",
		timer = 0,
		limit = 0,
		count = 1,
		extraDelay = 1,
		tracked = {},
	}
end

function Custom.newSlot(isBoss)
	return {
		enabled = true,               -- slot switch: off = this slot is skipped (its settings are kept)
		id = 0,                       -- 0 = this slot does not spawn
		limit = isBoss and 0 or 5,    -- max alive from this slot (0 = no limit); unit slots only
		timer = isBoss and 0 or 3,    -- seconds before it spawns
		strength = nil,               -- enemy strength (nil = default)
		mode = "casual",              -- "casual" (normal form) | "tumored"
		ally = false,                 -- false = enemy unit (red), true = ally unit (blue)
		stats = {},                   -- stat overrides (hp, shield, armor, damage, bullets, range, speed); missing = game default
		tracked = {},                 -- units this slot spawned, for the limit
		count = 1,                    -- how many battlers per spawn (2 = 1 extra battler with the same ID)
		extraDelay = 1,               -- seconds before each extra battler
		outfit = "",                  -- an accessory code (from the Accessory Paster SAVE) put on every battler of this slot
		death = isBoss ~= nil and Custom.newDeath() or nil, -- "if this battler dies, spawn another" settings
	}
end

Custom.boss = Custom.newSlot(true)
Custom.units = {}
for index = 1, 25 do
	Custom.units[index] = Custom.newSlot(false)
end

function Custom.setSwap(value)
	if Custom.swap == value then return end
	Custom.swap = value
	pcall(function()
		SandboxSettings:InvokeServer("SpawnTeamsSwap", value)
	end)
end

function Custom.alive(slot)
	local count = 0
	for unit in pairs(slot.tracked) do
		local humanoid = unit.Parent and unit:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			count += 1
		else
			slot.tracked[unit] = nil
		end
	end
	return count
end

function Custom.spawn(slot)
	if slot.id <= 0 or not getRefs() or not sandboxBlueBase() then return false end
	while Custom.busy do
		task.wait(0.05)
	end
	Custom.busy = true

	local spawned = false
	local ok, err = pcall(function()
		-- remember what is already there so we can find the unit we spawn
		local before = {}
		for _, folderName in ipairs({ "FriendlyFolder", "EnemyFolder" }) do
			local folder = npcFolder(folderName)
			if folder then
				for _, unit in folder:GetChildren() do
					before[unit] = true
				end
			end
		end

		local function collectNew()
			local found = {}
			for _, folderName in ipairs({ "FriendlyFolder", "EnemyFolder" }) do
				local folder = npcFolder(folderName)
				if folder then
					for _, unit in folder:GetChildren() do
						if not before[unit] then
							table.insert(found, unit)
						end
					end
				end
			end
			return found
		end

		local baseSwap = SwitchTeamsAtStart and true or false
		local strength = slot.strength or Magnification
		local form = Custom.FORMS[slot.mode]
		local stats = Custom.statTable and Custom.statTable(slot) or {}
		local statsCamel = Custom.statTable and Custom.statTable(slot, true) or {}
		local hasStats = next(stats) ~= nil

		local function attempt(spawnType, statsToSend, swap)
			Custom.setSwap(swap)
			local invoked, invokeError = pcall(function()
				SandboxSpawn:InvokeServer(spawnType, slot.id, form, strength, statsToSend)
			end)
			if not invoked then
				warn("Oscar's Cool Panel: spawn " .. spawnType .. " " .. tostring(slot.id) .. " failed: " .. tostring(invokeError))
				return false
			end
			for _ = 1, 8 do
				task.wait(0.1)
				local found = collectNew()
				if #found > 0 then
					for _, unit in found do
						slot.tracked[unit] = true
						if Custom.onSpawned then
							task.spawn(Custom.onSpawned, slot, unit)
						end
					end
					return true
				end
			end
			return false
		end

		-- ally = the game's Friendly unit (blue), enemy = the Enemy unit (red); the same ID gives that side's version.
		-- If something does not work (wrong stat names, Friendly not accepted) fall back step by step so a unit still spawns.
		local plan = {}
		local function addPlan(spawnType, swap)
			table.insert(plan, { spawnType, stats, swap })
			if hasStats then
				table.insert(plan, { spawnType, statsCamel, swap })
				table.insert(plan, { spawnType, {}, swap })
			end
		end
		if slot.ally then
			addPlan("Friendly", baseSwap)
			addPlan("Enemy", true) -- old way: an Enemy unit with the teams swapped
		else
			addPlan("Enemy", baseSwap)
		end

		for _, step in ipairs(plan) do
			if attempt(step[1], step[2], step[3]) then
				spawned = true
				if hasStats and next(step[2]) == nil then
					warn("Oscar's Cool Panel: the game did not accept the stat names, spawned with default stats. Open the game's spawn menu and press DETECT.")
				end
				break
			end
		end
	end)

	if not ok then
		warn("Oscar's Cool Panel: custom spawn error: " .. tostring(err))
	elseif not spawned then
		warn("Oscar's Cool Panel: could not spawn ID " .. tostring(slot.id))
	end

	Custom.setSwap(SwitchTeamsAtStart and true or false) -- keep the normal team setting
	Custom.busy = false
	return ok and spawned
end

-- spawns the slot's battler; if its count is 2 or more the extra battlers follow in the background,
-- one every "extraDelay" seconds, so the other slots are never held up
function Custom.spawnGroup(slot, isActive)
	local any = false
	if slot.limit == 0 or Custom.alive(slot) < slot.limit then
		if Custom.spawn(slot) then
			any = true
		end
	end
	local total = math.max(1, math.floor(slot.count or 1))
	for extra = 1, total - 1 do
		task.spawn(function()
			task.wait(DelayEnemyCycle and ((slot.extraDelay or 0) * extra / SpawnRate) or 0)
			if not isActive() or destroyed then return end
			if slot.limit == 0 or Custom.alive(slot) < slot.limit then
				Custom.spawn(slot)
			end
		end)
	end
	return any
end

function Custom.isActive(session)
	return Custom.on and Custom.session == session and checkBasesValid()
end

function Custom.runCycle(session)
	task.spawn(function()
		pcall(function()
			SandboxSettings:InvokeServer("EnableHealthBars", true)
		end)
	end)
	while Custom.isActive(session) do
		local spawned = false
		for _, slot in ipairs(Custom.units) do
			if not Custom.isActive(session) then return end
			if slot.id > 0 and slot.enabled then
				task.wait(DelayEnemyCycle and (slot.timer / SpawnRate) or 0)
				if not Custom.isActive(session) then return end
				if Custom.spawnGroup(slot, function()
					return Custom.isActive(session)
				end) then
					spawned = true
				end
			end
		end
		if not spawned then
			task.wait(0.5)
		end
	end
end

function Custom.watcher(session)
	while Custom.on and Custom.session == session do
		if getRefs() and checkBasesValid() then
			task.wait(0.1)
			if Custom.isActive(session) then
				Custom.runCycle(session)
			end
		end
		task.wait(0.5)
	end
end

function Custom.setEnabled(on)
	Custom.on = on
	Custom.session += 1
	if on then
		task.spawn(Custom.watcher, Custom.session)
	end
end
table.insert(spawners, Custom.setEnabled)

-- Boss slot: spawns right away (after its timer) whenever a new ID is entered
function Custom.spawnBoss()
	local slot = Custom.boss
	if slot.id <= 0 or not slot.enabled then return end
	task.spawn(function()
		task.wait(slot.timer)
		Custom.spawnGroup(slot, function()
			return true
		end)
	end)
end

local function getState(chapter)
	local state = chapterState[chapter]
	if not state then
		local opts = newChapterOpts()
		state = {
			on = false,
			tumoredOn = false,
			setNormal = createSpawner(chapter, "A", opts),
			setTumored = createSpawner(chapter, "B", opts),
			opts = opts,
			listeners = {},
		}
		chapterState[chapter] = state
	end
	return state
end

local function setChapter(chapter, on)
	local state = getState(chapter)
	state.on = on
	state.setNormal(on)
	for _, refresh in state.listeners do
		refresh()
	end
end

local function setChapterTumored(chapter, on)
	local state = getState(chapter)
	state.tumoredOn = on
	state.setTumored(on)
	for _, refresh in state.listeners do
		refresh()
	end
end

AWC_BOSSRUSH.onStop = function()
	setChapter(AWC_BOSSRUSH, false)
	setChapterTumored(AWC_BOSSRUSH, false)
end

local JETROCK = { ["Jetrock"] = true, ["Hellfighter"] = true }

local PANCAKE_TEXTURE = "rbxassetid://7940780144"
local FACE_TEXTURE = "rbxassetid://14693378169"
local SHIRT_TEXTURE = "http://www.roblox.com/asset/?id=15961342990"
local PANTS_TEXTURE = "http://www.roblox.com/asset/?id=15127605786"

local RAGE_PARTICLE_TEXTURE = "rbxassetid://12011714416"
local RAGE_SHIRT_TEXTURE = "rbxassetid://15437559653"
local RAGE_PANTS_TEXTURE = "rbxassetid://97707096036910"
local RAGE_MESH_TEXTURE = "rbxassetid://7940780144"

local LIMB_COLOR = Color3.fromRGB(255, 204, 153)
local MESH_COLOR = Color3.fromRGB(0, 0, 255)
local PELICAN_BLUE = Color3.fromRGB(0, 170, 255)

local PELICAN_LIMBS = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

local PELICAN_JET_SEQUENCE = {
	{ 1, "Chainsaw" }, { 1, "Chainsaw" },
	{ 1, "DarkBomber" }, { 1, "DarkBomber" }, { 1, "DarkBomber" },
	{ 3, "Zipbomb" }, { 2, "Zipbomb" },
	{ 2, "Tormented" }, { 1, "Tormented" },
	{ 1, "Magerator" },
	{ 2, "Zipbomb" },
	{ 2, "Magerator" },
}

local PELICAN_PEON_STEPS = {
	{ 6, 1 }, { 1, 1 }, { 1, 1 }, { 1, 1 },
	{ 6, 2 }, { 2, 2 }, { 2, 2 },
	{ 4, 3 }, { 2, 3 }, { 2, 3 },
	{ 4, 4 }, { 2, 4 }, { 2, 4 },
	{ 6, 5 }, { 2, 5 },
	{ 2, 6, SAPPER, 5 }, { 2, 6, SAPPER, 5 },
	{ 6, 5 }, { 2, 5 },
	{ 1, 1 }, { 1, 1 }, { 1, 1 },
	{ 6, 7, TEAPOT, 2 },
	{ 1, 1 }, { 1, 1 },
	{ 6, 8, JETROCK, 1 },
}

local function isRageExcluded(npc)
	return npc.Name == "Pancake Pelican Of Truth" or npc.Name == "Jet" or npc.Name == "Tank"
end

local function createPelicanScript(withPeons)
	local feature = { on = false }
	local session = 0

	local cycleActive = false
	local cycleGeneration = 0
	local buffedMode = false
	local rageModeActive = false
	local spawned75Percent = false
	local spawnedAt0HP = false

	local healthConnections = {}
	local folderConnections = {}
	local processedPelicans = setmetatable({}, { __mode = "k" })
	local pendingPelicans = setmetatable({}, { __mode = "k" })
	local rageProcessed = setmetatable({}, { __mode = "k" })
	local processedJets = setmetatable({}, { __mode = "k" })

	local units = {}

	local function buildUnits(mag)
		local buffed = mag * 5
		local function unit(id, form, magnification)
			return { "Enemy", id, form, magnification }
		end

		units.boss = unit(151, "B", mag * 1.25)

		units.doombringer = unit(17, "A", mag / 5)
		units.exec = unit(72, "A", mag / 5)
		units.scarletStorm = unit(33, "B", mag / 5)
		units.patriotWarhead = unit(108, "B", mag / 5)
		units.americanFatboy = unit(108, "A", mag / 5)
		units.xtreme = unit(72, "B", mag / 5)
		units.doomsdayMuffin = unit(82, "B", mag / 5)

		units.terminator = unit(13, "B", buffed)
		units.fatboy = unit(70, "A", buffed * 5)
		units.warhead = unit(70, "B", buffed * 5)
		units.redzone = unit(98, "B", buffed * 5)

		if withPeons then
			local ids = { 11, 75, 76, 79, 32, 69, 120, 14 }
			units.peons = {}
			units.buffedPeons = {}
			for index, id in ipairs(ids) do
				local divisor = id == 14 and 2 or 1
				units.peons[index] = unit(id, "B", mag / divisor)
				units.buffedPeons[index] = unit(id, "B", buffed / divisor)
			end

			units.jet = {
				Chainsaw = unit(58, "B", mag * 7.5),
				Zipbomb = unit(98, "A", mag * 7.5),
				DarkBomber = unit(22, "B", mag * 7.5),
				Tormented = unit(125, "B", mag * 7.5),
				Magerator = unit(24, "B", mag * 7.5),
			}
			units.buffedJet = {
				Chainsaw = unit(58, "B", buffed * 7.5),
				Zipbomb = unit(98, "A", buffed * 7.5),
				DarkBomber = unit(22, "B", buffed * 7.5),
				Tormented = unit(125, "B", buffed * 7.5),
				Magerator = unit(24, "B", buffed * 7.5),
			}
		else
			units.jet = {
				Chainsaw = unit(58, "B", mag),
				Zipbomb = unit(98, "B", mag),
				DarkBomber = unit(22, "B", mag),
				Tormented = unit(125, "B", mag),
				Magerator = unit(24, "B", mag),
			}
			units.buffedJet = units.jet
		end
	end

	local function alive(generation)
		return cycleActive and generation == cycleGeneration
	end

	local function spawn(enemy, generation)
		generation = generation or cycleGeneration

		while alive(generation) and aliveEnemies() >= (UnitLimitOverride or 30) do
			task.wait(0.1)
		end

		if not alive(generation) then
			return
		end

		SandboxSpawn:InvokeServer(unpack(enemy))
	end

	local function spawnForGeneration(enemy, delay, generation)
		task.delay(delay, function()
			if not alive(generation) then
				return
			end
			spawn(enemy, generation)
		end)
	end

	local function waitScaled(seconds)
		task.wait(DelayEnemyCycle and (seconds / SpawnRate) or 0)
	end

	local function applyRageParticle(pelican)
		task.spawn(function()
			local torso = pelican:FindFirstChild("Torso") or pelican:WaitForChild("Torso", 5)

			if not torso or not torso:IsA("BasePart") then
				return
			end

			if not rageModeActive or not pelican.Parent then
				return
			end

			local existing = torso:FindFirstChild("RageMode")

			if existing and existing:IsA("ParticleEmitter") then
				existing.Enabled = true
				return
			end

			local rageMode = Instance.new("ParticleEmitter")
			rageMode.Name = "RageMode"
			rageMode.RotSpeed = NumberRange.new(-360, 360)
			rageMode.Rotation = NumberRange.new(-360, 360)
			rageMode.Drag = 2
			rageMode.Rate = 5
			rageMode.Lifetime = NumberRange.new(0.015, 0.5)
			rageMode.LightEmission = 1
			rageMode.Texture = RAGE_PARTICLE_TEXTURE
			rageMode.Speed = NumberRange.new(0, 0)
			rageMode.Size = NumberSequence.new(50)
			rageMode.Enabled = true
			rageMode.Parent = torso
		end)
	end

	local function applyRageAppearance(npc)
		if not rageModeActive
			or not npc
			or not npc:IsA("Model")
			or not npc.Parent
			or not npc:IsDescendantOf(FriendlyFolder)
			or isRageExcluded(npc) then
			return
		end

		if rageProcessed[npc] then
			return
		end

		rageProcessed[npc] = true

		local shirt = npc:FindFirstChildOfClass("Shirt")
		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = npc
		end
		shirt.ShirtTemplate = RAGE_SHIRT_TEXTURE

		local pants = npc:FindFirstChildOfClass("Pants")
		if not pants then
			pants = Instance.new("Pants")
			pants.Parent = npc
		end
		pants.PantsTemplate = RAGE_PANTS_TEXTURE

		for _, object in ipairs(npc:GetDescendants()) do
			if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart" then
				object.Transparency = 0.25
			elseif object:IsA("SpecialMesh") then
				if not object.Parent or object.Parent.Name ~= "Head" then
					object.TextureId = RAGE_MESH_TEXTURE
				end
			end
		end

		local highlight = npc:FindFirstChild("RageModeHighlight")
		if not highlight or not highlight:IsA("Highlight") then
			highlight = Instance.new("Highlight")
			highlight.Name = "RageModeHighlight"
		end
		highlight.FillColor = Color3.fromRGB(234, 255, 0)
		highlight.OutlineTransparency = 0.99
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillTransparency = 1
		highlight.Adornee = npc
		highlight.Parent = npc

		local torso = npc:FindFirstChild("Torso")
		if torso then
			local sound = torso:FindFirstChild("Spawning")
			if not sound then
				sound = Instance.new("Sound")
				sound.Name = "Spawning"
				sound.SoundId = "rbxassetid://85240801566874"
				sound.Volume = 10
				sound.PlaybackSpeed = 0.9
				sound.Parent = torso
			end

			local existing = torso:FindFirstChild("RageMode")
			if existing and existing:IsA("ParticleEmitter") then
				existing.Enabled = true
			else
				local rageMode = Instance.new("ParticleEmitter")
				rageMode.Name = "RageMode"
				rageMode.RotSpeed = NumberRange.new(-360, 360)
				rageMode.Rotation = NumberRange.new(-360, 360)
				rageMode.Drag = 2
				rageMode.Rate = 5
				rageMode.Lifetime = NumberRange.new(0.015, 0.5)
				rageMode.LightEmission = 1
				rageMode.Texture = RAGE_PARTICLE_TEXTURE
				rageMode.Speed = NumberRange.new(0, 0)
				rageMode.Size = NumberSequence.new(10)
				rageMode.Enabled = true
				rageMode.Parent = torso
			end
		end
	end

	local function activateRageMode(pelican)
		if rageModeActive then
			return
		end

		rageModeActive = true

		if pelican and pelican.Parent then
			applyRageParticle(pelican)
		end

		for _, npc in ipairs(FriendlyFolder:GetChildren()) do
			applyRageAppearance(npc)
		end
	end

	local function pick(normal, buffed)
		if withPeons and buffedMode and buffed then
			return buffed
		end
		return normal
	end

	local function processJet(jet)
		if not cycleActive or not jet or jet.Name ~= "Jet" or processedJets[jet] then
			return
		end

		processedJets[jet] = true

		local generation = cycleGeneration

		task.spawn(function()
			for _, entry in ipairs(PELICAN_JET_SEQUENCE) do
				task.wait(entry[1])

				if not alive(generation) then
					return
				end

				spawn(pick(units.jet[entry[2]], units.buffedJet[entry[2]]), generation)
			end
		end)
	end

	local function checkPelicanHealth(pelican)
		if not cycleActive or not pelican or not pelican.Parent then
			return
		end

		if healthConnections[pelican] then
			return
		end

		local generation = cycleGeneration

		task.spawn(function()
			local humanoid = pelican:FindFirstChildOfClass("Humanoid") or pelican:WaitForChild("Humanoid", 5)

			if not humanoid or not alive(generation) or not pelican.Parent then
				return
			end

			local function checkHealth()
				if not alive(generation) then
					return
				end

				if humanoid.MaxHealth <= 0 then
					return
				end

				if humanoid.Health <= 0 then
					if not spawnedAt0HP then
						spawnedAt0HP = true

						spawnForGeneration(units.terminator, 2, generation)
						spawnForGeneration(units.fatboy, 2, generation)
						spawnForGeneration(units.warhead, 2, generation)
						spawnForGeneration(units.redzone, 2, generation)
					end

					return
				end

				if humanoid.Health <= humanoid.MaxHealth * 0.75 then
					if not spawned75Percent then
						spawned75Percent = true

						spawnForGeneration(units.doombringer, 0.5, generation)
						spawnForGeneration(units.exec, 1, generation)
						spawnForGeneration(units.scarletStorm, 1.5, generation)
					end
				end

				if humanoid.Health <= humanoid.MaxHealth * 0.5 then
					if not buffedMode then
						buffedMode = true
						activateRageMode(pelican)

						spawnForGeneration(units.xtreme, 0.5, generation)
						spawnForGeneration(units.patriotWarhead, 1, generation)
						spawnForGeneration(units.americanFatboy, 1.5, generation)
						spawnForGeneration(units.doomsdayMuffin, 2, generation)
					end
				end
			end

			healthConnections[pelican] = humanoid.HealthChanged:Connect(checkHealth)

			checkHealth()
		end)
	end

	local function setupPancakeTexture(object)
		if object.Name ~= "PancakeTexture" then
			return
		end

		pcall(function()
			if object:IsA("Texture") or object:IsA("Decal") then
				object.Texture = PANCAKE_TEXTURE
			elseif object:IsA("SpecialMesh") then
				object.TextureId = PANCAKE_TEXTURE
				object.VertexColor = Vector3.new(1, 1, 1)
			elseif object:IsA("MeshPart") then
				object.TextureID = PANCAKE_TEXTURE
			end
		end)
	end

	local function applyPelicanMeshTextures(pelican)
		for _, object in ipairs(pelican:GetDescendants()) do
			if object:IsA("SurfaceAppearance") then
				object:Destroy()
			elseif object:IsA("MeshPart") then
				pcall(function()
					object.TextureID = PANCAKE_TEXTURE
				end)
			elseif object:IsA("SpecialMesh") then
				pcall(function()
					object.TextureId = PANCAKE_TEXTURE
					object.VertexColor = Vector3.new(1, 1, 1)
				end)
			end
		end
	end

	local function setupPelican(pelican)
		if not pelican or not pelican.Parent then
			return
		end

		if processedPelicans[pelican] or pendingPelicans[pelican] then
			return
		end

		pendingPelicans[pelican] = true

		task.spawn(function()
			for _, limbName in ipairs(PELICAN_LIMBS) do
				pelican:WaitForChild(limbName, 5)
			end

			task.wait()

			pendingPelicans[pelican] = nil

			if not pelican.Parent or processedPelicans[pelican] then
				return
			end

			processedPelicans[pelican] = true

			applyPelicanMeshTextures(pelican)

			for _, object in ipairs(pelican:GetDescendants()) do
				if object:IsA("BasePart") then
					local isMainLimb = false

					for _, limbName in ipairs(PELICAN_LIMBS) do
						if object == pelican:FindFirstChild(limbName) then
							isMainLimb = true
							break
						end
					end

					if not isMainLimb then
						local parentModel = object:FindFirstAncestorWhichIsA("Model")

						if parentModel and parentModel ~= pelican then
							object.Transparency = 1
						end
					end
				end
			end

			for _, object in ipairs(pelican:GetDescendants()) do
				if object:IsA("SpecialMesh") then
					object.VertexColor = Vector3.new(1, 1, 1)
				elseif object:IsA("MeshPart") then
					object.Color = MESH_COLOR
				elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
					object.Color = ColorSequence.new(PELICAN_BLUE)
					object.Enabled = false
				elseif object:IsA("PointLight") then
					object.Color = PELICAN_BLUE
				end
			end

			for _, limbName in ipairs(PELICAN_LIMBS) do
				local part = pelican:FindFirstChild(limbName)

				if part and part:IsA("BasePart") then
					part.Transparency = 0
					part.LocalTransparencyModifier = 0

					if part:IsA("MeshPart") then
						part.Color = MESH_COLOR
						part.TextureID = PANCAKE_TEXTURE
					else
						part.Color = LIMB_COLOR
					end

					for _, descendant in ipairs(part:GetDescendants()) do
						if descendant:IsA("SpecialMesh") then
							descendant.VertexColor = Vector3.new(1, 1, 1)
						end
					end
				end
			end

			local torso = pelican:FindFirstChild("Torso")
			local rootPart = pelican:FindFirstChild("HumanoidRootPart")

			if torso then
				for _, object in ipairs(torso:GetDescendants()) do
					if object:IsA("BasePart") then
						object.Color = PELICAN_BLUE
						object.Transparency = 0.75
						object.LocalTransparencyModifier = 0
					end
				end

				local sound = torso:FindFirstChild("PelicanSound")

				if not sound then
					sound = Instance.new("Sound")
					sound.Name = "PelicanSound"
					sound.SoundId = "rbxassetid://80366561193643"
					sound.Volume = 10
					sound.PlaybackSpeed = 0.85
					sound.Looped = true
					sound.Parent = torso
				end

				local spawnSound = rootPart and rootPart:FindFirstChild("Spawn")

				if spawnSound and spawnSound:IsA("Sound") then
					spawnSound:Stop()
					spawnSound.SoundId = "rbxassetid://6647947988"
					spawnSound.Volume = 10
					spawnSound.PlaybackSpeed = 1
					spawnSound.TimePosition = 0
					spawnSound:Play()
				end

				local engine = torso:FindFirstChild("Engine1")

				if engine and engine:IsA("Sound") then
					engine:Stop()
					engine.Volume = 0
				end

				sound:Play()

				if rageModeActive then
					applyRageParticle(pelican)
				end
			end

			local rightArm = pelican:FindFirstChild("Right Arm")
			local handle = rightArm and rightArm:FindFirstChild("Handle")
			local box = handle and handle:FindFirstChild("Box001")

			if box and box:IsA("BasePart") then
				box.Transparency = 0.75
				box.LocalTransparencyModifier = 0
				box.Color = PELICAN_BLUE
			end

			local head = pelican:FindFirstChild("Head")

			if head and head:IsA("BasePart") then
				head.Transparency = 0
				head.LocalTransparencyModifier = 0

				local face = head:FindFirstChild("face")

				if face and not face:IsA("Decal") then
					face:Destroy()
					face = nil
				end

				if not face then
					face = Instance.new("Decal")
					face.Name = "face"
					face.Parent = head
				end

				face.Texture = FACE_TEXTURE
				face.Face = Enum.NormalId.Front
				face.Transparency = 0
				face.Color3 = Color3.new(1, 1, 1)
				face.LocalTransparencyModifier = 0
			end

			local shirt = pelican:FindFirstChildOfClass("Shirt")
			if not shirt then
				shirt = Instance.new("Shirt")
				shirt.Parent = pelican
			end
			shirt.ShirtTemplate = SHIRT_TEXTURE

			local pants = pelican:FindFirstChildOfClass("Pants")
			if not pants then
				pants = Instance.new("Pants")
				pants.Parent = pelican
			end
			pants.PantsTemplate = PANTS_TEXTURE
		end)
	end

	local function processExistingObjects()
		for _, object in ipairs(FriendlyFolder:GetChildren()) do
			if object.Name == "PancakeTexture" then
				setupPancakeTexture(object)
			end

			for _, descendant in ipairs(object:GetDescendants()) do
				if descendant.Name == "PancakeTexture" then
					setupPancakeTexture(descendant)
				end
			end

			if object.Name == "Pancake Pelican Of Truth" then
				setupPelican(object)

				if cycleActive then
					checkPelicanHealth(object)
				end
			end

			if object.Name == "Jet" and cycleActive then
				processJet(object)
			end

			if rageModeActive then
				applyRageAppearance(object)
			end
		end
	end

	local function onChildAdded(object)
		if object.Name == "Pancake Pelican Of Truth" then
			setupPelican(object)

			if cycleActive then
				checkPelicanHealth(object)
			end
		end

		if object.Name == "Jet" and cycleActive then
			processJet(object)
		end

		if object.Name == "PancakeTexture" then
			setupPancakeTexture(object)
		end

		if rageModeActive then
			task.defer(function()
				if rageModeActive and object.Parent == FriendlyFolder then
					applyRageAppearance(object)
				end
			end)
		end

		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant.Name == "PancakeTexture" then
				setupPancakeTexture(descendant)
			end
		end
	end

	local function onDescendantAdded(object)
		if object.Name == "PancakeTexture" then
			setupPancakeTexture(object)
		end

		if object.Name == "Pancake Pelican Of Truth" then
			setupPelican(object)

			if cycleActive then
				checkPelicanHealth(object)
			end
		end
	end

	local function resetState()
		cycleActive = false
		cycleGeneration += 1

		buffedMode = false
		rageModeActive = false
		spawned75Percent = false
		spawnedAt0HP = false

		for pelican, connection in pairs(healthConnections) do
			connection:Disconnect()
			healthConnections[pelican] = nil
		end

		table.clear(rageProcessed)
		table.clear(processedJets)
	end

	local function runPeons(generation)
		while alive(generation) do
			for _, step in ipairs(PELICAN_PEON_STEPS) do
				local seconds, index, caps, capCount = step[1], step[2], step[3], step[4]

				if not caps or countByNames(caps) < capCount then
					waitScaled(seconds)

					if not alive(generation) then
						return
					end

					if not caps or countByNames(caps) < capCount then
						spawn(pick(units.peons[index], units.buffedPeons[index]), generation)
					end
				end
			end

			task.wait()
		end
	end

	local function startCycle()
		local opts = getState(DARK_PELICAN).opts
		buildUnits(opts.strength or 1)

		cycleActive = true
		cycleGeneration += 1
		local generation = cycleGeneration

		buffedMode = false
		rageModeActive = false
		spawned75Percent = false
		spawnedAt0HP = false

		table.clear(rageProcessed)
		table.clear(processedJets)

		task.spawn(function()
			if SwitchTeamsAtStart then
				SandboxSettings:InvokeServer("SpawnTeamsSwap", true)
				Custom.swap = true
			end
			SandboxSettings:InvokeServer("EnableHealthBars", true)
		end)

		processExistingObjects()

		for _, object in ipairs(FriendlyFolder:GetChildren()) do
			if object.Name == "Jet" then
				processJet(object)
			end
		end

		task.spawn(function()
			if not opts.bossless then
				spawn(units.boss, generation)
			end

			if withPeons then
				runPeons(generation)
			end
		end)
	end

	local function connectFolder()
		if #folderConnections > 0 then
			return
		end
		table.insert(folderConnections, FriendlyFolder.ChildAdded:Connect(onChildAdded))
		table.insert(folderConnections, FriendlyFolder.DescendantAdded:Connect(onDescendantAdded))
	end

	local function disconnectFolder()
		for _, connection in folderConnections do
			connection:Disconnect()
		end
		table.clear(folderConnections)
	end

	local function watcher(mySession)
		while feature.on and session == mySession do
			if getRefs() then
				connectFolder()

				local valid = checkBasesValid()

				if valid and not cycleActive then
					task.wait(0.1)
					if feature.on and session == mySession and checkBasesValid() then
						startCycle()
					end
				elseif not valid and cycleActive then
					resetState()
				end
			end

			task.wait(0.5)
		end
	end

	function feature.set(on)
		feature.on = on
		session += 1
		resetState()
		disconnectFolder()

		if on then
			task.spawn(watcher, session)
		end
	end

	table.insert(spawners, feature.set)

	return feature
end

local pelicanScripts = {
	benjamins = createPelicanScript(true),
	israel = createPelicanScript(false),
}

local Avatar = {
	running = false,
	userId = nil,
	applyFriendly = true,
	applyEnemies = true,
	girlTorso = false,
	oopsAllOscar = false,
}
local GIRL_TORSO_MESH_ID = "rbxassetid://48112070"
local ACCESSORY_PASSES = 5

do
	local avatarSession = 0
	local oscarMode = false
	local InsertService = game:GetService("InsertService")
	local avatarConnections = {}
	local appearanceModel, humanoidDescription
	local processed = setmetatable({}, { __mode = "k" })

	local function applyFace(targetHead)
		for _, object in ipairs(targetHead:GetChildren()) do
			if object:IsA("Decal") and object.Name:lower() == "face" then
				object:Destroy()
			end
		end

		local sourceHead = appearanceModel:FindFirstChild("Head")
		if sourceHead then
			for _, object in ipairs(sourceHead:GetChildren()) do
				if object:IsA("Decal") and object.Name:lower() == "face" then
					local face = object:Clone()
					face.Name = "face"
					face.Face = Enum.NormalId.Front
					face.Parent = targetHead
					return
				end
			end
		end

		if humanoidDescription and humanoidDescription.Face ~= 0 then
			local face = Instance.new("Decal")
			face.Name = "face"
			face.Face = Enum.NormalId.Front
			face.Texture = "rbxassetid://" .. tostring(humanoidDescription.Face)
			face.Parent = targetHead
		end
	end

	local function applyBodyColors(npc)
		local source = appearanceModel:FindFirstChildOfClass("BodyColors")
		if not source then return end

		local old = npc:FindFirstChildOfClass("BodyColors")
		if old then old:Destroy() end

		local new = source:Clone()
		new.Parent = npc

		local colorProperties = {
			Head = "HeadColor3",
			Torso = "TorsoColor3",
			["Left Arm"] = "LeftArmColor3",
			["Right Arm"] = "RightArmColor3",
			["Left Leg"] = "LeftLegColor3",
			["Right Leg"] = "RightLegColor3",
		}
		for partName, propertyName in pairs(colorProperties) do
			local part = npc:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				part.Color = new[propertyName]
			end
		end
	end

	local function applyR6Meshes(npc)
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end

		for _, object in ipairs(npc:GetChildren()) do
			if object:IsA("CharacterMesh") then
				object:Destroy()
			end
		end

		for _, sourceMesh in ipairs(appearanceModel:GetChildren()) do
			if sourceMesh:IsA("CharacterMesh") then
				local mesh = Instance.new("CharacterMesh")
				mesh.Name = sourceMesh.Name
				mesh.BodyPart = sourceMesh.BodyPart
				mesh.MeshId = sourceMesh.MeshId
				mesh.BaseTextureId = sourceMesh.BaseTextureId
				mesh.OverlayTextureId = sourceMesh.OverlayTextureId
				mesh.Parent = npc
			end
		end

		if Avatar.girlTorso then
			local torsoMesh
			for _, object in ipairs(npc:GetChildren()) do
				if object:IsA("CharacterMesh") and object.BodyPart == Enum.BodyPart.Torso then
					torsoMesh = object
					break
				end
			end
			if torsoMesh then
				torsoMesh.MeshId = GIRL_TORSO_MESH_ID
			else
				torsoMesh = Instance.new("CharacterMesh")
				torsoMesh.Name = "GirlTorsoMesh"
				torsoMesh.BodyPart = Enum.BodyPart.Torso
				torsoMesh.MeshId = GIRL_TORSO_MESH_ID
				torsoMesh.Parent = npc
			end
		end
	end

	local function applyR15Body(npc)
		for _, sourcePart in ipairs(appearanceModel:GetChildren()) do
			if sourcePart:IsA("MeshPart") then
				local targetPart = npc:FindFirstChild(sourcePart.Name)
				if targetPart and targetPart:IsA("MeshPart") then
					targetPart.MeshId = sourcePart.MeshId
					targetPart.TextureID = sourcePart.TextureID
					if sourcePart.RenderFidelity ~= Enum.RenderFidelity.Automatic then
						targetPart.RenderFidelity = sourcePart.RenderFidelity
					end
				end
			end
		end
	end

	local function getNpcScale(npc, targetHead)
		local scale = npc:GetScale()
		if math.abs(scale - 1) < 0.001 then
			scale = targetHead.Size.Y
		end
		return scale
	end

	local function applyHeadMesh(targetHead, npcScale)
		local sourceHead = appearanceModel:FindFirstChild("Head")
		if not sourceHead then return end

		local sourceMesh = sourceHead:FindFirstChildWhichIsA("SpecialMesh")
		local targetMesh = targetHead:FindFirstChildWhichIsA("SpecialMesh")
		if targetMesh then targetMesh:Destroy() end

		if sourceMesh then
			local new = sourceMesh:Clone()
			new.Scale = sourceMesh.Scale * npcScale
			new.Parent = targetHead
		elseif sourceHead:IsA("MeshPart") then
			local new = Instance.new("SpecialMesh")
			new.Name = "AvatarHeadMesh"
			new.MeshType = Enum.MeshType.FileMesh
			new.MeshId = sourceHead.MeshId
			if sourceHead.TextureID ~= "" then
				new.TextureId = sourceHead.TextureID
			else
				local surface = sourceHead:FindFirstChildOfClass("SurfaceAppearance")
				if surface and surface.ColorMap ~= "" then
					new.TextureId = surface.ColorMap
				end
			end
			new.Scale = sourceHead.Size * npcScale
			new.Parent = targetHead
		end
	end

	local function removeAccessoryJoints(handle)
		for _, child in ipairs(handle:GetChildren()) do
			if child:IsA("JointInstance") or child:IsA("WeldConstraint") then
				child:Destroy()
			end
		end
	end

	local OSCAR_ACCESSORY_IDS = {
		135980393520176,
		71261715244629,
		72356714104047,
		71365578455669,
		77274011481440,
	}
	local OSCAR_SHIRT_ID = 80542805166073
	local OSCAR_PANTS_ID = 15596174212

	local OSCAR_BLACK = Color3.fromRGB(0, 0, 0)
	local OSCAR_BROWN = Color3.fromRGB(105, 64, 40)

	local OSCAR_PART_COLORS = {
		["Head"] = OSCAR_BLACK,
		["Torso"] = OSCAR_BLACK,
		["Left Arm"] = OSCAR_BROWN,
		["Right Arm"] = OSCAR_BROWN,
		["Left Leg"] = OSCAR_BLACK,
		["Right Leg"] = OSCAR_BLACK,
		["UpperTorso"] = OSCAR_BLACK,
		["LowerTorso"] = OSCAR_BLACK,
		["LeftUpperArm"] = OSCAR_BROWN,
		["LeftLowerArm"] = OSCAR_BROWN,
		["LeftHand"] = OSCAR_BROWN,
		["RightUpperArm"] = OSCAR_BROWN,
		["RightLowerArm"] = OSCAR_BROWN,
		["RightHand"] = OSCAR_BROWN,
		["LeftUpperLeg"] = OSCAR_BLACK,
		["LeftLowerLeg"] = OSCAR_BLACK,
		["LeftFoot"] = OSCAR_BLACK,
		["RightUpperLeg"] = OSCAR_BLACK,
		["RightLowerLeg"] = OSCAR_BLACK,
		["RightFoot"] = OSCAR_BLACK,
	}

	local oscar = { loaded = false, accessories = {}, shirt = nil, pants = nil }

	local function loadAsset(id, className)
		local success, result = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(id))
		end)
		if not success or not result or not result[1] then
			success, result = pcall(function()
				return { InsertService:LoadAsset(id) }
			end)
		end
		if not success or not result or not result[1] then
			warn("Oops All Oscar: could not load asset", id)
			return nil
		end

		local root = result[1]
		local found = root:IsA(className) and root or root:FindFirstChildWhichIsA(className, true)
		if not found then
			warn("Oops All Oscar: asset has no", className, id)
		end
		return found
	end

	local function loadOscarAssets()
		if oscar.loaded then return end
		for _, id in ipairs(OSCAR_ACCESSORY_IDS) do
			local accessory = loadAsset(id, "Accessory")
			if accessory then
				table.insert(oscar.accessories, accessory)
			end
		end
		oscar.shirt = loadAsset(OSCAR_SHIRT_ID, "Shirt")
		oscar.pants = loadAsset(OSCAR_PANTS_ID, "Pants")
		oscar.loaded = true
	end

	local function applyOscarBodyColors(npc)
		local old = npc:FindFirstChildOfClass("BodyColors")
		if old then old:Destroy() end

		local colors = Instance.new("BodyColors")
		colors.HeadColor3 = OSCAR_BLACK
		colors.TorsoColor3 = OSCAR_BLACK
		colors.LeftArmColor3 = OSCAR_BROWN
		colors.RightArmColor3 = OSCAR_BROWN
		colors.LeftLegColor3 = OSCAR_BLACK
		colors.RightLegColor3 = OSCAR_BLACK
		colors.Parent = npc

		for partName, color in pairs(OSCAR_PART_COLORS) do
			local part = npc:FindFirstChild(partName)
			if part and part:IsA("BasePart") then
				part.Color = color
			end
		end
	end

	local function applyOscarClothing(npc)
		for _, className in ipairs({ "Shirt", "Pants", "ShirtGraphic" }) do
			local old = npc:FindFirstChildOfClass(className)
			if old then old:Destroy() end
		end

		if oscar.shirt then
			oscar.shirt:Clone().Parent = npc
		else
			local shirt = Instance.new("Shirt")
			shirt.ShirtTemplate = "rbxassetid://" .. tostring(OSCAR_SHIRT_ID)
			shirt.Parent = npc
		end

		if oscar.pants then
			oscar.pants:Clone().Parent = npc
		else
			local pants = Instance.new("Pants")
			pants.PantsTemplate = "rbxassetid://" .. tostring(OSCAR_PANTS_ID)
			pants.Parent = npc
		end
	end

	local function removeFace(targetHead)
		for _, object in ipairs(targetHead:GetChildren()) do
			if object:IsA("Decal") and object.Name:lower() == "face" then
				object:Destroy()
			end
		end
	end

	local function applyAccessories(npc, npcScale, sources)
		for _, object in ipairs(npc:GetChildren()) do
			if object:IsA("Accessory") and not object:GetAttribute("OscarAdded") then
				object:Destroy()
			end
		end

		for _, sourceAccessory in ipairs(sources) do
			if not sourceAccessory:IsA("Accessory") then continue end

			local accessory = sourceAccessory:Clone()
			local handle = accessory:FindFirstChild("Handle")
			if not handle or not handle:IsA("BasePart") then
				accessory:Destroy()
				continue
			end

			local accessoryAttachment = handle:FindFirstChildWhichIsA("Attachment")
			if not accessoryAttachment then
				accessory:Destroy()
				continue
			end

			local targetAttachment
			for _, descendant in ipairs(npc:GetDescendants()) do
				if descendant:IsA("Attachment")
					and descendant.Name == accessoryAttachment.Name
					and descendant.Parent:IsA("BasePart") then
					targetAttachment = descendant
					break
				end
			end
			if not targetAttachment then
				accessory:Destroy()
				continue
			end

			for _, descendant in ipairs(accessory:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Size *= npcScale
					descendant.CanCollide = false
					descendant.CanTouch = false
					descendant.CanQuery = false
					descendant.Massless = true
				elseif descendant:IsA("SpecialMesh") then
					descendant.Scale *= npcScale
				elseif descendant:IsA("Attachment") then
					descendant.Position *= npcScale
				end
			end

			accessory.Parent = npc

			local bodyPart = targetAttachment.Parent
			removeAccessoryJoints(handle)
			handle.CFrame = bodyPart.CFrame * targetAttachment.CFrame * accessoryAttachment.CFrame:Inverse()

			local weld = Instance.new("Weld")
			weld.Name = "AccessoryWeld"
			weld.Part0 = bodyPart
			weld.Part1 = handle
			weld.C0 = targetAttachment.CFrame
			weld.C1 = accessoryAttachment.CFrame
			weld.Parent = handle
		end
	end

	local function applyAppearance(npc, mySession)
		if avatarSession ~= mySession or not npc:IsA("Model") or processed[npc] or not npc.Parent then
			return
		end

		local targetHead = npc:FindFirstChild("Head") or npc:WaitForChild("Head", 5)
		if avatarSession ~= mySession or not targetHead or not targetHead:IsA("BasePart") or not npc.Parent then
			return
		end

		processed[npc] = true
		local npcScale = getNpcScale(npc, targetHead)

		local sources
		if oscarMode then
			applyOscarBodyColors(npc)
			applyOscarClothing(npc)
			removeFace(targetHead)
			sources = oscar.accessories
		else
			applyBodyColors(npc)

			for _, className in ipairs({ "Shirt", "Pants", "ShirtGraphic" }) do
				local old = npc:FindFirstChildOfClass(className)
				if old then old:Destroy() end
				local new = appearanceModel:FindFirstChildOfClass(className)
				if new then new:Clone().Parent = npc end
			end

			applyHeadMesh(targetHead, npcScale)
			applyFace(targetHead)
			applyR6Meshes(npc)
			applyR15Body(npc)
			sources = appearanceModel:GetChildren()
		end

		for pass = 1, ACCESSORY_PASSES do
			if avatarSession ~= mySession or not npc.Parent then break end
			applyAccessories(npc, npcScale, sources)
			if pass < ACCESSORY_PASSES then
				task.wait(0.5)
			end
		end
	end

	local function setupFolder(folder, mySession)
		for _, npc in ipairs(folder:GetChildren()) do
			task.spawn(function()
				pcall(applyAppearance, npc, mySession)
			end)
		end
		table.insert(avatarConnections, folder.ChildAdded:Connect(function(npc)
			task.spawn(function()
				pcall(applyAppearance, npc, mySession)
			end)
		end))
	end

	-- Accessory adder: paste any accessory ID and it is put on units (blue) or enemies (red).
	-- With a unit ID (the "ID" stat of a unit, like 1 = Battler) only that kind of unit gets it.
	local accessoryRules = {}
	local accessoryCache = {}
	local addedAccessories = {}
	local accessoryOwner = setmetatable({}, { __mode = "k" })
	local addedUndo = {} -- { undo = function, rule = rule } for clothing / body parts that were changed
	local accessoryConnections = {}
	local accessoryApplied = setmetatable({}, { __mode = "k" })

	local function attachOneAccessory(npc, npcScale, sourceAccessory)
		local accessory = sourceAccessory:Clone()
		local handle = accessory:FindFirstChild("Handle")
		if not handle or not handle:IsA("BasePart") then
			accessory:Destroy()
			return nil
		end

		local accessoryAttachment = handle:FindFirstChildWhichIsA("Attachment")
		if not accessoryAttachment then
			accessory:Destroy()
			return nil
		end

		local targetAttachment
		for _, descendant in ipairs(npc:GetDescendants()) do
			if descendant:IsA("Attachment")
				and descendant.Name == accessoryAttachment.Name
				and descendant.Parent:IsA("BasePart") then
				targetAttachment = descendant
				break
			end
		end
		if not targetAttachment then
			accessory:Destroy()
			return nil
		end

		for _, descendant in ipairs(accessory:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Size *= npcScale
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.Massless = true
			elseif descendant:IsA("SpecialMesh") then
				descendant.Scale *= npcScale
			elseif descendant:IsA("Attachment") then
				descendant.Position *= npcScale
			end
		end

		accessory:SetAttribute("OscarAdded", true)
		accessory.Parent = npc

		local bodyPart = targetAttachment.Parent
		removeAccessoryJoints(handle)
		handle.CFrame = bodyPart.CFrame * targetAttachment.CFrame * accessoryAttachment.CFrame:Inverse()

		local weld = Instance.new("Weld")
		weld.Name = "AccessoryWeld"
		weld.Part0 = bodyPart
		weld.Part1 = handle
		weld.C0 = targetAttachment.CFrame
		weld.C1 = accessoryAttachment.CFrame
		weld.Parent = handle

		return accessory
	end

	local function accessoryFolder(ally)
		local npcRoot = Workspace:FindFirstChild("NPCFolders")
		return npcRoot and npcRoot:FindFirstChild(ally and "FriendlyFolder" or "EnemyFolder")
	end

	local function ruleMatches(npc, rule)
		if npc.Parent ~= accessoryFolder(rule.ally) then return false end
		if rule.unitId and rule.unitId > 0 then
			return tonumber(npc:GetAttribute("ID")) == rule.unitId
		end
		return true
	end

	local R15_PARTS = {
		Head = true, UpperTorso = true, LowerTorso = true,
		LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
		RightUpperArm = true, RightLowerArm = true, RightHand = true,
		LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
		RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
		-- R6 names, in case the unit uses them
		Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	}

	-- shirt / pants / t-shirt: replace the unit's current one, remember it so it can be put back
	local function applyClothing(npc, rule)
		local className = rule.clothing.ClassName
		local old = npc:FindFirstChildOfClass(className)
		local new = rule.clothing:Clone()
		if old then old.Parent = nil end
		new.Parent = npc
		table.insert(addedUndo, { rule = rule, undo = function()
			pcall(function() new:Destroy() end)
			if old and npc.Parent then old.Parent = npc end
		end })
	end

	-- body part packages (like bundle arms): copy the mesh / texture onto the matching part of the unit
	local function applyBodyParts(npc, rule)
		local changed = 0
		for _, sourcePart in ipairs(rule.partModel:GetDescendants()) do
			if sourcePart:IsA("MeshPart") and R15_PARTS[sourcePart.Name] then
				local target = npc:FindFirstChild(sourcePart.Name, true)
				if target and target:IsA("MeshPart") then
					local oldMesh, oldTexture, oldSize = target.MeshId, target.TextureID, target.Size
					local oldAppearance = target:FindFirstChildOfClass("SurfaceAppearance")
					local newAppearance
					pcall(function()
						target.MeshId = sourcePart.MeshId
						target.TextureID = sourcePart.TextureID
						local sa = sourcePart:FindFirstChildOfClass("SurfaceAppearance")
						if oldAppearance then oldAppearance.Parent = nil end
						if sa then
							newAppearance = sa:Clone()
							newAppearance.Parent = target
						end
					end)
					changed += 1
					table.insert(addedUndo, { rule = rule, undo = function()
						pcall(function()
							target.MeshId = oldMesh
							target.TextureID = oldTexture
							if newAppearance then newAppearance:Destroy() end
							if oldAppearance then oldAppearance.Parent = target end
						end)
					end })
				end
			end
		end
		return changed
	end

	-- body part groups -> the part names a unit might use (R15 and R6)
	local COLOR_PART_NAMES = {
		Head = { "Head" },
		Torso = { "UpperTorso", "LowerTorso", "Torso" },
		LeftArm = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm" },
		RightArm = { "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm" },
		LeftLeg = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg" },
		RightLeg = { "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" },
	}
	local BODY_COLORS_PROPERTY = {
		Head = "HeadColor3", Torso = "TorsoColor3", LeftArm = "LeftArmColor3",
		RightArm = "RightArmColor3", LeftLeg = "LeftLegColor3", RightLeg = "RightLegColor3",
	}

	-- Body colour: the part ends up with exactly the selected colour. The material becomes plain (no shine / texture
	-- changing the shade), mesh textures and surface appearances are taken off, the shirt / pants that would cover the
	-- part are hidden, and if the game paints the part again the chosen colour is put back.
	local CLOTHES_FOR_GROUP = {
		Torso = { { "Shirt", "ShirtTemplate" }, { "ShirtGraphic", "Graphic" } },
		LeftArm = { { "Shirt", "ShirtTemplate" } },
		RightArm = { { "Shirt", "ShirtTemplate" } },
		LeftLeg = { { "Pants", "PantsTemplate" } },
		RightLeg = { { "Pants", "PantsTemplate" } },
	}

	local function applyBodyColor(npc, rule)
		local bodyColors = npc:FindFirstChildOfClass("BodyColors")
		local color = rule.color
		for group in pairs(rule.colorGroups) do
			for _, partName in ipairs(COLOR_PART_NAMES[group] or {}) do
				local part = npc:FindFirstChild(partName)
				if part and part:IsA("BasePart") then
					local oldColor, oldMaterial = part.Color, part.Material
					local oldTexture = part:IsA("MeshPart") and part.TextureID or nil
					local removed = {}
					part.Color = color
					part.Material = Enum.Material.SmoothPlastic
					if part:IsA("MeshPart") then
						pcall(function() part.TextureID = "" end)
					end
					for _, child in ipairs(part:GetChildren()) do
						if child:IsA("SurfaceAppearance") then
							table.insert(removed, child)
							child.Parent = nil
						end
					end
					local keeper = part:GetPropertyChangedSignal("Color"):Connect(function()
						if part.Color ~= color then
							part.Color = color
						end
					end)
					table.insert(addedUndo, { rule = rule, undo = function()
						keeper:Disconnect()
						pcall(function()
							part.Color = oldColor
							part.Material = oldMaterial
							if oldTexture then part.TextureID = oldTexture end
							for _, child in ipairs(removed) do child.Parent = part end
						end)
					end })
				end
			end
			if bodyColors and BODY_COLORS_PROPERTY[group] then
				local property = BODY_COLORS_PROPERTY[group]
				local oldValue = bodyColors[property]
				bodyColors[property] = color
				table.insert(addedUndo, { rule = rule, undo = function()
					pcall(function() bodyColors[property] = oldValue end)
				end })
			end
			for _, info in ipairs(CLOTHES_FOR_GROUP[group] or {}) do
				for _, object in ipairs(npc:GetChildren()) do
					if object:IsA(info[1]) then
						local property = info[2]
						local oldValue = object[property]
						if oldValue ~= "" then
							pcall(function() object[property] = "" end)
							table.insert(addedUndo, { rule = rule, undo = function()
								pcall(function() object[property] = oldValue end)
							end })
						end
					end
				end
			end
		end
	end

	-- wipe: takes off every accessory the unit already has (the game's own ones), put back when the group is removed
	local function applyWipe(npc, rule)
		for _, object in ipairs(npc:GetChildren()) do
			if object:IsA("Accessory") and not object:GetAttribute("OscarAdded") then
				object.Parent = nil
				table.insert(addedUndo, { rule = rule, undo = function()
					pcall(function()
						if npc.Parent then object.Parent = npc end
					end)
				end })
			end
		end
	end

	-- shirt texture (like the Israel shirt): sets the unit's Shirt, or gives it one
	local function applyShirt(npc, rule)
		local shirt = npc:FindFirstChildOfClass("Shirt")
		if shirt then
			local oldTemplate = shirt.ShirtTemplate
			shirt.ShirtTemplate = rule.shirtTemplate
			table.insert(addedUndo, { rule = rule, undo = function()
				pcall(function() shirt.ShirtTemplate = oldTemplate end)
			end })
		else
			shirt = Instance.new("Shirt")
			shirt.ShirtTemplate = rule.shirtTemplate
			shirt.Parent = npc
			table.insert(addedUndo, { rule = rule, undo = function()
				pcall(function() shirt:Destroy() end)
			end })
		end
	end

	-- 2D face: a decal on the front of the head, with its own colour
	local function applyFace(npc, rule)
		local head = npc:FindFirstChild("Head")
		if not head then return end
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("Decal") and string.lower(child.Name) == "face" then
				child.Parent = nil
				table.insert(addedUndo, { rule = rule, undo = function()
					pcall(function()
						if head.Parent then child.Parent = head end
					end)
				end })
			end
		end
		local decal = Instance.new("Decal")
		decal.Name = "face"
		decal.Face = Enum.NormalId.Front
		decal.Texture = rule.face
		decal.Color3 = rule.faceColor or Color3.new(1, 1, 1)
		decal.Parent = head
		table.insert(addedUndo, { rule = rule, undo = function()
			pcall(function() decal:Destroy() end)
		end })
	end

	-- colour tint for clothes (Shirt / Pants / T-shirt) and for accessory / bundle meshes: it multiplies with the texture.
	-- clothesOpacity / meshesOpacity (0..1) = how strongly the tint is mixed in (0 = original colour, 1 = full tint).
	-- meshTexture (string) = texture that replaces the one on hat / accessory meshes.
	local function applyTint(npc, rule)
		task.wait(0.8) -- new units: let their clothes and accessories (and ours) appear first
		if not npc.Parent then return end
		local function setProperty(object, property, value)
			local old = object[property]
			object[property] = value
			table.insert(addedUndo, { rule = rule, undo = function()
				pcall(function() object[property] = old end)
			end })
		end
		local targets = rule.tintTargets
		local function mix(old, color, opacity)
			return old:Lerp(color, math.clamp(opacity or 1, 0, 1))
		end
		if targets.clothes then
			local color = targets.clothes
			for _, object in ipairs(npc:GetChildren()) do
				if object:IsA("Shirt") or object:IsA("Pants") or object:IsA("ShirtGraphic") then
					pcall(setProperty, object, "Color3", mix(object.Color3, color, targets.clothesOpacity))
				end
			end
		end
		if targets.meshes or targets.meshTexture then
			local color = targets.meshes
			for _, accessory in ipairs(npc:GetChildren()) do
				if accessory:IsA("Accessory") then
					for _, object in ipairs(accessory:GetDescendants()) do
						if color then
							if object:IsA("BasePart") then
								pcall(setProperty, object, "Color", mix(object.Color, color, targets.meshesOpacity))
							elseif object:IsA("SpecialMesh") then
								local old = object.VertexColor
								local opacity = math.clamp(targets.meshesOpacity or 1, 0, 1)
								pcall(setProperty, object, "VertexColor", Vector3.new(old.X, old.Y, old.Z):Lerp(Vector3.new(color.R, color.G, color.B), opacity))
							elseif object:IsA("SurfaceAppearance") then
								pcall(setProperty, object, "Color", mix(object.Color, color, targets.meshesOpacity))
							end
						end
						if targets.meshTexture then
							if object:IsA("MeshPart") then
								pcall(setProperty, object, "TextureID", targets.meshTexture)
							elseif object:IsA("SpecialMesh") then
								pcall(setProperty, object, "TextureId", targets.meshTexture)
							elseif object:IsA("SurfaceAppearance") then
								-- a SurfaceAppearance overrides TextureID, so its colour map is swapped instead
								pcall(setProperty, object, "ColorMap", targets.meshTexture)
							end
						end
					end
				end
			end
		end
	end

	local function applyRuleToNpc(npc, rule)
		if not npc:IsA("Model") or not npc.Parent then return end
		local done = accessoryApplied[npc]
		if done and done[rule] then return end
		if not ruleMatches(npc, rule) then return end

		local head = npc:FindFirstChild("Head") or npc:WaitForChild("Head", 5)
		if not head or not head:IsA("BasePart") or not npc.Parent then return end

		if not (rule.accessory or rule.clothing or rule.partModel or rule.colorGroups or rule.tintTargets or rule.wipe or rule.face or rule.shirtTemplate) then return end

		accessoryApplied[npc] = accessoryApplied[npc] or {}
		accessoryApplied[npc][rule] = true

		if rule.wipe then
			pcall(applyWipe, npc, rule)
			return
		end
		if rule.face then
			pcall(applyFace, npc, rule)
			return
		end
		if rule.shirtTemplate then
			pcall(applyShirt, npc, rule)
			return
		end
		if rule.clothing then
			pcall(applyClothing, npc, rule)
			return
		end
		if rule.colorGroups then
			pcall(applyBodyColor, npc, rule)
			return
		end
		if rule.tintTargets then
			pcall(applyTint, npc, rule)
			return
		end
		if rule.partModel then
			pcall(applyBodyParts, npc, rule)
			return
		end

		local ok, accessory = pcall(attachOneAccessory, npc, getNpcScale(npc, head), rule.accessory)
		if ok and accessory then
			table.insert(addedAccessories, accessory)
			accessoryOwner[accessory] = rule
		end
	end

	local function watchAccessoryFolders()
		if #accessoryConnections > 0 then return end
		for _, ally in ipairs({ true, false }) do
			local folder = accessoryFolder(ally)
			if folder then
				table.insert(accessoryConnections, folder.ChildAdded:Connect(function(npc)
					task.spawn(function()
						task.wait(0.4) -- let the game set the unit's attributes first
						for _, rule in ipairs(accessoryRules) do
							pcall(applyRuleToNpc, npc, rule)
						end
					end)
				end))
			end
		end
	end

	local function loadAssetRoot(id)
		local success, result = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(id))
		end)
		if not success or not result or not result[1] then
			success, result = pcall(function()
				return { InsertService:LoadAsset(id) }
			end)
		end
		if success and result and result[1] then
			return result[1]
		end
		return nil
	end

	-- Turns what the person typed (an ID, an rbxassetid:// link or a URL) into a texture string a mesh can use.
	-- Decal / Texture asset IDs are converted to their real image ID. Returns nil if nothing usable was typed.
	function Avatar.resolveTexture(input)
		input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if input == "" then return nil end
		if input:find("rbxassetid://", 1, true) or input:find("http", 1, true) then
			return input
		end
		local digits = input:match("%d+")
		if not digits then return nil end
		local root = loadAssetRoot(tonumber(digits))
		if root then
			local image
			pcall(function()
				if root:IsA("Decal") or root:IsA("Texture") then
					image = root.Texture
				else
					local decal = root:FindFirstChildWhichIsA("Decal", true) or root:FindFirstChildWhichIsA("Texture", true)
					image = decal and decal.Texture
				end
			end)
			if image and image ~= "" then return image end
		end
		return "rbxassetid://" .. digits
	end

	-- Turns one asset ID into things we can put on a unit: accessories, clothing, body part meshes.
	-- Returns a list like { { accessory = x }, { clothing = y }, { partModel = z } }
	local function resolveAsset(id)
		local found = {}
		local root = loadAssetRoot(id)
		if not root then return found end
		local all = root:GetDescendants()
		table.insert(all, root)
		local hasParts = false
		for _, object in ipairs(all) do
			if object:IsA("Accessory") then
				table.insert(found, { accessory = object })
			elseif object:IsA("Shirt") or object:IsA("Pants") or object:IsA("ShirtGraphic") then
				table.insert(found, { clothing = object })
			elseif object:IsA("MeshPart") and R15_PARTS[object.Name] and not object:FindFirstAncestorWhichIsA("Accessory") then
				hasParts = true
			end
		end
		if hasParts then
			table.insert(found, { partModel = root })
		end
		return found
	end

	-- A bundle ID (like an Overseer arms bundle): every asset inside it is loaded one by one.
	local function resolveBundle(bundleId)
		local found = {}
		local okDetails, details = pcall(function()
			return game:GetService("AssetService"):GetBundleDetailsAsync(bundleId)
		end)
		if not okDetails or type(details) ~= "table" or type(details.Items) ~= "table" then
			return found, false
		end
		local assetIds = {}
		for _, item in ipairs(details.Items) do
			if item.Type == "Asset" then
				table.insert(assetIds, item.Id)
			elseif item.Type == "UserOutfit" then
				local okOutfit, description = pcall(function()
					return Players:GetHumanoidDescriptionFromOutfitId(item.Id)
				end)
				if okOutfit and description then
					for _, property in ipairs({ "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Shirt", "Pants", "GraphicTShirt" }) do
						local value = description[property]
						if value and value > 0 then table.insert(assetIds, value) end
					end
					pcall(function()
						for _, entry in ipairs(description:GetAccessories(true)) do
							if entry.AssetId and entry.AssetId > 0 then table.insert(assetIds, entry.AssetId) end
						end
					end)
				end
			end
		end
		local seen = {}
		for _, assetId in ipairs(assetIds) do
			if not seen[assetId] then
				seen[assetId] = true
				for _, entry in ipairs(resolveAsset(assetId)) do
					table.insert(found, entry)
				end
			end
		end
		return found, true
	end

	-- onDone(ok, message) is called when the item loaded (or failed).
	-- forceBundle = true: the ID is a bundle. Otherwise it is tried as an asset first, then as a bundle.
	-- group (optional) lets a whole set be removed again with Avatar.removeGroup(group).
	function Avatar.addAccessory(id, unitId, ally, onDone, forceBundle, group)
		task.spawn(function()
			local cacheKey = (forceBundle and "b" or "a") .. tostring(id)
			local items = accessoryCache[cacheKey]
			if items == nil then
				items = {}
				if not forceBundle then
					items = resolveAsset(id)
				end
				if #items == 0 then
					items = resolveBundle(id)
				end
				accessoryCache[cacheKey] = items
			end
			if #items == 0 then
				if onDone then onDone(false, "Could not load " .. tostring(id) .. " (wrong ID, or not an accessory, clothing or bundle).") end
				return
			end

			local folder = accessoryFolder(ally)
			for _, item in ipairs(items) do
				local rule = {
					accessory = item.accessory, clothing = item.clothing, partModel = item.partModel,
					id = id, unitId = unitId or 0, ally = ally, group = group,
				}
				table.insert(accessoryRules, rule)
				if folder then
					for _, npc in folder:GetChildren() do
						task.spawn(function()
							pcall(applyRuleToNpc, npc, rule)
						end)
					end
				end
			end
			watchAccessoryFolders()

			if onDone then
				onDone(true, "Added " .. tostring(id) .. " (" .. tostring(#items) .. " piece" .. (#items == 1 and "" or "s") .. ") to " .. (ally and "units (blue)" or "enemies (red)")
					.. ((unitId or 0) > 0 and (" with ID " .. tostring(unitId)) or "") .. ". New ones get it too.")
			end
		end)
	end

	-- puts a list of { id, bundle } on ONE unit (used by the Custom Spawner outfits)
	function Avatar.applyToUnit(npc, entries, wipeFirst)
		task.spawn(function()
			task.wait(0.5) -- let the game finish building the unit first
			if not npc.Parent then return end
			local ally = npc.Parent == accessoryFolder(true)
			if wipeFirst then
				pcall(applyWipe, npc, { wipe = true, group = "slotOutfit" })
			end
			for _, entry in ipairs(entries) do
				local cacheKey = (entry.bundle and "b" or "a") .. tostring(entry.id)
				local items = accessoryCache[cacheKey]
				if items == nil then
					items = {}
					if not entry.bundle then
						items = resolveAsset(entry.id)
					end
					if #items == 0 then
						items = resolveBundle(entry.id)
					end
					accessoryCache[cacheKey] = items
				end
				for _, item in ipairs(items) do
					local rule = {
						accessory = item.accessory, clothing = item.clothing, partModel = item.partModel,
						id = entry.id, unitId = 0, ally = ally, group = "slotOutfit",
					}
					pcall(applyRuleToNpc, npc, rule)
				end
			end
		end)
	end

	-- groups = { Head = true, Torso = true, LeftArm = true, RightArm = true, LeftLeg = true, RightLeg = true }
	-- team: 0 = enemies, 1 = units, 2 = both. unitId 0 = every unit.
	function Avatar.addBodyColor(groups, color, unitId, team, group)
		for _, ally in ipairs({ false, true }) do
			if team == 2 or (team == 1) == ally then
				local rule = { colorGroups = groups, color = color, id = 0, unitId = unitId or 0, ally = ally, group = group }
				table.insert(accessoryRules, rule)
				local folder = accessoryFolder(ally)
				if folder then
					for _, npc in folder:GetChildren() do
						task.spawn(function()
							pcall(applyRuleToNpc, npc, rule)
						end)
					end
				end
			end
		end
		watchAccessoryFolders()
	end

	-- generic "add a rule that is not an accessory" (wipe / face) to the units of a team
	local function addSpecialRule(fields, unitId, team, group)
		for _, ally in ipairs({ false, true }) do
			if team == 2 or (team == 1) == ally then
				local rule = { id = 0, unitId = unitId or 0, ally = ally, group = group }
				for key, value in pairs(fields) do rule[key] = value end
				table.insert(accessoryRules, rule)
				local folder = accessoryFolder(ally)
				if folder then
					for _, npc in folder:GetChildren() do
						task.spawn(function()
							pcall(applyRuleToNpc, npc, rule)
						end)
					end
				end
			end
		end
		watchAccessoryFolders()
	end

	-- takes off the accessories the battlers already wear (before an outfit goes on)
	function Avatar.addWipe(unitId, team, group)
		addSpecialRule({ wipe = true }, unitId, team, group)
	end

	-- template = "rbxassetid://..." shirt texture
	function Avatar.addShirt(template, unitId, team, group)
		addSpecialRule({ shirtTemplate = template }, unitId, team, group)
	end

	-- texture = image ID string, color = Color3 (white = the face as it is)
	function Avatar.addFace(texture, color, unitId, team, group)
		addSpecialRule({ face = texture, faceColor = color }, unitId, team, group)
	end

	-- targets = { clothes = Color3, clothesOpacity = 0..1, meshes = Color3, meshesOpacity = 0..1, meshTexture = string } (all optional); team 0/1/2 like addBodyColor
	function Avatar.addTint(targets, unitId, team, group)
		for _, ally in ipairs({ false, true }) do
			if team == 2 or (team == 1) == ally then
				local rule = { tintTargets = targets, id = 0, unitId = unitId or 0, ally = ally, group = group }
				table.insert(accessoryRules, rule)
				local folder = accessoryFolder(ally)
				if folder then
					for _, npc in folder:GetChildren() do
						task.spawn(function()
							pcall(applyRuleToNpc, npc, rule)
						end)
					end
				end
			end
		end
		watchAccessoryFolders()
	end

	-- deletes every accessory the units currently wear (the game's own ones too). Returns how many units were touched.
	function Avatar.deleteAllAccessories(unitId, team)
		local units, removed = 0, 0
		for _, ally in ipairs({ false, true }) do
			if team == 2 or (team == 1) == ally then
				local folder = accessoryFolder(ally)
				if folder then
					for _, npc in folder:GetChildren() do
						if npc:IsA("Model") and ((unitId or 0) <= 0 or tonumber(npc:GetAttribute("ID")) == unitId) then
							local any = false
							for _, object in ipairs(npc:GetChildren()) do
								if object:IsA("Accessory") then
									pcall(function() object:Destroy() end)
									removed += 1
									any = true
								end
							end
							if any then units += 1 end
						end
					end
				end
			end
		end
		return units, removed
	end

	-- removes everything that was added with this group name (rules, accessories, clothing and body part changes)
	function Avatar.removeGroup(group)
		for index = #accessoryRules, 1, -1 do
			if accessoryRules[index].group == group then
				table.remove(accessoryRules, index)
			end
		end
		for index = #addedAccessories, 1, -1 do
			local accessory = addedAccessories[index]
			local owner = accessoryOwner[accessory]
			if owner and owner.group == group then
				pcall(function() accessory:Destroy() end)
				table.remove(addedAccessories, index)
			end
		end
		for index = #addedUndo, 1, -1 do
			if addedUndo[index].rule.group == group then
				pcall(addedUndo[index].undo)
				table.remove(addedUndo, index)
			end
		end
	end

	function Avatar.getAccessoryRules()
		local list = {}
		for _, rule in ipairs(accessoryRules) do
			table.insert(list, { id = rule.id, unitId = rule.unitId, ally = rule.ally, group = rule.group })
		end
		return list
	end

	function Avatar.clearAccessories()
		table.clear(accessoryRules)
		for _, connection in accessoryConnections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(accessoryConnections)
		for _, accessory in addedAccessories do
			pcall(function()
				accessory:Destroy()
			end)
		end
		table.clear(addedAccessories)
		for _, entry in ipairs(addedUndo) do
			pcall(entry.undo)
		end
		table.clear(addedUndo)
		for key in pairs(accessoryApplied) do
			accessoryApplied[key] = nil
		end
	end

	function Avatar.stop()
		Avatar.running = false
		avatarSession += 1
		for _, connection in avatarConnections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(avatarConnections)
	end

	function Avatar.start()
		Avatar.stop()
		Avatar.running = true
		local mySession = avatarSession
		local useOscar = Avatar.oopsAllOscar
		local targetUserId = Avatar.userId or player.UserId

		task.spawn(function()
			if useOscar then
				loadOscarAssets()
				if avatarSession ~= mySession then return end
				oscarMode = true
			else
				local ok, model = pcall(function()
					return Players:GetCharacterAppearanceAsync(targetUserId)
				end)
				if avatarSession ~= mySession then return end
				if not ok or not model then
					warn("Avatar Applier: could not load avatar for UserId", targetUserId)
					Avatar.running = false
					if Avatar.onFailed then Avatar.onFailed() end
					return
				end
				appearanceModel = model

				local descOk, description = pcall(function()
					return Players:GetHumanoidDescriptionFromUserId(targetUserId)
				end)
				if avatarSession ~= mySession then return end
				humanoidDescription = descOk and description or nil
				oscarMode = false
			end
			table.clear(processed)

			local npcFolders = Workspace:WaitForChild("NPCFolders", 10)
			if not npcFolders or avatarSession ~= mySession then return end

			if Avatar.applyFriendly then
				local folder = npcFolders:WaitForChild("FriendlyFolder", 10)
				if folder and avatarSession == mySession then setupFolder(folder, mySession) end
			end
			if Avatar.applyEnemies then
				local folder = npcFolders:WaitForChild("EnemyFolder", 10)
				if folder and avatarSession == mySession then setupFolder(folder, mySession) end
			end
		end)
	end
end

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local GRAY = Color3.fromRGB(150, 150, 150)
local ON_COLOR = Color3.fromRGB(150, 230, 150)
local TUMORED_COLOR = Color3.fromRGB(205, 160, 235)
local PANEL_COLOR = Color3.fromRGB(45, 45, 45)
local ROW_HEIGHT = 44
local SETTING_HEIGHT = 40

local connections = {}
local layoutCounter = 0

local function nextOrder()
	layoutCounter += 1
	return layoutCounter
end

local function make(class, props, parent)
	local inst = Instance.new(class)
	for key, value in props do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function outline(inst, thickness)
	return make("UIStroke", {
		Thickness = thickness or 2,
		Color = BLACK,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, inst)
end

local function listen(signal, fn)
	table.insert(connections, signal:Connect(fn))
end

local gui = make("ScreenGui", { Name = "OscarsCoolPanel", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50 }, playerGui)

local ICON_ASSET_ID = nil
local ICON_PNG_BASE64 =
	"iVBORw0KGgoAAAANSUhEUgAAAHAAAABwCAMAAADxPgR5AAAAwFBMVEXg4M7g3c3i1s3e19Hi0NDez9Ddy87Zx87R0tnSxtDRws/LwdG/zuG/wNmawtcT2RjF" ..
	"u9C8uNKwttiZtuOlpbuji3aLlK2Df5JSm+1hm4sim3IOoglFhuFjgFknhbIVgxF7dmx1ZktSZUFKTU03Zzw4UTA4Q1U0Qzohcn8hVykSbxETWhQlSCclPioT" ..
	"SBsTPh48MjEoMTYjMTQiKTEcMicdKS0cJS0bIioRNhsSLx0VJyMOJxwWHyUQHyEUGyQPGiGeSleTAAAWBElEQVR42o2aC2OiyBKF2TxmNCYzxhiY2ayD8uoA" ..
	"DQg08lT//7+6p7oBMZPZu7UTNBr5qOo6VdW42pevsPn8YQFbKlssHh7mX7/c393c3Px1ZTfXdvcF9nW0/jc6zL8+fGI474NGsIeHC21kEvID8eYj8G7gfZF2" ..
	"f68evygfeptLG37R+ufXPEI+XCMV4H5qOPFcXjXOSUz12tTnK1NgjZ7Jy5E+XhzFib4q4ODN3f14LnXNi+Xz82r1DOuXob92ei6v4RMkQtoHQTEfxk+oawbm" ..
	"KnrDYtB1gbZ+eXlZSXuemrzeT4j0QQ1nHWI/eUctyx1hlGv07sMk9nTe1ZqAo63Xq/WK/q16n6XTX0ew/Oyzdk9e9Pblo9GV3PWXMqSW9EG5tQLmx5VJ8ODx" ..
	"cqnioWLZR0UbgzZZLHLqfsLFJ6aBVCRpP378c23EXMPZtXSTAqvWdpSBJiGfZv7dBDjSnkea9Oif32zwk5xcLuYU0FEgpHVtIjPtL41+1bQBPfr5db6Y0D4n" ..
	"fSQSUro4l1Ht68sDQTRtxGqDXbyl+MJFaGDAyfP+8rz3d/v9169fnyJ/DESqIENhIKh2xbsAtb+mepcuPhNvcO2d8Tja22Tvn7upFENIxYMY6IHOrA2R1C7Q" ..
	"PsR9aKmkAHjheXs/CAK+3zOXsX8jjgvZO/llZHwATgNLmkdI4WDP++XtU9+Pw3AvhB9E7LOovozruBzKyAAc/LnEUbu2mzus4XICtOEWLOKRENxHZD/6+GOQ" ..
	"zQX45crDC+Watlyvl+vX1+XdnUwalTG/bJuxPbM3Nhwsm7JI2dRHZNEgDFkAVM0hF2UJ/ujUsISKl7I0bao4sdZ3X+Ui/vjxy3YJyBiOcLDsyiJPmScTyYHn" ..
	"meg8Al4q7HIorXMqdtrN7yG8mH1umzo0g0q/wTIu4aIegWdHIkkqWF03MHLRg48sMMMwrs+e4vWsZe8kCRL/aVRmtD8idTuLkthna8pUIm4jhsQU0mpRS2sE" ..
	"HN6///OO93xfeGN+LpcjcTk0Le2W7BMdDquYCvCEJcW40DeIY4RI4rCPojwXAh7WNUiifMdbPs+8fvmGaBKxB5I+CKgqyi017Gs8XYHRcD9O1iSOO911mRuJ" ..
	"KIlsy7b3ysjVKiqabrtNoJRCX007ZD+wKHsYgLJmqn43v2rzsK8sNgOXmtTXu1cXxngY29vdzrLd/cDEcjaFrbMwqNjzU9+Gn56eRicvaO3mTjVzwIYFfpiP" ..
	"/Wu5nG3bINjc0a9PW440jOIg2m03G8uVQDo0cVg1WWbbQXC2F89PQwMeOszUtL4pQCOLxXLaWQfT8yDU1WtO7O7g2u53s6x9mQvmmGdj3js1tKQeCX+f6Czo" ..
	"+HBnAe8vpA/NJ41j2QD++fGeWK+w3RDK4clOvlhS2Wn12aKfDGU1I/E9LUfey4vWezMZEz7WRS8MhiLSAwkA225fX9fDCwBWkeN3+oyqNY2ManIgYj8nSJD2" ..
	"r81UdaLYV09+bvhOnR+YLT2RxwHYVdEmqAxK0MX8yzgnyWHoMplo//xf+xXxnvfTofV7pUVToRwegSbgxghigzS/eKBp74ampXsaCrFsyDkZ1v8ElB7+2mw2" ..
	"JreQH58nzamu1usg1mdPCOn9/WU0g+5upchp1zH/D8B/mAT+dDZ/m2iCQYDiGgTmG5kZhHESfjfjCrU12SydWNfuiUBFoy8ht5NpEO3pPwC9gLrP347z5vCQ" ..
	"aIT6rgxI33xDzY7jxE+MTWVowxRINUv+uxpA/wvwnb/L5mO+cQDfzO9Te3sLyOEwDBM/tLbVVrsQVJ28vRp5/xMwJOAv3zQjlJnBt+/gmNJH0wzegKyC0HkN" ..
	"LTmp3P41KcmyQNMqUvpo//z4xPpRrxfMu++oyPpRFI5AxzHR/iRRrmZYmwDG7K9xYLlVjUHKsd+gYA1//Hj5zcbXFJX5wTse33lEwIEnIxsEMqr49xYT0I1b" ..
	"Y5wwb+8+Guia7M5PS1IJtWX8PCnr6+rLy7aMzdB40WUrjHvgW0CefX8L3wZgVfs+D804f5BzymWMVgIZNhEaccZN+Nd+I0Px/np/R3qdrbtD/Gb6i7UngX3K" ..
	"mCYt3tv3ERjUNfHM5GwjmPP52Gdv+sW8UYtJge4ZX9SOcLTlekHvPaQRj2N/bUXRFBhcA82Y+n4U1yKy14a9N2aLxWyw23GXPptp0z3ald2uU9tYL5eG7XIe" ..
	"g4lWHwneAymWBOqzxjQxURVMDh9pl5f50PenvW5FK6X1crm9vf9gtw+YEWkedP0AiR/yFGcT0aDCIKTcjM0+TQM0/TJBwYlEU5a5N83AyWYVxXvq1AeknaZp" ..
	"zrjv0wkDTJxk5iALaCLseXg/rAGMof+46bqutD/SRqR296nJ5d0e8kNeCqjCfAtCAnICvl2KTF/dTBJFVXWYfsKqJeD2cfUb7xMPp7ibW804HMqyaOoqptpl" ..
	"p4UCmhNmX2lIFFXdlCjlVX08dQfj03CqEYNOf3dJ4ksS3a5zAJumTZIEQA9AjKE4uTlB9r8FrRyIgypJ6tMJOTOtIyp1KGMeH2fQISVunyf30wW9W6ZwsYOH" ..
	"IXnIvALEBuE1HQlRZsrnIQG7JIiTioDp+kmNMSglUhjzoZ4stJdPDdezmM29kkKaJDH1PWZn5CKd33cC6ojKHPI5brDPQNLEddseAVzef1G3woZslFPhBfh7" ..
	"+ZZUu8TmSAjM0yb6rM0a0UhgbDmODyOs40sVNhTSJG5bAp68+zHpx9kGo+GMdPjtG04tDxP/5PHbagtFZdjNhNQXEtsGkBMwtCyJdMhi6vsExBIGiOjx2J1s" ..
	"KirqZt58NlcFWhWAlaYiO1Ts0Z4xmdwaZY69XxTHJIvQXkP6EhiAZ4JlbSzHRUc2g7pryjwBmELanbazSxN4uhqrX/6whtRBnmY6hNgdEaU6hMDs2207ArF2" ..
	"xLMcFgAY1gdcGQb+tm6PEni5dNmIxgK30q75q6k96eB1DQkxrES71dYi45Shvm3J3MQY50SUOKFIDwAmEGN7PnUn47GnLfpbGBRala2a9H0IwEIGHq/jb+5J" ..
	"F3lJxCQJEyGoC3jRCISDG8t0JTAuvMzDvFMl8PDUdXoPfBwbxmJAqDvCY8Qf5T8pUTyuvBx5Culjm885jzj2nX4PtOy9u9k4tqDKntCeMcZ1VW2DJC3Xj3QC" ..
	"eXhePT1Ok0NTKfPY720+rCQJEVvcKkYbSGIaBWsqAty25IbUNR0vATBEq5CTKdbwqIA6xmb9cY1L8u3V02oI8ELqUJUdenWFP3HMn6tHtYiPdkfKR9rUiUCB" ..
	"AzORRYdbcm9Ymg6TL9S4IrIWqjifTrnlopWEvv4zRG4lTH9cjeXtOktXukVFxNmgf+KPnjYyog3qViJq7kP9nCZQFm3cfZ7npeMngs6cUKuqpCbOBITTOyiV" ..
	"2y524TypVBKtvuGs2jQ5v21cF04kMd+sVvrG2QAIoiDPEqRLEMTY8IcJSywXrpcFgAxvMj8MA1/guiAKRIPWOfATtI80EliMqjUGH0kWF2MiQlwSwZlNpSTY" ..
	"bETTnU7n87FtEobTYC7zMWtEtc3KPC1zRI5BDQxVzgyjOu7La+BTl+pymhiiiBxvxqhqF/096kK0FS0VYzROuLJykV8UMMFcKMJnMZ0fa5d6HrSexBGrBF1L" ..
	"EGdVRVM/Eqtt6iTB7txyURiiBInUpPrjb5Xm8WfdSGDkGTaYhWgaEfkhSdwMizSiWdunt8M3x/aY43kR0gRcyauzqhaQa1FEmIIC1Fts4lyOwYoCnXn676XN" ..
	"piKGMYjZGzdyXRclGjEUAilfC5GJyNmgcNeMbqQECWqoQ3pgtoP5JqnL4piQQtqW6mAb4gT4LJYxEwAe0u1vQF1QOtZC3ZoEj/aZTujuqHL6IsNMw1xUFTui" ..
	"kSOmFhy0VZsi9GiDXY7RgBTZyn4dYB0TJMAhF2lxQH1Nvd+AP5vmCA1k1OdpxRzgLD/2scHFqRuRQZFHxBzJgRSh6e2NwEiyFlo4CJRcc+jKNNw0DYK73/se" ..
	"K7quSFP9I9AuqG5mzGbZoSuYyhlzMLpvWByaY1nULbVcNc/gH1Li2BRYqCoJx02xvMtYu9x399xx0/xQ5Jl9Bfz2orOUhjS2/cm562KGpowhpBpd0F8h/Kq1" ..
	"bRESa9PPhxhnKpp6QvTehHbCKKcN8HXVcivGiei28eGQZymTLqLjk0EU2zQ7gIcc8DmWilLGFao3URaARzlfMWbKzdJGRpQO6Em0qBB+w3lNqDqGECvQfEq6" ..
	"psxs75Bl3voRJO2xt5XHsuKQpWkUccg7oJyBkDjdz8MWxqwjSn4fmzKaEIkHFu1iQgQTug/i6JyYjqypQIU+ao+MbZdlxuzJ9rYrybkA7TTvUpt1GHddrJ/v" ..
	"UJ66FrdeX3fo6lA3yVBU5mXyJgfNEHVECf+YOBZgCAglD2pbdTwW+yj0HQOAvjGOwMdHw7PXj486w/jZVxkfiUqOuqHpNymnFMLIKD0cRn2EtTrHxBOYoRwz" ..
	"7vMUMYX6Iovvo9h3a2M2IAdgz1+udYdDAFQuHEslqeO78KDOBLc2b/JOgrprMo7CNGPFdZmY6nW0QKI1ouIWr/euz6Pjdmz92mxi2pbROleixk6waKSjw4gd" ..
	"Z1RqcAV0a2jk0U0baNKvSPgVXR0aCEoZZMKrCqsPXNUc0vUYR232OCHaGckP3YBjE0rKaGqcX27/pPBlp4pj5/sEGFRyciobKtnUGPAhDlbb4gD6sUyZTahv" ..
	"3+hnsoYwnZKUoXNSX6T7aiQMfBISQ92D8DvUmhbq/Pv7sK8I5FBRRAkVYhHxJMGH4XEVI1bAdRmLmPc0Gz1U69f/tvZoj0RI5CiKaOzyyEIRjpH8Z0FyPAo/" ..
	"wanoXtDbUMSihiadOOkQGCg/cZMWf0OxPZ5ylNok9VazAXK9hgB62Ac2EaMGDAd3buLy3Q6a4lyKra3RgWPsNSj3KfmR/uLICRj4UHAsJxvEwI8R50MU5b7D" ..
	"I2+yhuv18/P6eS0flgaAG7TCQyMYJalFskcrNTH/ohqok3MCBqolEJI3DccL2BCYyGe14fAT4AqqGQy5gGZ4ARpTQ1tlzGc7NyubOpLF23FCak9vQURDt5+d" ..
	"hXQxlHNAICtMK2jCSATkgeHwb+CgilKofupTknrG47c/A12220VuhGwRXClRbgBTTjMGP9Y8VoZKDWScoMIEJMSsSHB+bEnbc9dELpJOaqSh0eZn3yI+Aj2P" ..
	"pSQ+xKKqeISJFBMATh0fUQqwr4DwkyMyET2hpnGL5l/R1FL4h7IpjmfqVU3EOd7wUUtrtHrP4ekA/PYbECU8IiRv25i3kTg2mDTP0F99ksJHkz9GCX23hmtB" ..
	"QakADGmw6PKkihxukbmhS6KISRRp6plxuv3DGnpkdLcCq8dxNu5WyBnXRSH2g5iEz8OkFUREH2rlqI1aQOP2oaOK6srRiT6ucCw65l6ogL0SprytBMJJVDUk" ..
	"qU/yB9CyAp/2gCR8jKjtEeNrQtMmiFUkMHh0hwKxxJRIu0ZkitRgl2cubzGv+XFqK9zt58DMtvOu4aQLtEZMmBYNawc5ScQxjRTwkYBYR561AmsMKLBoU2qW" ..
	"TZClGfIGI1xXSOBF6x+BtucVu1cIAyO+P8w0Aap503THJgohO/QdDI0VJrxKROhBSFVyEM9cQReBND1kNGci9VDHPT9J7fVg2rUqJDCzNtQE0+5YKQFUwoUu" ..
	"QCwIWBxRXptMDisUzwhDqqCNeStI6ZgbcteK8VGaTJGmns+Zt9V7+w2IxMnUly+7XUbF+tjtaYMNAdLch2ojwwcBFKKQT30sr/JQ+KiFHHs5iyOcMfawvEKh" ..
	"QEME0fgcyDwK6fB9CxdcfveDpYloZoVfzlt4VAa5nLE9E3SXpsPzI50beSZDiR2zi77BRY1yLkQOoLIroEf9l0ngq/ya0OIKrP5HAUabHJSbJC+whTg2GZlw" ..
	"zKrFPA/BpQxjkAstueQaJIUHzG+030g/BW49Rr2MlT0Qn07kt1vWIctTdbcW6vdjIqcHvIAVZz62Hd5wPein1OhjdwckGg3kiOJWZN6fPIxQMB2hvs6i4iu/" ..
	"Et25h7zID9gBFMqpjOXApeoa5CMU2p0oxudjLcsFotLSXJpg4sffen/yEHUNZUKtIMovDkSk7W4OYiGBhM7zNJOkvJMkgp2kIYOtXYvVs2qOaoVdMIbd7E/A" ..
	"nig9dDGYoErRWrolEEVZErLI0rxIMbn3wFNHdhqtwWRCq+fSQNOiBmExogJy234K9LCbE9Tv8SkExuLqa+ZCunco5SHPAEx7G4Aj8sjxqcSqEnRFSArX57Hk" ..
	"X4CMiFRJwYKSaGqHh/DqQGtI908LUAmYSWoPJGTXe8h3mBC5GjHylM75J6AqNCzL0RZo0sfHMNDAW57neLGUTODKEegBCJM0efcBwLqlaPr1+dwdsHZsn/4r" ..
	"cLulsBYlFdKYGoUFhcQqmqV0MkfGkurkGno5GN1o5GEsm8WRcIhmtO9yJv4F2C9kUXZNQnUDDr7uOCKJRZQ8gPNyXEKWH8eIdg0RjzXdrTmf8TdUbYumLMX/" ..
	"Adp4TOlGaa3ur0HHxEFMC2J2XanqwCgL6VpX9mCVvXTDmCd1mrb5XgGNPwGZtdtDzvmhpFU5Si03pAlKGGnlAcsnSw9+Bt4Q1FKmSewj51Bv8+yY7lOUUmMh" ..
	"EfpS+zBgGNu9SGmDYTOfFiqXYLRePBTSw4OUIimRgJlknVTqkB1kDz8ggbAMqVccxd5D7TNu9S3MwIZpS8HVje122wM7pm5D+WEkCwshSwmDHMnRMu814ZEs" ..
	"TqPs5ZNcTQ20ZvbRM1i5t20AbX2xhvCMNSbvXoOGTn+nG/vSS8umofbDthTl9EAlBnLHIZcllYDkvgR2U2J3HoDGWmeNrbOzt7UbKm3o9vrW3mmL2ZqctI3l" ..
	"DGen28w5LmdP1z+UP2zDD3L9cjAPstbIzJDAaWGjp4ceiBbPiq2edgTsizeAtjafq1ljNp/JpDG8/X7/utuPOABPpVq7ghoGhVZlYsYgoGZChCbPE2CWGXp2" ..
	"QNYDSP8T45byErsn+dUp3VvfMgn0UrmeH4CyjlJwCTyoglGWDqsoDxOgIbBAgooNeSjDjFTRlnTLXR4WANr6Gn7qtG/bjMC0lI2ir2z4mfDSS4JKT6fAZqOA" ..
	"UT2sK800M/XtMA63BkYdedRv11KpKoMBPFyMnsuMUbUtO190MZGF8hAeCYTLqWVEbXsKnNM3PwScEXA226TGYkmbxuXzmnUHGVMKJq1g0bOklxNJdBdgmm71" ..
	"LQOwhltWS3jAJPB5PsR0JoEL3WP6fGFk2xm9NV8uZgrYG2r3YYApoPSPvoelx3NKcaHQICWBqDc6AQccgPPZfKa+CAOQbWfzZwBxxFP6GgeHRVqq3lT0P2Wq" ..
	"GjBRs1OfpcrFDsDedJpEjdogoK2PhpDOpZPL51sdQDy1UwObDtuWXj8vbpdpqRwsh0cAx/J9umq/AJIr0hkw9S2Usbba7RVwNPhm3MLRTKej2n/Ax+ecOLlK" ..
	"U6pth7Qv3gp4Ok3Fn/YnNiQRYTV0uzEuwP8BAGru2iyqlAoAAAAASUVORK5CYII="

local BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function decodeBase64(data)
	data = (data:gsub("[^" .. BASE64_CHARS .. "=]", ""))
	local out = {}
	local bits, bitCount = 0, 0
	for i = 1, #data do
		local char = data:sub(i, i)
		if char == "=" then break end
		bits = bits * 64 + (BASE64_CHARS:find(char, 1, true) - 1)
		bitCount += 6
		if bitCount >= 8 then
			bitCount -= 8
			local byte = math.floor(bits / 2 ^ bitCount)
			out[#out + 1] = string.char(byte)
			bits -= byte * 2 ^ bitCount
		end
	end
	return table.concat(out)
end

local NOTE_PNG_BASE64 =
	"iVBORw0KGgoAAAANSUhEUgAAAikAAAA6CAMAAABCkDkwAAAASFBMVEXg4ubCxs6NkZVfXV1EQT04OEA8NzE0NTsxNTwxNDYtNTs1MzYyMzkyMzcyMy4vMzozMjoyMjw0Mj" ..
	"UwMjguMTgzLzMrLzYgHR2Xaz/yAAAVAElEQVR42u2dC5PcqLKEWwIESCCEBPj//9ObWUj9GHv37Nh74saJEF5Pd+vV7eHrrCwosQ+PFns78Ge7mmULIXAHHsK1Pect+jVs" ..
	"3s/WbPt5spfWinPGWDe7bfE+ZB67+pwPUxcbTfLeObt9tvC3bdsi3zKHwGvx04Xz87Bl2fNq+aOFu/2b7XGRgoflBIN90VH5JSnZr2sEKR7bPklxxZm8lU4KTsOxQoptps" ..
	"atGL/KSTcp/5OknGjsbMtS13Wtlc/RH11ozsbnnZRUiIefPV7FF2ckpaFty+bmsHMbWAkepORmqy3ZdipvUv43SWF3k5O1tx/nYyUvsR5HKZ+kbDnNvu7YHhc5942UNhsT" ..
	"tj3OcwQpO0hxSUgxDbJSNojRTcr/MinG1FVPwskFisCyxMvAvJOypdlAIppp1ezVxnefYhzizF5n0xbA52NyTkjJ2heTm8ZF4x9EHzk+cutFxdfzb1L+e6RUdPuutZ6ml6" ..
	"CczCzLwu/xp08hKT/M4k1zdqmmvZPiTNO2TnZ8jBLDYppncbZmeMDBGF74z0jJNyn/f6QsSweFoiI/OihEpfb48oWUkPTwkDbWYj6iT5vHh1pbJ6Xu4UnK4+FmM4y45B4/" ..
	"e7R/DL5Hf59XbDlJOWMM/srTi5SU4JjeeEhnu0n5b5Ey1UkrpU9QphcoZKVSVD5IgUeNqQ2PUY0jUMnFvzU3Yw9CzEVKnk9S9OPRisHWaf0VKULCOynx2ho6Hnh6kZLCRc" ..
	"rJxXm29++kJMS9lK5/5CFZ3N3+UFNOUKbpB3+sl1/prDTbHcqZO/O7i7435KE5AGHm4p1bkSzb1TfnZuyZSMq0Q6yQLs8wL81AUwp+jACFSVUo2dhscjHFOCfuprhmSyi2" ..
	"xQNH7nDANrlRldaCaS2ZcvgQzZFwyWYNnuEc0JBzSc1xHMcbg8NssA378Y4zX5dmOUoEUsrd1X+sKQRFgk8HZboguVCxP5Eyk4fVziTlMXgGG68YkCgz/UFe1VS4YVAFmu" ..
	"J6wFpJis3WjLpZjR8m2eZSg4sZdTiYI8Eqg5TYnBlVsoclSSl5C3hshmzJucW0GbI2agDV+ES11l+v1fIJNpiRb4JnB2TluPv6D0m5QOleBYoCVN5ZgeONb43WgzEGv39Q" ..
	"oEjKrEDKKJgode2R2IQ9go2mpmDroNTqGSZKMmokCS25Yl2CFUa/gpFwBDw7rDGlFMfebtSklFPDiZAU56BDI7TDNLnCmB2v4wCdwoMaLfRDjQnPFEkxJAWcxLur/5QUdc" ..
	"YezSdarz+pSv0ghekMvOnpaFf9GKwBKWV4KK91pU+ZKDLToh4Djuv+FppiZ0afaenOF4FiVGo0ml/+IppAHRBZMJlP9fjcpTtVyLbklewJvEDD+Ro7jEl6BHtgitpCCud5" ..
	"VNg1Ql+UsqXcRuVfIKWLSVds/Fo1gZlesCAcvJPiu6ZoDRKmBZrS/UoPM5UOZjJ0tBvzHRyyFoA0QVOQAI0/php9957oTmiAyACiiVGMPhnPjaIWGP6lSBiDA8ADdKS1w2" ..
	"mgA03R1RYEH91wFEhxhcEGsaqVUXmqjZk1SSQ/eJ879PwrpPTYo8ZhGMAKfoi2TG9WJXwlRRwtZAQd+BhW+hWkx9QZLXu4YXJIpQHLuoCUAZpiTKam7Bcp7uThlA9NUpLg" ..
	"OjrKhPgMNYuAJPY6jHSTV/QpMNpdYRTsDP5L1A8gg1OrPX0KUMJLKtJxZlN3+zNSpk9SBiHlx38iZbIUFZAizrZBiRBm1JOUvV3Rx/XowwQIWfJTU+gkEDzgTSyf0lWIpt" ..
	"DSjiqXTgv/Q4djvy6ldaERfbFIh2aBDb5FyTlQG4YkZFZqnGfYF8WjR7z6Okpzt98lRcPPKjbRFE278u5UPknxc2b0qQ0ZEHKf7l3N0B1t+3C07XK0Fo9J88WTFOd6duK0" ..
	"KtAIQmGEDUYfKMVIjvgUz6glSINdEW4OBqOY4YWBQnb9IC22RLyKjWpsZubRScm297miu/127tMTH6W7pR0pKO+xB63PzIWLlC03xJmKboVqiD8BKT1Ltkm9ZckrvKXYl8" ..
	"VKnoSNQw3BR+QiRyYVWRytRAtzfv+Zr8DJ9sCkRG1GcKMS+GrySm/Yc2QxrUyuiclIf9JPblukT5lPE2zpWmy5ncqfk0JOmCOLqKhJYo9ePzzt9oWUbGpdmik7VMCVpe5w" ..
	"m7NrZmnFlLiYGUmI9evq3GHibmpsjmMkhYdcpJjmEWhsKIg3tiC1xfU45WxDas61UkzmQAvOQaRBZwspCDnNhGbtvpEU07KB50XsSdb+KEygc4tm4yY3N/0DpyLtMe0I98" ..
	"jbn5PCvPgJSs98rnah8kFK5IxdnaxB79dc5mL3FthtR0T/lCPu1jUEp7ZrolABlQU7+3IkF8ypKSFYA1OKLmVVQ+agGohBp5IYXMQerZUtcrTVIdeBOqQzZjkO4daNY3Dz" ..
	"kaApwg8YtKAIF9xMRBJuGw5tHLNrJNGYW1P+BU0BKuoC5cXJm6Z8kIJQlCEldYkpWYQgqPxuaymgAP1hjw09M5u6W7PvUAEpnYuluVABR9ufpByl2dx6DSY6v7SDWBwbx+" ..
	"JhXo9mN7kUSML20gJIQb9DbWysZms5pRmgZNEMB57wEazJBVcwNorldTgfanIwvzZ3V//xaL4MpuiuJyRFfTW0X0hhQQu+tDE4t8XjSMdRa+MDtEEmf3c/twjnuu+yNe47" ..
	"jw1L2Oy2Sy0cr0ZEWDVAUvLxVlkHy0ydSXi+hTRTd1h9S7rOeb+499o7Dtr2hq08+5p45Me0B2tjvOc/sv3lvM894/w9UohHt7R9uvCLo/3x7mi3bdnYe4wPx1k7SbtR2G" ..
	"t5E1Kai8uTlAN0bFkgepGCnvxPpAAVkoIH+0lKp5Wzxz2L6km3kBI4iyyk7DFnd7AaE/9IxLSblH+HlEmJU9H6xEV/JYW/0RcpOdFbGJPRFewheIrjeJIi1Qe9ZIVbQcqy" ..
	"cdp/+9AU9H7fxgeZwnuS4q+KTLKBTjY/kYJPIaB4vus7Kb3wgOWe/MyHwMRIF8xXPqQi5iblu9GnTyi/ItDXNPmTlAUJhZSKHCQlcfat96wIB1BBcKrh6kghZQMOVkiBT+" ..
	"mkpK4zOb+Tgt5G1xecGK6eh7T8TEo+0knKVcJ0kTLP4PUi5eiklLf6FBIiBS8y33mT8m1STkL0hconKeH8zXKGMCwRvRFgMi06YmZXRiGC0UK+sazGjsEWOIqUkMfUBagg" ..
	"CYH5rNVakGJZOQfvgggVnhDy3CR5jMPZ4Xxtu8W9KJrpiyJLU0oribeKnKh0BhI/EZRtIZ4ZObOQYuhp0Zhiec+ox3+P3Dtwk/JtUsSqcGZWib58eNr9RYqf5xhmoIJut7" ..
	"xpoyXuEVvRezu7DPWQbJekJNdJgf4XjnzgSl4cMk4RL3Nc1xYy5obQhXSmXOQ4cOJMsadmOGNwtC1za/wU8CMfpHiS4vJFSjk1hbaKfsrAXa3NSJWl3FISblK+ScokibG+" ..
	"fn7JffaQ0osUKVFJplrkJGjJfiUFsUIKz0RT5lI1y3FxODgJLUNJGKNSyW+kPGdmcGkHLJAKCwK4MtJdcneSMh+l1qPMHOhrX0lJEpKck/Czc9zHrtQN3kIifgohbNXN3q" ..
	"T8ASky97P2Yf1p+mtS0BsnKT+s804NiA/bmQJJ9DmyS2WzJjO6QH7UQ7Nwe2HIMMNos+v3EfqCHAWkxK+kjINBYrQtJymhjQ9teQ8ASLEptQhlSOPAA0Et9KWnP4wmJylJ" ..
	"QgtIacYvUvCNRFk0pdgwjL7JzY03Kd+e9zlH2rSU0nZh+TS06zspUPNkWLzE6rU2Ds5yXAtssDYNf+IBlTG2wbCOg7VJDbq2UFutlTXXO6KSbyDJN6OH0dQjQ38OhIdyQD" ..
	"gMyxc40BYXXCs13UJTAytQWm3wxc3Zve7B8SCQ0gxyaJklaLbJFBROAIzwULh+1oNabeS4bzMVyhSqLcO4moOUWr/6ePuU7/uUSVBZdfcpb6Ky/qgfpPjkZhZBTqu37Nbq" ..
	"jINZrBwpbVvYDCRl47iqkIJDNRLdwn6y6NnFOI/Oq+jbAolB/xnO32EvPASczyykcCCWdZGHwXXnIoFr2+iMStvM7nmQo6aAnGCSN9aV8TEGBcWINvNe+ZWfADyvnBrAFQ" ..
	"CqbcF4kGL9kU0TTblJ+Z3o854EvUhZ13X5Sgo6ZAApTTSF03/4Ru/VzSZvDV9bzhsCEJDCgsZBr7CkDfGFA65VKmOr3XwyblCVNyNCAeA0aVqDcSIVYKtWlp5EHs57WKFK" ..
	"BgGoARhT/dyjD7hqsNa6NXdAoMAR3hKZDSd7fHPZPNSK1wUf1GqW9NdmedORtRyUAzF39Plu9GGltX76FfnzvJtwX40PKX9oCu/yAikGveWSHqWyoA4sexsDw8KDBVFSaq" ..
	"tAleyOIAVnLSxPGJXZmhQsPIbzdBDB0wdekhv0db1qqUosW3iMxvLsQUn0IS3qoRKlaeHsovXETNvDtX5YfwPSjGOGUHhD2wBS5FHtq7+rVn7Lp/w4y67Pdt0kJvcXx9f8" ..
	"ICMBUlV+Nf313VbodTUNUk6rdrCBjtUZO+rO2kiFfpokOiHcoC/pTyK+8WIjZjBlcQmnpMqF9fyDVowR5/UqPLHp7zH2R9CA3ud744LlgI9Zdo7kFqK4LzDcg7wJGZpE9+" ..
	"Y2DKRFLuJxET0Ou4U+2XQj8F1S9CcoWuaYJxa+fjaYh9SykAKL0b/XktWsA4vW0PlqMAwsubFLEX0Uv/66Mh6AFByVEYOa5d3KagUgqm44faZKHUox94GEDGsDcOxrXE/Y" ..
	"akZpU1wySkih+PD9zQYglwWJs8OeQe+LKN4m/pq+W2hm1kWiNkQfL1GxLhwLNP5G4BukPI2KeidFT78kRYZRRFPwdWUUUI+zwm0YD9bfTxCEAE1hN66VPoWdik4uPGti1a" ..
	"SK+DYLKYtR5w0h3DcdMyUKvoMUDCNU6DFCYDRlhZUwTUtht9o6KUifWEo31h3OAxugRitJ4bNBiYZNQgpZJV0wOwPvYkMMgrcuHFW5A9A/J+U19vYBynmn2FdSvD9gXTsp" ..
	"VrzCoI/DhHVCz5quAexMyXdXC8ugeV+7JmHcWxQ6e6zMomkwuL8u+95EUyosKuLCBgJLGy9NeRgKjzEwxCzz5Qv2PrQLcWbEBSbaXzcwmNl9Z0YkXimLpkj0QTwifdpAqW" ..
	"hngNJSDTOgm5Tv5D76Kj14C0Xd0/6sKVFSmO5o0ZskZQxb0+s0snCWTmTEt9/UrdGnPElBqJKzDEIVA0xyQopU7NdFEwLEMzWCr90UJthMZrgXUUPTMbcRj9AtqpTqjpa6" ..
	"NeKTrEi+ucrCvoCZxncylBDkPuJTkD8NgwVhK69apJz/oVvOW7ijz/dIOW2K7gNvk9xX2DVl+YmUgKjvuqNlvsycRYwioo9mz5ID98PuldZTmSv6VBc48jbxLpFhMKWTYm" ..
	"hQ6S9HOlrGhZmXpBnGt39NOKPyCsBgGSVEsbabmiIeheI2KJLCi7V9WXZbbeqOduC2SXGUkMXhB+8pQaJFFhXIQXi8Sfn2eEpXkXPmZ5qe0WfheiefbQMpqSlxtK6ga/nb" ..
	"p89YOfqpqSndeGi5KVVfjraVo0nPSYp6WJdzpmdxrt/tTh3BHqY0kYn2aiROdFIkpcalLYMKOprZslK8awRH0kwtYKo3Va1z/U14d+NjlJ84yfbcGUz2LHmN4lNuBP4pKX" ..
	"U9x2hlxuc5R6gYkvb9J1CkDq1kx/WVCifqTJpTCWatFV/tgv6nvmdKiXO5HB6uAXZC1+JYkwTv2XB4s8ZBVGzg0mEsu7WWa8EZGc4/wuG83VckS8mZzcwy+NuM9xb2ppgU" ..
	"KlxrhluCLJlRltrYkuGcYa0Lc5qCszianx2iUXKcn0Y+5WaLdwffjlObAP3g7M/tU/4pKVDsRWB5q7fu4ykT12pbPn+TUgckq9nsqw9czaTXTLNe1fclaBkPEvPVo+SNs3" ..
	"YRGU1cNo7Ruric8359fZy+xNOcZB0fTiNzijAsLGjjMA66MrMaZs7b0hf6iVKtdBwlHTS4hkQuS5QjAYbjqpeAM21bwl9W+sbgssxr4hX/BTKCH1mMK0v6fKz4cbe/IwW/" ..
	"fi4c2cfxn6RAWEAJKPryG7wqxtCDO0nptShW5vo7KUakn3ezh8BKSamF66XYfkbPkRTOHWfps44KSVm2dPXwIouX7pw9ZsWt1KHECxWSwmK3DGfsuNDGtNTjSCcpMCq71F" ..
	"lv0ItN6g8C62qDVOxKNbC87jUx10qHNyn/iBQrpOzLpJ/2BH/rvnJJv1+u2PckRVaxDtsnKVCOo7TAL3xfr7aTEmR9rV6hdlEnlWd9RcgkfScV09u5bhx78lywJfWqTESZ" ..
	"LcSrdlcmGTezkhS+B7ENT1LI5jsp9lq0O+Qj3KT8HikRfqRWLrf1XOoN6SbN7F+t7SiFQCIvW1guUoLvPY0c1AYL0yFy0SuQXu1FSsfF+74epUssfk2uzzD1BZEvUvrabt" ..
	"uyby9SeMch/IutUD52+Zal3jtc/U6dYgn4ixTeOSKgHH1VuZuU75HCL1t8LXR9zvWAHP83dabPJdP5TYfSJ9GLrglHp+OMK+fyjvLkXMjvvMAZy+gnNok8nZReVuuF0r4I" ..
	"1HnGGX3OdSrTddvHfpGyhe2s9CcC/mdSPFcNs0HWoczhp+T/bv+AlNDNZeS9Ouvq11piiOedVr/k5LxDQ0C5SHG9clpWSu9CcZEijpJE9MeLFIae/t3vR+Ja4kPpQxhnOi" ..
	"mJZdUxpb5u8vJc0ZSY4GekI4+HP2CKcD5CkOufgmQmn2Xl2pMUruDPVzcpv0UKb/U9O/SQqkLeblMQBXivDvblvwblEDe89/t/uI5j3yVGgf/PDsYU+QaDCLkZaNlfoYf9" ..
	"RWNzOVoxneJ8uTrlScrOldVpbrvy9HsZ39c1PYDHsoMUT0laLEjxAej4wn+RfyMlv0iJNyl/QAoHwnhv13ljXpH7Jv6WFNARKCk78+ZDVvwU2+Fl2aXwQYpEGZASXx7llZ" ..
	"NcetPV59SUeJECbkRTun79RApRYbDppIDPkxTRFP9rTblJ+S1S3vKZX2Y5f2VT+rNtu56dh57WooczyWieZWX5Py19/vZm8ZWUX2z91drpz40cFZRLnFvyT5/6+QZ3pdvv" ..
	"k3K3u92k3O0m5W43KXe7SbnbTcrdblLudreblLvdpNzt32z/B5q9tuo/7cOEAAAAAElFTkSuQmCC"

-- executor compatibility: finds a function under any of the names different executors use
-- (Xeno, Solara, Wave, Delta, Synapse-style, Krnl, Fluxus, Codex, Velocity ...). Missing ones just disable that feature.
function Custom.exec(...)
	for _, name in ipairs({ ... }) do
		for _, source in ipairs({
			function() return getgenv and getgenv() end,
			function() return getfenv and getfenv(0) end,
			function() return _G end,
		}) do
			local okSource, env = pcall(source)
			if okSource and type(env) == "table" then
				local okValue, value = pcall(function() return env[name] end)
				if okValue and type(value) == "function" then
					return value
				end
			end
		end
	end
	return nil
end

function Custom.copy(text)
	local copy = Custom.exec("setclipboard", "toclipboard", "set_clipboard", "write_clipboard", "writeclipboard")
	if not copy then
		pcall(function()
			local okSyn, syn = pcall(function() return getgenv().syn end)
			if okSyn and type(syn) == "table" and type(syn.write_clipboard) == "function" then
				copy = syn.write_clipboard
			end
		end)
	end
	if not copy then
		pcall(function()
			local clip = getgenv().Clipboard
			if type(clip) == "table" and type(clip.set) == "function" then
				copy = clip.set
			end
		end)
	end
	if not copy then return false end
	return (pcall(copy, text))
end

local function loadEmbeddedImage(fileName, encoded)
	if encoded == "" then return nil end
	local ok, result = pcall(function()
		local write = Custom.exec("writefile", "write_file")
		local asset = Custom.exec("getcustomasset", "getsynasset", "get_custom_asset", "getcustomasset_")
		if not write or not asset then return nil end
		write(fileName, decodeBase64(encoded))
		return asset(fileName)
	end)
	if ok and type(result) == "string" and result ~= "" then
		return result
	end
	return nil
end

local FLAG_PNG_BASE64 = table.concat({
	"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",
})

local flagAsset = nil
local function getFlagAsset()
	if not flagAsset then
		flagAsset = loadEmbeddedImage("OscarsCoolPanelFlag.png", FLAG_PNG_BASE64)
	end
	return flagAsset
end

local function loadIconImage()
	if ICON_ASSET_ID then
		return "rbxassetid://" .. tostring(ICON_ASSET_ID)
	end
	return loadEmbeddedImage("OscarsCoolPanelIcon.png", ICON_PNG_BASE64)
end

local GHOST_MP3_BASE64 = table.concat({
	"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",
	"VUH8//soxOWACSRtWUekZQFCiemVhJiIlEaExzenZHsRvKK31KGvFjsAUmWFJKRRWtNxIoAAA0QN5bVx8AF4lyxKalCCJEDEhV4kI6zatXw8XfCYvPPVDkiiQkdt8OstFSJEtdeTg1caevRcnjdYVolnnFk99lm1YK2rbchzaQw+kfvzlEad",
	"c9WC9Na37T1ezPrjfyu22c1/zMtEig1KAzFG5qEt+tX6z//NUmfM///mmIAyqpAZ//soxOgACiR3YaSYZ6FHEelhgwzwJRQTCoVqiFRMQ7SJjnp4BoDwbGo5jkQiSZLxjWGVI4/KexYyzBEeLxeKQ6VcFEka51JsAnySuuzp23Vf//DbDCq1",
	"2gIQMFEtNIgFJyJEjlEiRsUcSpzUQ6JQVEQMqDtURA1EzxKGhEGlA08TPKgq75KDUsehqCrlB2Wlf7q3KBqIg6sFTqw0DxWR6aunootjeAJfPmaTeecmyOAA/dWY//soxOYACbRfRqeYZ0FFCWmmmJAA1Zcefry54Qlwm2VLGioTGCJ7S4ug",
	"c+VQ2LHnaAmxcquUrbwIfJgUUiIRYGvY7SeBVNxKqqEhJxJIsjEkIIhklgiRNLNVJEKmrjygMY6FAnX9mAlUurAICGHhKCo13rDSjzDv1jToNSwagqGu/BXavEr/+7/nWEBKy8+HhnKrCqqs2ZYBCuqAicmZuQRCyiffQv5H8TMyxtmNv15x",
	"mjH5//soxOYAESELR7j2AAkUj6hbkjAAGtNSn2l9Lh9/mza1eNxj/2Y/jUvlKD/gzv710ksKFQBWCEjVX2aFIjXhERqeaMn8U0LoRP4v7/+chDU8hHFIRMKJhIUjQsKwoQjUKxc2HxNV1dvY11agoYkGvWadFdzgVFCAtY8yoqFH4/SEhd0Z",
	"qH1GqekJN/FtgzjCQMihoKkQkRCRoV8Kkh/kgZSDIqKgkJiQVAQkcuRCYCJEVUxB//soxM4DCLw3NkCYwAEui+FE9JggTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVTVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxNSDyDxs/gMkaQEfKVtAMI7RVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//soxN8DSFFEwECEc8jrAFKAEIwAVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLCDwBACAACAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//soxLADwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV",
})

local ICON_SIZE = 56

local icon = make("ImageButton", {
	Name = "Icon",
	Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
	Position = UDim2.new(0, 10, 0.5, -ICON_SIZE / 2),
	BackgroundColor3 = PANEL_COLOR,
	AutoButtonColor = false,
	Image = "",
	ScaleType = Enum.ScaleType.Crop,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, icon)
outline(icon)

local iconImage = loadIconImage()
if iconImage then
	icon.Image = iconImage
else
	make("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "☰",
		TextColor3 = WHITE,
		TextSize = 28,
		Font = Enum.Font.GothamBold,
	}, icon)
end

local panel = make("Frame", {
	Name = "Panel",
	Size = UDim2.fromOffset(360, 440),
	Position = UDim2.fromOffset(72, 100),
	BackgroundColor3 = PANEL_COLOR,
	Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, panel)
outline(panel, 3)

local panelTitle = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	Text = "OSCAR'S COOL PANEL",
	TextColor3 = WHITE,
	TextSize = 16,
	Font = Enum.Font.GothamBold,
}, panel)

local PANEL_WIDTH, PANEL_HEIGHT = 360, 440

local panelMoved = false

local function placePanel()
	if panelMoved then return end
	local screen = gui.AbsoluteSize
	local iconPos = icon.AbsolutePosition
	local x = iconPos.X + ICON_SIZE + 8
	if x + PANEL_WIDTH > screen.X then
		x = iconPos.X - PANEL_WIDTH - 8
	end
	local y = iconPos.Y + ICON_SIZE / 2 - PANEL_HEIGHT / 2
	x = math.clamp(x, 0, math.max(0, screen.X - PANEL_WIDTH))
	y = math.clamp(y, 0, math.max(0, screen.Y - PANEL_HEIGHT))
	panel.Position = UDim2.fromOffset(x, y)
end

local dragging = false
local dragMoved = false
local dragStart, dragStartPos

listen(icon.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragMoved = false
		dragStart = input.Position
		dragStartPos = icon.Position
	end
end)

listen(UserInputService.InputChanged, function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local delta = input.Position - dragStart
	if not dragMoved and delta.Magnitude < 6 then return end
	dragMoved = true
	panelMoved = false
	local screen = gui.AbsoluteSize
	local x = math.clamp(dragStartPos.X.Offset + delta.X, 0, math.max(0, screen.X - ICON_SIZE))
	local y = math.clamp(dragStartPos.Y.Offset + delta.Y, 0, math.max(0, screen.Y - ICON_SIZE))
	icon.Position = UDim2.new(dragStartPos.X.Scale, x, dragStartPos.Y.Scale, y)
	if panel.Visible then
		placePanel()
	end
end)

listen(UserInputService.InputEnded, function(input)
	if not dragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	dragging = false
	if not dragMoved then
		panel.Visible = not panel.Visible
		if panel.Visible then
			placePanel()
		end
	end
end)

-- PC support: drag the panel by its title bar, and RightShift (or Insert) opens / closes it
do
	local panelDragging = false
	local panelDragStart, panelDragOrigin

	listen(panelTitle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			panelDragging = true
			panelDragStart = input.Position
			panelDragOrigin = panel.AbsolutePosition
		end
	end)

	listen(UserInputService.InputChanged, function(input)
		if not panelDragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - panelDragStart
		local screen = gui.AbsoluteSize
		local x = math.clamp(panelDragOrigin.X + delta.X, 0, math.max(0, screen.X - PANEL_WIDTH))
		local y = math.clamp(panelDragOrigin.Y + delta.Y, 0, math.max(0, screen.Y - PANEL_HEIGHT))
		panelMoved = true
		panel.Position = UDim2.fromOffset(x, y)
	end)

	listen(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			panelDragging = false
		end
	end)

	listen(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
			panel.Visible = not panel.Visible
			if panel.Visible then
				placePanel()
			end
		end
	end)
end


local DELETE_MP3_BASE64 = table.concat({
	"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",
	"egYRQ8CK9NOKOEUQDNgISiukCbidKCayogCwGoIMiRaiu7bC5iLWRphMJWBiDsORwieakS2cZd6VN293DRBkPmflYxiSMtqIszO78nPrQj5NnrPtwQq1pS5pST52gj03nWdlbcg8qovpemoMAyDYZt4YsOAQU6VlhHgaDO4RJEPXmaZkZZYt",
	"gwpSosVObCY+MJY4FEmSEnsVgp/SJg0A0b1gnvnCH+wAb+3/RbSqe9v/+/j9//s4xN6DCpl1TmyMTZlUialNpgxgFiEjtrMYKeZHHtu8AEdo4777K9JgGGIDVgDTTiSRYI+IjDEgEseoDI1Ip9W8EMDL4cd31kaCx6QQFM/KgiSDnYDVgvSs",
	"QDYV7ea7fKtuCNgzrRLGsYwGOjA2b46mJ17hjZNRICsA6hMKguE5INAplXQ1foBUJX0TLQnklwgMgjiqSOYwIaGvVhoIhCnfXJjM1+E1TkyBNEFRn41ozTLgvapLmw+MRjCQVFUlgZKsUocLEXLcIUGiRpykgJq1QESFlbm0//s4xOsADu2F",
	"a6SNOzlHm2lJgwkw7D26WyqFCzav0dx3BNbC4gGFwqUvQjEB9C+Kk5FGtqFdMaoRyhOY7UyoFtUgVihgToYkCBiaexs6xvJqhq0pVfUm+/DU1KMFmGmQJMFfFx7CaiJYMRLbH4U2InIqDEn9tjTNj5I7JLKaK/hxQb9////H/NbV/BUaO2fT",
	"48bPNLR//nm3Fo81EizOx1SxskltuVNOJU8U1zRcZj2thr/VZm+gICv9KgKWyw/LUKAgJe1qqX/7WCoy/SOr1WCgJKTCrQEv//s4xOeAC/yDSsy8YcmUHKs1hgw04f/rAI/+oK4thw+qFZvqwCOZH///kyhgYIPZYrA0NjEhqg6yORkasqxy",
	"MvkqGTWf///YZMstIy7LJZYZf/982ad43Nypo4tiyiyjzCjQI8gHCQYDPVvmjSruNz//7lMFDAw5HZymKGDAwVVQZ9KIlOpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqq//s4xOaBCsxlRMwwxQGTlKQFh4xxqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xOoDi/mM4AMYa8l6rc1EMwvJqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
})

local SPAWN_MP3_BASE64 = table.concat({
	"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",
	"o+lUrn24MZFPiNKwLoydckCJUmQtFI5dpdr3i0djB5rToUlkHVPs7355nU5qFrMYlW5rMYx5LXTiyBwgl0hOsE2UE+AhAyaEICQFLoVWAsGjoIiVJEs1caIiYeHSoiWARjwkeyJJgiiIr1PKqDqBQ89cNEZ7TEOWrct1jnoJfBXr1rBXqPSw",
	"//soxPCDiwyXDiewaUlSkiHBhg0odBWAAAX7QoUONJ7UopNRSBJVbX+sDEZarnoYMBAQpW+Z//MYKJ6ZXqFLKVpv/5SlNzPUqgLUMY2YxgxjGq1FARIUql/8MKf/oBOrSlKX1bM4V+Z8KYIiVh//9TUVFQ0eHQqJhuQJs9VTdjlRF//1RFQ9",
	"nY5f5bDI71mCx0ef/5q1sqORrJUMmWWy5kdkuZGrWo5MoYKCDA5ZQQMEGBxM//soxOmDB5A3FkewZUGRG+GJh4y5QU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//soxOiDCXBDEEekzgEmBmHI9iQIqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"//soxO2CCml85qSYTpEjLdCYcA+Aqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//soxLADwAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
})

local DOOM_TICK_MP3_BASE64 = table.concat({
	"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",
	"87DUm8/mX+ma553nxhFURRijUqSi3ygmBgiP4CALcANQ+hdKJoom2JhoCTKp//soxLYASKUlPUEkTMEHnqcgIwl47AVrvHhdgUbsruuQtAw79Tciri7/MOZ3V5TL1OTYxqZNxcpjhTsl0ay7adndDnoLKFM1ADDjJJIW+AHbQflV0gwuUTpD",
	"UVfYwfSUsIDMOvg4UI/QmCGIJz6XBaDmqgFO9XUf7n5edYp7SLkzEuG839AIh0c2o2t6lABt2EgIq7ADvqKXXEMtRrbsjbA/B0Lg4/Nu7CZxRpGMw4Y9uIDx//soxMIACJjbPaEYcIEXHGcoFImgExx81KBY9UcTHdl2p7MjJor6U1QrDCVF",
	"Sxk8TQYU7UXVBDAuZJKlsAHPNeQgSHhT8DzxM9XIwpoSBpbsLx33c8ckqNIYW154gfB1qZgqIuobli5D8zhQrSiQv37CIeZNqilZVT0W40JwOJEpBX0AfsILJpjP2zPLqLfkjlG3BblD0aTMU5kwj5+NDy0TelQMzw3d9109jDfe+b4EZ5N9",
	"//soxMwACMjnP6EwcCEYo+doIwmhLkoutw47EKEJ06aSo70KAgGCBiYB9iSMwnTkaSDIJ7cWFgSuqzkJgiirJEkFg01LHwVlQ7UWNOg4sSRRbVViMwgSHbjHAJJXRUBIyF6AGkEQCGgoEzce/F//d/1JhCA8vBEDqlqxye4yY0suXKomNtsW",
	"pQCFfw6sNSoUvPjEwqgJeGIo47EgpJ6rZyiSTqBoOiVxZ4KlsRPUDV0RFQ1///soxNUACLzrPaEkcEEZnCd0JJVgKqPafWCsFYdqTEFNRTMuMTAwqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//soxN4ACMjbQaCgbeEYmmd0Yo+Aqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"//soxOcCCaylJqSYdoErlGLAwZnoqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
})

local DOOM_BELL_MP3_BASE64 = table.concat({
	"SUQzBAAAAAABAFRYWFgAAAASAAADbWFqb3JfYnJhbmQAZGFzaABUWFhYAAAAEQAAA21pbm9yX3ZlcnNpb24AMABUWFhYAAAAHAAAA2NvbXBhdGlibGVfYnJhbmRzAGlzbzZtcDQxAFRTU0UAAAAPAAADTGF2ZjYwLjE2LjEwMAAAAAAAAAAA",
	"AAAA//s4wAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAACpAACPcAAEBwoMDxITFhkbHiEiJSgrLTAzNDc6PD9CQ0ZJTE5RVFVYW11gY2RnamxvcnV2eXx+gYSGiYyNkJOWmJuen6Klp6qtrrG0trm8v8DDxsjLzs/S1dfa3eDh5Ofp7O/w",
	"8/b4+/4AAAAATGF2YzYwLjMxAAAAAAAAAAAAAAAAJAaBAAAAAAAAj3C6jhTwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//s4xAADwAABpAAAACAAADSAAAAETEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//s4xGGDwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//s4xJ4DwAABpAAAACAAADSAAAAEVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//s4xJ4DwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVV//s4xJ4DwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//s4xJ4DwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
	"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//s4xJ4DwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUCEI8bnl1GOOkY",
	"EF+EjFEFemcrDl4mMKqyuUK4qg4BIHYSe663HZmpNvCyiDi1BEMcmh4NCwEgBo5sDJCGY0bSQKQbqqdQMu+YxBmJGocRAmS2cKocd22voIw4cYkQIMGALqEjQW8vHEEGAhiw6wCQheCHRUJrGocj//s4xJ4DwAABpAAAACAAADSAAAAEQXvV",
	"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",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xOSByWwwdg5vCEE+BUIV/3WEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xJ4DwAAAAAAAACAAADSAAAAEqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xJ4DwAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqq//s4xJ4DwAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xJ4DwAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xJ4DwAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpMQU1FMy4xMDCq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xJ4DwAABpAAAACAAADSAAAAEqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//s4xJ4DwAABpAAAACAAADSAAAAEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	"qqqq",
})

local doomStop = nil

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local function playEmbeddedSound(fileName, encoded, parent, volume)
	local file = loadEmbeddedImage(fileName, encoded)
	if not file then return nil end
	local sound = Instance.new("Sound")
	sound.SoundId = file
	sound.Volume = volume or 1
	sound.Parent = parent
	sound:Play()
	return sound
end

-- Ghost mode: only the Oscar cube (the icon) turns invisible, it can still be clicked
local Ghost = { on = false, saved = {}, sound = nil }
local GHOST_PROPS = {
	"BackgroundTransparency", "TextTransparency", "TextStrokeTransparency",
	"ImageTransparency", "Transparency",
}

local function setGhost(on)
	Ghost.on = on
	if on then
		for _, object in ipairs({ icon, table.unpack(icon:GetDescendants()) }) do
			if not Ghost.saved[object] then
				local original = {}
				for _, prop in ipairs(GHOST_PROPS) do
					local ok, value = pcall(function()
						return object[prop]
					end)
					if ok and type(value) == "number" then
						original[prop] = value
						pcall(function()
							object[prop] = 1
						end)
					end
				end
				if next(original) ~= nil then
					Ghost.saved[object] = original
				end
			end
		end
		pcall(function()
			if Ghost.sound and Ghost.sound.Parent then
				Ghost.sound:Play()
			else
				Ghost.sound = playEmbeddedSound("OscarsCoolPanelGhost.mp3", GHOST_MP3_BASE64, gui, 1)
			end
		end)
	else
		for object, original in pairs(Ghost.saved) do
			for prop, value in pairs(original) do
				pcall(function()
					object[prop] = value
				end)
			end
		end
		table.clear(Ghost.saved)
	end
end

-- Delete GUI: asks first, then plays the sound and removes the whole menu
local confirmOverlay = make("Frame", {
	Name = "DeleteConfirm",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	BackgroundTransparency = 0.05,
	Visible = false,
	Active = true,
	ZIndex = 50,
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, confirmOverlay)

make("TextLabel", {
	Size = UDim2.new(1, -30, 0, 110),
	Position = UDim2.fromOffset(15, 70),
	BackgroundTransparency = 1,
	Text = "WARNING\nThis deletes Oscar's Cool Panel completely. Everything stops and you have to run the script again to get it back.\nAre you sure?",
	TextColor3 = WHITE,
	TextSize = 15,
	TextWrapped = true,
	Font = Enum.Font.GothamBold,
	ZIndex = 51,
}, confirmOverlay)

local confirmDelete = make("TextButton", {
	Size = UDim2.new(0.5, -20, 0, 40),
	Position = UDim2.new(0, 15, 0, 200),
	BackgroundColor3 = Color3.fromRGB(230, 90, 90),
	Text = "DELETE GUI",
	TextColor3 = BLACK,
	TextSize = 15,
	Font = Enum.Font.GothamBold,
	ZIndex = 51,
}, confirmOverlay)
outline(confirmDelete)

local cancelDelete = make("TextButton", {
	Size = UDim2.new(0.5, -20, 0, 40),
	Position = UDim2.new(0.5, 5, 0, 200),
	BackgroundColor3 = WHITE,
	Text = "CANCEL",
	TextColor3 = BLACK,
	TextSize = 15,
	Font = Enum.Font.GothamBold,
	ZIndex = 51,
}, confirmOverlay)
outline(cancelDelete)

listen(cancelDelete.MouseButton1Click, function()
	confirmOverlay.Visible = false
end)

listen(confirmDelete.MouseButton1Click, function()
	confirmOverlay.Visible = false
	local sound
	pcall(function()
		sound = playEmbeddedSound("OscarsCoolPanelDelete.mp3", DELETE_MP3_BASE64, SoundService, 1)
	end)
	if sound then
		Debris:AddItem(sound, 10)
	end
	if _G.SandboxMenuCleanup then
		pcall(_G.SandboxMenuCleanup)
	else
		gui:Destroy()
	end
end)

local TAB_NAMES = { "Settings", "Main Chapters", "Subchapters", "Stages", "Custom Bosses/Stages", "Misc" }
local TABS_PER_ROW = 3
local pages = {}
local tabButtons = {}

local function showTab(name)
	for tabName, page in pages do
		page.Visible = tabName == name
	end
	for tabName, button in tabButtons do
		button.BackgroundColor3 = tabName == name and WHITE or GRAY
	end
end

for index, tabName in ipairs(TAB_NAMES) do
	local button = make("TextButton", {
		Size = UDim2.new(1 / TABS_PER_ROW, -4, 0, 28),
		Position = UDim2.new(((index - 1) % TABS_PER_ROW) / TABS_PER_ROW, 2, 0, 34 + math.floor((index - 1) / TABS_PER_ROW) * 30),
		BackgroundColor3 = GRAY,
		Text = tabName,
		TextColor3 = BLACK,
		TextSize = 12,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
	}, panel)
	outline(button)
	tabButtons[tabName] = button

	local page = make("ScrollingFrame", {
		Size = UDim2.new(1, -16, 1, -106),
		Position = UDim2.fromOffset(8, 98),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.25,
		ScrollingEnabled = true,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Active = true,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, panel)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
	}, page)
	pages[tabName] = page

	listen(button.MouseButton1Click, function()
		showTab(tabName)
	end)
end

local function addHeader(page, text)
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, page)
end

local function addGrayRow(parent, text)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, SETTING_HEIGHT),
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, parent)
	outline(row)
	make("TextLabel", {
		Size = UDim2.new(1, -96, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = BLACK,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
	}, row)
	return row
end

local function addSwitch(row, isOn, onChange)
	local button = make("TextButton", {
		Size = UDim2.fromOffset(56, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		TextColor3 = BLACK,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Text = "",
	}, row)
	outline(button)

	local function refresh()
		local on = isOn()
		button.Text = on and "ON" or "OFF"
		button.BackgroundColor3 = on and ON_COLOR or WHITE
	end

	listen(button.MouseButton1Click, function()
		onChange(not isOn())
		refresh()
	end)
	refresh()
	return refresh
end

local function addNumberBox(row, initialText, onCommit)
	local box = make("TextBox", {
		Size = UDim2.fromOffset(80, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		TextSize = 16,
		Font = Enum.Font.GothamBold,
		Text = initialText,
		ClearTextOnFocus = false,
	}, row)
	outline(box)
	listen(box.FocusLost, function()
		onCommit(box)
	end)
	return box
end

local OPTION_ROWS = {
	terminator   = { "Replace Terminator with Paintmaster", "swapTerminator" },
	bucketTagger = { "Replace Bucket Tagger / Treasure Seller with Battler", "replaceTaggers" },
	patrol       = { "Remove Patrol", "removePatrol" },
	deleter      = { "Remove Deleter", "removeDeleter" },
	bloodhorn    = { "Remove Bloodhorn", "removeBloodhorn" },
	noSupportBosses = { "Disable the 3 support bosses", "noSupportBosses" },
}

local function addChapterRow(page, chapter)
	local state = getState(chapter)

	local function labelText()
		return chapter.name
	end

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, page)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, container)

	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = WHITE,
		LayoutOrder = 1,
	}, container)
	outline(header, 3)

	-- special rows (flag background + small grey subtitle), used by FOR AMERICA!!!!
	local flagImage
	if chapter.flag then
		local asset = getFlagAsset()
		if asset then
			flagImage = make("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = asset,
				ImageRectOffset = Vector2.new(0, 22),
				ImageRectSize = Vector2.new(310, 38),
				ZIndex = 0,
			}, header)
		end
	end
	local hasSubtitle = chapter.subtitle ~= nil

	local nameButton = make("TextButton", {
		Size = UDim2.new(1, -44, hasSubtitle and 0.62 or 1, 0),
		BackgroundTransparency = 1,
		Text = labelText(),
		TextColor3 = flagImage and WHITE or BLACK,
		TextStrokeTransparency = flagImage and 0 or 1,
		TextStrokeColor3 = BLACK,
		TextSize = chapter.nameSize or 18,
		TextWrapped = chapter.nameSize ~= nil,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.GothamBold,
	}, header)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, nameButton)

	if hasSubtitle then
		make("TextLabel", {
			Size = UDim2.new(1, -54, 0.38, 0),
			Position = UDim2.new(0, 10, 0.6, 0),
			BackgroundTransparency = 1,
			Text = chapter.subtitle,
			TextColor3 = flagImage and Color3.fromRGB(205, 205, 205) or Color3.fromRGB(110, 110, 110),
			TextStrokeTransparency = flagImage and 0.3 or 1,
			TextStrokeColor3 = BLACK,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
		}, header)
	end

	local refresh
	local refreshTumored
	local strengthBox
	local refreshOptions = {}

	do
		local drawer = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			LayoutOrder = 2,
		}, container)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)

		if not chapter.fixedForms then
			local tumoredRow = addGrayRow(drawer, "Tumored cycle")
			refreshTumored = addSwitch(tumoredRow, function()
				return state.tumoredOn
			end, function(value)
				setChapterTumored(chapter, value)
			end)
		end

		if chapter.boss and not chapter.noBossless then
			table.insert(refreshOptions, addSwitch(addGrayRow(drawer, "Bossless"), function()
				return state.opts.bossless
			end, function(value)
				state.opts.bossless = value
			end))
		end

		local strengthRow = addGrayRow(drawer, "Enemy Strength")
		strengthBox = addNumberBox(strengthRow, "0", function(box)
			local number = tonumber(box.Text)
			if number and number > 0 then
				state.opts.strength = number
			else
				state.opts.strength = nil
			end
			refresh()
		end)

		for _, optionName in ipairs(chapter.options or {}) do
			local def = OPTION_ROWS[optionName]
			if def then
				local key = def[2]
				table.insert(refreshOptions, addSwitch(addGrayRow(drawer, def[1]), function()
					return state.opts[key]
				end, function(value)
					state.opts[key] = value
				end))
			end
		end

		if chapter.credits then
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = chapter.credits,
				TextColor3 = WHITE,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Gotham,
				LayoutOrder = nextOrder(),
			}, drawer)
		end

		if chapter.pelican then
			local pelicanRefreshers = {}

			local function addPelicanSwitch(label, feature, other)
				table.insert(pelicanRefreshers, addSwitch(addGrayRow(drawer, label), function()
					return feature.on
				end, function(value)
					if value and other.on then
						other.set(false)
					end
					feature.set(value)
					for _, refreshPelican in pelicanRefreshers do
						refreshPelican()
					end
				end))
			end

			addPelicanSwitch("Benjamins pelican (with peons)", pelicanScripts.benjamins, pelicanScripts.israel)
			addPelicanSwitch("Israel pelican (no peons)", pelicanScripts.israel, pelicanScripts.benjamins)

			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Text = "Credits: Benjamins and Israel pelican made by Gerald Broflovski",
				TextColor3 = WHITE,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Gotham,
				LayoutOrder = nextOrder(),
			}, drawer)
		end

		local chevron = make("TextButton", {
			Size = UDim2.new(0, 44, 1, 0),
			Position = UDim2.new(1, -44, 0, 0),
			BackgroundTransparency = 1,
			Text = ">",
			TextColor3 = flagImage and WHITE or BLACK,
			TextStrokeTransparency = flagImage and 0 or 1,
			TextStrokeColor3 = BLACK,
			TextSize = 24,
			Font = Enum.Font.GothamBold,
		}, header)
		listen(chevron.MouseButton1Click, function()
			drawer.Visible = not drawer.Visible
			chevron.Text = drawer.Visible and "v" or ">"
		end)
	end

	refresh = function()
		if flagImage then
			-- on = the flag fades so the green shows through
			flagImage.ImageTransparency = state.on and 0.6 or 0
		end
		if state.on then
			header.BackgroundColor3 = ON_COLOR
		elseif state.tumoredOn then
			header.BackgroundColor3 = TUMORED_COLOR
		else
			header.BackgroundColor3 = WHITE
		end
		nameButton.Text = labelText()
		if refreshTumored then
			refreshTumored()
		end
		for _, refreshOption in refreshOptions do
			refreshOption()
		end
		if strengthBox then
			strengthBox.Text = state.opts.strength and tostring(state.opts.strength) or "0"
		end
	end
	table.insert(state.listeners, refresh)

	listen(nameButton.MouseButton1Click, function()
		setChapter(chapter, not state.on)
	end)
end

local function addToggleCogRow(page, title, isOn, onChange)
	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, page)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, container)

	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = WHITE,
		LayoutOrder = 1,
	}, container)
	outline(header, 3)

	local nameButton = make("TextButton", {
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = BLACK,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
	}, header)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, nameButton)

	local function refresh()
		header.BackgroundColor3 = isOn() and ON_COLOR or WHITE
	end
	refresh()

	listen(nameButton.MouseButton1Click, function()
		onChange(not isOn())
		refresh()
	end)

	local drawer = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
	}, container)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)

	local chevron = make("TextButton", {
		Size = UDim2.new(0, 44, 1, 0),
		Position = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Text = ">",
		TextColor3 = BLACK,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
	}, header)
	listen(chevron.MouseButton1Click, function()
		drawer.Visible = not drawer.Visible
		chevron.Text = drawer.Visible and "v" or ">"
	end)

	return drawer, header, refresh
end

-- every section is built on its own, so one failing section can never take the whole menu down
-- Accessory paster: pasted accessory / clothing / bundle IDs are stored here, saved inside the code,
-- and put on the chosen battler (or all battlers) when the code is loaded.
Custom.accStore = {}
-- Body colours applied from the Avatar Applier: { groups = { Head = true, ... }, color = { r, g, b }, unitId = 0, team = 2 }
-- They are saved in / loaded from the Avatar Applier code, and the body picker reads them to show the colours.
Custom.bodyColorStore = {}
Custom.BODY_GROUP_ORDER = { "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }
Custom.ACC_GROUP = "paster"
Custom.TEAM_NAMES = { [0] = "Enemies", [1] = "Units", [2] = "Both teams" }

function Custom.describeAccStore()
	if #Custom.accStore == 0 then
		return "Nothing stored."
	end
	local lines = {}
	for index, entry in ipairs(Custom.accStore) do
		lines[#lines + 1] = string.format("%d. %s%d  ->  %s, %s", index, entry.bundle and "bundle " or "", entry.id,
			entry.unitId > 0 and ("battler ID " .. entry.unitId) or "all battlers", Custom.TEAM_NAMES[entry.team] or "?")
	end
	return table.concat(lines, "\n")
end

-- puts everything stored on the battlers (removes what the paster added before, so loading twice never doubles up)
Custom.outfitReplace = true      -- Avatar Applier: take off the old accessories before the outfit goes on
Custom.slotOutfitReplace = true  -- Custom Spawner: same for the outfit of a spawned battler

function Custom.applyAccStore(onStatus)
	Avatar.removeGroup(Custom.ACC_GROUP)
	if Custom.outfitReplace then
		local done = {}
		for _, entry in ipairs(Custom.accStore) do
			local key = entry.unitId .. "," .. entry.team
			if not done[key] then
				done[key] = true
				Avatar.addWipe(entry.unitId, entry.team, Custom.ACC_GROUP)
			end
		end
	end
	local total = #Custom.accStore
	if total == 0 then
		if onStatus then onStatus("No accessories stored, nothing to put on.") end
		return
	end
	local jobs, finished, failed = 0, 0, 0
	for _, entry in ipairs(Custom.accStore) do
		jobs += (entry.team == 2) and 2 or 1
	end
	local function done(ok)
		finished += 1
		if not ok then failed += 1 end
		if finished == jobs and onStatus then
			onStatus("Put " .. tostring(total) .. " stored item" .. (total == 1 and "" or "s") .. " on the battlers"
				.. (failed > 0 and (" (" .. tostring(failed) .. " could not be loaded)") or "") .. ".")
		end
	end
	for _, entry in ipairs(Custom.accStore) do
		if entry.team == 0 or entry.team == 2 then
			Avatar.addAccessory(entry.id, entry.unitId, false, done, entry.bundle, Custom.ACC_GROUP)
		end
		if entry.team == 1 or entry.team == 2 then
			Avatar.addAccessory(entry.id, entry.unitId, true, done, entry.bundle, Custom.ACC_GROUP)
		end
	end
end

-- Scrolling for every tab (Settings, Chapters, Subchapters, Misc ...): mouse wheel on PC,
-- finger / mouse drag on the page on mobile (works even when you start on top of a button).
do
	-- make the scrollable area always as long as the content (+ extra room at the bottom),
	-- so nothing at the end of Misc is cut off
	for _, page in pairs(pages) do
		local layout = page:FindFirstChildOfClass("UIListLayout")
		if layout then
			local function resize()
				page.AutomaticCanvasSize = Enum.AutomaticSize.None
				page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 120)
			end
			resize()
			listen(layout:GetPropertyChangedSignal("AbsoluteContentSize"), resize)
		end
	end

	local function activePage()
		for _, page in pairs(pages) do
			if page.Visible then return page end
		end
		return nil
	end
	local function inside(page, position)
		local p, size = page.AbsolutePosition, page.AbsoluteSize
		return position.X >= p.X and position.X <= p.X + size.X and position.Y >= p.Y and position.Y <= p.Y + size.Y
	end
	local function clampScroll(page, y)
		local maxY = math.max(0, math.max(page.AbsoluteCanvasSize.Y, page.CanvasSize.Y.Offset) - page.AbsoluteSize.Y)
		return math.clamp(y, 0, maxY)
	end

	listen(UserInputService.InputChanged, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		if not panel.Visible then return end
		local page = activePage()
		if not page then return end
		local mouse = UserInputService:GetMouseLocation()
		local inset = game:GetService("GuiService"):GetGuiInset()
		local position = Vector2.new(mouse.X, mouse.Y - (gui.IgnoreGuiInset and inset.Y or 0))
		if inside(page, position) or inside(page, mouse) then
			page.CanvasPosition = Vector2.new(0, clampScroll(page, page.CanvasPosition.Y - input.Position.Z * 60))
		end
	end)

	local touchPage, touchStart, touchCanvas, touchActive
	listen(UserInputService.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not panel.Visible then return end
		local page = activePage()
		if page and inside(page, Vector2.new(input.Position.X, input.Position.Y)) then
			touchPage, touchStart, touchCanvas, touchActive = page, input.Position, page.CanvasPosition.Y, false
		end
	end)
	listen(UserInputService.InputChanged, function(input)
		if not touchPage then return end
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local delta = input.Position.Y - touchStart.Y
		if not touchActive and math.abs(delta) < 10 then return end
		touchActive = true
		touchPage.CanvasPosition = Vector2.new(0, clampScroll(touchPage, touchCanvas - delta))
	end)
	listen(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			touchPage = nil
		end
	end)
end

local function safeBuild(name, build)
	local ok, err = pcall(build)
	if not ok then
		warn("Oscar's Cool Panel: '" .. name .. "' failed to build: " .. tostring(err))
	end
end

showTab("Main Chapters")
safeBuild("Settings", function()
	local page = pages["Settings"]

	local function addSetting(text, get, set)
		addSwitch(addGrayRow(page, text), get, set)
	end

	addNumberBox(addGrayRow(page, "Unit Limit (0 = stage default)"), "0", function(box)
		local number = tonumber(box.Text)
		if number and number > 0 then
			UnitLimitOverride = math.floor(number)
		else
			UnitLimitOverride = nil
		end
		box.Text = tostring(UnitLimitOverride or 0)
	end)
	addSetting("Delay Enemy Cycle", function() return DelayEnemyCycle end, function(value) DelayEnemyCycle = value end)
	addSetting("Enable Switch Teams at Start", function() return SwitchTeamsAtStart end, function(value) SwitchTeamsAtStart = value end)
	addSetting("Ghost Mode", function() return Ghost.on end, setGhost)

	local deleteRow = addGrayRow(page, "Delete GUI")
	local deleteButton = make("TextButton", {
		Size = UDim2.fromOffset(56, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(230, 90, 90),
		Text = "DELETE",
		TextColor3 = BLACK,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
	}, deleteRow)
	outline(deleteButton)
	listen(deleteButton.MouseButton1Click, function()
		confirmOverlay.Visible = true
	end)

	addNumberBox(addGrayRow(page, "Spawn Rate"), tostring(SpawnRate), function(box)
		local number = tonumber(box.Text)
		if number and number > 0 then
			SpawnRate = number
		end
		box.Text = tostring(SpawnRate)
	end)

	local doomOk, doomErr = pcall(function()
	-- Timer of DOOM: countdown (HH:MM:SS), ticking while it runs; at 0 the bell plays and enemy 98 (form B) spawns every second
	local doom = { on = false, seconds = 600, session = 0, sounds = {} }

	local doomLabel = make("TextLabel", {
		Name = "TimerOfDoom",
		Size = UDim2.fromOffset(300, 60),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 56),
		BackgroundTransparency = 1,
		Text = "00:10:00",
		TextColor3 = Color3.fromRGB(205, 25, 25),
		TextSize = 52,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(40, 0, 0),
		Font = Enum.Font.Creepster,
		Visible = false,
		Active = false,
		ZIndex = 10,
	}, gui)

	local function formatDoom(total)
		total = math.max(0, math.floor(total))
		return string.format("%02d:%02d:%02d", math.floor(total / 3600), math.floor(total / 60) % 60, total % 60)
	end

	local function stopDoomSounds()
		for _, sound in doom.sounds do
			pcall(function()
				sound:Stop()
				sound:Destroy()
			end)
		end
		table.clear(doom.sounds)
	end

	local function stopDoom()
		doom.on = false
		doom.session += 1
		stopDoomSounds()
		doomLabel.Visible = false
	end
	doomStop = stopDoom

	local function startDoom()
		stopDoom()
		doom.on = true
		local mySession = doom.session
		local endTime = os.clock() + doom.seconds

		doomLabel.Text = formatDoom(doom.seconds)
		doomLabel.Visible = true

		task.spawn(function()
			local tick = playEmbeddedSound("OscarsCoolPanelDoomTick.mp3", DOOM_TICK_MP3_BASE64, SoundService, 1)
			if tick then
				tick.Looped = true
				table.insert(doom.sounds, tick)
			end

			while doom.on and doom.session == mySession do
				local remaining = endTime - os.clock()
				if remaining <= 0 then
					break
				end
				doomLabel.Text = formatDoom(math.ceil(remaining))
				task.wait(0.1)
			end
			if not (doom.on and doom.session == mySession) then return end

			-- time is up
			doomLabel.Text = formatDoom(0)
			stopDoomSounds()
			local bell = playEmbeddedSound("OscarsCoolPanelDoomBell.mp3", DOOM_BELL_MP3_BASE64, SoundService, 1)
			if bell then
				table.insert(doom.sounds, bell)
			end

			while doom.on and doom.session == mySession do
				if getRefs() and checkBasesValid() then
					task.spawn(function()
						pcall(function()
							SandboxSpawn:InvokeServer("Enemy", 98, "B", Magnification, {})
						end)
					end)
				end
				task.wait(1)
			end
		end)
	end

	local doomDrawer = addToggleCogRow(page, "Timer of DOOM", function()
		return doom.on
	end, function(value)
		if value then
			startDoom()
		else
			stopDoom()
		end
	end)

	addNumberBox(addGrayRow(doomDrawer, "Time (seconds, 600 = 10 min)"), tostring(doom.seconds), function(box)
		local number = tonumber(box.Text)
		if number and number > 0 then
			doom.seconds = math.floor(number)
		else
			doom.seconds = 600
		end
		box.Text = tostring(doom.seconds)
		if not doom.on then
			doomLabel.Text = formatDoom(doom.seconds)
		end
	end)

	end)
	if not doomOk then
		warn("Timer of DOOM failed to load:", doomErr)
	end

	local cannonDrawer = addToggleCogRow(page, "Auto Cannon", function()
		return cannon.on
	end, function(value)
		cannon.on = value
		applyCannonMode()
	end)

	local modeRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, SETTING_HEIGHT),
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, cannonDrawer)
	outline(modeRow)

	addNumberBox(addGrayRow(cannonDrawer, "Fire rate (cooldown, seconds)"), tostring(cannon.cooldown), function(box)
		local number = tonumber(box.Text)
		if number and number >= 0 then
			cannon.cooldown = number
		else
			cannon.cooldown = 45 -- blank or invalid goes back to the default
		end
		box.Text = tostring(cannon.cooldown)
	end)

	-- Visual timer: countdown shown on top of the game's cannon button, says FIRE! when it is ready
	local GuiService = game:GetService("GuiService")
	local timerLabel = make("TextLabel", {
		Name = "CannonTimer",
		Size = UDim2.fromOffset(160, 44),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 34,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = BLACK,
		Font = Enum.Font.GothamBlack,
		Visible = false,
		Active = false,
		ZIndex = 10,
	}, gui)

	local cannonGuiObject = nil
	local function findCannonGui()
		if cannonGuiObject and cannonGuiObject.Parent then
			return cannonGuiObject
		end
		cannonGuiObject = nil
		for _, object in ipairs(playerGui:GetDescendants()) do
			if (object:IsA("TextLabel") or object:IsA("TextButton")) and not object:IsDescendantOf(gui) then
				local text = string.upper(object.Text)
				if text == "FIRE!" or text == "FIRE" then
					cannonGuiObject = object
					break
				end
			end
		end
		return cannonGuiObject
	end

	task.spawn(function()
		local nextSearch = 0
		while not destroyed do
			task.wait(0.05)
			if not cannon.visualTimer then
				timerLabel.Visible = false
				continue
			end

			local remaining = math.max(0, cannon.readyAt - os.clock())
			if cannon.ready or remaining <= 0 then
				timerLabel.Text = "FIRE!"
				timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				timerLabel.Text = string.format("%.1f", remaining)
				timerLabel.TextColor3 = WHITE
			end

			-- sit on top of the cannon: use the game's cannon button if we can find it, else bottom right
			local target = nil
			if os.clock() >= nextSearch then
				nextSearch = os.clock() + 1
				target = findCannonGui()
			elseif cannonGuiObject and cannonGuiObject.Parent then
				target = cannonGuiObject
			end

			local screen = gui.AbsoluteSize
			if target and target:IsA("GuiObject") and target.AbsoluteSize.X > 0 then
				local topCenter = target.AbsolutePosition + Vector2.new(target.AbsoluteSize.X / 2, 0)
				local screenGui = target:FindFirstAncestorWhichIsA("ScreenGui")
				if screenGui and not screenGui.IgnoreGuiInset then
					topCenter += GuiService:GetGuiInset()
				end
				timerLabel.Position = UDim2.fromOffset(topCenter.X, topCenter.Y + 6)
			else
				timerLabel.Position = UDim2.fromOffset(screen.X - 100, screen.Y - 230)
			end
			timerLabel.Visible = true
		end
	end)

	addSwitch(addGrayRow(cannonDrawer, "Visual timer"), function()
		return cannon.visualTimer
	end, function(value)
		cannon.visualTimer = value
		if value then
			-- start counting from the current fire rate right away (35 -> shows 35, 5 -> shows 5)
			if cannon.ready then
				startCannonCooldown()
			end
		else
			timerLabel.Visible = false
		end
	end)

	local rangeRow = addGrayRow(cannonDrawer, "Range (length)")
	local rangeBox
	local noteHolder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, cannonDrawer)

	local noteImage = loadEmbeddedImage("OscarsCoolPanelNote.png", NOTE_PNG_BASE64)
	if noteImage then
		make("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = noteImage,
			ScaleType = Enum.ScaleType.Fit,
		}, noteHolder)
	else
		make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "1 length is technically 2 studs",
			TextColor3 = WHITE,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, noteHolder)
	end

	local modeButtons = {}
	local function refreshMode()
		for mode, button in modeButtons do
			button.BackgroundColor3 = cannon.mode == mode and ON_COLOR or WHITE
		end
		local hasRange = cannon.mode ~= "Liberty"
		rangeRow.Visible = hasRange
		noteHolder.Visible = hasRange
		if hasRange then
			rangeBox.Text = tostring(cannon.ranges[cannon.mode])
		end
	end

	for index, mode in ipairs({ "Cannon", "Liberty", "Slammer" }) do
		local button = make("TextButton", {
			Size = UDim2.new(1 / 3, -8, 0, 24),
			Position = UDim2.new((index - 1) / 3, 6, 0.5, -12),
			TextColor3 = BLACK,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = mode,
		}, modeRow)
		outline(button)
		modeButtons[mode] = button
		listen(button.MouseButton1Click, function()
			cannon.mode = mode
			applyCannonMode()
			refreshMode()
		end)
	end

	rangeBox = addNumberBox(rangeRow, tostring(cannon.ranges[cannon.mode]), function(box)
		local number = tonumber(box.Text)
		if number and number > 0 then
			cannon.ranges[cannon.mode] = number
		end
		box.Text = tostring(cannon.ranges[cannon.mode])
	end)

	refreshMode()
end)

safeBuild("Main Chapters", function()
	local page = pages["Main Chapters"]
	for _, category in ipairs(CATEGORIES) do
		addHeader(page, category.name)
		for _, chapter in ipairs(category.chapters) do
			addChapterRow(page, chapter)
		end
	end
end)

safeBuild("Subchapters", function()
	local page = pages["Subchapters"]
	for _, category in ipairs(SUBCHAPTERS) do
		addHeader(page, category.name)
		for _, chapter in ipairs(category.chapters) do
			addChapterRow(page, chapter)
		end
	end
end)

safeBuild("Stages", function()
	local page = pages["Stages"]
	for _, category in ipairs(STAGES) do
		addHeader(page, category.name)
		for _, chapter in ipairs(category.chapters) do
			addChapterRow(page, chapter)
		end
	end
end)

safeBuild("Custom Bosses/Stages", function()
	local page = pages["Custom Bosses/Stages"]
	for _, category in ipairs(CUSTOM_STAGES) do
		addHeader(page, category.name)
		if #category.chapters == 0 then
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "Nothing here yet.",
				TextColor3 = GRAY,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Gotham,
				LayoutOrder = nextOrder(),
			}, page)
		end
		for _, chapter in ipairs(category.chapters) do
			addChapterRow(page, chapter)
		end
	end
end)

-- Outcast / Blight + Crimson Skies enemy mutations (made by Gerald Broflovski), shown as a switch in the Avatar Applier.
-- Outcast and Blight units get your avatar, a glow, a health bar and twitching. Every other enemy grows crystals and shakes below 45% health.
local CrimsonSkies = { running = false }
do
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local LocalPlayer = player

	local IsRunning = false
	local Connections = {}
	local ProcessedNPCs = {}
	local FriendlyFolder, EnemyFolder
	local TargetUserId = LocalPlayer.UserId
	local loadedFor = nil

	local CrystalMeshId = "rbxassetid://1059108471"
	local PentagramTextureId = "rbxassetid://660232231"

	local AppearanceModel, HumanoidDescription

	local function LoadAvatarData()
		if AppearanceModel then return true end
		local Success, Model = pcall(function()
			return Players:GetCharacterAppearanceAsync(TargetUserId)
		end)
		if Success and Model then AppearanceModel = Model else warn("Could not load avatar for:", TargetUserId) return false end

		local DescSuccess, Desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(TargetUserId)
		end)
		if DescSuccess then HumanoidDescription = Desc end
		return true
	end

	-- OVERHEAD TITLE & HEALTH BAR
	local function SetupOverheadUI(NPC, Humanoid)
		local Head = NPC:FindFirstChild("Head")
		if not Head then return end

		local Billboard = Instance.new("BillboardGui")
		Billboard.Name = "OutcastBossUI"
		Billboard.Size = UDim2.new(0, 250, 0, 70)
		Billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		Billboard.AlwaysOnTop = true
		Billboard.Adornee = Head
		Billboard.Parent = Head

		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.Name = "TitleLabel"
		TitleLabel.Size = UDim2.new(1, 0, 0, 30)
		TitleLabel.Position = UDim2.new(0, 0, 0, 0)
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Font = Enum.Font.Creepster
		TitleLabel.Text = "EMBODIMENT OF AGONY"
		TitleLabel.TextColor3 = Color3.fromRGB(220, 20, 20)
		TitleLabel.TextSize = 22
		TitleLabel.TextStrokeTransparency = 0
		TitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		TitleLabel.Parent = Billboard

		local HealthBG = Instance.new("Frame")
		HealthBG.Name = "HealthBG"
		HealthBG.Size = UDim2.new(1, 0, 0, 18)
		HealthBG.Position = UDim2.new(0, 0, 0, 35)
		HealthBG.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
		HealthBG.BorderSizePixel = 0
		HealthBG.Parent = Billboard

		local BGCorner = Instance.new("UICorner")
		BGCorner.CornerRadius = UDim.new(0, 4)
		BGCorner.Parent = HealthBG

		local BGStroke = Instance.new("UIStroke")
		BGStroke.Color = Color3.fromRGB(15, 0, 0)
		BGStroke.Thickness = 1.5
		BGStroke.Parent = HealthBG

		local HealthFill = Instance.new("Frame")
		HealthFill.Name = "HealthFill"
		HealthFill.Size = UDim2.new(1, 0, 1, 0)
		HealthFill.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
		HealthFill.BorderSizePixel = 0
		HealthFill.Parent = HealthBG

		local FillCorner = Instance.new("UICorner")
		FillCorner.CornerRadius = UDim.new(0, 4)
		FillCorner.Parent = HealthFill

		local HealthText = Instance.new("TextLabel")
		HealthText.Name = "HealthText"
		HealthText.Size = UDim2.new(1, 0, 1, 0)
		HealthText.BackgroundTransparency = 1
		HealthText.Font = Enum.Font.Creepster
		HealthText.TextColor3 = Color3.fromRGB(255, 100, 100)
		HealthText.TextSize = 14
		HealthText.TextStrokeTransparency = 0.2
		HealthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		HealthText.Text = math.floor(Humanoid.Health) .. " / " .. math.floor(Humanoid.MaxHealth)
		HealthText.Parent = HealthBG

		local function UpdateHealth()
			local Percent = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
			HealthFill.Size = UDim2.new(Percent, 0, 1, 0)
			HealthText.Text = math.floor(Humanoid.Health) .. " / " .. math.floor(Humanoid.MaxHealth)
		end

		table.insert(Connections, Humanoid.HealthChanged:Connect(UpdateHealth))
		UpdateHealth()

		return Billboard
	end

	-- ATTACH SMALL-MEDIUM CRYSTALS FOR CRIMSON SKIES ENEMIES (Head, Right Arm, Left Leg)
	local function AttachEnemyLowHPCrystals(NPC)
		local DarkColorShades = {
			Color3.fromRGB(25, 25, 30),
			Color3.fromRGB(45, 10, 10),
			Color3.fromRGB(15, 15, 18),
			Color3.fromRGB(60, 5, 5),
			Color3.fromRGB(35, 35, 40)
		}

		local TargetParts = {
			"Head",
			"Right Arm",
			"RightUpperArm",
			"Left Leg",
			"LeftLowerLeg"
		}

		for _, PartName in ipairs(TargetParts) do
			local Part = NPC:FindFirstChild(PartName)
			if Part and Part:IsA("BasePart") then
				local CrystalCount = math.random(2, 4)

				for i = 1, CrystalCount do
					local Crystal = Instance.new("SpecialMesh")
					Crystal.Name = "EnemyCrystalMesh"
					Crystal.MeshType = Enum.MeshType.FileMesh
					Crystal.MeshId = CrystalMeshId

					-- Small to Medium sized crystals (0.4 to 0.9)
					local ScaleFactor = math.random(4, 9) / 10
					Crystal.Scale = Vector3.new(ScaleFactor, ScaleFactor * (math.random(10, 13)/10), ScaleFactor)

					local CrystalPart = Instance.new("Part")
					CrystalPart.Name = "EnemyMutationCrystal"
					CrystalPart.Size = Vector3.new(0.5, 0.5, 0.5)
					CrystalPart.Color = DarkColorShades[math.random(1, #DarkColorShades)]
					CrystalPart.Material = Enum.Material.Glass
					CrystalPart.CanCollide = false
					CrystalPart.Massless = true

					Crystal.Parent = CrystalPart

					local RandomOffset = Vector3.new(
						(math.random(-12, 12) / 10) * (Part.Size.X / 2),
						(math.random(-12, 12) / 10) * (Part.Size.Y / 2),
						(math.random(-12, 12) / 10) * (Part.Size.Z / 2)
					)
				
					local RandomRotation = CFrame.Angles(
						math.rad(math.random(-180, 180)),
						math.rad(math.random(-180, 180)),
						math.rad(math.random(-180, 180))
					)

					local Weld = Instance.new("Weld")
					Weld.Part0 = Part
					Weld.Part1 = CrystalPart
					Weld.C0 = CFrame.new(RandomOffset) * RandomRotation
					Weld.Parent = CrystalPart

					CrystalPart.Parent = NPC
				end
			end
		end
	end

	-- ATTACH FULL BLIGHT CRYSTALS FOR OUTCAST
	local function AttachBlightCrystals(NPC)
		local DarkColorShades = {
			Color3.fromRGB(25, 25, 30),
			Color3.fromRGB(45, 10, 10),
			Color3.fromRGB(15, 15, 18),
			Color3.fromRGB(60, 5, 5),
			Color3.fromRGB(35, 35, 40)
		}

		for _, Part in ipairs(NPC:GetChildren()) do
			if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" then
				local CrystalCount = math.random(3, 6)

				for i = 1, CrystalCount do
					local Crystal = Instance.new("SpecialMesh")
					Crystal.Name = "BlightCrystalMesh"
					Crystal.MeshType = Enum.MeshType.FileMesh
					Crystal.MeshId = CrystalMeshId

					local ScaleFactor = math.random(4, 12) / 10
					Crystal.Scale = Vector3.new(ScaleFactor, ScaleFactor * (math.random(10, 14)/10), ScaleFactor)

					local CrystalPart = Instance.new("Part")
					CrystalPart.Name = "BlightCrystal"
					CrystalPart.Size = Vector3.new(0.5, 0.5, 0.5)
					CrystalPart.Color = DarkColorShades[math.random(1, #DarkColorShades)]
					CrystalPart.Material = Enum.Material.Glass
					CrystalPart.CanCollide = false
					CrystalPart.Massless = true

					Crystal.Parent = CrystalPart

					local RandomOffset = Vector3.new(
						(math.random(-15, 15) / 10) * (Part.Size.X / 2),
						(math.random(-15, 15) / 10) * (Part.Size.Y / 2),
						(math.random(-15, 15) / 10) * (Part.Size.Z / 2)
					)
				
					local RandomRotation = CFrame.Angles(
						math.rad(math.random(-180, 180)),
						math.rad(math.random(-180, 180)),
						math.rad(math.random(-180, 180))
					)

					local Weld = Instance.new("Weld")
					Weld.Part0 = Part
					Weld.Part1 = CrystalPart
					Weld.C0 = CFrame.new(RandomOffset) * RandomRotation
					Weld.Parent = CrystalPart

					CrystalPart.Parent = NPC
				end
			end
		end
	end

	-- GREY AND WHITE GLOW
	local function AddGreyWhiteGlow(NPC)
		local OldHighlight = NPC:FindFirstChild("OutcastGlow")
		if OldHighlight then OldHighlight:Destroy() end

		local Highlight = Instance.new("Highlight")
		Highlight.Name = "OutcastGlow"
		Highlight.Adornee = NPC
		Highlight.FillColor = Color3.fromRGB(200, 200, 200)
		Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		Highlight.FillTransparency = 0.6
		Highlight.OutlineTransparency = 0.1
		Highlight.Parent = NPC

		task.spawn(function()
			while IsRunning and Highlight and Highlight.Parent do
				local TweenInfoData = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				local Tween1 = TweenService:Create(Highlight, TweenInfoData, {FillTransparency = 0.8, OutlineTransparency = 0.4})
				Tween1:Play()
				Tween1.Completed:Wait()
				if not IsRunning or not Highlight.Parent then break end
				local Tween2 = TweenService:Create(Highlight, TweenInfoData, {FillTransparency = 0.5, OutlineTransparency = 0.0})
				Tween2:Play()
				Tween2.Completed:Wait()
			end
		end)
	end

	-- BLIGHT BEAM SPECIAL MOVE
	local function ExecuteBlightBeam(NPC)
		local LeftArm = NPC:FindFirstChild("Left Arm") or NPC:FindFirstChild("LeftUpperArm")
		local Torso = NPC:FindFirstChild("Torso") or NPC:FindFirstChild("UpperTorso")
		if not LeftArm or not Torso then return end

		local LeftShoulder = Torso:FindFirstChild("Left Shoulder") or LeftArm:FindFirstChild("LeftShoulder")
		local OriginalC0 = LeftShoulder and LeftShoulder.C0

		if LeftShoulder then
			LeftShoulder.C0 = OriginalC0 * CFrame.Angles(math.rad(120), math.rad(0), math.rad(-20))
		end

		local PentagramPart = Instance.new("Part")
		PentagramPart.Name = "BlightBeamPentagram"
		PentagramPart.Size = Vector3.new(4, 0.05, 4)
		PentagramPart.Transparency = 1
		PentagramPart.CanCollide = false
		PentagramPart.Massless = true

		local SurfaceGui = Instance.new("SurfaceGui")
		SurfaceGui.Face = Enum.NormalId.Top
		SurfaceGui.AlwaysOnTop = true
		SurfaceGui.Parent = PentagramPart

		local Image = Instance.new("ImageLabel")
		Image.Size = UDim2.new(1, 0, 1, 0)
		Image.BackgroundTransparency = 1
		Image.Image = PentagramTextureId
		Image.ImageColor3 = Color3.fromRGB(255, 0, 0)
		Image.Parent = SurfaceGui

		local Weld = Instance.new("Weld")
		Weld.Part0 = LeftArm
		Weld.Part1 = PentagramPart
		Weld.C0 = CFrame.new(0, -1.8, 0) * CFrame.Angles(0, 0, math.rad(90))
		Weld.Parent = PentagramPart

		PentagramPart.Parent = NPC

		task.spawn(function()
			while PentagramPart and PentagramPart.Parent do
				Image.Rotation = (Image.Rotation + 5) % 360
				task.wait(0.03)
			end
		end)

		task.delay(3.5, function()
			if PentagramPart then PentagramPart:Destroy() end
			if LeftShoulder and OriginalC0 then
				LeftShoulder.C0 = OriginalC0
			end
		end)
	end

	-- GENERIC ENEMY LOW HP LOGIC (< 45%)
	local function StartGenericEnemyBehavior(NPC, Humanoid)
		local Mutated = false

		local function TriggerMutation()
			if Mutated then return end
			Mutated = true

			-- 1. Attach Crystals to Head, Right Arm, Left Leg
			AttachEnemyLowHPCrystals(NPC)

			-- 2. Make Limbs Shake
			task.spawn(function()
				local MotorJoints = {}
				for _, Descendant in ipairs(NPC:GetDescendants()) do
					if Descendant:IsA("Motor6D") and Descendant.Name ~= "RootJoint" then
						table.insert(MotorJoints, {Joint = Descendant, OriginalC0 = Descendant.C0})
					end
				end

				local ShakeConnection
				ShakeConnection = RunService.Heartbeat:Connect(function()
					if not IsRunning or not NPC or not NPC.Parent then
						if ShakeConnection then ShakeConnection:Disconnect() end
						return
					end

					for _, JointData in ipairs(MotorJoints) do
						if JointData.Joint and JointData.Joint.Parent then
							local ShakeOffset = CFrame.Angles(
								math.rad(math.random(-100, 100) * 0.08),
								math.rad(math.random(-100, 100) * 0.08),
								math.rad(math.random(-100, 100) * 0.08)
							)
							JointData.Joint.C0 = JointData.OriginalC0 * ShakeOffset
						end
					end
				end)
				table.insert(Connections, ShakeConnection)
			end)
		end

		-- Check HP
		table.insert(Connections, Humanoid.HealthChanged:Connect(function(Health)
			if not Mutated and (Health / Humanoid.MaxHealth) <= 0.45 then
				TriggerMutation()
			end
		end))

		if (Humanoid.Health / Humanoid.MaxHealth) <= 0.45 then
			TriggerMutation()
		end
	end

	-- OUTCAST / BLIGHT SPECIFIC BEHAVIOR
	local function StartOutcastBehavior(NPC, Humanoid)
		local InPhase2 = false
		local SpeedMultiplier = 1.0

		local Animator = Humanoid:FindFirstChildOfClass("Animator") or Humanoid
		if Animator then
			table.insert(Connections, Animator.AnimationPlayed:Connect(function(AnimationTrack)
				local AnimName = AnimationTrack.Name:lower()
				if AnimName:find("blight") or AnimName:find("beam") then
					ExecuteBlightBeam(NPC)
				end
			end))
		end

		table.insert(Connections, NPC.ChildAdded:Connect(function(Child)
			local ChildName = Child.Name:lower()
			if ChildName:find("blightbeam") or ChildName:find("beam") then
				ExecuteBlightBeam(NPC)
			end
		end))

		-- LIMB SHAKING LOOP
		task.spawn(function()
			local MotorJoints = {}
			for _, Descendant in ipairs(NPC:GetDescendants()) do
				if Descendant:IsA("Motor6D") and Descendant.Name ~= "RootJoint" and Descendant.Name ~= "Left Shoulder" then
					table.insert(MotorJoints, {Joint = Descendant, OriginalC0 = Descendant.C0})
				end
			end

			local ShakeConnection
			ShakeConnection = RunService.Heartbeat:Connect(function()
				if not IsRunning or not NPC or not NPC.Parent then
					if ShakeConnection then ShakeConnection:Disconnect() end
					return
				end

				local ShakeIntensity = InPhase2 and 0.12 or 0.05
				for _, JointData in ipairs(MotorJoints) do
					if JointData.Joint and JointData.Joint.Parent then
						local ShakeOffset = CFrame.Angles(
							math.rad(math.random(-100, 100) * ShakeIntensity),
							math.rad(math.random(-100, 100) * ShakeIntensity),
							math.rad(math.random(-100, 100) * ShakeIntensity)
						)
						JointData.Joint.C0 = JointData.OriginalC0 * ShakeOffset
					end
				end
			end)
			table.insert(Connections, ShakeConnection)
		end)

		-- TWITCH LOOP
		task.spawn(function()
			local Joints = {}
			for _, Descendant in ipairs(NPC:GetDescendants()) do
				if Descendant:IsA("Motor6D") and Descendant.Name ~= "RootJoint" and Descendant.Name ~= "Left Shoulder" then
					table.insert(Joints, {Joint = Descendant, OriginalC0 = Descendant.C0})
				end
			end

			while IsRunning and NPC and NPC.Parent do
				local BaseWait = (math.random(1, 4) / 20) / SpeedMultiplier
				task.wait(BaseWait)
				if not IsRunning or not NPC.Parent then break end

				local TwitchCount = math.random(2, math.min(5, #Joints))
				for i = 1, TwitchCount do
					local JointData = Joints[math.random(1, #Joints)]
					if JointData and JointData.Joint and JointData.Joint.Parent then
						local Intensity = InPhase2 and 90 or 60
						local RandomRotation = CFrame.Angles(
							math.rad(math.random(-Intensity, Intensity)),
							math.rad(math.random(-Intensity, Intensity)),
							math.rad(math.random(-Intensity, Intensity))
						)
					
						JointData.Joint.C0 = JointData.OriginalC0 * RandomRotation
						task.wait((math.random(2, 6) / 100) / SpeedMultiplier)
						JointData.Joint.C0 = JointData.OriginalC0
					end
				end
			end
		end)

		local function TransformToBlight()
			if InPhase2 then return end
			InPhase2 = true
			SpeedMultiplier = 4.5
		
			NPC.Name = "Blight"
			AttachBlightCrystals(NPC)
		end

		table.insert(Connections, Humanoid.HealthChanged:Connect(function(Health)
			if not InPhase2 and (Health / Humanoid.MaxHealth) <= 0.5 then
				TransformToBlight()
			end
		end))

		if (Humanoid.Health / Humanoid.MaxHealth) <= 0.5 then
			TransformToBlight()
		end
	end

	-- STANDARD AVATAR APPEARANCE FUNCTIONS
	local function ApplyFace(NPC, TargetHead)
		for _, Object in ipairs(TargetHead:GetChildren()) do
			if Object:IsA("Decal") and Object.Name:lower() == "face" then Object:Destroy() end
		end
		local SourceHead = AppearanceModel and AppearanceModel:FindFirstChild("Head")
		if SourceHead then
			for _, Object in ipairs(SourceHead:GetChildren()) do
				if Object:IsA("Decal") and Object.Name:lower() == "face" then
					local Face = Object:Clone()
					Face.Name = "face"
					Face.Face = Enum.NormalId.Front
					Face.Parent = TargetHead
					return
				end
			end
		end
		if HumanoidDescription and HumanoidDescription.Face ~= 0 then
			local Face = Instance.new("Decal")
			Face.Name = "face"
			Face.Face = Enum.NormalId.Front
			Face.Texture = "rbxassetid://" .. tostring(HumanoidDescription.Face)
			Face.Parent = TargetHead
		end
	end

	local function ApplyBodyColors(NPC)
		local SourceBodyColors = AppearanceModel and AppearanceModel:FindFirstChildOfClass("BodyColors")
		if not SourceBodyColors then return end

		local OldBodyColors = NPC:FindFirstChildOfClass("BodyColors")
		if OldBodyColors then OldBodyColors:Destroy() end

		local NewBodyColors = SourceBodyColors:Clone()
		NewBodyColors.Parent = NPC

		local ColorProperties = {
			Head = "HeadColor3",
			Torso = "TorsoColor3",
			["Left Arm"] = "LeftArmColor3",
			["Right Arm"] = "RightArmColor3",
			["Left Leg"] = "LeftLegColor3",
			["Right Leg"] = "RightLegColor3",
		}

		for PartName, PropertyName in pairs(ColorProperties) do
			local Part = NPC:FindFirstChild(PartName)
			if Part and Part:IsA("BasePart") then
				Part.Color = NewBodyColors[PropertyName]
			end
		end
	end

	local function ApplyR6CharacterMeshes(NPC)
		local Humanoid = NPC:FindFirstChildOfClass("Humanoid")
		if not Humanoid or Humanoid.RigType ~= Enum.HumanoidRigType.R6 then return end

		for _, Object in ipairs(NPC:GetChildren()) do
			if Object:IsA("CharacterMesh") then Object:Destroy() end
		end

		if AppearanceModel then
			for _, SourceMesh in ipairs(AppearanceModel:GetChildren()) do
				if SourceMesh:IsA("CharacterMesh") then
					local NewMesh = Instance.new("CharacterMesh")
					NewMesh.Name = SourceMesh.Name
					NewMesh.BodyPart = SourceMesh.BodyPart
					NewMesh.MeshId = SourceMesh.MeshId
					NewMesh.BaseTextureId = SourceMesh.BaseTextureId
					NewMesh.OverlayTextureId = SourceMesh.OverlayTextureId
					NewMesh.Parent = NPC
				end
			end
		end
	end

	local function ApplyR15Body(NPC)
		if not AppearanceModel then return end
		for _, SourcePart in ipairs(AppearanceModel:GetChildren()) do
			if SourcePart:IsA("MeshPart") then
				local TargetPart = NPC:FindFirstChild(SourcePart.Name)
				if TargetPart and TargetPart:IsA("MeshPart") then
					TargetPart.MeshId = SourcePart.MeshId
					TargetPart.TextureID = SourcePart.TextureID
					if SourcePart.RenderFidelity ~= Enum.RenderFidelity.Automatic then
						TargetPart.RenderFidelity = SourcePart.RenderFidelity
					end
				end
			end
		end
	end

	local function GetNPCScale(NPC, TargetHead)
		local NPCScale = NPC:GetScale()
		if math.abs(NPCScale - 1) < 0.001 then NPCScale = TargetHead.Size.Y end
		return NPCScale
	end

	local function ApplyHeadMesh(TargetHead, NPCScale)
		if not AppearanceModel then return end
		local SourceHead = AppearanceModel:FindFirstChild("Head")
		if not SourceHead then return end

		local SourceMesh = SourceHead:FindFirstChildWhichIsA("SpecialMesh")
		local TargetMesh = TargetHead:FindFirstChildWhichIsA("SpecialMesh")
		if TargetMesh then TargetMesh:Destroy() end

		if SourceMesh then
			local NewMesh = SourceMesh:Clone()
			NewMesh.Scale = SourceMesh.Scale * NPCScale
			NewMesh.Parent = TargetHead
		elseif SourceHead:IsA("MeshPart") then
			local NewMesh = Instance.new("SpecialMesh")
			NewMesh.Name = "AvatarHeadMesh"
			NewMesh.MeshType = Enum.MeshType.FileMesh
			NewMesh.MeshId = SourceHead.MeshId
			if SourceHead.TextureID ~= "" then
				NewMesh.TextureId = SourceHead.TextureID
			else
				local Surface = SourceHead:FindFirstChildOfClass("SurfaceAppearance")
				if Surface and Surface.ColorMap ~= "" then NewMesh.TextureId = Surface.ColorMap end
			end
			NewMesh.Scale = SourceHead.Size * NPCScale
			NewMesh.Parent = TargetHead
		end
	end

	local function RemoveAccessoryJoints(Handle)
		for _, Child in ipairs(Handle:GetChildren()) do
			if Child:IsA("JointInstance") or Child:IsA("WeldConstraint") then Child:Destroy() end
		end
	end

	local function ApplyAccessories(NPC, NPCScale)
		if not AppearanceModel then return end
		for _, Object in ipairs(NPC:GetChildren()) do
			if Object:IsA("Accessory") then Object:Destroy() end
		end

		for _, SourceAccessory in ipairs(AppearanceModel:GetChildren()) do
			if not SourceAccessory:IsA("Accessory") then continue end

			local Accessory = SourceAccessory:Clone()
			local Handle = Accessory:FindFirstChild("Handle")
			if not Handle or not Handle:IsA("BasePart") then Accessory:Destroy() continue end

			local AccessoryAttachment = Handle:FindFirstChildWhichIsA("Attachment")
			if not AccessoryAttachment then Accessory:Destroy() continue end

			local TargetAttachment
			for _, Descendant in ipairs(NPC:GetDescendants()) do
				if Descendant:IsA("Attachment") and Descendant.Name == AccessoryAttachment.Name and Descendant.Parent:IsA("BasePart") then
					TargetAttachment = Descendant
					break
				end
			end

			if not TargetAttachment then Accessory:Destroy() continue end

			for _, Descendant in ipairs(Accessory:GetDescendants()) do
				if Descendant:IsA("BasePart") then
					Descendant.Size *= NPCScale
					Descendant.CanCollide = false
					Descendant.CanTouch = false
					Descendant.CanQuery = false
					Descendant.Massless = true
				elseif Descendant:IsA("SpecialMesh") then
					Descendant.Scale *= NPCScale
				elseif Descendant:IsA("Attachment") then
					Descendant.Position *= NPCScale
				end
			end

			Accessory.Parent = NPC
			local BodyPart = TargetAttachment.Parent
			RemoveAccessoryJoints(Handle)
			Handle.CFrame = BodyPart.CFrame * TargetAttachment.CFrame * AccessoryAttachment.CFrame:Inverse()

			local Weld = Instance.new("Weld")
			Weld.Name = "AccessoryWeld"
			Weld.Part0 = BodyPart
			Weld.Part1 = Handle
			Weld.C0 = TargetAttachment.CFrame
			Weld.C1 = AccessoryAttachment.CFrame
			Weld.Parent = Handle
		end
	end

	local function ApplyAppearance(NPC)
		if not IsRunning or not NPC:IsA("Model") or ProcessedNPCs[NPC] then
			return
		end

		if not NPC.Parent then return end

		local TargetHead = NPC:FindFirstChild("Head") or NPC:WaitForChild("Head", 5)
		local Humanoid = NPC:FindFirstChildOfClass("Humanoid") or NPC:WaitForChild("Humanoid", 5)
		if not TargetHead or not TargetHead:IsA("BasePart") or not Humanoid or not NPC.Parent or not IsRunning then return end

		ProcessedNPCs[NPC] = true

		-- ROUTE SPECIFIC BEHAVIORS
		if NPC.Name == "Outcast" or NPC.Name == "Blight" then
			local NPCScale = GetNPCScale(NPC, TargetHead)

			ApplyBodyColors(NPC)

			for _, ClassName in ipairs({"Shirt", "Pants", "ShirtGraphic"}) do
				local Old = NPC:FindFirstChildOfClass(ClassName)
				if Old then Old:Destroy() end
				local New = AppearanceModel and AppearanceModel:FindFirstChildOfClass(ClassName)
				if New then New:Clone().Parent = NPC end
			end

			ApplyHeadMesh(TargetHead, NPCScale)
			ApplyFace(NPC, TargetHead)
			ApplyR6CharacterMeshes(NPC)
			ApplyR15Body(NPC)
			ApplyAccessories(NPC, NPCScale)

			SetupOverheadUI(NPC, Humanoid)
			AddGreyWhiteGlow(NPC)
			StartOutcastBehavior(NPC, Humanoid)
		else
			-- GENERIC CRIMSON SKIES ENEMIES BEHAVIOR
			StartGenericEnemyBehavior(NPC, Humanoid)
		end
	end

	local function SetupFolder(Folder)
		if not Folder then return end
		for _, NPC in ipairs(Folder:GetChildren()) do
			task.spawn(ApplyAppearance, NPC)
		end
		table.insert(Connections, Folder.ChildAdded:Connect(function(NPC)
			task.spawn(ApplyAppearance, NPC)
		end))
	end

	function CrimsonSkies.start()
		if IsRunning then return true end
		TargetUserId = Avatar.userId or LocalPlayer.UserId
		if loadedFor ~= TargetUserId then
			AppearanceModel, HumanoidDescription, loadedFor = nil, nil, nil
		end
		if not LoadAvatarData() then return false end
		loadedFor = TargetUserId

		local npcRoot = Workspace:FindFirstChild("NPCFolders") or Workspace:WaitForChild("NPCFolders", 5)
		FriendlyFolder = npcRoot and npcRoot:FindFirstChild("FriendlyFolder")
		EnemyFolder = npcRoot and npcRoot:FindFirstChild("EnemyFolder")

		IsRunning = true
		CrimsonSkies.running = true
		ProcessedNPCs = {}
		if EnemyFolder then SetupFolder(EnemyFolder) end
		if FriendlyFolder then SetupFolder(FriendlyFolder) end
		return true
	end

	function CrimsonSkies.stop()
		if not IsRunning then return end
		IsRunning = false
		CrimsonSkies.running = false

		for _, connection in ipairs(Connections) do
			pcall(function() connection:Disconnect() end)
		end
		Connections = {}

		for NPC in pairs(ProcessedNPCs) do
			if NPC and NPC.Parent then
				local Glow = NPC:FindFirstChild("OutcastGlow")
				if Glow then Glow:Destroy() end

				local Head = NPC:FindFirstChild("Head")
				if Head then
					local UI = Head:FindFirstChild("OutcastBossUI")
					if UI then UI:Destroy() end
				end

				for _, Child in ipairs(NPC:GetChildren()) do
					if Child.Name == "BlightCrystal" or Child.Name == "EnemyMutationCrystal" or Child.Name == "BlightBeamPentagram" then
						Child:Destroy()
					end
				end
			end
		end
		ProcessedNPCs = {}
	end
end

safeBuild("Misc / Avatar Applier", function()
	local page = pages["Misc"]

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, page)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, container)

	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = WHITE,
		LayoutOrder = 1,
	}, container)
	outline(header, 3)

	local nameButton = make("TextButton", {
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Text = "Avatar Applier",
		TextColor3 = BLACK,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
	}, header)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, nameButton)

	local function refreshHeader()
		header.BackgroundColor3 = Avatar.running and ON_COLOR or WHITE
	end
	Avatar.onFailed = refreshHeader

	listen(nameButton.MouseButton1Click, function()
		if Avatar.running then
			Avatar.stop()
		else
			Avatar.start()
		end
		refreshHeader()
	end)

	local drawer = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
	}, container)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)

	addSwitch(addGrayRow(drawer, "Oops All Oscar"), function()
		return Avatar.oopsAllOscar
	end, function(value)
		Avatar.oopsAllOscar = value
	end)

	addSwitch(addGrayRow(drawer, "Applies for blue team"), function()
		return Avatar.applyFriendly
	end, function(value)
		Avatar.applyFriendly = value
	end)

	addSwitch(addGrayRow(drawer, "Applies for red team"), function()
		return Avatar.applyEnemies
	end, function(value)
		Avatar.applyEnemies = value
	end)

	-- Outcast / Blight + Crimson Skies mutations (own on/off, uses the User ID box below)
	local crimsonWanted, crimsonPending = false, false
	local crimsonRefresh
	crimsonRefresh = addSwitch(addGrayRow(drawer, "Outcast / Blight mutations"), function()
		return CrimsonSkies.running or crimsonPending
	end, function(value)
		crimsonWanted = value
		if value then
			crimsonPending = true
			task.spawn(function()
				CrimsonSkies.start()
				crimsonPending = false
				if not crimsonWanted then
					CrimsonSkies.stop()
				end
				crimsonRefresh()
			end)
		else
			CrimsonSkies.stop()
		end
	end)

	addNumberBox(addGrayRow(drawer, "User ID for custom avatar (blank = you)"), "", function(box)
		local number = tonumber(box.Text)
		Avatar.userId = number and math.floor(number) or nil
		if not number then
			box.Text = ""
		end
	end)

	-- Accessory adder
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "Accessory Adder",
		TextColor3 = WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, drawer)

	local accessoryRow = addGrayRow(drawer, "Accessory ID")
	local accessoryBox = make("TextBox", {
		Size = UDim2.fromOffset(130, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "paste ID",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		ClearTextOnFocus = false,
	}, accessoryRow)
	outline(accessoryBox)

	local accessoryUnitId = 0
	addNumberBox(addGrayRow(drawer, "Only unit ID (0 = every unit)"), "0", function(box)
		local number = tonumber(box.Text)
		accessoryUnitId = (number and number > 0) and math.floor(number) or 0
		box.Text = tostring(accessoryUnitId)
	end)

	local accessoryAlly = true
	local targetRow = addGrayRow(drawer, "Put it on")
	local targetButton = make("TextButton", {
		Size = UDim2.fromOffset(120, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		Text = "",
	}, targetRow)
	outline(targetButton)
	local function refreshTarget()
		if accessoryAlly then
			targetButton.Text = "BLUE (units)"
			targetButton.BackgroundColor3 = Color3.fromRGB(110, 170, 255)
		else
			targetButton.Text = "RED (enemies)"
			targetButton.BackgroundColor3 = Color3.fromRGB(235, 100, 100)
		end
	end
	refreshTarget()
	listen(targetButton.MouseButton1Click, function()
		accessoryAlly = not accessoryAlly
		refreshTarget()
	end)

	local actionRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, SETTING_HEIGHT),
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, drawer)
	outline(actionRow)
	local addAccessoryButton = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 24),
		Position = UDim2.new(0, 6, 0.5, -12),
		BackgroundColor3 = ON_COLOR,
		TextColor3 = BLACK,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Text = "ADD",
	}, actionRow)
	outline(addAccessoryButton)
	local removeAccessoryButton = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 24),
		Position = UDim2.new(0.5, 2, 0.5, -12),
		BackgroundColor3 = Color3.fromRGB(230, 90, 90),
		TextColor3 = BLACK,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Text = "REMOVE ALL",
	}, actionRow)
	outline(removeAccessoryButton)

	local accessoryStatus = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	listen(addAccessoryButton.MouseButton1Click, function()
		local id = tonumber(string.match(accessoryBox.Text, "%d+"))
		if not id then
			accessoryStatus.Text = "Paste an accessory ID first."
			return
		end
		accessoryStatus.Text = "Loading " .. tostring(id) .. "..."
		Avatar.addAccessory(id, accessoryUnitId, accessoryAlly, function(ok, message)
			accessoryStatus.Text = message
		end)
	end)

	listen(removeAccessoryButton.MouseButton1Click, function()
		Avatar.clearAccessories()
		-- this also took the body colours off, so forget them too (the picker shows the real colours again)
		table.clear(Custom.bodyColorStore)
		if Custom.refreshBodyPicker then Custom.refreshBodyPicker() end
		accessoryStatus.Text = "All added accessories removed."
	end)

	-- Accessory paster (saved inside the code below)
	-- Body colors + delete accessories
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "Body Colors / Delete Accessories",
		TextColor3 = WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, drawer)

	-- target: which team and which battler (shared by colors and delete)
	local targetTeam = 2
	local targetUnitId = 0
	local colorStatus

	local targetTeamRow = addGrayRow(drawer, "Target team")
	local targetTeamButton = make("TextButton", {
		Size = UDim2.fromOffset(110, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = Custom.TEAM_NAMES[targetTeam],
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, targetTeamRow)
	outline(targetTeamButton)
	listen(targetTeamButton.MouseButton1Click, function()
		targetTeam = (targetTeam + 1) % 3
		targetTeamButton.Text = Custom.TEAM_NAMES[targetTeam]
		if Custom.refreshBodyPicker then Custom.refreshBodyPicker() end
	end)

	addNumberBox(addGrayRow(drawer, "Target battler ID (0 = all)"), "0", function(box)
		local number = tonumber(box.Text)
		targetUnitId = (number and number > 0) and math.floor(number) or 0
		box.Text = tostring(targetUnitId)
		if Custom.refreshBodyPicker then Custom.refreshBodyPicker() end
	end)

	-- body part picker, drawn like a little Roblox character: click the parts to colour
	local SKIN = Color3.fromRGB(254, 200, 150)
	local selectedParts = { Head = true, Torso = true, LeftArm = true, RightArm = true, LeftLeg = true, RightLeg = true }
	local partButtons = {}
	local pickerRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, 176),
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, drawer)
	outline(pickerRow)
	make("TextLabel", {
		Size = UDim2.new(1, -20, 0, 16),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Text = "Body parts to colour (click to switch)",
		TextColor3 = BLACK,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
	}, pickerRow)
	local figure = make("Frame", {
		Size = UDim2.fromOffset(120, 150),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 22),
		BackgroundTransparency = 1,
	}, pickerRow)

	-- the picker shows the real colours: the colour you applied to that part, otherwise the colour the battler / enemy has
	local partStrokes = {}
	local PICKER_PART_NAMES = {
		Head = { "Head" },
		Torso = { "UpperTorso", "Torso" },
		LeftArm = { "LeftUpperArm", "Left Arm" },
		RightArm = { "RightUpperArm", "Right Arm" },
		LeftLeg = { "LeftUpperLeg", "Left Leg" },
		RightLeg = { "RightUpperLeg", "Right Leg" },
	}
	local function entryFitsTarget(entry)
		return (entry.team == 2 or targetTeam == 2 or entry.team == targetTeam)
			and (entry.unitId == 0 or targetUnitId == 0 or entry.unitId == targetUnitId)
	end
	local function liveBattlerColor(group)
		local npcRoot = Workspace:FindFirstChild("NPCFolders")
		if not npcRoot then return nil end
		for _, folderName in ipairs({ "EnemyFolder", "FriendlyFolder" }) do
			local isAlly = folderName == "FriendlyFolder"
			if targetTeam == 2 or (targetTeam == 1) == isAlly then
				local folder = npcRoot:FindFirstChild(folderName)
				if folder then
					for _, npc in ipairs(folder:GetChildren()) do
						if npc:IsA("Model") and (targetUnitId <= 0 or tonumber(npc:GetAttribute("ID")) == targetUnitId) then
							for _, partName in ipairs(PICKER_PART_NAMES[group]) do
								local part = npc:FindFirstChild(partName)
								if part and part:IsA("BasePart") then
									return part.Color
								end
							end
							local bodyColors = npc:FindFirstChildOfClass("BodyColors")
							if bodyColors then
								local ok, value = pcall(function() return bodyColors[group .. "Color3"] end)
								if ok and typeof(value) == "Color3" then return value end
							end
						end
					end
				end
			end
		end
		return nil
	end
	local function partDisplayColor(group)
		local store = Custom.bodyColorStore
		for index = #store, 1, -1 do
			local entry = store[index]
			if entry.groups[group] and entryFitsTarget(entry) then
				return Color3.fromRGB(entry.color[1], entry.color[2], entry.color[3])
			end
		end
		return liveBattlerColor(group) or SKIN
	end
	local function refreshPartButtons()
		for group, button in pairs(partButtons) do
			button.BackgroundColor3 = partDisplayColor(group)
			local on = selectedParts[group] and true or false
			button.Text = on and "✓" or ""
			local stroke = partStrokes[group]
			if stroke then
				stroke.Thickness = on and 4 or 2
				stroke.Color = on and Color3.fromRGB(0, 200, 0) or BLACK
			end
		end
	end
	local function addPartButton(group, position, size)
		local button = make("TextButton", {
			Size = size,
			Position = position,
			BackgroundColor3 = SKIN,
			Text = "",
			TextColor3 = BLACK,
			TextSize = 22,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
		}, figure)
		partStrokes[group] = outline(button)
		partButtons[group] = button
		listen(button.MouseButton1Click, function()
			selectedParts[group] = not selectedParts[group] or nil
			refreshPartButtons()
		end)
	end
	-- on screen the character faces you, so its right arm is on the left
	addPartButton("Head", UDim2.fromOffset(40, 0), UDim2.fromOffset(40, 34))
	addPartButton("RightArm", UDim2.fromOffset(0, 38), UDim2.fromOffset(28, 56))
	addPartButton("Torso", UDim2.fromOffset(32, 38), UDim2.fromOffset(56, 56))
	addPartButton("LeftArm", UDim2.fromOffset(92, 38), UDim2.fromOffset(28, 56))
	addPartButton("RightLeg", UDim2.fromOffset(32, 98), UDim2.fromOffset(27, 52))
	addPartButton("LeftLeg", UDim2.fromOffset(61, 98), UDim2.fromOffset(27, 52))
	refreshPartButtons()
	Custom.refreshBodyPicker = refreshPartButtons

	local function setAllParts(on)
		for group in pairs(partButtons) do
			selectedParts[group] = on or nil
		end
		refreshPartButtons()
	end
	local selectButtons = addGrayRow(drawer, "Select parts")
	local function makeRowButton(row, text, width, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, row)
		outline(button)
		return button
	end
	listen(makeRowButton(selectButtons, "NONE", 54, 8).MouseButton1Click, function() setAllParts(false) end)
	listen(makeRowButton(selectButtons, "ALL", 54, 68).MouseButton1Click, function() setAllParts(true) end)
	listen(makeRowButton(selectButtons, "REFRESH", 70, 128).MouseButton1Click, function() refreshPartButtons() end)

	-- colour: premade swatches or your own RGB
	local currentColor = { 255, 0, 0 }
	local rBox, gBox, bBox, preview
	local function refreshColor()
		for index, box in ipairs({ rBox, gBox, bBox }) do
			box.Text = tostring(currentColor[index])
		end
		preview.BackgroundColor3 = Color3.fromRGB(currentColor[1], currentColor[2], currentColor[3])
	end

	local swatchRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, drawer)
	outline(swatchRow)
	make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, swatchRow)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(30, 30), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, swatchRow)
	local PREMADE = {
		{ 255, 0, 0 }, { 255, 128, 0 }, { 255, 221, 0 }, { 0, 200, 0 }, { 0, 170, 170 }, { 0, 100, 255 },
		{ 130, 0, 220 }, { 255, 105, 180 }, { 255, 255, 255 }, { 150, 150, 150 }, { 0, 0, 0 }, { 120, 70, 30 },
		{ 254, 200, 150 }, { 0, 255, 255 }, { 120, 255, 0 }, { 128, 0, 0 },
	}
	for index, rgb in ipairs(PREMADE) do
		local swatch = make("TextButton", {
			BackgroundColor3 = Color3.fromRGB(rgb[1], rgb[2], rgb[3]),
			Text = "",
			AutoButtonColor = true,
			LayoutOrder = index,
		}, swatchRow)
		outline(swatch)
		listen(swatch.MouseButton1Click, function()
			currentColor = { rgb[1], rgb[2], rgb[3] }
			refreshColor()
		end)
	end

	local rgbRow = addGrayRow(drawer, "Custom RGB (0-255)")
	preview = make("Frame", {
		Size = UDim2.fromOffset(24, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
	}, rgbRow)
	outline(preview)
	local function makeRgbBox(index, offset)
		local box = make("TextBox", {
			Size = UDim2.fromOffset(38, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = tostring(currentColor[index]),
			ClearTextOnFocus = false,
		}, rgbRow)
		outline(box)
		listen(box.FocusLost, function()
			local number = tonumber(box.Text)
			currentColor[index] = number and math.clamp(math.floor(number), 0, 255) or currentColor[index]
			refreshColor()
		end)
		return box
	end
	bBox = makeRgbBox(3, 40)
	gBox = makeRgbBox(2, 82)
	rBox = makeRgbBox(1, 124)
	refreshColor()

	-- puts every stored body colour on the battlers (removes the old ones first, so nothing doubles up)
	function Custom.rebuildBodyColors()
		Avatar.removeGroup("bodycolor")
		for _, entry in ipairs(Custom.bodyColorStore) do
			Avatar.addBodyColor(entry.groups, Color3.fromRGB(entry.color[1], entry.color[2], entry.color[3]), entry.unitId, entry.team, "bodycolor")
		end
	end

	local colorButtons = addGrayRow(drawer, "Body colour")
	local applyColorButton = makeRowButton(colorButtons, "APPLY", 64, 8)
	local resetColorButton = makeRowButton(colorButtons, "RESET COLOURS", 104, 78)
	local deleteRow = addGrayRow(drawer, "Delete accessories")
	local deleteAccButton = makeRowButton(deleteRow, "DELETE ALL", 90, 8)
	addSwitch(addGrayRow(drawer, "Outfit loader: remove old accessories first"), function()
		return Custom.outfitReplace
	end, function(value)
		Custom.outfitReplace = value
	end)

	local tintClothes, tintMeshes = true, true
	local clothesColor = { 255, 255, 255 }
	local meshColor = { 255, 255, 255 }
	local clothesOpacity, meshOpacity = 100, 100 -- percent: how strongly the tint is mixed in

	-- a row with its own R G B boxes and a preview square
	local function addTintRgbRow(label, colorTable)
		local row = addGrayRow(drawer, label)
		local previewBox = make("Frame", {
			Size = UDim2.fromOffset(24, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(colorTable[1], colorTable[2], colorTable[3]),
		}, row)
		outline(previewBox)
		for index, offset in ipairs({ 124, 82, 40 }) do
			local box = make("TextBox", {
				Size = UDim2.fromOffset(38, 24),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -offset, 0.5, 0),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				Text = tostring(colorTable[index]),
				ClearTextOnFocus = false,
			}, row)
			outline(box)
			listen(box.FocusLost, function()
				local number = tonumber(box.Text)
				if number then
					colorTable[index] = math.clamp(math.floor(number), 0, 255)
				end
				box.Text = tostring(colorTable[index])
				previewBox.BackgroundColor3 = Color3.fromRGB(colorTable[1], colorTable[2], colorTable[3])
			end)
		end
	end

	-- a row with one percent box (0-100)
	local function addOpacityRow(label, getValue, setValue)
		local row = addGrayRow(drawer, label)
		local box = make("TextBox", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = tostring(getValue()),
			ClearTextOnFocus = false,
		}, row)
		outline(box)
		listen(box.FocusLost, function()
			local number = tonumber((box.Text:gsub("%%", "")))
			if number then
				setValue(math.clamp(math.floor(number), 0, 100))
			end
			box.Text = tostring(getValue())
		end)
	end

	addSwitch(addGrayRow(drawer, "Tint clothes (shirt / pants)"), function()
		return tintClothes
	end, function(value)
		tintClothes = value
	end)
	addTintRgbRow("Clothes RGB", clothesColor)
	addOpacityRow("Clothes tint opacity %", function() return clothesOpacity end, function(value) clothesOpacity = value end)
	addSwitch(addGrayRow(drawer, "Tint hats / accessory meshes"), function()
		return tintMeshes
	end, function(value)
		tintMeshes = value
	end)
	addTintRgbRow("Hats RGB", meshColor)
	addOpacityRow("Hats tint opacity %", function() return meshOpacity end, function(value) meshOpacity = value end)
	local tintRow = addGrayRow(drawer, "Colour tint")
	local applyTintButton = makeRowButton(tintRow, "TINT", 54, 8)
	local resetTintButton = makeRowButton(tintRow, "RESET TINT", 84, 68)

	-- hat texture changer: swaps the texture on hat / accessory meshes
	local textureRow = addGrayRow(drawer, "Hat texture ID")
	local textureBox = make("TextBox", {
		Size = UDim2.fromOffset(120, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "image / decal ID",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		Font = Enum.Font.Code,
		ClearTextOnFocus = false,
	}, textureRow)
	outline(textureBox)
	local textureButtons = addGrayRow(drawer, "Hat texture")
	local applyTextureButton = makeRowButton(textureButtons, "APPLY", 64, 8)
	local resetTextureButton = makeRowButton(textureButtons, "RESET TEXTURE", 104, 78)

	-- Shirt texture (Israel shirt by default)
	local shirtRow = addGrayRow(drawer, "Shirt texture ID (Israel shirt)")
	local shirtBox = make("TextBox", {
		Size = UDim2.fromOffset(120, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "shirt ID",
		PlaceholderColor3 = GRAY,
		Text = "15961342990",
		TextSize = 12,
		Font = Enum.Font.Code,
		ClearTextOnFocus = false,
	}, shirtRow)
	outline(shirtBox)
	local shirtButtons = addGrayRow(drawer, "Shirt")
	local applyShirtButton = makeRowButton(shirtButtons, "APPLY SHIRT", 90, 8)
	local resetShirtButton = makeRowButton(shirtButtons, "RESET SHIRT", 90, 104)

	-- 2D face adder: a face picture on the front of the head, with its own colour
	local faceColor = { 255, 255, 255 }
	local faceRow = addGrayRow(drawer, "2D face (decal / image ID)")
	local faceBox = make("TextBox", {
		Size = UDim2.fromOffset(120, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "face ID",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		Font = Enum.Font.Code,
		ClearTextOnFocus = false,
	}, faceRow)
	outline(faceBox)
	addTintRgbRow("Face colour RGB (255 = original)", faceColor)
	local faceButtons = addGrayRow(drawer, "2D face")
	local applyFaceButton = makeRowButton(faceButtons, "ADD FACE", 80, 8)
	local resetFaceButton = makeRowButton(faceButtons, "RESET FACE", 90, 94)

	colorStatus = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local function targetText()
		return (targetUnitId > 0 and ("battler ID " .. targetUnitId) or "all battlers") .. " / " .. Custom.TEAM_NAMES[targetTeam]
	end

	listen(applyColorButton.MouseButton1Click, function()
		local groups, count = {}, 0
		for group in pairs(selectedParts) do
			groups[group] = true
			count += 1
		end
		if count == 0 then
			colorStatus.Text = "Pick at least one body part first."
			return
		end
		-- the newest colour replaces older ones on the same parts / target, then everything is put on again
		for _, entry in ipairs(Custom.bodyColorStore) do
			if entry.unitId == targetUnitId and entry.team == targetTeam then
				for group in pairs(groups) do entry.groups[group] = nil end
			end
		end
		for index = #Custom.bodyColorStore, 1, -1 do
			if next(Custom.bodyColorStore[index].groups) == nil then table.remove(Custom.bodyColorStore, index) end
		end
		table.insert(Custom.bodyColorStore, {
			groups = groups, color = { currentColor[1], currentColor[2], currentColor[3] },
			unitId = targetUnitId, team = targetTeam,
		})
		Custom.rebuildBodyColors()
		refreshPartButtons()
		colorStatus.Text = "Coloured " .. tostring(count) .. " part" .. (count == 1 and "" or "s") .. " on " .. targetText() .. ". New units get it too. It is saved in the Avatar Applier code."
	end)

	listen(resetColorButton.MouseButton1Click, function()
		table.clear(Custom.bodyColorStore)
		Avatar.removeGroup("bodycolor")
		refreshPartButtons()
		colorStatus.Text = "Body colours put back."
	end)

	listen(applyTintButton.MouseButton1Click, function()
		if not tintClothes and not tintMeshes then
			colorStatus.Text = "Switch on clothes and/or meshes first."
			return
		end
		Avatar.addTint({
			clothes = tintClothes and Color3.fromRGB(clothesColor[1], clothesColor[2], clothesColor[3]) or nil,
			clothesOpacity = clothesOpacity / 100,
			meshes = tintMeshes and Color3.fromRGB(meshColor[1], meshColor[2], meshColor[3]) or nil,
			meshesOpacity = meshOpacity / 100,
		}, targetUnitId, targetTeam, "tint")
		colorStatus.Text = "Tinted " .. (tintClothes and "clothes" or "") .. ((tintClothes and tintMeshes) and " and " or "") .. (tintMeshes and "hats" or "") .. " on " .. targetText() .. ". New units get it too."
	end)

	listen(resetTintButton.MouseButton1Click, function()
		Avatar.removeGroup("tint")
		colorStatus.Text = "Tints put back."
	end)

	listen(applyTextureButton.MouseButton1Click, function()
		local typed = textureBox.Text
		colorStatus.Text = "Loading texture..."
		task.spawn(function()
			local texture = Avatar.resolveTexture(typed)
			if not texture then
				colorStatus.Text = "Type a texture ID first."
				return
			end
			Avatar.removeGroup("hattexture") -- replaces the previous texture instead of stacking
			Avatar.addTint({ meshTexture = texture }, targetUnitId, targetTeam, "hattexture")
			colorStatus.Text = "Hat texture set on " .. targetText() .. ". New units get it too."
		end)
	end)

	listen(resetTextureButton.MouseButton1Click, function()
		Avatar.removeGroup("hattexture")
		colorStatus.Text = "Hat textures put back."
	end)

	listen(applyShirtButton.MouseButton1Click, function()
		local id = tonumber(string.match(shirtBox.Text, "%d+"))
		if not id then
			colorStatus.Text = "Type a shirt ID first."
			return
		end
		Avatar.removeGroup("shirt") -- replaces the previous shirt instead of stacking
		Avatar.addShirt("rbxassetid://" .. tostring(id), targetUnitId, targetTeam, "shirt")
		colorStatus.Text = "Shirt " .. tostring(id) .. " put on " .. targetText() .. ". New units get it too."
	end)

	listen(resetShirtButton.MouseButton1Click, function()
		Avatar.removeGroup("shirt")
		colorStatus.Text = "Shirts put back."
	end)

	listen(applyFaceButton.MouseButton1Click, function()
		local typed = faceBox.Text
		colorStatus.Text = "Loading face..."
		task.spawn(function()
			local texture = Avatar.resolveTexture(typed)
			if not texture then
				colorStatus.Text = "Type a face ID first."
				return
			end
			Avatar.removeGroup("face") -- replaces the previous face (and its colour) instead of stacking
			Avatar.addFace(texture, Color3.fromRGB(faceColor[1], faceColor[2], faceColor[3]), targetUnitId, targetTeam, "face")
			colorStatus.Text = "Face added to " .. targetText() .. ". Change the colour and press ADD FACE again to recolour it. New units get it too."
		end)
	end)

	listen(resetFaceButton.MouseButton1Click, function()
		Avatar.removeGroup("face")
		colorStatus.Text = "Faces put back."
	end)

	listen(deleteAccButton.MouseButton1Click, function()
		local units, removed = Avatar.deleteAllAccessories(targetUnitId, targetTeam)
		colorStatus.Text = "Deleted " .. tostring(removed) .. " accessories from " .. tostring(units) .. " unit" .. (units == 1 and "" or "s") .. " (" .. targetText() .. ")."
	end)

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Text = "Accessory Paster (saved with the code below)",
		TextColor3 = WHITE,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, drawer)

	local pasteRow = addGrayRow(drawer, "Item ID (b123 = bundle)")
	local pasteBox = make("TextBox", {
		Size = UDim2.fromOffset(110, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "paste ID",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		ClearTextOnFocus = false,
		Font = Enum.Font.Gotham,
	}, pasteRow)
	outline(pasteBox)

	local pasteUnitId = 0
	addNumberBox(addGrayRow(drawer, "Battler ID (0 = all battlers)"), "0", function(box)
		local number = tonumber(box.Text)
		pasteUnitId = (number and number > 0) and math.floor(number) or 0
		box.Text = tostring(pasteUnitId)
	end)

	local pasteTeam = 2
	local teamRow = addGrayRow(drawer, "Goes on")
	local teamButton = make("TextButton", {
		Size = UDim2.fromOffset(110, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = Custom.TEAM_NAMES[pasteTeam],
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, teamRow)
	outline(teamButton)
	listen(teamButton.MouseButton1Click, function()
		pasteTeam = (pasteTeam + 1) % 3
		teamButton.Text = Custom.TEAM_NAMES[pasteTeam]
	end)

	local pasteButtonRow = addGrayRow(drawer, "")
	local function makePasteButton(text, width, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, pasteButtonRow)
		outline(button)
		return button
	end
	local removeAllAccButton = makePasteButton("REMOVE ALL", 84, 8)
	local removePrevAccButton = makePasteButton("REMOVE PREVIOUS", 112, 98)
	local addAccButton = makePasteButton("ADD", 44, 216)

	local pasteList = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local function refreshPasteList()
		pasteList.Text = "Stored:\n" .. Custom.describeAccStore()
	end
	Custom.refreshAccUI = refreshPasteList
	refreshPasteList()

	listen(addAccButton.MouseButton1Click, function()
		local text = string.lower((string.gsub(pasteBox.Text, "%s", "")))
		local id = tonumber(string.match(text, "%d+"))
		if not id or id <= 0 then
			pasteList.Text = "Paste an ID first.\n" .. Custom.describeAccStore()
			return
		end
		local isBundle = string.find(text, "b") ~= nil
		table.insert(Custom.accStore, { id = id, unitId = pasteUnitId, team = pasteTeam, bundle = isBundle })
		pasteBox.Text = ""
		refreshPasteList()
	end)

	listen(removePrevAccButton.MouseButton1Click, function()
		table.remove(Custom.accStore)
		refreshPasteList()
	end)

	listen(removeAllAccButton.MouseButton1Click, function()
		table.clear(Custom.accStore)
		Avatar.removeGroup(Custom.ACC_GROUP) -- also takes them off the battlers that already have them
		refreshPasteList()
	end)

	-- Save / Load for the accessory adder: everything that is currently added becomes one code
	local accSaveRow = addGrayRow(drawer, "Save / Load accessories")
	local function makeAccButton(text, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, accSaveRow)
		outline(button)
		return button
	end
	local accLoadButton = makeAccButton("LOAD", 8)
	local accSaveButton = makeAccButton("SAVE", 68)

	local accCodeRow = addGrayRow(drawer, "Code")
	local accCodeBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "save to get a code / paste one here",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, accCodeRow)
	outline(accCodeBox)

	listen(accSaveButton.MouseButton1Click, function()
		local rules = Avatar.getAccessoryRules()
		local pasterRules = {}
		for _, rule in ipairs(rules) do
			-- id 0 = body colour / tint / face / wipe rules, those are not accessories (body colours are saved below)
			if rule.group ~= Custom.ACC_GROUP and rule.id and rule.id ~= 0 then table.insert(pasterRules, rule) end
		end
		if #pasterRules == 0 and #Custom.accStore == 0 and #Custom.bodyColorStore == 0 then
			accessoryStatus.Text = "Nothing to save yet. Press ADD first."
			return
		end
		local parts = {}
		local seen = {}
		for _, rule in ipairs(pasterRules) do
			local key = string.format("%d,%d,%d", rule.id, rule.unitId or 0, rule.ally and 1 or 0)
			if not seen[key] then
				seen[key] = true
				table.insert(parts, key)
			end
		end
		-- the paster list: id,battlerId,team,bundle joined by |
		local pasterParts = {}
		for _, entry in ipairs(Custom.accStore) do
			table.insert(pasterParts, string.format("%d,%d,%d,%d", entry.id, entry.unitId, entry.team, entry.bundle and 1 or 0))
		end
		table.insert(parts, "P:" .. table.concat(pasterParts, "|"))
		-- the body colours: r,g,b,mask(Head Torso LeftArm RightArm LeftLeg RightLeg),battlerId,team joined by |
		if #Custom.bodyColorStore > 0 then
			local colorParts = {}
			for _, entry in ipairs(Custom.bodyColorStore) do
				local mask = ""
				for _, group in ipairs(Custom.BODY_GROUP_ORDER) do
					mask ..= entry.groups[group] and "1" or "0"
				end
				table.insert(colorParts, string.format("%d,%d,%d,%s,%d,%d", entry.color[1], entry.color[2], entry.color[3], mask, entry.unitId, entry.team))
			end
			table.insert(parts, "C:" .. table.concat(colorParts, "|"))
		end
		local body = Custom.encodeBase64(table.concat(parts, ";"))
		local code = "OSA1" .. body .. Custom.checksum(body)
		accCodeBox.Text = code
		local copied = false
		copied = Custom.copy(code)
		accessoryStatus.Text = copied and "Saved! The code is in the box and copied to your clipboard." or "Saved! Copy the code from the box."
	end)

	listen(accLoadButton.MouseButton1Click, function()
		local code = string.gsub(accCodeBox.Text, "%s", "")
		if string.sub(code, 1, 4) ~= "OSA1" or #code < 7 then
			accessoryStatus.Text = "Could not load: that is not a valid accessory code."
			return
		end
		local body = string.sub(code, 5, #code - 1)
		if Custom.checksum(body) ~= string.sub(code, #code) then
			accessoryStatus.Text = "Could not load: the code is damaged (a character is wrong or missing)."
			return
		end
		local ok, decoded = pcall(decodeBase64, body)
		if not ok or decoded == "" then
			accessoryStatus.Text = "Could not load: the code could not be read."
			return
		end

		local rules = {}
		local newStore
		local newBodyColors = {}
		for _, part in ipairs(string.split(decoded, ";")) do
			local colorData = string.match(part, "^C:(.*)$")
			if colorData then
				for _, text in ipairs(string.split(colorData, "|")) do
					local cr, cg, cb, mask, cunit, cteam = string.match(text, "^(%d+),(%d+),(%d+),([01]+),(%d+),([012])$")
					if not cr or #mask ~= #Custom.BODY_GROUP_ORDER then
						accessoryStatus.Text = "Could not load: the code could not be read."
						return
					end
					local groups = {}
					for index, group in ipairs(Custom.BODY_GROUP_ORDER) do
						if string.sub(mask, index, index) == "1" then groups[group] = true end
					end
					table.insert(newBodyColors, {
						groups = groups,
						color = { math.clamp(tonumber(cr), 0, 255), math.clamp(tonumber(cg), 0, 255), math.clamp(tonumber(cb), 0, 255) },
						unitId = tonumber(cunit), team = tonumber(cteam),
					})
				end
				continue
			end
			local pasterData = string.match(part, "^P:(.*)$")
			if pasterData then
				newStore = {}
				if pasterData ~= "" then
					for _, text in ipairs(string.split(pasterData, "|")) do
						local pid, punit, pteam, pbundle = string.match(text, "^(%d+),(%d+),([012]),([01])$")
						if not pid then
							accessoryStatus.Text = "Could not load: the code could not be read."
							return
						end
						table.insert(newStore, { id = tonumber(pid), unitId = tonumber(punit), team = tonumber(pteam), bundle = pbundle == "1" })
					end
				end
				continue
			end
			local id, unitId, ally = string.match(part, "^(%d+),(%d+),([01])$")
			if not id then
				accessoryStatus.Text = "Could not load: the code could not be read."
				return
			end
			table.insert(rules, { id = tonumber(id), unitId = tonumber(unitId), ally = ally == "1" })
		end

		Avatar.clearAccessories()
		-- clearAccessories took every body colour off, so the saved ones (if any) go back on
		Custom.bodyColorStore = newBodyColors
		Custom.rebuildBodyColors()
		if Custom.refreshBodyPicker then Custom.refreshBodyPicker() end
		if newStore then
			Custom.accStore = newStore
			Custom.refreshAccUI()
			Custom.applyAccStore(function(message)
				accessoryStatus.Text = message
			end)
		end
		if #rules == 0 then
			if not newStore then
				accessoryStatus.Text = #newBodyColors > 0 and ("Loaded " .. tostring(#newBodyColors) .. " body colour" .. (#newBodyColors == 1 and "" or "s") .. ".") or "Nothing in that code."
			end
			return
		end
		accessoryStatus.Text = "Loading " .. tostring(#rules) .. " accessories..."
		local loaded, failed = 0, 0
		for _, rule in ipairs(rules) do
			Avatar.addAccessory(rule.id, rule.unitId, rule.ally, function(done)
				if done then loaded += 1 else failed += 1 end
				if loaded + failed == #rules then
					accessoryStatus.Text = "Loaded " .. tostring(loaded) .. " accessories" .. (failed > 0 and (", " .. tostring(failed) .. " could not be loaded.") or ".")
				end
			end)
		end
	end)

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Text = "Switch it OFF and ON again after changing these. Oops All Oscar ignores the User ID. Outcast / Blight mutations use the User ID too.\nCredits: made by Gerald Broflovski",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local chevron = make("TextButton", {
		Size = UDim2.new(0, 44, 1, 0),
		Position = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Text = ">",
		TextColor3 = BLACK,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
	}, header)
	listen(chevron.MouseButton1Click, function()
		drawer.Visible = not drawer.Visible
		chevron.Text = drawer.Visible and "v" or ">"
	end)
end)

safeBuild("AWC Bossrush", function()
	local page = pages["Misc"]
	addChapterRow(page, AWC_BOSSRUSH)
end)

-- Music Player (Misc tab): plays the game's own OST / Joke OST sounds, plus a Roblox ID sound effect player
safeBuild("Music Player", function()
	local page = pages["Misc"]
	local MUSIC_NAMES = {
		["Acceptance"] = "Silence",
		["AltPath"] = "End of Beginning Tumore",
		["PokeyMeansBusiness"] = "Exec",
		["ArtThou"] = "Stage Start Tumore",
		["Interception"] = "Red Herring Normal",
		["PlayingMayhem"] = "Red Herring Challenge Normal",
		["Basement"] = "The Battle Begins Normal",
		["FoxTrot"] = "Catalog Muffin",
		["BattleofLittleSlugger"] = "Doombringer",
		["BetusBlues"] = "???",
		["BossBoomBox"] = "Bedridden",
		["CHADSBrokenWind"] = "CH2 Section 1 Tumore",
		["CasualMode"] = "Casual Menu",
		["CelsiusTrouble"] = "FL Stage 19 Normal",
		["Chad"] = "Jetrock",
		["CoverOFDescent"] = "Normal Menu",
		["DangerStage"] = "CH1 Normal Challenge",
		["DarkSkies"] = "Redbeard",
		["DivineCombat"] = "Paintmaster",
		["DontPreheatYourOven"] = "FL Normal",
		["Enmity"] = "Treachstone Old",
		["EnsembleOfFools"] = "CH1 Tumore Challenge",
		["FaultLines"] = "CH2 Section 3 Normal",
		["FaultLinesHard"] = "CH2 Stage 29 Normal",
		["Flashpoint"] = "CH1 Section 3 Tumore",
		["FlashpointHard"] = "CH1 Stage 29 Tumore",
		["Forest"] = "CH2 Section 1 Normal",
		["GameOver"] = "Silence",
		["GetBackHere"] = "Coil Stage 19 Tumore",
		["GhettoLibretto"] = "CH2 Section 2 Normal",
		["GlacierIntense"] = "FL Stage 19 Tumore",
		["GlacierTheme"] = "FL Tumore",
		["Gothic"] = "Babatala Challenge Normal",
		["Heartbeat"] = "Silence",
		["InnocenceGlitched"] = "Coil Normal",
		["InnocenceMangled"] = "Coil Tumore",
		["JumpIntoBattle"] = "Terminator",
		["KillingTwoBirds"] = "Rockstar Radical",
		["King"] = "Turking",
		["Lose"] = "Silence",
		["Masked"] = "Infernus",
		["Matricide"] = "Deathbringer",
		["McLartyPartyPeople"] = "Birthday Normal",
		["Nave"] = "CH1 Section 2 Tumore",
		["NowhereToRun"] = "Coil Stage 19 Tumore",
		["OfRainbows"] = "Silence",
		["OfRainbowssssssss"] = "Silence",
		["OldTestament"] = "Tumore Menu",
		["OutsidetheFold"] = "CH1 Section 3 Normal",
		["OutsidetheFoldHard"] = "CH1 Stage 29 Normal",
		["OwnLittleWorld"] = "???",
		["Peace"] = "Normal Win Screen",
		["PeaceBeWithYou"] = "Normal Win",
		["RageOfTheChampions"] = "CH2 Challenge Tumore",
		["Repentant"] = "CH1 Section 1 Tumore",
		["RevengeOfTheCyclops"] = "CH2 Challenge Normal",
		["RudeBuster"] = "Coil Challenge Normal",
		["RushTheme"] = "Sandbox Old",
		["SMBWorld6Theme"] = "Tumore Selection",
		["SandboxMode"] = "Enter Sandbox",
		["Select Difficulty"] = "Silence",
		["Sodom"] = "Classic Tumore",
		["SongWhenYouFightSans"] = "Birthday Battler",
		["SongWhenYouFightSansHardMode"] = "Celebration Battler",
		["SpinningOutofOrbit"] = "Tumore Win",
		["SugarcubeHalistorm"] = "Soulfuse",
		["Tandava"] = "End of Beginning Normal",
		["TheBattleOfAward42"] = "DJ Radical",
		["TheMayorsLement"] = "CH2 Section 2 Tumore",
		["TheNoiseTheme"] = "Fusecoil",
		["ThisDudeTrash"] = "Silence",
		["Title Screen"] = "Title Screen Old",
		["TundraTitan"] = "FL Challenge Tumore",
		["UnderMySkin"] = "Hellfighter",
		["Unknown Depths"] = "Stage Start Normal",
		["WinterBliss"] = "FL Challenge Normal",
		["WorldMapTheme"] = "Normal Selection",
		["GunsBlazing"] = "CH3 Stage 29 Normal",
		["EndOfTheLine"] = "CH3 Stage 29 Tumore",
		["WallsOfDenial"] = "CH3 Section 1 Tumore",
		["TheEndIsAnguish"] = "CH3 Section 2 Normal",
		["Retrograde"] = "Insecure",
		["WhenBloodDries"] = "CH3 Section 1 Normal",
		["Ruin"] = "CH3 Section 2 Tumore",
		["TheFuture"] = "Blackmail",
		["Castle"] = "CH3 Section 3 Tumore",
		["RocketRider"] = "CH3 Section 3 Normal",
		["ItSeesEverything"] = "CH3 Challenge Normal",
		["PlayingWithFirepower"] = "CH3 Challenge Tumore",
		["ImpastaSyndrome"] = "Cesus",
		["Archetype"] = "Bulldozer",
		["HereTheyAre"] = "X-TREME",
		["Dalv"] = "Mister Mancer",
		["MentallySpooky"] = "Doctor Despair",
		["MC4Theme"] = "Muffin Tumore",
		["MC5Theme"] = "Muffin Challenge Tumore",
		["ADayAtTheBeach"] = "Muffin Challenge Normal",
		["UnderCoverAtNight"] = "Muffin Normal",
		["TrainMadness"] = "Muffin Stage 19 Tumore",
		["WinterContingency"] = "Muffin Stage 19 Tumore",
		["BattleAgainstARudeOpponent"] = "Coil Challenge Tumore",
		["MC10Theme"] = "Doomsday Muffin",
		["SugarRush"] = "???",
		["AsYouWish"] = "Almanac",
		["EastAsia"] = "Red Herring Tumore",
		["NuclearFusion"] = "Red Herring Challenge Tumore",
		["BalladOfTheBurningSquirrel"] = "Birthday Tumore",
		["MorningStar"] = "Babatala Tumore",
		["Shadowdance"] = "Babatala Normal",
		["OnslaughtOfBeasts"] = "Babatala Challenge Tumore",
		["Mistake"] = "???",
		["BattleofLittleSluggerOld"] = "Doombringer Old",
		["AsTheShadow"] = "CH4 Challenge Tumore",
		["Elfin"] = "CH4 Challenge Normal",
		["DesertedHell"] = "CH4 Section 1 Tumore",
		["FollowingYourStar"] = "CH4 Section 1 Normal",
		["FightTheMovement"] = "Monolith",
		["JumpIntoBattle2"] = "Monsalt",
		["DescendantOfTepes"] = "CH4 Section 2 Tumore",
		["NightSakura"] = "CH4 Section 2 Normal",
		["ShootAStrangeBird"] = "Martyr",
		["HistoryOfTheMoon"] = "Reinbo",
		["PizzaEngineer"] = "CH4 Section 3 Normal",
		["WarWithoutReasonHard"] = "CH4 Stage 29 Tumore",
		["WarWithoutReason"] = "CH4 Section 3 Tumore",
		["SauceMachine"] = "CH4 Stage 29 Normal",
		["CampersRiseAndShine"] = "Crusher",
		["HardDriveToMunchYou"] = "Father",
		["CurtainCall"] = "X-TREME Meltdown",
		["Unexpectancy"] = "Cesus Crashout",
		["Soul0System"] = "Cross",
		["HopeOfBirth"] = "Chronos",
		["Gutbuster"] = "Crimson Tumore",
		["GutbusterLayer"] = "Crimson Stage 14 Tumore",
		["FieldOfToilets"] = "Crimson Normal",
		["Thunderstorm"] = "Crimson Challenge Tumore",
		["FieldOfFlushing"] = "Crimson Stage 14 Normal",
		["RageOfTheAbandoned"] = "Crimson Challenge Normal",
		["TheBlight"] = "Outcast Phase 2",
		["UltraChurch"] = "Outcast",
		["TheBlightEnd"] = "Blight Death",
		["LeftAliveDeadTrying"] = "Apostle",
		["TrashZone"] = "CH5 Section 1 Tumore",
		["PizzaScare"] = "CH5 Challenge Tumore",
		["GoodEatin"] = "CH5 Section 1 Normal",
		["PizzaScape"] = "CH5 Challenge Normal",
		["PeppermanStrikes"] = "Chef Sarge",
		["HellFriedPizza"] = "Sargent",
		["TheWorldRevolving"] = "FunK1d",
		["FateMetalRemix"] = "Mortis Phase 2",
		["BigBang"] = "GameK1d",
		["Landside"] = "CH5 Section 3 Normal",
		["Formaldehyde"] = "CH5 Section 3 Tumore",
		["WegaChallenge"] = "GameK1d Phase 2",
		["WegaChallengeHard"] = "GameK1d Phase 3",
		["BiteTheCrust"] = "CH5 Section 2 Normal",
		["TunnelyShimbers"] = "CH5 Section 2 Tumore",
		["VoveteMiserias"] = "Lichen",
		["CantoVIBoss3"] = "Stem",
		["LullablyofBetrayedSin"] = "Treachstone Asleep",
		["FleeNowWickedAngel"] = "Treachstone",
		["LandsideHard"] = "CH5 Stage 29 Normal",
		["ThePartWhereHeKillsYou"] = "Server",
		["ThePartWhereHeKillsYou_Intro"] = "Server Asleep",
		["BombsForThrowingAtYou"] = "Mortis Phase 1",
		["BombsForThrowingAtYou_Intro"] = "Mortis Cutscene",
		["TheresNothing"] = "Nothing",
		["FinalBoss10"] = "Casual Challenger",
	}
	
	local musicEntries = {}
	local idSounds = {}
	local currentFolderName = "OST"
	local searchText = ""

	-- speed / pitch. Speed changes the playback speed (and with it the pitch, like a record).
	-- Pitch is kept separate: a pitch-shift effect cancels out the speed's own pitch change, so
	-- "speed 2, pitch 1" is twice as fast but the same note height.
	local musicSpeed = 1
	local musicPitch = 1
	local originalSpeeds = setmetatable({}, { __mode = "k" })

	local function applyAudioSettings(sound)
		if not sound or not sound.Parent then return end
		if originalSpeeds[sound] == nil then
			originalSpeeds[sound] = sound.PlaybackSpeed
		end
		sound.PlaybackSpeed = musicSpeed

		local effect = sound:FindFirstChild("OscarPitchShift")
		local ratio = musicPitch / musicSpeed
		if math.abs(ratio - 1) < 0.001 then
			if effect then effect:Destroy() end
		else
			if not effect then
				effect = Instance.new("PitchShiftSoundEffect")
				effect.Name = "OscarPitchShift"
				effect.Parent = sound
			end
			effect.Octave = math.clamp(ratio, 0.5, 5)
		end
	end

	local function resetAudioSettings(sound)
		local original = originalSpeeds[sound]
		if original ~= nil then
			pcall(function()
				sound.PlaybackSpeed = original
			end)
			originalSpeeds[sound] = nil
		end
		local effect = sound:FindFirstChild("OscarPitchShift")
		if effect then
			effect:Destroy()
		end
	end

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, page)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, container)

	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = WHITE,
		LayoutOrder = 1,
	}, container)
	outline(header, 3)

	local nameButton = make("TextButton", {
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Text = "Music Player",
		TextColor3 = BLACK,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
	}, header)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, nameButton)

	local drawer = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
	}, container)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)

	local chevron = make("TextButton", {
		Size = UDim2.new(0, 44, 1, 0),
		Position = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Text = ">",
		TextColor3 = BLACK,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
	}, header)

	local loadList -- defined below

	local function toggleDrawer()
		drawer.Visible = not drawer.Visible
		chevron.Text = drawer.Visible and "v" or ">"
		if drawer.Visible and #musicEntries == 0 then
			loadList(currentFolderName)
		end
	end
	listen(chevron.MouseButton1Click, toggleDrawer)
	listen(nameButton.MouseButton1Click, toggleDrawer)

	-- tab row (OST / Joke OST)
	local tabRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, SETTING_HEIGHT),
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, drawer)
	outline(tabRow)

	local tabButtons = {}
	for index, tabName in ipairs({ "OST", "JOKEOST" }) do
		local button = make("TextButton", {
			Size = UDim2.new(0.5, -8, 0, 24),
			Position = UDim2.new((index - 1) * 0.5, 6, 0.5, -12),
			TextColor3 = BLACK,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = tabName == "OST" and "OST" or "Joke OST",
		}, tabRow)
		outline(button)
		tabButtons[tabName] = button
	end

	local function refreshTabs()
		for tabName, button in tabButtons do
			button.BackgroundColor3 = currentFolderName == tabName and ON_COLOR or WHITE
		end
	end

	-- search
	local searchRow = addGrayRow(drawer, "Search")
	local searchBox = make("TextBox", {
		Size = UDim2.fromOffset(150, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "type a name",
		Text = "",
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		ClearTextOnFocus = false,
	}, searchRow)
	outline(searchBox)

	-- the sound list
	local listFrame = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 240),
		BackgroundColor3 = Color3.fromRGB(70, 70, 70),
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
	}, drawer)
	outline(listFrame)
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
	}, listFrame)

	local emptyLabel = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 13,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		LayoutOrder = 0,
	}, listFrame)

	local function refreshEntries()
		local needle = string.lower(searchText)
		for _, entry in musicEntries do
			local playing = entry.sound.Parent ~= nil and entry.sound.IsPlaying
			if not playing and entry.sound.Parent then
				resetAudioSettings(entry.sound) -- song ended by itself: give the game its sound back
			end
			entry.button.BackgroundColor3 = playing and ON_COLOR or WHITE
			entry.button.Text = (playing and "Playing: " or "> ") .. entry.name
			entry.button.Visible = needle == "" or string.find(string.lower(entry.name), needle, 1, true) ~= nil
		end
	end

	local function stopAllMusic()
		for _, folderName in ipairs({ "OST", "JOKEOST" }) do
			local folder = SoundService:FindFirstChild(folderName)
			if folder then
				for _, sound in folder:GetChildren() do
					if sound:IsA("Sound") then
						pcall(function()
							sound:Stop()
							resetAudioSettings(sound)
						end)
					end
				end
			end
		end
	end

	loadList = function(folderName)
		currentFolderName = folderName
		refreshTabs()
		for _, entry in musicEntries do
			entry.button:Destroy()
		end
		table.clear(musicEntries)

		-- no yielding here: if the folder is not in the game, just say so
		local folder = SoundService:FindFirstChild(folderName)
		if not folder then
			emptyLabel.Text = folderName .. " was not found in this game."
			emptyLabel.Visible = true
			return
		end

		local list = {}
		for _, sound in folder:GetChildren() do
			if sound:IsA("Sound") then
				local displayName = sound:GetAttribute("DisplayName")
				if folderName == "OST" and MUSIC_NAMES[sound.Name] then
					displayName = MUSIC_NAMES[sound.Name]
				end
				table.insert(list, { sound = sound, name = tostring(displayName or sound.Name) })
			end
		end
		table.sort(list, function(a, b)
			return string.lower(a.name) < string.lower(b.name)
		end)

		emptyLabel.Visible = #list == 0
		emptyLabel.Text = #list == 0 and "No sounds in this folder." or ""

		for index, item in ipairs(list) do
			local button = make("TextButton", {
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = Enum.Font.GothamBold,
				Text = "> " .. item.name,
				LayoutOrder = index,
			}, listFrame)
			make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, button)
			outline(button)

			local entry = { sound = item.sound, name = item.name, button = button }
			table.insert(musicEntries, entry)

			listen(button.MouseButton1Click, function()
				if item.sound.IsPlaying then
					item.sound:Stop()
				else
					stopAllMusic()
					applyAudioSettings(item.sound)
					item.sound:Play()
				end
				task.delay(0.15, refreshEntries)
			end)
		end
		refreshEntries()
	end

	for tabName, button in tabButtons do
		listen(button.MouseButton1Click, function()
			loadList(tabName)
		end)
	end
	listen(searchBox:GetPropertyChangedSignal("Text"), function()
		searchText = searchBox.Text
		refreshEntries()
	end)

	local stopRow = addGrayRow(drawer, "Stop music")
	local stopButton = make("TextButton", {
		Size = UDim2.fromOffset(56, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(230, 90, 90),
		Text = "STOP",
		TextColor3 = BLACK,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
	}, stopRow)
	outline(stopButton)
	listen(stopButton.MouseButton1Click, function()
		stopAllMusic()
		task.delay(0.15, refreshEntries)
	end)

	local function refreshLiveAudio()
		for _, entry in musicEntries do
			if entry.sound.Parent and entry.sound.IsPlaying then
				applyAudioSettings(entry.sound)
			end
		end
		for sound in pairs(idSounds) do
			applyAudioSettings(sound)
		end
	end

	addNumberBox(addGrayRow(drawer, "Speed (1 = normal)"), "1", function(box)
		local number = tonumber(box.Text)
		if number and number > 0 then
			musicSpeed = math.clamp(number, 0.1, 10)
		else
			musicSpeed = 1
		end
		box.Text = tostring(musicSpeed)
		refreshLiveAudio()
	end)

	addNumberBox(addGrayRow(drawer, "Pitch (1 = normal)"), "1", function(box)
		local number = tonumber(box.Text)
		if number and number > 0 then
			musicPitch = math.clamp(number, 0.1, 10)
		else
			musicPitch = 1
		end
		box.Text = tostring(musicPitch)
		refreshLiveAudio()
	end)

	-- Roblox ID sound effect: plays on top of the music, does not stop it
	local idRow = addGrayRow(drawer, "Sound effect ID")
	local idBox = make("TextBox", {
		Size = UDim2.fromOffset(150, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "Roblox sound ID",
		Text = "",
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		ClearTextOnFocus = false,
	}, idRow)
	outline(idBox)

	local idVolume = 1
	addNumberBox(addGrayRow(drawer, "Effect volume (0-10)"), "1", function(box)
		local number = tonumber(box.Text)
		if number and number >= 0 then
			idVolume = math.min(number, 10)
		end
		box.Text = tostring(idVolume)
	end)

	local idLoop = false
	addSwitch(addGrayRow(drawer, "Loop effect"), function()
		return idLoop
	end, function(value)
		idLoop = value
	end)

	local playRow = make("Frame", {
		Size = UDim2.new(1, 0, 0, SETTING_HEIGHT),
		BackgroundColor3 = GRAY,
		LayoutOrder = nextOrder(),
	}, drawer)
	outline(playRow)

	local playIdButton = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 24),
		Position = UDim2.new(0, 6, 0.5, -12),
		BackgroundColor3 = ON_COLOR,
		TextColor3 = BLACK,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Text = "PLAY ID",
	}, playRow)
	outline(playIdButton)

	local stopIdButton = make("TextButton", {
		Size = UDim2.new(0.5, -8, 0, 24),
		Position = UDim2.new(0.5, 2, 0.5, -12),
		BackgroundColor3 = Color3.fromRGB(230, 90, 90),
		TextColor3 = BLACK,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		Text = "STOP EFFECTS",
	}, playRow)
	outline(stopIdButton)

	local statusLabel = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local function stopEffects()
		for sound in pairs(idSounds) do
			pcall(function()
				sound:Stop()
				sound:Destroy()
			end)
		end
		table.clear(idSounds)
	end

	listen(playIdButton.MouseButton1Click, function()
		local id = string.match(idBox.Text, "%d+")
		if not id then
			statusLabel.Text = "Type a Roblox sound ID first (numbers only)."
			return
		end

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. id
		sound.Volume = idVolume
		sound.Looped = idLoop
		sound.Parent = SoundService
		applyAudioSettings(sound)
		idSounds[sound] = true
		statusLabel.Text = "Loading " .. id .. "..."
		sound:Play()

		if not idLoop then
			sound.Ended:Connect(function()
				idSounds[sound] = nil
				sound:Destroy()
			end)
		end

		task.spawn(function()
			local waited = 0
			while sound.Parent and not sound.IsLoaded and waited < 6 do
				task.wait(0.2)
				waited += 0.2
			end
			if not sound.Parent then return end
			if sound.IsLoaded and sound.TimeLength > 0 then
				statusLabel.Text = "Playing " .. id
			else
				idSounds[sound] = nil
				sound:Destroy()
				statusLabel.Text = "Could not load " .. id .. " (it may be private, deleted or not an audio)."
			end
		end)
	end)

	listen(stopIdButton.MouseButton1Click, function()
		stopEffects()
		statusLabel.Text = "Effects stopped."
	end)

	-- keep the Playing labels right when songs end by themselves
	task.spawn(function()
		while not destroyed and gui.Parent do
			task.wait(0.5)
			if drawer.Visible then
				refreshEntries()
			end
		end
	end)

	Custom.musicStop = function()
		stopEffects()
		stopAllMusic()
	end

	refreshTabs()
end)

-- Stat overrides (Custom Spawner): blank = game default. The key names the game expects are read from the
-- game's own "SPAWN STATISTIC" menu when it is open; otherwise these default guesses are used.
Custom.STATS = {
	{ id = "health", guess = "Health", letter = "HP" },           -- heart
	{ id = "armor", guess = "Armor", letter = "ARM" },            -- blue shield
	{ id = "resistance", guess = "Resistance", letter = "RES" },  -- green helmet
	{ id = "damage", guess = "Damage", letter = "DMG" },          -- sword
	{ id = "attackrate", guess = "AttackRate", letter = "RATE" }, -- bullets
	{ id = "range", guess = "Range", letter = "RNG" },            -- bow
	{ id = "walkspeed", guess = "Walkspeed", letter = "WALK" },   -- boot
}
Custom.statKeys = nil
Custom.statKeysDetected = false

function Custom.detectStatKeys()
	local GENERIC = {
		Frame = true, TextBox = true, TextLabel = true, ImageLabel = true, Holder = true,
		Container = true, Value = true, Amount = true, Stat = true, Input = true, Box = true,
	}
	for _, object in ipairs(playerGui:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton")) and not object:IsDescendantOf(gui)
			and string.find(string.upper(object.Text), "SPAWN STATISTIC", 1, true) then
			local container = object.Parent
			for _ = 1, 3 do
				if not container then break end
				local boxes = {}
				for _, descendant in ipairs(container:GetDescendants()) do
					if descendant:IsA("TextBox") then
						table.insert(boxes, descendant)
					end
				end
				if #boxes >= #Custom.STATS then
					-- order them like the menu: rows top to bottom, each row left to right
					table.sort(boxes, function(a, b)
						return a.AbsolutePosition.Y < b.AbsolutePosition.Y
					end)
					local rows, current, lastY = {}, nil, nil
					for _, box in ipairs(boxes) do
						local y = box.AbsolutePosition.Y
						if not current or y - lastY > 20 then
							current = {}
							table.insert(rows, current)
						end
						table.insert(current, box)
						lastY = y
					end
					local ordered = {}
					for _, row in ipairs(rows) do
						table.sort(row, function(a, b)
							return a.AbsolutePosition.X < b.AbsolutePosition.X
						end)
						for _, box in ipairs(row) do
							table.insert(ordered, box)
						end
					end

					local keys, used, good = {}, {}, true
					for index = 1, #Custom.STATS do
						local box = ordered[index]
						local cell = box
						while cell.Parent and cell.Parent ~= container do
							cell = cell.Parent
						end
						local name
						for _, candidate in ipairs({ cell.Name, box.Name }) do
							if not GENERIC[candidate] and not used[candidate] then
								name = candidate
								break
							end
						end
						if not name then
							good = false
							break
						end
						used[name] = true
						keys[Custom.STATS[index].id] = name
					end
					if good then
						return keys
					end
				end
				container = container.Parent
			end
		end
	end
	return nil
end

-- Units carry their stats as attributes (Health, Armor, AttackRate, ...). Read the exact spelling from any unit in the game.
function Custom.detectStatKeysFromUnits()
	local npcRoot = Workspace:FindFirstChild("NPCFolders")
	if not npcRoot then return nil end
	for _, folderName in ipairs({ "FriendlyFolder", "EnemyFolder", "BaseFolder" }) do
		local folder = npcRoot:FindFirstChild(folderName)
		if folder then
			for _, unit in folder:GetChildren() do
				local lowered = {}
				for name in pairs(unit:GetAttributes()) do
					lowered[string.lower(name)] = name
				end
				local keys, all = {}, true
				for _, stat in ipairs(Custom.STATS) do
					local found = lowered[string.lower(stat.guess)]
					if found then
						keys[stat.id] = found
					else
						all = false
					end
				end
				if all then
					return keys
				end
			end
		end
	end
	return nil
end

function Custom.refreshStatKeys()
	local keys = Custom.detectStatKeysFromUnits() or Custom.detectStatKeys()
	if keys then
		Custom.statKeys = keys
		Custom.statKeysDetected = true
	elseif not Custom.statKeys then
		Custom.statKeys = {}
		for _, stat in ipairs(Custom.STATS) do
			Custom.statKeys[stat.id] = stat.guess
		end
	end
	return Custom.statKeysDetected
end

function Custom.statTable(slot, camelCase)
	local result = nil
	for _, stat in ipairs(Custom.STATS) do
		local value = slot.stats[stat.id]
		if value ~= nil then
			if not Custom.statKeys then
				Custom.refreshStatKeys()
			end
			result = result or {}
			local key = Custom.statKeys[stat.id] or stat.guess
			if camelCase then
				key = string.lower(string.sub(key, 1, 1)) .. string.sub(key, 2)
			end
			result[key] = value
		end
	end
	return result or {}
end

-- Save / Load: the whole Custom Spawner (boss slot + 25 unit slots) becomes one code you can keep and paste back later.
function Custom.encodeBase64(data)
	local out = {}
	for i = 1, #data, 3 do
		local a, b, c = string.byte(data, i, i + 2)
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local c1 = math.floor(n / 262144) % 64
		local c2 = math.floor(n / 4096) % 64
		local c3 = math.floor(n / 64) % 64
		local c4 = n % 64
		out[#out + 1] = string.sub(BASE64_CHARS, c1 + 1, c1 + 1)
		out[#out + 1] = string.sub(BASE64_CHARS, c2 + 1, c2 + 1)
		out[#out + 1] = b and string.sub(BASE64_CHARS, c3 + 1, c3 + 1) or "="
		out[#out + 1] = c and string.sub(BASE64_CHARS, c4 + 1, c4 + 1) or "="
	end
	return table.concat(out)
end

function Custom.checksum(text)
	local sum = 0
	for i = 1, #text do
		sum = (sum * 31 + string.byte(text, i)) % 64
	end
	return string.sub(BASE64_CHARS, sum + 1, sum + 1)
end

-- turns an Accessory Paster SAVE code into a list of { id, bundle }
Custom.outfitCache = {}
function Custom.parseOutfit(text)
	text = string.gsub(text or "", "%s", "")
	if text == "" then return {} end
	if Custom.outfitCache[text] then return Custom.outfitCache[text] end
	if string.sub(text, 1, 4) ~= "OSA1" or #text < 7 then return nil end
	local body = string.sub(text, 5, #text - 1)
	if Custom.checksum(body) ~= string.sub(text, #text) then return nil end
	local ok, decoded = pcall(decodeBase64, body)
	if not ok or decoded == "" then return nil end
	local list, seen = {}, {}
	for _, part in ipairs(string.split(decoded, ";")) do
		local pasterData = string.match(part, "^P:(.*)$")
		if pasterData then
			for _, entry in ipairs(string.split(pasterData, "|")) do
				local id, _, _, bundle = string.match(entry, "^(%d+),(%d+),([012]),([01])$")
				if id and not seen[id .. bundle] then
					seen[id .. bundle] = true
					table.insert(list, { id = tonumber(id), bundle = bundle == "1" })
				end
			end
		else
			local id = string.match(part, "^(%d+),%d+,[01]$")
			if id and not seen[id .. "0"] and not seen[id .. "1"] then
				seen[id .. "0"] = true
				table.insert(list, { id = tonumber(id), bundle = false })
			end
		end
	end
	Custom.outfitCache[text] = list
	return list
end

-- called for every unit a slot spawns: puts the slot's outfit on it and watches for its death
function Custom.onSpawned(slot, unit)
	if slot.outfit and slot.outfit ~= "" then
		local list = Custom.parseOutfit(slot.outfit)
		if list and #list > 0 and Avatar.applyToUnit then
			pcall(Avatar.applyToUnit, unit, list, Custom.slotOutfitReplace)
		end
	end
	local death = slot.death
	if not death then return end
	local humanoid = unit:FindFirstChildOfClass("Humanoid") or unit:WaitForChild("Humanoid", 3)
	if not humanoid then return end
	while unit.Parent and humanoid.Health > 0 and not destroyed do
		task.wait(0.2)
	end
	if destroyed or not unit.Parent and humanoid.Health > 0 then return end
	if humanoid.Health > 0 then return end
	if not (death.enabled and death.id > 0) then return end
	if not (getRefs() and checkBasesValid()) then return end
	Custom.spawnGroup(death, function()
		return not destroyed
	end)
end

function Custom.slotToString(slot)
	local flags = 0
	if slot.enabled then flags += 1 end
	if slot.ally then flags += 2 end
	if slot.mode == "tumored" then flags += 4 end
	local death = slot.death or Custom.newDeath()
	if death.enabled then flags += 8 end
	local fields = { flags, slot.id, slot.limit, slot.timer, slot.strength or "" }
	for _, stat in ipairs(Custom.STATS) do
		local value = slot.stats[stat.id]
		fields[#fields + 1] = value ~= nil and tostring(value) or ""
	end
	-- spawn extra, outfit, then the "on death" battler (flags: 1 ally, 2 tumored)
	fields[#fields + 1] = tostring(slot.count or 1)
	fields[#fields + 1] = tostring(slot.extraDelay or 1)
	fields[#fields + 1] = (slot.outfit or "") ~= "" and Custom.encodeBase64(slot.outfit) or ""
	fields[#fields + 1] = tostring((death.ally and 1 or 0) + (death.mode == "tumored" and 2 or 0))
	fields[#fields + 1] = tostring(death.id)
	fields[#fields + 1] = death.strength and tostring(death.strength) or ""
	for _, stat in ipairs(Custom.STATS) do
		local value = death.stats[stat.id]
		fields[#fields + 1] = value ~= nil and tostring(value) or ""
	end
	fields[#fields + 1] = (death.outfit or "") ~= "" and Custom.encodeBase64(death.outfit) or ""
	return table.concat(fields, ",")
end

function Custom.serialize()
	local parts = { "B:" .. Custom.slotToString(Custom.boss) }
	for index, slot in ipairs(Custom.units) do
		if slot.id > 0 or not slot.enabled or next(slot.stats) ~= nil or (slot.count or 1) > 1 or (slot.outfit or "") ~= "" or (slot.death and slot.death.id > 0) then
			parts[#parts + 1] = index .. ":" .. Custom.slotToString(slot)
		end
	end
	-- the Battler sprites setup travels with the spawn cycles (older codes simply do not have this part)
	if Custom.spriteSerialize and Custom.spriteCount and Custom.spriteCount() > 0 then
		parts[#parts + 1] = "S:" .. Custom.spriteSerialize()
	end
	local body = Custom.encodeBase64(table.concat(parts, ";"))
	return "OSC1" .. body .. Custom.checksum(body)
end

function Custom.resetSlot(slot, isBoss)
	local fresh = Custom.newSlot(isBoss)
	slot.enabled = true
	slot.id = fresh.id
	slot.limit = fresh.limit
	slot.timer = fresh.timer
	slot.strength = nil
	slot.mode = "casual"
	slot.ally = false
	slot.stats = {}
	slot.count = 1
	slot.extraDelay = 1
	slot.outfit = ""
	slot.death = Custom.newDeath()
end

function Custom.slotFromString(slot, text)
	local fields = string.split(text, ",")
	local flags = tonumber(fields[1]) or 1
	slot.enabled = flags % 2 >= 1
	slot.ally = flags % 4 >= 2
	slot.mode = flags % 8 >= 4 and "tumored" or "casual"
	slot.id = math.max(0, math.floor(tonumber(fields[2]) or 0))
	slot.limit = math.max(0, math.floor(tonumber(fields[3]) or 0))
	slot.timer = math.max(0, tonumber(fields[4]) or 0)
	slot.strength = tonumber(fields[5])
	if slot.strength and slot.strength <= 0 then slot.strength = nil end
	slot.stats = {}
	for index, stat in ipairs(Custom.STATS) do
		local value = tonumber(fields[5 + index])
		if value ~= nil then
			slot.stats[stat.id] = value
		end
	end
	-- fields added later (older codes simply do not have them)
	local base = 5 + #Custom.STATS
	slot.count = math.max(1, math.floor(tonumber(fields[base + 1]) or 1))
	slot.extraDelay = math.max(0, tonumber(fields[base + 2]) or 1)
	local outfitText = fields[base + 3]
	slot.outfit = (outfitText and outfitText ~= "") and decodeBase64(outfitText) or ""
	local death = Custom.newDeath()
	death.enabled = flags % 16 >= 8
	local deathFlags = tonumber(fields[base + 4]) or 0
	death.ally = deathFlags % 2 >= 1
	death.mode = deathFlags % 4 >= 2 and "tumored" or "casual"
	death.id = math.max(0, math.floor(tonumber(fields[base + 5]) or 0))
	death.strength = tonumber(fields[base + 6])
	if death.strength and death.strength <= 0 then death.strength = nil end
	for index, stat in ipairs(Custom.STATS) do
		local value = tonumber(fields[base + 6 + index])
		if value ~= nil then
			death.stats[stat.id] = value
		end
	end
	death.enabled = death.id > 0
	local deathOutfit = fields[base + 7 + #Custom.STATS]
	death.outfit = (deathOutfit and deathOutfit ~= "") and decodeBase64(deathOutfit) or ""
	slot.death = death
end

-- returns true, or false + a reason
function Custom.deserialize(code)
	code = string.gsub(code or "", "%s", "")
	if string.sub(code, 1, 4) ~= "OSC1" or #code < 7 then
		return false, "That is not a valid code."
	end
	local body = string.sub(code, 5, #code - 1)
	if Custom.checksum(body) ~= string.sub(code, #code) then
		return false, "The code is damaged (a character is wrong or missing)."
	end

	local ok, decoded = pcall(decodeBase64, body)
	if not ok or decoded == "" then
		return false, "The code could not be read."
	end

	local slotsToApply = {}
	local spriteCode = nil
	for _, part in ipairs(string.split(decoded, ";")) do
		local name, data = string.match(part, "^(%w+):(.*)$")
		if not name then
			return false, "The code could not be read."
		end
		if name == "B" then
			slotsToApply[Custom.boss] = data
		elseif name == "S" then
			spriteCode = data
		else
			local slot = Custom.units[tonumber(name) or 0]
			if slot then
				slotsToApply[slot] = data
			end
		end
	end

	Custom.resetSlot(Custom.boss, true)
	for _, slot in ipairs(Custom.units) do
		Custom.resetSlot(slot, false)
	end
	for slot, data in pairs(slotsToApply) do
		Custom.slotFromString(slot, data)
	end
	if spriteCode and Custom.spriteLoad then
		pcall(Custom.spriteLoad, spriteCode)
	end

	Custom.boss.refreshUI()
	for _, slot in ipairs(Custom.units) do
		if slot.refreshUI then
			slot.refreshUI()
		end
	end

	return true
end

Custom.buildUI = function()
	local page = pages["Misc"]

	local iconData = {
		tumored =
			"iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAwFBMVEUAAACwA/NYAHpoAZCVBs3HAv6FBbVbAIN3A6f/AP+vAPykB9i7APp/AP/AAP68AP29AP29AP29APy9AP3FAP/B" ..
			"AP4AAP/BAP7BAP3BAP5mAnyeCOCYANycAP/AAP8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
			"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAACF/Z81AAAAMHRSTlMA/v/+/vv+/v4BB/0uAstOrItxzhCxAS1yj/7/BwZVAAAAAAAAAAAAAAAAAAAAAACRH3+wAAAEeElEQVR42u1XW5ubOgzE" ..
			"WL5gyJUkm+y25///zM5IJoGEbNu381DvtyTBaCyPRpJpmn/jfz26TSkdRill0/219aYsbQgDHP4ZeDefv2CqK5eZOWfLMOx0DMNQ5lhds9HPV59n5h/X/TY8xna8Ha/XUwHoD0ATfI55" ..
			"Ou63510xYOIMN1q5fhouOOdwZ8THeCvNbsSP493f5qirHE4NSStq7voY/XJkx9u47I/2ZTCfu6aMLnpxYV8Ubodn+uzbl+GFmJGuiE8SDk0xBwbnfJswsb0Op2YH8wjzlKPUkVPrMy42" ..
			"snOC+Rj2kwcKwAnucnShxy9Pa1dHxOK4AiEDLEkkTgxnI23TfAQAmBGoInzK+OZ9XwEyV+UqHounBCCf2gyAiQOdo4vJZ3DXJhFsVaJ7Bsg9vsM8Y5E4cdB0lzHk1vcyEQd/CfAYmSZk" ..
			"ovWedGA+tYI4GkBpDgGOwekeNKfk8azrZ/bui5ySQ/5zdwTow65KD7ogCeql6D5zkrm9E3UOSiCFsfp01wGuJ8c9iNn3NJjor8tFzsR+WoB0xLAtDykeGLqswIu18RyuPaLT+4lI3srt" ..
			"Q0emhBB4T8zBOwbWs+8C5xlbocI86QTa8MhHusBIWqB9jYCQcqlKEleJTHqF6PazfN50pzFQniSPazgj2kLqqlNZFQRXWubD9lSTt7qADIhqGbmGmO5yfqgRICpgE2QYh0VBuXTNPtiO" ..
			"/SSlyf0ZIW1dwvd3Ed0BujFwojoOJ3PyK/Z0Do8gE7uyLGYlmOLjlPwg+uthDYXW27GK4HSZbwFVKFjQ86N+JEqPYvKTda0GKsPSLAH+IwVLAAX5ck+lKT/peAI4BqsazwAi6QUgtp8E" ..
			"WJR6KGkVwLsVD94ASOu/arAfLMid/sosSYy2hRUA09u8DM8CaAjZfQegcYv+/nBVUn8HtSz5xoMp93TMhCgUdTuVOY3Cx1oUas6vD2ktL+jPShh3lo3xG4CU7pS8CKmrvYHlmA1pFYH+" ..
			"Sa8NJoftjyeA08itRU2mRBGjQSwGWEBLYRQQaVmUE0M4sx5gDU97K+CrIxqHu2U6Kwm97oFlhatrHfdsE966iaVUEiso5cmDDfob4xCFLVQ/rcCrGLWpaUajSGg5OK8cb7QkJcbSVGyN" ..
			"QqkXLbhtsiOCFaTnE1JhHFgvRSBB65J0nlXBW1vL0StHrzKaV0Vfu4vktEwrNBdOsCgjBl13ed3DUAtzbV9YTsilMmpJCAfiigzvCFeKiWrxiSeaxEMKypT2I08OvfTKwHnNHufH0zlY" ..
			"75sqsB5G7Forcub0ugNamrcqaLrL9DPDZFLIlHimFMO1eXN0hqC3tgtNhr7XI5oeNK1D8mSEpvize3f2RiyBwB3zSLNyxvi0pvj+7I5QgAfJtS3MxtRpw7k03539IekrzrHg/fPzqT5T" ..
			"CTgPl3lTXkWgEzwLyyKbhYfkcB6a39jzzQIQx314HeMN5uUP3l2U47I73vbbaewPx93wc/Ul4837zuUt8h+/ceGFa9NNY9Ph1+Xfe+ib8QuiKjFwEpZeugAAAABJRU5ErkJggg==",
		casual =
			"iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAwFBMVEX9lmP9YE/5MZD7D9r5PXj+qiv7hIr5aq73AK//AH//AAD+Z9L+oP1/AH9/AP/oEOEAAAD+uAD+APz+Afr8fQT9" ..
			"W/z5hAH+mf76Zvj6lwT8pwT9iP3+aTX+APv5GLL9APf+APv7ePv+Aff9Afn6CtL+Afj7WFL8Ecf3JfX9SPz2GPP6Nvn8Z9D9dSn6SGv4KJcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
			"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAW1qDAAAAMHRSTlP//vwK/f///wQCAf//AgJOAP8F+v7+/////////tD9MK7/TpL9cf3+/P38/P///fu8gKnAAAAD/0lEQVR42sWXaXPiMAyG" ..
			"HY6Wdq/ENiZxCDlJuPn//24lOYHcoZ3ZWX3owBQ9ll7JtszsceO8+jDwA2ZPWbhP033Cn6ivAMAtFWRBMhDEBIBHQpzO5wMgUt5LYOP+iRDnNdoBCX1ZsHEBU3FYr10XCGcg2F8C4HI8" ..
			"EMe16298lwghxdAMhA3rZ4co4NGNN2AuZhFU5awx2NDyv/ge3E8HiGBjCEchov0jAj4KwP/C8qcjCUghxCQkMAIwBPFhAKywSqJK/zWF4Mco5PkkxKMvfg8BAJ0E8BvUP/b9GEQkFRF1" ..
			"hJzAELQ3MbCe5UNYfbewfqD+m5+lAi7auooJ00mIwLr+IF62sOT1gk4++UMA8aaMw41jlzorIB1aAP6J/ndLSgRU+cPShhSXivpUk6QL+MDNk82uSiq9vGAPkggliDIxOfkYQtoB0ObL" ..
			"FlepPMdxGBHQ+/LD5AILm5Tw01lEbQD4RyK7SVje0YBg76Ta5Y0ByzQ0cWLEul0AdFha+TsK/ywZGUTzVgUTm7YGO3VS+AD9yB8cHK2dui3fjKSlqOTfFhHqL8SC/LVquqMxBpm8I8CP" ..
			"fbenjBxPn/uV1vd6AIaCAFSSyhg2AXYislwZ1wF/AIAIvk8NcWqmwO15gAl4zpgtKYc4Nn2wbwDg+NtZRsARY9DT0JiYRxsA+38mpZ4ALN9Me3ZSAEGFsNRUAI429YQqtETk9h+x204o" ..
			"gPX1oD8vwDieTCM+ASlKqF8AOMur9Q5tFIQ1AOerQOTTGSDD00ouMhGF9RMJJSisyQwc02RK5iL4KE9V9mjjFyQoN4knt1kw598EYBByWwhu/2uAfmxo7YF9FeApac41LB18brBfAGhw" ..
			"V6WXByQl6xucAPNxAGxr7ZkQ6HRp5ABlhCq8IOJQXypplX1cb6Qgy1+tgpK3DoDDLHJTSr/iD504q67WxmaaoXIvMEjDsAPAA6ldr/7NRFuhO2DMKQdPTwuAGaSdEQdvdTjUvcaFQl9a" ..
			"VwxU+FqUs0ETEOKpjio8dNBK1b8+JMyF4B3Ap7lXUIXnwUTf6gAPm1Le6yMn69xs9SxgH9Uz0ETMM6jBqjsnogoFJjEiJJRAXe8iqs2qzG5cjni3YNStDVxtcO1JecueTdAcsrCfxX0r" ..
			"S9Pt/kOTKi+aQ3dzQgEZiIAhdPqPzNqJaM4HANSPYpZL2SOEOVfyXa0JeyZVIhQzEwQKUZkJ/wr3QRA2Xw3tOdGMqRRF27a3Hcza7YcP6x+Us939llvbh+W32ayA62y/ar9a+mblOY7q" ..
			"ACmKXWlFRhM6vRamnzz4k3myjwLxNHghJLz+Dh198lQPGihXafPWM3b6zcTbTzzOv/Fy5U8b/tH023nC/j/gL1gkMJEpubccAAAAAElFTkSuQmCC",
		ally =
			"iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAwFBMVEUYofCkjlgBoP55jnvBi0IAVaoAVf8Af38AtLRQj6G6jDwAoP1Vqqr/AAD//wAAAAD+uAH3hQT8fQD8pwUBo/35" ..
			"mAMHnPUAf/8Aqf4A///PijMnls0DmvkAnf4BnPsAAP8Jl/W0jEoBnP05k7RtkY0CnPpMkagAnf2LjW+IkHAAoPxVkZlqjooVl9rjiCMDi+8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
			"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAALBiSvAAAAMHRSTlMI/a38/QMDAgP7/cQDAQEA//7///z/9wIEAf7+Ls5sARD9if37UPyw/fws/P39/w0+4gd/AAADoklEQVR42u2X2XabMBCG" ..
			"cZy0aboIWQsSIBbbgJe4ef+36wyrhGWHtKd3mXN8Yez5mE3Sr4D8owWfgP8M0BGa1vovAHmk1OSXK6Wi/AMArbof09PplBZF0T1V0VIAup+yrTGyM2OarEqfALwIACkX1YPknMtkl4AB" ..
			"Ar+Yh5TkCwAQZ/Wd8+R8KMsY7fHxsVytzwlQTiR6F/CFvG3BfV3GdGMZjePVN26KK0JwlX5q+OW1BG9KBQMTYJTi91XCt3me3wV8Qf/dCv/OWGgZE/DocOFbMmtnMMs/lXwHr6eOd2sC" ..
			"nh4lz4i6DVCk4rwGf8GuASEDwl7yCsK8AYjAX9ZQPBEy+PgIv18lT51xsABfIX7w37S18+TQEuIztCLSPoD+WhiO/uBNQ78BoYRWkCcfICIZT0qKrxbsBiAU0Ao3iREQ5ZDAAesnwjsG" ..
			"ZfjGm2BKYgRosm0TgJewOwBID5KwehmMCSguV5jAFIGgovdhThJrCSOtZwAFFTjHTvNYP08wlvZjSuOdFUIw7kCGH5xXhbgCWMvZ2F1hOJDm5ywCnOGkdP4Ib6YbDwCexwk0IpoBMv76" ..
			"2x0/XM4+AFRhBwOtHMAzeZhncBMARd3jqrQBmigjy9n8t2u6A8x+oEfeDNMY2CUQs6lrI0AQmwFKaYK+kcGwD/FdPANAqP0ciPk8x4ks3geEtxdEC4j+A4BStghAbwE2myVBQG1uRiAW" ..
			"hIBL5CWZdQHbuLQGCIA2/uoPiAFQyDYCIRZUoRukZ3cSAwODtKwIvlGGbw2uhWF0xP0uehYT7if1WATq29WEGHcJz3LW5CQv5XCiUU8ioluS7do8yOZqS8Mc1vgjVlFcn41sgGITas+W" ..
			"pvKqHyXabUbXvZtOp0SmVxHgjsD3tItg3E/tk5mNGRy5+THKhMA9mAY/9BgQTPRbS0+OvecCiMqi6U6W4Z+oUWgvToRztpk3rX1n40nK1yl7RgeRRKfxbCvgiIzAlgeZlEerfp0+ssWG" ..
			"53x3BcaWXw5efWMrDFnZUs0G5DpoeHKcSjZzh10W/TNH6jkaKSdvDb+cR40X2slQbMAZ/dU9laZQZe4fsYvYhMHajsTHHYcCujpvphOhOOkDIOrjKsazcdN3gtKX434nuamIzu8q1VZp" ..
			"NxJ0dl3vJ6trlMome3tX6rZim6RZw1GhTwaaf1sVZIHYxusJdlmlVZZtO8vgttBeOpReeGOJlOd+o5T+yKVLK7g1jRYp/XlzvWl/ADlyGeGiDV1HAAAAAElFTkSuQmCC",
		enemy =
			"iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAwFBMVEXdDgC/LwDgIAD/NyX/VTn/jmDkIQAAAAD+AQD/XADYIADyFQHvJADZHgD/YQD/AAD/xYX/NwD/RwCxAADWJgDX" ..
			"HgDMMwDXIAD/mGfXHwDZIQDXHgDWIAD/qHHXIADYIAB/AADYIAD/hlrXHgD/voDTHQDXHgD/tHr/0o3WHgD/aEf/VQD/dk/iGwDgIAD/OwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ..
			"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAACYxlWxAAAAMHRSTlMFBm////++AP///f/++/8B////Aw8yBXX/yC2NU/+S0wKx/27/D7L//1P/A/8P2ARsT29IAAAEcElEQVR42qWXaZviNgyA" ..
			"2e1uPfERE8dJIBzhGAaY8///u0qyndgJsNNWH3hCQK912JY0Y/9TZvd+0Lok0Vr/B4CubfSttLbW/wagv+Bjd6pIWnuil3X5TcAO16qOzUsnSZTar47NsXJu6T8BNJh+avbKqaJwTpzu" ..
			"78aCtt49BOxqUP+55JKTZhDiSM67awuI+wCEtz87+CcpK0ESUPgp1dayt3sACNJ6T4uT9lMiDgl2fK5HNvQAzU5brz7WJhEOLPmVJaGc9fotGs/vqDuGC8mV3QBoVnGZqgtZgEACxBiR" ..
			"eDFL9Ad1abIsB8lQTA9BguxOY4DW9pP0w9+KzGkGyTNTiMGGY2SCA7At6vtlhBmpe0bh86H40g5xdC5Y1a8vb6oTwtAKLgpfMaBmL1J5fXNH2xnhnFCyYTYC6J1dSu/AI31jnBcA2NY7" ..
			"PQC+2Do4gPpGFlPbhckNuJc5H5SsWAT4Ua7AAzRA4vrwUOSpPv0Eq4tMeh+uEUAziyHoHZh6gmxgSlEgBQH8JUpjydoQQlqPFon1oxdkDOUhSqNm6+DBsKDMEwe8SRAd4Y6mKmNACIH7" ..
			"V6yReZdcUMAUU/jdGO/EsoMXkRI58RQHQPSPAaDifXDySRSx08Efeva/YIKDBf2JBID1gN5v0e9J504UU3qBgGYEEFNA8Qggt8yHcVayxgOKGCCCC+K2BQOgZnt/EEwEEMk2+gMAT1Ic" ..
			"90eA7FsAmaiQC3mQO4Aki/kEIHMDl2tBch/QW4AnRiZHwZjJ9f4IAI4mN0Jh8mIMkFs9ewDI0/sgmwJgJ/oCdRMwuQwR8Lo4/H4dAPZjYoHEYpLohcJCgMNlflkMtUHybVWngCT2qGpA" ..
			"0AMHeJ8/zxd9qcbGo7NwIGZ4p7t9ECcCTt7TUGYo+68JgIxoIAxwFlbhThd98JOgCSixCcA1HkBYogt6epgyeau4/5rPPWDoOVqm4/sguQVdeY9K+ysANmKczBjgTDPOACyRIH1ZF39t" ..
			"ADA/DN2CoDJdAmDWccUHsjs+LoEEeD8cFhtSBzkvUN79flwhYLiVQyqH2kT36/kyH8kFXUELCFCyKhQW8AA3k+nTQYDFWN9lowfsmP3koTaGrRfv4fcNWh18eN6cRxZAe7AKJhT5uC4P" ..
			"QT+Q/kJCPH/J2AL2plseGpxRcxQBnuQ5zeOQRob3qvLbGfurfFSZvQI6cUj2gXIbCbrkqEdChukPIx6pwrWKAHiOAMLXaN+lNXGXR/kIdyAcBBEscADh2nfYBvsyAOof2GNwfrfLRQEX" ..
			"Lr99g8H7ljV0qu24053K4nx+9hbgEMJVo9/iXnnvBwV1AyLGV+Jyv19XNGEM3TpbKRlPKSLI2DdBXRrzw0s0LzC7WuKEFGKUiEgBbT3z3e4wsWgIqa5W+85NWW5UGlgqzn/aJ0bDKvXN" ..
			"1+Z4XL0oJb3wicjlx00AmVG7hw/bVn7ybNtGRQYpyt/b/ckVxl5rR2Nq6/3yJk3mhZuztx++3fhtq6aXY/ut6T3FpV9j+/4BgFyvo8GHxhsAAAAASUVORK5CYII=",
	}
	local icons = {}
	for name, data in pairs(iconData) do
		icons[name] = loadEmbeddedImage("OscarsPanel_" .. name .. ".png", data)
	end

	local statIconData = {
		walkspeed = "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",
		range = "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",
		attackrate = "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",
		damage = "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",
		resistance = "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",
		armor = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAvCAYAAAClgknJAAAJa0lEQVR42u2ZbYxcZRXHf+e5987OzuxLy3Yp7bbbd6iVt9QKBaSoRUSFGKgSDGiqJn4QiMYYvvjBGMF3jET8gCEmGmurSHhRQYwUCiGLpVhYXkqX7XZpl227u2XfZ2fm3vs8fphnZu/M3pl2twv6wSe5ye7c5+Wc5/zPOf9zLvx//HeHVPntemAj8ImY9yeBu4A3gIl5lKUO8IA7gOsivxv73Av8BcjV2iQFPADoyMK4JwCywE+AjwOrz0DwhcCNwEt2z2pnajunrZYFbgPum4MQbwCP2r9fBA7a3+LGEuCDwBbABTZVsXS1cTvwqzgFGoAue0DhpSjqGhbgJurxcxn8qQl06J/qgEkLs+M1brwFOKsWrt36JtxEEj8zSuCXoaYfWGFRgBt5sS0qvJOop+Hm71B/zXZUXSN6/CSZ3k7Cp3cSHH4Z//hhdJCPOz9tn/a54Mlbuo7E1i+SvmIbTuNZuK8/z8gD32Z8oLc45WyrwKFKBS4t86j1m/Fv+CajqXQBfY1NsGwVqUuuxz3eg/fmCzgvPclk116Cd7rOyHsVULfqIpzLbyTc8jny7RuYVAXkL9yyjZaOR5gc6EUXprvA1jgFLopCx936JcYb0uBHYoGGjKOgfS3OyrU4W27CHTzKgtefJ3v0AMHRA7iHOzF+FmN0YU2VodvOhbUbSbUswVt5ISOrLiRY1IbvWHCE09opx61c/kng11EFFgLJ4lvXqyO9diNjYczJNgaFQJhIwLI15JatAQOioTGXwfPzmCAPpooGymG4YQFZzyUnBdCbYpwJyqdOANLajkGI3MhqK/NwUYH10fCkmlrItrSV5gvwAT9PkwhjrscwcAx7YGRbAwwmU5BMnRo3VmBzimm+gHfl53Ef+hl+PhONZOuBjqICm21kKOy9/jJGGxeWNlmkQ241msVugjxwzBj2AfuAkyKlIF2mzSwyqQJSGC5CaDaGUR2yVznkRUDD+JI1eEvX4Pe+WlzWYmUuKdAU9QdJN2FQJWHOF8VSN1HwDWCNCGuAj4Y+h5VLIEJnGHLCaLQojAhGTpH+jaHRwIccRQqhNdSsVgpXCb4RFPCsvZCpZD2Nmz4F0wq4wIJKJ54OZfWN5NX0ba4QwRGphCeLHY8lVqDNGCaMJrQWMbU0AMRAEkOjXW8cp+BXBuqUw+qiAoAoSLdvYLzcwLq6AunmMpfR1SJJ5J3juCxwXWQWEDKRYFO5r2sMYi8DBU7LUpyZPh6vgPLqKXf60xPGGOZtLPRzSKLORh8QN4HECKVm42hSg8LO91DGnNYFxlqAsNxQGaAbOGLNu9LGXOd/oB6IVcCfGivBQYDdwONWEQHOA24Bltfwj/drxEIon5sqmc9YajkZIeVvAwOzD/lzrrBmrUBw9gpMDe84pxYXPgPBDRHqJTJ3CJlkesZVNNj8vdJWIG3zLHwG6AQGgbWAL4oyHcIw1uZunOXUQC9hBNwLdMjNOuQ8L0GzKTivnkcIKaAHeAgYAdYBm5RCIYU8YcD4uVh/KwJlKiqPu+/v1OemSmo5oliuHM42hQXvheOOAcMWQieBAeWUXZCZJnKxCjwIvFWyVn83Cwf7SgoEImTshibG/NFnLsPYEmuTheilQINIGUEMx0dqWqCnyJALcPPJDRwpSZQB+nWINqYkqLI0YMjmiKO2pTBXBZYCNwFfBq61NWlRYKMhN9QXC9moEydKXCTwyR7rRtRWTFgw64ui+LClrTlrrues8BmgGbgauNxuNBv/CIFxezHtQDYM6RQBpUoaZgcOVy5zKhV4C7isMN9gOh4mdc12Jr06MDAkwrAOCcXhGeAp63DFMQ68DFxsO1SzUeAV4B/2Iq4GFilFTwSjTROj5Dr3RJdkrdHL8sD3o2QvONCBu/8pxCv8f8Jm49/YBtBIjCDN9kbMLMJnHnjNNpKO2EsYEUGKMVRBsr+bYPhEZR/qwUoFem0gKGTjzBjuviepC2zNCnQoh/0VlFaARbZL9TGLXTML7Du2uE3Zv9PGcMBoxkoNBpg8tJ8wyFZaYKQSQgHwQ+DnpVkH/4UMHYfWcyCcGT6bgY8AVwCL7Wb6NG++VHvYPVpsCG02hp1KFfYRSOd95IVHMeVcvasalegoU7N7H+nXnqMyqzuW0G0HPmuz8unmB2Oz7YsW+2OWllxhmz3HjGEgcpAa7MPvO1hG1SzcYxXoiVRyhDrEf/geUpmpsmtbbgy3as0mG3H0LDA/AewBdgB/tIpYlDIYhux2phOYq4C9fyN/rKdym75qCgwAv42G9PGuvSR37yDaW+oT4Vk0GR3OOnnl7Okjtnnaby/AN4Z/KsVg5Pa9gUHMnl1oU1Z4Hoi6WVxNcsj255eUuiQ9r9CwbjNTbctLvtAripzWrMOQFHVajisR2vCudf5LgGXGsFtrHleqFCDEheaOxxh77JeV+L/dBq6qCuRsWN9W8u7MKN7YEM7GT+MnC3nBAIeUYlIblotQD7jWWcwp6O85RcKGYTnCM8bwiOMwFcFF47tDBPd+jdxwWZN7D/Ajy92qKoDV8AYbXAqec+wQST+PXHgVYQRPR5SiS4QpY/BESOiQpKiq0BIbMpt0yDvG8FeEPUpNY1bAMyHOn3/K5HN/ii6dAn5QGWhqlbX7bXBoLRIS/+Be0loj519J4DklSwwDB0V4Beg2kBdhOAxww4CU45SRPQfoD0N+L8ITStErMt1accAzUP/EA2R23oUu/y7wKnCnjUKnXcHdCfy4jP2JkPrM1wlu+S5+a2uhzghnMkRlDGcBF1TEYGX5UyWzEQ/SQ0O4D9/D2GP3obMzPr99AdgVS4hqjLdtJ3h9NI7nu/aR6H6JpJuivnkxJpUijHTyDKBFmBThsBW2+PRU0hAB5UHDwf14v/gqY0/viPtw8jvg7rnW0K2WAl03wyHrUiTbN+Cu24Rz3W2MrdhA4KoS9YgtICpOTwaGxNM7yO66m3zfm3GzXrYM+8SZNAFaLc3YHmc1AZz6JryLt5K+4CrctnMZXnYuQaoZ5Xoox5umxlHzT7xL4867GXrifkI9o8k4agnbHbVKjdnmoa8A36LwlbHqcABZshbVshQv2YCbTCOOV0EpDP47XWQP/Rs9syc5AHwjDvPzMVZR+Bzbb3OGmeen3zrsez7qgWXA/cDz1jfPRPAA+J7d9z1rhNUa19qKTtn8sZ7IZ9saoxN4xAapP1TG+fdTgUqnX2zpzqlGr33mNP4DynCL0qFeG6AAAAAASUVORK5CYII=",
		health = "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",
	}
	local statIcons = {}
	for name, data in pairs(statIconData) do
		statIcons[name] = loadEmbeddedImage("OscarsPanel_stat_" .. name .. ".png", data)
	end

	-- small square button that shows one of the face icons (or a letter if images are unavailable)
	local function addIconButton(row, offsetFromRight)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(30, 30),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offsetFromRight, 0.5, 0),
			BackgroundColor3 = WHITE,
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, row)
		outline(button)
		local image = make("ImageLabel", {
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.fromOffset(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Visible = false,
		}, button)
		return button, image
	end

	local function showIcon(button, image, asset, fallbackText)
		if asset then
			image.Image = asset
			image.Visible = true
			button.Text = ""
		else
			image.Visible = false
			button.Text = fallbackText
		end
	end

	local function valueText(slot, key)
		local value = slot[key]
		if key == "strength" then
			return value and tostring(value) or "0"
		end
		return tostring(value)
	end

	local function commitValue(slot, key, text)
		local number = tonumber(text)
		if key == "id" or key == "limit" then
			if number and number >= 0 then
				slot[key] = math.floor(number)
			end
		elseif key == "timer" then
			if number and number >= 0 then
				slot[key] = number
			end
		elseif key == "strength" then
			slot.strength = (number and number > 0) and number or nil
		end
	end

	local FIELD_LABELS = { id = "ID", limit = "Limit", timer = "Timer (s)", strength = "Strength" }

	local function addSlotBlock(outer, slot, title, keys)
		-- every slot is its own little box: a header row that is always visible (name, ID, ON/OFF, icons)
		-- and a body with all the settings that opens with the arrow button
		local wrapper = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, outer)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, wrapper)
		make("UIPadding", { PaddingBottom = UDim.new(0, 8) }, wrapper)

		local header = addGrayRow(wrapper, title)
		local titleLabel = header:FindFirstChildOfClass("TextLabel")
		if titleLabel then
			titleLabel.Size = UDim2.new(1, -170, 1, 0)
			titleLabel.TextSize = 12
			titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		end

		local parent = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			LayoutOrder = nextOrder(),
		}, wrapper)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, parent)

		local expandButton = make("TextButton", {
			Size = UDim2.fromOffset(30, 30),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -126, 0.5, 0),
			BackgroundColor3 = WHITE,
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Text = "v",
		}, header)
		outline(expandButton)
		listen(expandButton.MouseButton1Click, function()
			parent.Visible = not parent.Visible
			expandButton.Text = parent.Visible and "^" or "v"
		end)

		local function refreshTitle()
			if titleLabel then
				titleLabel.Text = title .. (slot.id > 0 and ("  -  ID " .. tostring(slot.id)) or "  -  empty")
					.. ((slot.count or 1) > 1 and ("  x" .. tostring(slot.count)) or "")
			end
			header.BackgroundColor3 = (slot.id > 0 and slot.enabled) and Color3.fromRGB(200, 225, 200) or GRAY
		end
		slot.refreshTitle = refreshTitle
		local teamButton, teamImage = addIconButton(header, 8)
		local modeButton, modeImage = addIconButton(header, 44)

		-- slot switch (ON/OFF)
		local switchButton = make("TextButton", {
			Size = UDim2.fromOffset(40, 30),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -80, 0.5, 0),
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, header)
		outline(switchButton)
		local function refreshSwitch()
			switchButton.Text = slot.enabled and "ON" or "OFF"
			switchButton.BackgroundColor3 = slot.enabled and ON_COLOR or WHITE
		end
		refreshSwitch()
		listen(switchButton.MouseButton1Click, function()
			slot.enabled = not slot.enabled
			refreshSwitch()
			refreshTitle()
		end)

		local function refreshTeam()
			if slot.ally then
				showIcon(teamButton, teamImage, icons.ally, "ALLY")
			else
				showIcon(teamButton, teamImage, icons.enemy, "FOE")
			end
		end
		local function refreshMode()
			if slot.mode == "tumored" then
				showIcon(modeButton, modeImage, icons.tumored, "TUM")
			else
				showIcon(modeButton, modeImage, icons.casual, "CAS")
			end
		end
		refreshTeam()
		refreshMode()

		listen(teamButton.MouseButton1Click, function()
			slot.ally = not slot.ally
			refreshTeam()
		end)
		listen(modeButton.MouseButton1Click, function()
			slot.mode = slot.mode == "tumored" and "casual" or "tumored"
			refreshMode()
		end)

		local fieldsRow = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = nextOrder(),
		}, parent)
		outline(fieldsRow)

		local count = #keys
		local fieldBoxes, statBoxes = {}, {}
		for index, key in ipairs(keys) do
			local column = make("Frame", {
				Size = UDim2.new(1 / count, 0, 1, 0),
				Position = UDim2.new((index - 1) / count, 0, 0, 0),
				BackgroundTransparency = 1,
			}, fieldsRow)
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 3),
				BackgroundTransparency = 1,
				Text = FIELD_LABELS[key],
				TextColor3 = BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, column)
			local box = make("TextBox", {
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.fromOffset(6, 22),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				TextSize = 15,
				Font = Enum.Font.GothamBold,
				Text = valueText(slot, key),
				ClearTextOnFocus = false,
			}, column)
			outline(box)
			fieldBoxes[key] = box
			listen(box.FocusLost, function()
				local oldValue = slot[key]
				commitValue(slot, key, box.Text)
				box.Text = valueText(slot, key)
				refreshTitle()
				if slot == Custom.boss and key == "id" and slot.id ~= oldValue and slot.id > 0 then
					Custom.spawnBoss()
				end
			end)
		end

		-- stat changers: heart, shield, armor, sword, bullets, bow, boot. Blank = the game's default.
		local statsRow = make("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundColor3 = GRAY,
			LayoutOrder = nextOrder(),
		}, parent)
		outline(statsRow)
		local statCount = #Custom.STATS
		for index, stat in ipairs(Custom.STATS) do
			local column = make("Frame", {
				Size = UDim2.new(1 / statCount, 0, 1, 0),
				Position = UDim2.new((index - 1) / statCount, 0, 0, 0),
				BackgroundTransparency = 1,
			}, statsRow)
			local asset = statIcons[stat.id]
			if asset then
				make("ImageLabel", {
					Size = UDim2.fromOffset(22, 22),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 3),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					Image = asset,
				}, column)
			else
				make("TextLabel", {
					Size = UDim2.new(1, 0, 0, 22),
					Position = UDim2.fromOffset(0, 3),
					BackgroundTransparency = 1,
					Text = stat.letter,
					TextColor3 = BLACK,
					TextSize = 11,
					Font = Enum.Font.GothamBold,
				}, column)
			end
			local statBox = make("TextBox", {
				Size = UDim2.new(1, -6, 0, 24),
				Position = UDim2.fromOffset(3, 27),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				PlaceholderText = "-",
				PlaceholderColor3 = GRAY,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				Text = slot.stats[stat.id] and tostring(slot.stats[stat.id]) or "",
				ClearTextOnFocus = false,
			}, column)
			outline(statBox)
			statBoxes[stat.id] = statBox
			listen(statBox.FocusLost, function()
				local number = tonumber(statBox.Text)
				slot.stats[stat.id] = number
				statBox.Text = number and tostring(number) or ""
			end)
		end

		-- ===== extras: spawn extra, outfit, on death =====
		local extraRefresh = {}

		local function addFieldsRow(target, defs)
			local row = make("Frame", {
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = GRAY,
				LayoutOrder = nextOrder(),
			}, target)
			outline(row)
			local boxes = {}
			for index, def in ipairs(defs) do
				local column = make("Frame", {
					Size = UDim2.new(def.width, 0, 1, 0),
					Position = UDim2.new(def.x, 0, 0, 0),
					BackgroundTransparency = 1,
				}, row)
				make("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					Position = UDim2.fromOffset(0, 3),
					BackgroundTransparency = 1,
					Text = def.label,
					TextColor3 = BLACK,
					TextSize = 11,
					Font = Enum.Font.GothamBold,
				}, column)
				local box = make("TextBox", {
					Size = UDim2.new(1, -12, 0, 24),
					Position = UDim2.fromOffset(6, 22),
					BackgroundColor3 = WHITE,
					TextColor3 = BLACK,
					PlaceholderText = def.placeholder or "",
					PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
					TextSize = def.textSize or 15,
					TextXAlignment = def.left and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
					ClipsDescendants = true,
					Font = def.left and Enum.Font.Code or Enum.Font.GothamBold,
					Text = def.get(),
					ClearTextOnFocus = false,
				}, column)
				outline(box)
				boxes[index] = box
				listen(box.FocusLost, function()
					def.set(box.Text, box)
					box.Text = def.get()
				end)
			end
			table.insert(extraRefresh, function()
				for index, def in ipairs(defs) do
					boxes[index].Text = def.get()
				end
			end)
		end

		local function checkedOutfit(text, box)
			text = string.gsub(text or "", "%s", "")
			if text ~= "" and Custom.parseOutfit(text) == nil then
				box.PlaceholderText = "not a valid accessory code"
				return ""
			end
			box.PlaceholderText = "paste outfit code"
			return text
		end

		local extrasRow = addGrayRow(parent, "More: spawn extra / outfit / on death")
		local extrasButton = make("TextButton", {
			Size = UDim2.fromOffset(70, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "OPEN",
		}, extrasRow)
		outline(extrasButton)

		local extraFrame = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = false,
			LayoutOrder = nextOrder(),
		}, parent)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, extraFrame)
		listen(extrasButton.MouseButton1Click, function()
			extraFrame.Visible = not extraFrame.Visible
			extrasButton.Text = extraFrame.Visible and "CLOSE" or "OPEN"
		end)

		addFieldsRow(extraFrame, {
			{ label = "Spawn count", x = 0, width = 0.25,
				get = function() return tostring(slot.count) end,
				set = function(text)
					local number = tonumber(text)
					if number and number >= 1 then slot.count = math.floor(number) end
					refreshTitle()
				end },
			{ label = "Extra delay (s)", x = 0.25, width = 0.25,
				get = function() return tostring(slot.extraDelay) end,
				set = function(text)
					local number = tonumber(text)
					if number and number >= 0 then slot.extraDelay = number end
				end },
			{ label = "Outfit code (from Accessory Paster)", x = 0.5, width = 0.5, left = true, textSize = 11, placeholder = "paste outfit code",
				get = function() return slot.outfit end,
				set = function(text, box) slot.outfit = checkedOutfit(text, box) end },
		})

		-- on death
		local death = slot.death
		local deathHeader = addGrayRow(extraFrame, "On death: summon this ID")
		local deathTeamButton, deathTeamImage = addIconButton(deathHeader, 8)
		local deathModeButton, deathModeImage = addIconButton(deathHeader, 44)
		-- the ID box IS the on/off: 0 or empty = nothing happens, an ID = that battler is summoned when this one dies
		local deathIdBox = make("TextBox", {
			Size = UDim2.fromOffset(70, 30),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -80, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			PlaceholderText = "ID",
			PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Text = "",
			ClearTextOnFocus = false,
		}, deathHeader)
		outline(deathIdBox)
		local deathTitle = deathHeader:FindFirstChildOfClass("TextLabel")
		if deathTitle then
			deathTitle.Size = UDim2.new(1, -160, 1, 0)
			deathTitle.TextSize = 12
		end
		local function refreshDeathHeader()
			death = slot.death
			death.enabled = death.id > 0
			deathIdBox.Text = death.id > 0 and tostring(death.id) or ""
			if death.ally then
				showIcon(deathTeamButton, deathTeamImage, icons.ally, "ALLY")
			else
				showIcon(deathTeamButton, deathTeamImage, icons.enemy, "FOE")
			end
			if death.mode == "tumored" then
				showIcon(deathModeButton, deathModeImage, icons.tumored, "TUM")
			else
				showIcon(deathModeButton, deathModeImage, icons.casual, "CAS")
			end
		end
		refreshDeathHeader()
		table.insert(extraRefresh, refreshDeathHeader)
		listen(deathIdBox.FocusLost, function()
			local number = tonumber(deathIdBox.Text)
			slot.death.id = (number and number > 0) and math.floor(number) or 0
			refreshDeathHeader()
		end)
		listen(deathTeamButton.MouseButton1Click, function()
			slot.death.ally = not slot.death.ally
			refreshDeathHeader()
		end)
		listen(deathModeButton.MouseButton1Click, function()
			slot.death.mode = slot.death.mode == "tumored" and "casual" or "tumored"
			refreshDeathHeader()
		end)

		addFieldsRow(extraFrame, {
			{ label = "Strength", x = 0, width = 0.3,
				get = function() return slot.death.strength and tostring(slot.death.strength) or "0" end,
				set = function(text)
					local number = tonumber(text)
					slot.death.strength = (number and number > 0) and number or nil
				end },
			{ label = "Outfit code", x = 0.3, width = 0.7, left = true, textSize = 11, placeholder = "paste outfit code",
				get = function() return slot.death.outfit end,
				set = function(text, box) slot.death.outfit = checkedOutfit(text, box) end },
		})

		local deathStatsRow = make("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundColor3 = GRAY,
			LayoutOrder = nextOrder(),
		}, extraFrame)
		outline(deathStatsRow)
		local deathStatBoxes = {}
		for index, stat in ipairs(Custom.STATS) do
			local column = make("Frame", {
				Size = UDim2.new(1 / #Custom.STATS, 0, 1, 0),
				Position = UDim2.new((index - 1) / #Custom.STATS, 0, 0, 0),
				BackgroundTransparency = 1,
			}, deathStatsRow)
			local asset = statIcons[stat.id]
			if asset then
				make("ImageLabel", {
					Size = UDim2.fromOffset(22, 22),
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 3),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
					Image = asset,
				}, column)
			else
				make("TextLabel", {
					Size = UDim2.new(1, 0, 0, 22),
					Position = UDim2.fromOffset(0, 3),
					BackgroundTransparency = 1,
					Text = stat.letter,
					TextColor3 = BLACK,
					TextSize = 11,
					Font = Enum.Font.GothamBold,
				}, column)
			end
			local statBox = make("TextBox", {
				Size = UDim2.new(1, -6, 0, 24),
				Position = UDim2.fromOffset(3, 27),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				PlaceholderText = "-",
				PlaceholderColor3 = GRAY,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				Text = slot.death.stats[stat.id] and tostring(slot.death.stats[stat.id]) or "",
				ClearTextOnFocus = false,
			}, column)
			outline(statBox)
			deathStatBoxes[stat.id] = statBox
			listen(statBox.FocusLost, function()
				local number = tonumber(statBox.Text)
				slot.death.stats[stat.id] = number
				statBox.Text = number and tostring(number) or ""
			end)
		end
		table.insert(extraRefresh, function()
			for statId, box in deathStatBoxes do
				box.Text = slot.death.stats[statId] ~= nil and tostring(slot.death.stats[statId]) or ""
			end
		end)

		-- used by Load to redraw everything in this slot
		slot.refreshUI = function()
			for _, refreshExtra in ipairs(extraRefresh) do
				refreshExtra()
			end
			refreshTitle()
			refreshTeam()
			refreshMode()
			refreshSwitch()
			for key, box in fieldBoxes do
				box.Text = valueText(slot, key)
			end
			for statId, box in statBoxes do
				box.Text = slot.stats[statId] ~= nil and tostring(slot.stats[statId]) or ""
			end
		end
	end

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, page)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, container)

	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = WHITE,
		LayoutOrder = 1,
	}, container)
	outline(header, 3)

	local nameButton = make("TextButton", {
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Text = "Custom Spawner",
		TextColor3 = BLACK,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
	}, header)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, nameButton)

	local function refreshHeader()
		header.BackgroundColor3 = Custom.on and ON_COLOR or WHITE
	end
	listen(nameButton.MouseButton1Click, function()
		Custom.setEnabled(not Custom.on)
		refreshHeader()
	end)

	local drawer = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 2,
	}, container)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)

	-- Save / Load
	local saveRow = addGrayRow(drawer, "Save / Load setup")
	local function makeSmallButton(text, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, saveRow)
		outline(button)
		return button
	end
	local loadButton = makeSmallButton("LOAD", 8)
	local saveButton = makeSmallButton("SAVE", 68)

	local codeRow = addGrayRow(drawer, "Code")
	local codeBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "save to get a code / paste one here",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, codeRow)
	outline(codeBox)

	local saveStatus = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	listen(saveButton.MouseButton1Click, function()
		local code = Custom.serialize()
		codeBox.Text = code
		local copied = false
		copied = Custom.copy(code)
		saveStatus.Text = copied and "Saved! The code is in the box and copied to your clipboard." or "Saved! Copy the code from the box (tap it, select all, copy)."
	end)

	listen(loadButton.MouseButton1Click, function()
		local ok, reason = Custom.deserialize(codeBox.Text)
		saveStatus.Text = ok and "Loaded!" or ("Could not load: " .. tostring(reason))
	end)

	addSwitch(addGrayRow(drawer, "Outfits: remove old accessories first"), function()
		return Custom.slotOutfitReplace
	end, function(value)
		Custom.slotOutfitReplace = value
	end)

	local detectRow = addGrayRow(drawer, "Stat names: default guesses")
	local detectButton = make("TextButton", {
		Size = UDim2.fromOffset(70, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "DETECT",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, detectRow)
	outline(detectButton)
	local detectLabel = detectRow:FindFirstChildOfClass("TextLabel")
	listen(detectButton.MouseButton1Click, function()
		local found = Custom.refreshStatKeys()
		if detectLabel then
			detectLabel.Text = found and "Stat names: read from game menu" or "Stat names: not found, using guesses"
		end
		if found then
			local parts = {}
			for _, stat in ipairs(Custom.STATS) do
				table.insert(parts, stat.id .. "=" .. tostring(Custom.statKeys[stat.id]))
			end
			print("Oscar's Cool Panel stat names: " .. table.concat(parts, ", "))
		end
	end)

	addSlotBlock(drawer, Custom.boss, "Boss Slot", { "id", "timer", "strength" })
	for index, slot in ipairs(Custom.units) do
		addSlotBlock(drawer, slot, "Unit Slot " .. index, { "id", "limit", "timer", "strength" })
	end

	local chevron = make("TextButton", {
		Size = UDim2.new(0, 44, 1, 0),
		Position = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Text = ">",
		TextColor3 = BLACK,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
	}, header)
	listen(chevron.MouseButton1Click, function()
		drawer.Visible = not drawer.Visible
		chevron.Text = drawer.Visible and "v" or ">"
	end)
end
-- Rename Stage + Puzzles (Misc tab)
-- Rename Stage: keeps the stage name on the battle screen on whatever you type.
-- Puzzles: spawn cycle made by Delifell ("you have to solve my puzzles one to get in ULTRA").
safeBuild("Rename Stage / Puzzles", function()
	local page = pages["Misc"]

	-- ===== Rename Stage =====
	local rename = { on = false, name = "Da fac", token = 0 }
	Custom.rename = rename

	local function stopRename()
		rename.on = false
		rename.token += 1
	end

	local function startRename()
		stopRename()
		rename.on = true
		local token = rename.token
		task.spawn(function()
			while rename.on and rename.token == token and not destroyed do
				local battleScreen = playerGui:FindFirstChild("BattleScreen")
				local stageName = battleScreen and battleScreen:FindFirstChild("StageName")
				if stageName and stageName.Text ~= rename.name then
					pcall(function()
						stageName.Text = rename.name
					end)
				end
				task.wait()
			end
		end)
	end
	Custom.renameStop = stopRename

	local renameDrawer = addToggleCogRow(page, "Rename Stage", function()
		return rename.on
	end, function(value)
		if value then
			startRename()
		else
			stopRename()
		end
	end)

	local nameRow = addGrayRow(renameDrawer, "Stage name")
	local nameBox = make("TextBox", {
		Size = UDim2.fromOffset(150, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Text = rename.name,
		ClearTextOnFocus = false,
	}, nameRow)
	outline(nameBox)
	listen(nameBox.FocusLost, function()
		rename.name = nameBox.Text
	end)

	-- ===== Puzzles (by Delifell) =====
	local puzzle = { on = false, form = "A", magnification = 11.1, spawnRate = 1, limit = 3, token = 0, cycle = nil }
	Custom.puzzle = puzzle

	local npcRoot = Workspace:WaitForChild("NPCFolders", 10)
	local friendlyFolder = npcRoot and npcRoot:FindFirstChild("FriendlyFolder")
	local baseFolder = npcRoot and npcRoot:FindFirstChild("BaseFolder")
	local settingsRemote = SandboxSettings
	local spawnRemote = SandboxSpawn

	local function countAlive(names, skipNoClog)
		local count = 0
		if not friendlyFolder then return 0 end
		for _, unit in friendlyFolder:GetChildren() do
			if (not names or names[unit.Name]) and not unit:GetAttribute("ConfusedTime")
				and not (skipNoClog and unit:GetAttribute("NoClog")) then
				local humanoid = unit:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					count += 1
				end
			end
		end
		return count
	end

	local BALLERS = { ["Baller Battler"] = true, ["Soccer Battler"] = true }

	local function spawnLimited(entry, token)
		while puzzle.on and puzzle.token == token and countAlive(nil, true) >= puzzle.limit do
			task.wait(0.1)
		end
		if puzzle.on and puzzle.token == token then
			pcall(function()
				spawnRemote:InvokeServer(table.unpack(entry))
			end)
		end
	end

	local function runCycle(token)
		local mag, form = puzzle.magnification, puzzle.form
		local boss = { "Enemy", 5, form, mag }
		local enemy1 = { "Enemy", 12, form, mag }
		local enemy2 = { "Enemy", 5, form, mag }
		local enemy3 = { "Enemy", 121, "B", mag, { Health = 1000000, Damage = 1000000, WalkSpeed = 50, AttackRate = 0 } }
		local enemy4 = { "Enemy", 44, form, mag }
		local rate = puzzle.spawnRate

		local function alive()
			return puzzle.on and puzzle.token == token
		end
		local function ballerCheck()
			if countAlive(BALLERS) < 1 then
				task.wait(999 / rate)
				if alive() and countAlive(BALLERS) < 1 then
					spawnLimited(enemy2, token)
				end
			end
		end

		spawnLimited(boss, token)
		while alive() do
			for _ = 1, 3 do
				task.wait(1 / rate)
				if not alive() then return end
				spawnLimited(enemy1, token)
			end
			ballerCheck()
			for _ = 1, 16 do
				task.wait(0.1 / rate)
				if not alive() then return end
				spawnLimited(enemy3, token)
			end
			task.wait(0.1 / rate)
			if not alive() then return end
			spawnLimited(enemy4, token)
			ballerCheck()
		end
	end

	local function stopPuzzle()
		puzzle.on = false
		puzzle.token += 1
		if puzzle.cycle then
			pcall(task.cancel, puzzle.cycle)
			puzzle.cycle = nil
		end
	end

	local function sandboxBase()
		local base = baseFolder and baseFolder:FindFirstChild("Blue Base")
		return base and base:GetAttribute("Sandbox") and base or nil
	end

	local function startPuzzle()
		stopPuzzle()
		puzzle.on = true
		local token = puzzle.token
		-- starts when the sandbox base exists (like the original script), restarts if you leave and come back
		task.spawn(function()
			local running = false
			while puzzle.on and puzzle.token == token and not destroyed do
				local base = sandboxBase()
				if base and not running then
					running = true
					pcall(function()
						settingsRemote:InvokeServer("SpawnTeamsSwap", true)
						settingsRemote:InvokeServer("EnableHealthBars", true)
					end)
					puzzle.cycle = task.spawn(runCycle, token)
				elseif not base and running then
					running = false
					if puzzle.cycle then
						pcall(task.cancel, puzzle.cycle)
						puzzle.cycle = nil
					end
				end
				task.wait(0.5)
			end
		end)
	end
	Custom.puzzleStop = stopPuzzle

	local puzzleDrawer = addToggleCogRow(page, "Puzzles (Delifell)", function()
		return puzzle.on
	end, function(value)
		if value then
			startPuzzle()
		else
			stopPuzzle()
		end
	end)

	local formRow = addGrayRow(puzzleDrawer, "Form (A / B)")
	local formButton = make("TextButton", {
		Size = UDim2.fromOffset(56, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Text = puzzle.form,
	}, formRow)
	outline(formButton)
	listen(formButton.MouseButton1Click, function()
		puzzle.form = puzzle.form == "A" and "B" or "A"
		formButton.Text = puzzle.form
	end)

	addNumberBox(addGrayRow(puzzleDrawer, "Magnification"), tostring(puzzle.magnification), function(box)
		local number = tonumber(box.Text)
		puzzle.magnification = (number and number > 0) and number or 11.1
		box.Text = tostring(puzzle.magnification)
	end)
	addNumberBox(addGrayRow(puzzleDrawer, "Spawn rate"), tostring(puzzle.spawnRate), function(box)
		local number = tonumber(box.Text)
		puzzle.spawnRate = (number and number > 0) and number or 1
		box.Text = tostring(puzzle.spawnRate)
	end)
	addNumberBox(addGrayRow(puzzleDrawer, "Unit limit"), tostring(puzzle.limit), function(box)
		local number = tonumber(box.Text)
		puzzle.limit = (number and number >= 1) and math.floor(number) or 3
		box.Text = tostring(puzzle.limit)
	end)

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "Switch it OFF and ON again after changing these.\nCredits: made by Delifell",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, puzzleDrawer)
end)

safeBuild("Custom Spawner", Custom.buildUI)

-- Battle Counter (Misc tab): small on-screen counter of living units (blue) and enemies (red)
safeBuild("Battle Counter", function()
	local page = pages["Misc"]
	local counter = { on = false, token = 0, gui = nil }
	Custom.counter = counter

	local function stopCounter()
		counter.on = false
		counter.token += 1
		if counter.gui then
			pcall(function()
				counter.gui:Destroy()
			end)
			counter.gui = nil
		end
	end

	local function aliveIn(folder)
		local count = 0
		if folder then
			for _, unit in folder:GetChildren() do
				local humanoid = unit:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					count += 1
				end
			end
		end
		return count
	end

	local function startCounter()
		stopCounter()
		counter.on = true
		local token = counter.token
		local hud = make("ScreenGui", { Name = "OscarsCounter", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60 }, playerGui)
		counter.gui = hud
		local box = make("Frame", {
			Size = UDim2.fromOffset(190, 34),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 6),
			BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			BackgroundTransparency = 0.25,
		}, hud)
		make("UICorner", { CornerRadius = UDim.new(0, 8) }, box)
		local blue = make("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(110, 170, 255),
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Text = "BLUE 0",
		}, box)
		local red = make("TextLabel", {
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.fromScale(0.5, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 110, 110),
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Text = "RED 0",
		}, box)
		task.spawn(function()
			while counter.on and counter.token == token and not destroyed do
				local npcRoot = Workspace:FindFirstChild("NPCFolders")
				blue.Text = "BLUE " .. aliveIn(npcRoot and npcRoot:FindFirstChild("FriendlyFolder"))
				red.Text = "RED " .. aliveIn(npcRoot and npcRoot:FindFirstChild("EnemyFolder"))
				task.wait(0.4)
			end
		end)
	end
	Custom.counterStop = stopCounter

	addSwitch(addGrayRow(page, "Battle Counter (alive units / enemies)"), function()
		return counter.on
	end, function(value)
		if value then
			startCounter()
		else
			stopCounter()
		end
	end)
end)

-- Size Changer (Misc tab): resizes everything on a battler (body, weapons, accessories ...) with Model:ScaleTo.
-- Press ADD for each setting (up to 50). Every setting has its own ID, size, team, max units and ON/OFF, and can be removed.
safeBuild("Size Changer", function()
	local page = pages["Misc"]
	local MAX_ENTRIES = 50
	local size = { loop = false, token = 0, entries = {}, units = setmetatable({}, { __mode = "k" }) }
	Custom.size = size

	local function folderFor(ally)
		local npcRoot = Workspace:FindFirstChild("NPCFolders")
		return npcRoot and npcRoot:FindFirstChild(ally and "FriendlyFolder" or "EnemyFolder")
	end

	local function matches(entry, unit)
		if not unit:IsA("Model") then return false end
		if entry.id > 0 and tonumber(unit:GetAttribute("ID")) ~= entry.id then return false end
		local humanoid = unit:FindFirstChildOfClass("Humanoid")
		return not humanoid or humanoid.Health > 0
	end

	-- the server decides where a battler stands, so a bigger / smaller body would sink into the floor or hover.
	-- The root joint is moved up / down by exactly the difference so the feet stay on the ground.
	local function findRootJoint(unit)
		local root = unit:FindFirstChild("HumanoidRootPart")
		if root then
			local joint = root:FindFirstChildWhichIsA("Motor6D")
			if joint then return root, joint end
		end
		local lower = unit:FindFirstChild("LowerTorso")
		local joint = lower and lower:FindFirstChild("Root")
		return root or lower, joint
	end

	-- parts / attachments / joints that appear AFTER the battler was resized (effects, spikes, weapons the game
	-- adds later) are scaled by the same factor, because Model:ScaleTo only knows what existed at that moment
	local function scaleLoose(object, factor)
		if object:IsA("BasePart") then
			object.Size = object.Size * factor
			local mesh = object:FindFirstChildWhichIsA("SpecialMesh")
			if mesh then mesh.Scale = mesh.Scale * factor end
		elseif object:IsA("Attachment") then
			object.Position = object.Position * factor
		elseif object:IsA("Motor6D") or object:IsA("Weld") or object:IsA("ManualWeld") then
			object.C0 = object.C0 - object.C0.Position + object.C0.Position * factor
			object.C1 = object.C1 - object.C1.Position + object.C1.Position * factor
		end
	end

	local function setScale(unit, info, factor)
		unit:ScaleTo(info.scale * factor)
		if info.joint and info.joint.Parent then
			info.joint.C0 = CFrame.new(0, info.feet * (factor - 1), 0) * info.baseC0
		end
		info.factor = factor
		if info.watch then info.watch:Disconnect() info.watch = nil end
		if math.abs(factor - 1) > 0.0001 then
			info.watch = unit.DescendantAdded:Connect(function(object)
				task.defer(function()
					if info.factor ~= 1 and object.Parent then
						pcall(scaleLoose, object, info.factor)
					end
				end)
			end)
		end
	end

	local function resetUnit(unit, info)
		pcall(function()
			setScale(unit, info, 1)
			if info.joint then info.joint.C0 = info.baseC0 end
		end)
		if info.watch then info.watch:Disconnect() info.watch = nil end
		size.units[unit] = nil
	end

	local function resetEntry(entry)
		local count = 0
		for unit, info in pairs(size.units) do
			if info.entry == entry and unit.Parent then
				resetUnit(unit, info)
				count += 1
			end
		end
		return count
	end

	local function resetAll()
		local count = 0
		for unit, info in pairs(size.units) do
			if unit.Parent then
				resetUnit(unit, info)
				count += 1
			end
		end
		return count
	end

	-- one pass over every ON setting; a battler is only taken by the first setting that matches it
	local function applyOnce()
		local claimed = {}
		local total = 0
		for _, entry in ipairs(size.entries) do
			if entry.enabled then
				local folder = folderFor(entry.ally)
				local taken = 0
				if folder then
					for _, unit in folder:GetChildren() do
						if taken >= entry.maxUnits then break end
						if not claimed[unit] and matches(entry, unit) then
							claimed[unit] = true
							taken += 1
							pcall(function()
								local info = size.units[unit]
								if info == nil then
									local root, joint = findRootJoint(unit)
									local boxCFrame, boxSize = unit:GetBoundingBox()
									local feet = root and math.max(0, root.Position.Y - (boxCFrame.Position.Y - boxSize.Y / 2)) or 0
									info = {
										scale = unit:GetScale(),
										joint = joint,
										baseC0 = joint and joint.C0 or CFrame.new(),
										feet = feet,
										factor = 1,
									}
									size.units[unit] = info
								end
								info.entry = entry
								if math.abs(info.factor - entry.scale) > 0.0001
									or math.abs(unit:GetScale() - info.scale * entry.scale) > 0.001 * math.max(1, info.scale * entry.scale) then
									setScale(unit, info, entry.scale)
								end
							end)
						end
					end
				end
				total += taken
			end
		end
		-- battlers whose setting was switched off / changed ID are put back
		for unit, info in pairs(size.units) do
			if not claimed[unit] then
				resetUnit(unit, info)
			end
		end
		return total
	end

	local function stopLoop()
		size.loop = false
		size.token += 1
	end

	local function startLoop()
		stopLoop()
		size.loop = true
		local token = size.token
		task.spawn(function()
			while size.loop and size.token == token and not destroyed do
				applyOnce()
				task.wait(0.4)
			end
		end)
	end
	Custom.sizeStop = function()
		stopLoop()
		pcall(resetAll)
	end

	local drawer = addToggleCogRow(page, "Size Changer (keep looping)", function()
		return size.loop
	end, function(value)
		if value then
			startLoop()
		else
			stopLoop()
		end
	end)

	local buttonRow = addGrayRow(drawer, "")
	local function rowButton(text, width, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, buttonRow)
		outline(button)
		return button
	end
	local countLabel = buttonRow:FindFirstChildOfClass("TextLabel")
	local addButton = rowButton("+ ADD", 60, 8)
	local applyButton = rowButton("RESIZE NOW", 90, 74)
	local resetButton = rowButton("RESET ALL", 74, 170)
	if countLabel then countLabel.Size = UDim2.new(1, -250, 1, 0) end

	local status = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = "Press + ADD to make a size setting (up to 50). Switch the header on to keep them applied.",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, drawer)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function refreshCount()
		if countLabel then
			countLabel.Text = "Settings: " .. tostring(#size.entries) .. " / " .. tostring(MAX_ENTRIES)
		end
	end
	refreshCount()

	local function addEntry()
		if #size.entries >= MAX_ENTRIES then
			status.Text = "That is the maximum: " .. tostring(MAX_ENTRIES) .. " size settings."
			return
		end
		local entry = { enabled = true, id = 0, scale = 2, ally = true, maxUnits = 1 }
		table.insert(size.entries, entry)

		local box = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = #size.entries,
		}, list)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, box)

		local header = addGrayRow(box, "")
		local title = header:FindFirstChildOfClass("TextLabel")
		if title then
			title.Size = UDim2.new(1, -110, 1, 0)
			title.TextSize = 12
			title.TextTruncate = Enum.TextTruncate.AtEnd
		end
		local function refreshHeader()
			local index = table.find(size.entries, entry) or 0
			if title then
				title.Text = "Size " .. tostring(index) .. "  -  " .. (entry.id > 0 and ("ID " .. tostring(entry.id)) or "every battler")
					.. "  x" .. tostring(entry.scale) .. (entry.ally and "  BLUE" or "  RED")
			end
			header.BackgroundColor3 = entry.enabled and Color3.fromRGB(200, 225, 200) or GRAY
		end
		entry.refreshHeader = refreshHeader

		local switchButton = make("TextButton", {
			Size = UDim2.fromOffset(44, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -44, 0.5, 0),
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, header)
		outline(switchButton)
		local function refreshSwitch()
			switchButton.Text = entry.enabled and "ON" or "OFF"
			switchButton.BackgroundColor3 = entry.enabled and ON_COLOR or WHITE
		end
		refreshSwitch()
		listen(switchButton.MouseButton1Click, function()
			entry.enabled = not entry.enabled
			refreshSwitch()
			refreshHeader()
			if not entry.enabled then
				resetEntry(entry) -- switched off: the battlers go back to normal right away
			elseif not size.loop then
				applyOnce()
			end
		end)

		local removeButton = make("TextButton", {
			Size = UDim2.fromOffset(32, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(230, 90, 90),
			Text = "X",
			TextColor3 = WHITE,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
		}, header)
		outline(removeButton)
		listen(removeButton.MouseButton1Click, function()
			resetEntry(entry)
			local index = table.find(size.entries, entry)
			if index then table.remove(size.entries, index) end
			box:Destroy()
			for position, other in ipairs(size.entries) do
				other.refreshHeader()
			end
			refreshCount()
		end)

		-- fields: ID | Size | Max units | team
		local fields = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 2,
		}, box)
		outline(fields)
		local function column(x, width, label)
			local holder = make("Frame", {
				Size = UDim2.new(width, 0, 1, 0),
				Position = UDim2.new(x, 0, 0, 0),
				BackgroundTransparency = 1,
			}, fields)
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 3),
				BackgroundTransparency = 1,
				Text = label,
				TextColor3 = BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, holder)
			return holder
		end
		local function numberBox(holder, text, commit)
			local textBox = make("TextBox", {
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.fromOffset(6, 22),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				TextSize = 15,
				Font = Enum.Font.GothamBold,
				Text = text,
				ClearTextOnFocus = false,
			}, holder)
			outline(textBox)
			listen(textBox.FocusLost, function()
				commit(textBox)
			end)
			return textBox
		end
		numberBox(column(0, 0.22, "Unit ID (0=all)"), "0", function(textBox)
			local number = tonumber(textBox.Text)
			entry.id = (number and number > 0) and math.floor(number) or 0
			textBox.Text = tostring(entry.id)
			refreshHeader()
		end)
		numberBox(column(0.22, 0.26, "Size 0.1-100"), tostring(entry.scale), function(textBox)
			local number = tonumber(textBox.Text)
			entry.scale = number and math.clamp(number, 0.1, 100) or 1
			textBox.Text = tostring(entry.scale)
			refreshHeader()
		end)
		numberBox(column(0.48, 0.22, "Up to (1-100)"), tostring(entry.maxUnits), function(textBox)
			local number = tonumber(textBox.Text)
			entry.maxUnits = number and math.clamp(math.floor(number), 1, 100) or 1
			textBox.Text = tostring(entry.maxUnits)
		end)
		local teamHolder = column(0.7, 0.3, "Goes on")
		local teamButton = make("TextButton", {
			Size = UDim2.new(1, -12, 0, 24),
			Position = UDim2.fromOffset(6, 22),
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, teamHolder)
		outline(teamButton)
		local function refreshTeam()
			teamButton.Text = entry.ally and "BLUE unit" or "RED enemy"
			teamButton.BackgroundColor3 = entry.ally and Color3.fromRGB(110, 170, 255) or Color3.fromRGB(235, 100, 100)
		end
		refreshTeam()
		listen(teamButton.MouseButton1Click, function()
			entry.ally = not entry.ally
			refreshTeam()
			refreshHeader()
		end)

		refreshHeader()
		refreshCount()
		status.Text = "Added size setting " .. tostring(#size.entries) .. "."
	end

	listen(addButton.MouseButton1Click, addEntry)
	listen(applyButton.MouseButton1Click, function()
		local count = applyOnce()
		status.Text = count > 0 and ("Resized " .. tostring(count) .. " battler" .. (count == 1 and "" or "s") .. ".")
			or "No matching battler found right now (check the ID, the blue / red switch and that the setting is ON)."
	end)
	listen(resetButton.MouseButton1Click, function()
		local count = resetAll()
		status.Text = "Put " .. tostring(count) .. " battler" .. (count == 1 and "" or "s") .. " back to their size."
	end)

	addEntry() -- start with one setting ready
end)

-- Animation Changer (Misc tab): swaps ONE kind of animation (idle / walk / punch ...) on the battlers you pick.
-- It watches which animation the game is playing, and while it plays it puts yours on top (higher priority).
safeBuild("Animation Changer", function()
	local page = pages["Misc"]
	local MAX_ENTRIES = 30
	local TYPES = {
		{ name = "Idle", keys = "idle" },
		{ name = "Walk", keys = "walk,run" },
		{ name = "Punch", keys = "punch,attack,swing,slash,melee,hit" },
		{ name = "Custom", keys = "" },
	}
	local anim = { loop = false, token = 0, entries = {}, ours = setmetatable({}, { __mode = "k" }), tracks = setmetatable({}, { __mode = "k" }) }
	Custom.anim = anim

	local function folderFor(ally)
		local npcRoot = Workspace:FindFirstChild("NPCFolders")
		return npcRoot and npcRoot:FindFirstChild(ally and "FriendlyFolder" or "EnemyFolder")
	end

	local function matchesUnit(entry, unit)
		if not unit:IsA("Model") then return false end
		if entry.id > 0 and tonumber(unit:GetAttribute("ID")) ~= entry.id then return false end
		return true
	end

	local function keywordsOf(entry)
		local list = {}
		for word in string.gmatch(string.lower(entry.keys or ""), "[^,%s]+") do
			table.insert(list, word)
		end
		return list
	end

	local function nameMatches(track, words)
		local names = { string.lower(track.Name or "") }
		pcall(function()
			if track.Animation then
				table.insert(names, string.lower(track.Animation.Name))
				table.insert(names, string.lower(track.Animation.AnimationId))
			end
		end)
		for _, name in ipairs(names) do
			for _, word in ipairs(words) do
				if string.find(name, word, 1, true) then return true end
			end
		end
		return false
	end

	-- the game keeps Animation objects named "Idle" / "Walk" / ... inside each battler, but the playing
	-- track is often just called "Animation": so also collect the IDs of the matching objects
	local function idsOfNamed(unit, words)
		local ids, names = {}, {}
		for _, object in ipairs(unit:GetDescendants()) do
			if object:IsA("Animation") and not object:GetAttribute("OscarMade") and object.Name ~= "OscarAnim" then
				local lowered = string.lower(object.Name)
				for _, word in ipairs(words) do
					if string.find(lowered, word, 1, true) then
						ids[string.lower(object.AnimationId)] = true
						if #names < 6 then table.insert(names, object.Name) end
						break
					end
				end
			end
		end
		return ids, names
	end

	local function trackId(track)
		local id = ""
		pcall(function() id = string.lower(track.Animation.AnimationId) end)
		return id
	end

	local function animatorOf(unit)
		return unit:FindFirstChildWhichIsA("Animator", true)
	end

	-- every playing track of a battler, from its Animator, Humanoid or AnimationController
	local function playingTracks(unit)
		local result, seenTrack = {}, {}
		local function collect(object)
			local ok, list = pcall(function() return object:GetPlayingAnimationTracks() end)
			if ok and type(list) == "table" then
				for _, track in ipairs(list) do
					if not seenTrack[track] then
						seenTrack[track] = true
						table.insert(result, track)
					end
				end
			end
		end
		for _, object in ipairs(unit:GetDescendants()) do
			if object:IsA("Animator") or object:IsA("Humanoid") or object:IsA("AnimationController") then
				collect(object)
			end
		end
		return result
	end

	-- Priority ladder (lowest -> highest). A replacement plays ONE step above the animation it replaces, so
	-- the order the game uses (idle < walk < attack) is kept. Before, every replacement was Action4, so an
	-- always-on Idle replacement covered the Walk and Punch replacements and everything looked like idle.
	local PRIORITY_LADDER = {
		Enum.AnimationPriority.Core, Enum.AnimationPriority.Idle, Enum.AnimationPriority.Movement,
		Enum.AnimationPriority.Action, Enum.AnimationPriority.Action2, Enum.AnimationPriority.Action3,
		Enum.AnimationPriority.Action4,
	}
	local function priorityAbove(original)
		local current = Enum.AnimationPriority.Core
		pcall(function() current = original.Priority end)
		for position, value in ipairs(PRIORITY_LADDER) do
			if value == current then
				return PRIORITY_LADDER[math.min(position + 1, #PRIORITY_LADDER)]
			end
		end
		return Enum.AnimationPriority.Action
	end

	local function priorityIndex(value)
		for position, entryValue in ipairs(PRIORITY_LADDER) do
			if entryValue == value then return position end
		end
		return 4
	end

	-- idle / walk / punch decided from the keywords, so Custom entries with those words behave the same
	local function kindOf(entry)
		local keys = string.lower(entry.keys or "")
		if string.find(keys, "idle", 1, true) then return "idle" end
		if string.find(keys, "walk", 1, true) or string.find(keys, "run", 1, true) then return "walk" end
		if string.find(keys, "punch", 1, true) or string.find(keys, "attack", 1, true) then return "punch" end
		return "other"
	end

	local function speedOfUnit(unit)
		local speed = 0
		pcall(function()
			local root = unit.PrimaryPart or unit:FindFirstChild("HumanoidRootPart") or unit:FindFirstChildWhichIsA("BasePart", true)
			local v = root.AssemblyLinearVelocity
			speed = Vector3.new(v.X, 0, v.Z).Magnitude
		end)
		return speed
	end

	local function weightOf(track)
		local weight = 1
		pcall(function() weight = track.WeightCurrent end)
		return weight
	end

	-- cached per battler (refreshed every ~1.5s): the animator, the objects that play animations,
	-- and the animation IDs of the game's named Animation objects. GetDescendants every step was heavy.
	anim.cache = setmetatable({}, { __mode = "k" })
	anim.state = setmetatable({}, { __mode = "k" })
	local function unitInfo(unit, now)
		local info = anim.cache[unit]
		if info and now - info.time < 1.5 and info.player and info.player.Parent then
			return info
		end
		info = { time = now, sources = {}, ids = {} }
		for _, object in ipairs(unit:GetDescendants()) do
			if object:IsA("Animator") or object:IsA("Humanoid") or object:IsA("AnimationController") then
				table.insert(info.sources, object)
			end
		end
		info.player = animatorOf(unit) or unit:FindFirstChildWhichIsA("Humanoid", true) or unit:FindFirstChildWhichIsA("AnimationController", true)
		anim.cache[unit] = info
		return info
	end

	local function livePlayingTracks(info)
		local result, seenTrack = {}, {}
		for _, object in ipairs(info.sources) do
			local ok, list = pcall(function() return object:GetPlayingAnimationTracks() end)
			if ok and type(list) == "table" then
				for _, track in ipairs(list) do
					if not seenTrack[track] then
						seenTrack[track] = true
						table.insert(result, track)
					end
				end
			end
		end
		return result
	end

	-- one pass: for every ON setting and every matching battler; fills entry.report with what happened
	local function step()
		local now = os.clock()
		local perUnit = {} -- tracks of each battler, read once per pass
		for index, entry in ipairs(anim.entries) do
			if entry.enabled then
				local report = { units = 0, noAnimator = 0, originals = 0, playing = 0, zero = 0, err = nil, names = {} }
				entry.report = report
				local words = keywordsOf(entry)
				local folder = folderFor(entry.ally)
				if entry.animId <= 0 then
					report.err = "no animation ID typed"
				elseif #words == 0 then
					report.err = "'Animation name contains' is empty"
				elseif not folder then
					report.err = "no " .. (entry.ally and "FriendlyFolder" or "EnemyFolder") .. " yet"
				else
					for _, unit in folder:GetChildren() do
						if matchesUnit(entry, unit) then
							report.units += 1
							local ok, err = pcall(function()
								local info = unitInfo(unit, now)
								local player = info.player
								if not player then
									report.noAnimator += 1
									return
								end
								local wantedIds = info.ids[entry.keys]
								if not wantedIds then
									wantedIds = idsOfNamed(unit, words)
									info.ids[entry.keys] = wantedIds
								end
								local tracks = perUnit[unit]
								if not tracks then
									tracks = livePlayingTracks(info)
									perUnit[unit] = tracks
								end
								-- the matching original that is really visible right now (highest weight wins)
								local original, originalWeight
								for _, track in ipairs(tracks) do
									if not anim.ours[track] and track.IsPlaying then
										if #report.names < 4 then table.insert(report.names, track.Name .. " " .. string.gsub(trackId(track), "rbxassetid://", "")) end
										local id = trackId(track)
										if (id ~= "" and wantedIds[id]) or nameMatches(track, words) then
											local weight = weightOf(track)
											if weight > 0.05 and (not original or weight > originalWeight) then
												original, originalWeight = track, weight
											end
										end
									end
								end
								local kind = kindOf(entry)
								local moving = speedOfUnit(unit) > 1.5
								if kind == "idle" and moving then
									-- an idle replacement must never stay on while the battler walks
									original = nil
								elseif kind == "walk" then
									if not moving then
										original = nil
									elseif not original then
										-- the game's walk track has no name we know: use the strongest non-idle track playing
										local idleWords = { "idle" }
										for _, track in ipairs(tracks) do
											if not anim.ours[track] and track.IsPlaying and not nameMatches(track, idleWords) then
												local weight = weightOf(track)
												if weight > 0.05 and (not original or weight > originalWeight) then
													original, originalWeight = track, weight
												end
											end
										end
									end
								end
								anim.tracks[unit] = anim.tracks[unit] or {}
								local mine = anim.tracks[unit][entry]
								if original then
									report.originals += 1
									if not mine then
										local animation = Instance.new("Animation")
										animation.Name = "OscarAnim"
										animation.AnimationId = "rbxassetid://" .. tostring(entry.animId)
										mine = player:LoadAnimation(animation)
										anim.ours[mine] = true
										anim.tracks[unit][entry] = mine
									end
									pcall(function()
										local level = priorityIndex(priorityAbove(original))
										-- keep idle < walk < punch even if the game gave them the same priority
										if kind == "idle" then level = math.min(level, 3)
										elseif kind == "walk" then level = math.max(level, 4)
										elseif kind == "punch" then level = math.max(level, 5) end
										mine.Priority = PRIORITY_LADDER[level]
									end)
									pcall(function() mine.Looped = original.Looped end)
									local state = anim.state[mine]
									if not state then
										state = { last = 0, active = false }
										anim.state[mine] = state
									end
									local position = 0
									pcall(function() position = original.TimePosition end)
									-- fresh start (it was off / the game restarted its animation): start ours from the same point
									local restarted = (not state.active) or position < state.last - 0.05
									state.last, state.active = position, true
									local speed = original.Speed * entry.speed
									local weight = math.max(originalWeight, 0.01)
									if restarted or not mine.IsPlaying then
										if not mine.IsPlaying and (restarted or original.Looped) then
											mine:Play(0.1, weight, speed)
										end
										pcall(function()
											if mine.IsPlaying and not original.Looped and original.Length > 0 and mine.Length > 0 then
												mine.TimePosition = math.clamp(position / original.Length * mine.Length, 0, mine.Length)
											end
										end)
									end
									if mine.IsPlaying then
										mine:AdjustSpeed(speed)
										-- follow the original's weight so ours fades in/out exactly when the game's does
										if math.abs(weightOf(mine) - weight) > 0.02 then
											mine:AdjustWeight(weight, 0)
										end
										report.playing += 1
									end
									if mine.Length == 0 then report.zero += 1 end
								elseif mine then
									local state = anim.state[mine]
									if state then state.active = false end
									if mine.IsPlaying then
										mine:Stop(0.15)
									end
								end
							end)
							if not ok then report.err = tostring(err) end
						end
					end
				end
			end
		end
	end

	local function reportText()
		local lines = {}
		for index, entry in ipairs(anim.entries) do
			local r = entry.report
			if entry.enabled and r then
				local text
				if r.err then
					text = "problem: " .. r.err
				elseif r.units == 0 then
					text = "no battler matches (check team colour and Unit ID)"
				elseif r.noAnimator == r.units then
					text = "the battlers have no animator"
				elseif r.originals == 0 then
					local seen = #r.names > 0 and table.concat(r.names, ", ") or "nothing"
					text = r.units .. " battler(s) found but none plays an animation matching '" .. tostring(entry.keys) .. "'. They play: " .. seen .. ". Put one of those names in 'Animation name contains'."
				elseif r.zero > 0 then
					text = "your animation loaded with length 0: Roblox refused this ID in this game (use an animation the game or Roblox owns, same rig type)"
				else
					text = "working on " .. r.playing .. "/" .. r.originals .. " battler(s)"
				end
				table.insert(lines, "Anim " .. index .. ": " .. text)
			end
		end
		return #lines > 0 and table.concat(lines, "\n") or "Turn on the main toggle and at least one setting."
	end

	local function stopAllOurs()
		for unit, byEntry in pairs(anim.tracks) do
			for _, track in pairs(byEntry) do
				pcall(function()
					track:Stop(0)
					track:Destroy()
				end)
			end
		end
		table.clear(anim.tracks)
	end

	local function stopLoop()
		anim.loop = false
		anim.token += 1
		stopAllOurs()
	end

	local function startLoop()
		stopLoop()
		anim.loop = true
		local token = anim.token
		task.spawn(function()
			local ticks = 0
			while anim.loop and anim.token == token and not destroyed do
				step()
				ticks += 1
				if ticks % 30 == 1 then
					pcall(function() Custom.animStatus(reportText()) end)
				end
				task.wait(0.03)
			end
		end)
	end
	Custom.animStop = stopLoop

	local drawer = addToggleCogRow(page, "Animation Changer (idle / walk / punch)", function()
		return anim.loop
	end, function(value)
		if value then startLoop() else stopLoop() end
	end)

	local topRow = addGrayRow(drawer, "")
	local countLabel = topRow:FindFirstChildOfClass("TextLabel")
	local addButton = make("TextButton", {
		Size = UDim2.fromOffset(60, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "+ ADD",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, topRow)
	outline(addButton)
	if countLabel then countLabel.Size = UDim2.new(1, -90, 1, 0) end

	local status = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text = "Press + ADD, pick Idle / Walk / Punch, paste your animation ID and switch the header on. If nothing changes, the ID is not allowed in this game or the rig type (R6 / R15) does not match. DETECT shows what the battlers are playing.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	-- ===== animation ID collector: type a battler's unit ID, get every animation it owns =====
	do
		local collectState = { ally = true, id = 0 }
		local collectRow = addGrayRow(drawer, "")
		local collectTitle = collectRow:FindFirstChildOfClass("TextLabel")
		if collectTitle then
			collectTitle.Text = "ID collector"
			collectTitle.Size = UDim2.new(0, 90, 1, 0)
			collectTitle.TextSize = 12
		end
		local idBox = make("TextBox", {
			Size = UDim2.fromOffset(60, 24),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 96, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			PlaceholderText = "unit ID",
			PlaceholderColor3 = GRAY,
			Text = "",
			TextSize = 13,
			Font = Enum.Font.GothamBold,
			ClearTextOnFocus = false,
		}, collectRow)
		outline(idBox)
		local teamButton = make("TextButton", {
			Size = UDim2.fromOffset(64, 24),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 162, 0.5, 0),
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, collectRow)
		outline(teamButton)
		local function refreshTeam()
			teamButton.Text = collectState.ally and "BLUE" or "RED"
			teamButton.BackgroundColor3 = collectState.ally and Color3.fromRGB(110, 170, 255) or Color3.fromRGB(235, 100, 100)
		end
		refreshTeam()
		listen(teamButton.MouseButton1Click, function()
			collectState.ally = not collectState.ally
			refreshTeam()
		end)
		local collectButton = make("TextButton", {
			Size = UDim2.fromOffset(70, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = "COLLECT",
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, collectRow)
		outline(collectButton)

		local allRow = addGrayRow(drawer, "")
		local allTitle = allRow:FindFirstChildOfClass("TextLabel")
		if allTitle then
			allTitle.Text = "All game animations"
			allTitle.Size = UDim2.new(0, 150, 1, 0)
			allTitle.TextSize = 12
		end
		local filterBox = make("TextBox", {
			Size = UDim2.new(1, -250, 0, 24),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 156, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			PlaceholderText = "filter (idle, walk...)",
			PlaceholderColor3 = GRAY,
			Text = "",
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			ClearTextOnFocus = false,
		}, allRow)
		outline(filterBox)
		local scanButton = make("TextButton", {
			Size = UDim2.fromOffset(80, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = "SCAN ALL",
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, allRow)
		outline(scanButton)

		local results = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = nextOrder(),
		}, drawer)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, results)

		local function addResult(order, name, id, playing)
			local row = make("Frame", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = GRAY,
				LayoutOrder = order,
			}, results)
			outline(row)
			make("TextLabel", {
				Size = UDim2.new(1, -140, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				BackgroundTransparency = 1,
				Text = name .. "  -  " .. id .. (playing and "  (playing)" or ""),
				TextColor3 = BLACK,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = Enum.Font.GothamBold,
			}, row)
			local copy = make("TextButton", {
				Size = UDim2.fromOffset(62, 22),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				BackgroundColor3 = WHITE,
				Text = "COPY",
				TextColor3 = BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, row)
			outline(copy)
			local use = make("TextButton", {
				Size = UDim2.fromOffset(52, 22),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -74, 0.5, 0),
				BackgroundColor3 = WHITE,
				Text = "USE",
				TextColor3 = BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, row)
			outline(use)
			listen(use.MouseButton1Click, function()
				local last = anim.entries[#anim.entries]
				if last and last.setAnim then
					last.setAnim(tonumber(id))
					status.Text = "Put " .. id .. " (" .. name .. ") into the last setting (Anim " .. #anim.entries .. ")."
				else
					status.Text = "Press + ADD first, then USE."
				end
			end)
			listen(copy.MouseButton1Click, function()
				local done = Custom.copy(id)
				copy.Text = done and "COPIED" or "no clip"
				task.delay(1.2, function()
					if copy.Parent then copy.Text = "COPY" end
				end)
				status.Text = (done and "Copied " or "Your executor can't copy; the ID is ") .. id .. " (" .. name .. "). Paste it into 'New animation ID'."
			end)
		end

		listen(collectButton.MouseButton1Click, function()
			for _, child in ipairs(results:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			local wanted = math.max(0, math.floor(tonumber(idBox.Text) or 0))
			idBox.Text = wanted > 0 and tostring(wanted) or ""
			local folder = folderFor(collectState.ally)
			if not folder then
				status.Text = "No " .. (collectState.ally and "FriendlyFolder" or "EnemyFolder") .. " found. Start a battle first."
				return
			end
			local seen, found, units = {}, 0, 0
			for _, unit in folder:GetChildren() do
				if unit:IsA("Model") and (wanted == 0 or tonumber(unit:GetAttribute("ID")) == wanted) then
					units += 1
					pcall(function()
						local label = tostring(unit.Name)
						for _, object in ipairs(unit:GetDescendants()) do
							if object:IsA("Animation") and object.Name ~= "OscarAnim" then
								local id = string.match(object.AnimationId, "%d+")
								if id and not seen[id] and found < 60 then
									seen[id] = true
									found += 1
									addResult(found, object.Name, id, false)
								end
							end
						end
						for _, track in ipairs(playingTracks(unit)) do
							if not anim.ours[track] then
								local id = string.match(trackId(track), "%d+")
								if id and not seen[id] and found < 60 then
									seen[id] = true
									found += 1
									addResult(found, track.Name, id, true)
								end
							end
						end
					end)
				end
			end
			if found > 0 then
				status.Text = "Found " .. found .. " animation(s) on " .. units .. " battler(s). Press COPY on one, then paste it into 'New animation ID'."
			elseif units == 0 then
				status.Text = "No " .. (collectState.ally and "BLUE" or "RED") .. " battler" .. (wanted > 0 and (" with ID " .. wanted) or "") .. " on the field. Spawn it first or switch the team."
			else
				status.Text = units .. " battler(s) found but they hold no animations right now. Try again while they move."
			end
		end)

		listen(scanButton.MouseButton1Click, function()
			for _, child in ipairs(results:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end
			local filter = string.lower((string.gsub(filterBox.Text or "", "^%s+", "")))
			local roots = { game:GetService("ReplicatedStorage"), Workspace:FindFirstChild("NPCFolders") }
			pcall(function() table.insert(roots, game:GetService("ReplicatedFirst")) end)
			pcall(function() table.insert(roots, game:GetService("StarterPlayer")) end)
			pcall(function() table.insert(roots, game:GetService("Lighting")) end)
			local seen, list, scanned = {}, {}, 0
			status.Text = "Scanning..."
			for _, root in ipairs(roots) do
				local okScan, items = pcall(function() return root:GetDescendants() end)
				if okScan then
					for _, object in ipairs(items) do
						scanned += 1
						if scanned % 4000 == 0 then task.wait() end
						if object:IsA("Animation") and object.Name ~= "OscarAnim" then
							local id = string.match(object.AnimationId, "%d+")
							if id and not seen[id] then
								local owner = object.Parent and object.Parent.Name or "?"
								local label = object.Name .. " (" .. owner .. ")"
								if filter == "" or string.find(string.lower(label), filter, 1, true) or string.find(id, filter, 1, true) then
									seen[id] = true
									table.insert(list, { label = label, id = id })
								end
							end
						end
					end
				end
			end
			table.sort(list, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
			for index, item in ipairs(list) do
				if index > 250 then break end
				addResult(index, item.label, item.id, false)
			end
			status.Text = #list > 0 and ("Found " .. #list .. " animation(s)" .. (#list > 250 and " (showing 250, use the filter)" or "") .. ". USE puts one into your last setting, COPY copies it.")
				or "Nothing found. The game may keep its animations only on the server."
		end)
	end

	Custom.animStatus = function(text)
		status.Size = UDim2.new(1, 0, 0, 70)
		status.Text = text
	end

	local list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, drawer)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function refreshCount()
		if countLabel then
			countLabel.Text = "Settings: " .. tostring(#anim.entries) .. " / " .. tostring(MAX_ENTRIES)
		end
	end
	refreshCount()

	local function addEntry(init)
		if #anim.entries >= MAX_ENTRIES then
			status.Text = "That is the maximum: " .. tostring(MAX_ENTRIES) .. " settings."
			return
		end
		local entry = { enabled = true, id = 0, ally = true, typeIndex = 1, keys = TYPES[1].keys, animId = 0, speed = 1 }
		if type(init) == "table" then
			for key, value in pairs(init) do entry[key] = value end
		end
		table.insert(anim.entries, entry)

		local box = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = #anim.entries,
		}, list)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, box)

		local header = addGrayRow(box, "")
		local title = header:FindFirstChildOfClass("TextLabel")
		if title then
			title.Size = UDim2.new(1, -110, 1, 0)
			title.TextSize = 12
			title.TextTruncate = Enum.TextTruncate.AtEnd
		end
		local function refreshHeader()
			local index = table.find(anim.entries, entry) or 0
			if title then
				title.Text = "Anim " .. tostring(index) .. "  -  " .. TYPES[entry.typeIndex].name .. "  -  "
					.. (entry.id > 0 and ("ID " .. tostring(entry.id)) or "every battler") .. (entry.ally and "  BLUE" or "  RED")
			end
			header.BackgroundColor3 = entry.enabled and Color3.fromRGB(200, 225, 200) or GRAY
		end
		entry.refreshHeader = refreshHeader

		local switchButton = make("TextButton", {
			Size = UDim2.fromOffset(44, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -44, 0.5, 0),
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, header)
		outline(switchButton)
		local function refreshSwitch()
			switchButton.Text = entry.enabled and "ON" or "OFF"
			switchButton.BackgroundColor3 = entry.enabled and ON_COLOR or WHITE
		end
		refreshSwitch()
		listen(switchButton.MouseButton1Click, function()
			entry.enabled = not entry.enabled
			refreshSwitch()
			refreshHeader()
			if not entry.enabled then
				for unit, byEntry in pairs(anim.tracks) do
					local track = byEntry[entry]
					if track then
						pcall(function() track:Stop(0.1) end)
					end
				end
			end
		end)

		local removeButton = make("TextButton", {
			Size = UDim2.fromOffset(32, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(230, 90, 90),
			Text = "X",
			TextColor3 = WHITE,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
		}, header)
		outline(removeButton)
		entry.remove = function()
			for unit, byEntry in pairs(anim.tracks) do
				local track = byEntry[entry]
				if track then
					pcall(function()
						track:Stop(0)
						track:Destroy()
					end)
					byEntry[entry] = nil
				end
			end
			local index = table.find(anim.entries, entry)
			if index then table.remove(anim.entries, index) end
			box:Destroy()
			for _, other in ipairs(anim.entries) do
				other.refreshHeader()
			end
			refreshCount()
		end
		listen(removeButton.MouseButton1Click, entry.remove)

		-- row 1: unit ID | animation ID | speed | team
		local fields = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 2,
		}, box)
		outline(fields)
		local function column(holderParent, x, width, label)
			local holder = make("Frame", {
				Size = UDim2.new(width, 0, 1, 0),
				Position = UDim2.new(x, 0, 0, 0),
				BackgroundTransparency = 1,
			}, holderParent)
			make("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 3),
				BackgroundTransparency = 1,
				Text = label,
				TextColor3 = BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, holder)
			return holder
		end
		local function textBox(holder, text, size, commit)
			local input = make("TextBox", {
				Size = UDim2.new(1, -12, 0, 24),
				Position = UDim2.fromOffset(6, 22),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				TextSize = size or 14,
				Font = Enum.Font.GothamBold,
				Text = text,
				ClearTextOnFocus = false,
			}, holder)
			outline(input)
			listen(input.FocusLost, function()
				commit(input)
			end)
			return input
		end
		textBox(column(fields, 0, 0.2, "Unit ID (0=all)"), tostring(entry.id), 14, function(input)
			local number = tonumber(input.Text)
			entry.id = (number and number > 0) and math.floor(number) or 0
			input.Text = tostring(entry.id)
			refreshHeader()
		end)
		local animInput
		animInput = textBox(column(fields, 0.2, 0.36, "New animation ID"), entry.animId > 0 and tostring(entry.animId) or "", 13, function(input)
			local number = tonumber(string.match(input.Text, "%d+"))
			entry.animId = number and math.floor(number) or 0
			input.Text = entry.animId > 0 and tostring(entry.animId) or ""
			-- a different animation: drop the old loaded tracks so the new one loads
			for unit, byEntry in pairs(anim.tracks) do
				local track = byEntry[entry]
				if track then
					pcall(function()
						track:Stop(0)
						track:Destroy()
					end)
					byEntry[entry] = nil
				end
			end
		end)
		entry.setAnim = function(number)
			entry.animId = number
			animInput.Text = tostring(number)
			for unit, byEntry in pairs(anim.tracks) do
				local track = byEntry[entry]
				if track then
					pcall(function()
						track:Stop(0)
						track:Destroy()
					end)
					byEntry[entry] = nil
				end
			end
		end
		textBox(column(fields, 0.56, 0.18, "Speed"), tostring(entry.speed), 14, function(input)
			local number = tonumber(input.Text)
			entry.speed = number and math.clamp(number, 0.05, 20) or 1
			input.Text = tostring(entry.speed)
		end)
		local teamHolder = column(fields, 0.74, 0.26, "Goes on")
		local teamButton = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, teamHolder)
		outline(teamButton)
		local function refreshTeam()
			teamButton.Text = entry.ally and "BLUE unit" or "RED enemy"
			teamButton.BackgroundColor3 = entry.ally and Color3.fromRGB(110, 170, 255) or Color3.fromRGB(235, 100, 100)
		end
		refreshTeam()
		listen(teamButton.MouseButton1Click, function()
			entry.ally = not entry.ally
			refreshTeam()
			refreshHeader()
		end)

		-- row 2: which animation to replace (type) | name keywords | detect
		local second = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 3,
		}, box)
		outline(second)
		local typeHolder = column(second, 0, 0.22, "Replaces")
		local typeButton = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = TYPES[entry.typeIndex].name,
		}, typeHolder)
		outline(typeButton)
		local keysBox
		keysBox = textBox(column(second, 0.22, 0.5, "Animation name contains (comma list)"), entry.keys, 12, function(input)
			entry.keys = input.Text
			if entry.typeIndex ~= #TYPES then
				-- typing your own words turns it into Custom
				if string.lower(input.Text) ~= TYPES[entry.typeIndex].keys then
					entry.typeIndex = #TYPES
					typeButton.Text = TYPES[entry.typeIndex].name
					refreshHeader()
				end
			end
		end)
		listen(typeButton.MouseButton1Click, function()
			entry.typeIndex = entry.typeIndex % #TYPES + 1
			if TYPES[entry.typeIndex].keys ~= "" then
				entry.keys = TYPES[entry.typeIndex].keys
				keysBox.Text = entry.keys
			end
			typeButton.Text = TYPES[entry.typeIndex].name
			refreshHeader()
		end)
		local detectHolder = column(second, 0.72, 0.28, "What plays now")
		local detectButton = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "DETECT",
		}, detectHolder)
		outline(detectButton)
		listen(detectButton.MouseButton1Click, function()
			local folder = folderFor(entry.ally)
			if not folder then
				status.Text = "No " .. (entry.ally and "FriendlyFolder" or "EnemyFolder") .. " found. Start a battle first."
				return
			end
			local seen, lines = {}, {}
			local units, matched, withTracks = 0, 0, 0
			for _, unit in folder:GetChildren() do
				units += 1
				if matchesUnit(entry, unit) then
					matched += 1
					pcall(function()
						local count = 0
						for _, track in ipairs(playingTracks(unit)) do
							if not anim.ours[track] then
								count += 1
								local id = track.Animation and track.Animation.AnimationId or "?"
								local key = track.Name .. id
								if not seen[key] then
									seen[key] = true
									table.insert(lines, track.Name .. " (" .. string.gsub(id, "rbxassetid://", "") .. ")")
								end
							end
						end
						if count > 0 then withTracks += 1 end
					end)
				end
			end
			if #lines > 0 then
				status.Text = "Playing now: " .. table.concat(lines, ", ") .. "  -  tip: type one of these numbers into 'Animation name contains' to replace exactly that one."
			elseif units == 0 then
				status.Text = "No battlers on the " .. (entry.ally and "BLUE" or "RED") .. " side right now. Spawn some or switch the team button."
			elseif matched == 0 then
				status.Text = units .. " battlers on this side but none with Unit ID " .. entry.id .. ". Try 0 (= all) or switch the team."
			else
				status.Text = matched .. " matching battler(s) found but no animation is playing on them (they may play animations on the server, or have none right now). Try again while they move."
			end
		end)

		refreshHeader()
		refreshCount()
		status.Text = "Added setting " .. tostring(#anim.entries) .. "."
	end

	-- ===== save / load =====
	local function cleanKeys(text)
		return (string.gsub(text or "", "[|~]", ""))
	end
	local function serializeAnim()
		local rows = {}
		for _, entry in ipairs(anim.entries) do
			rows[#rows + 1] = table.concat({
				entry.enabled and 1 or 0, entry.ally and 1 or 0, entry.id, entry.animId, entry.speed,
				entry.typeIndex, cleanKeys(entry.keys),
			}, "~")
		end
		local body = Custom.encodeBase64(table.concat(rows, "|"))
		return "OSN1" .. body .. Custom.checksum(body)
	end
	local function loadAnim(code)
		code = string.gsub(code or "", "%s", "")
		if string.sub(code, 1, 4) ~= "OSN1" or #code < 5 then
			return false, "That is not a valid animation code."
		end
		local body = string.sub(code, 5, #code - 1)
		if Custom.checksum(body) ~= string.sub(code, #code) then
			return false, "The code is damaged (a character is wrong or missing)."
		end
		local ok, decoded = pcall(decodeBase64, body)
		if not ok then return false, "The code could not be read." end
		local list = {}
		if decoded ~= "" then
			for _, row in ipairs(string.split(decoded, "|")) do
				local f = string.split(row, "~")
				if #f < 6 then return false, "The code could not be read." end
				local typeIndex = math.clamp(math.floor(tonumber(f[6]) or 1), 1, #TYPES)
				list[#list + 1] = {
					enabled = f[1] == "1",
					ally = f[2] ~= "0",
					id = math.max(0, math.floor(tonumber(f[3]) or 0)),
					animId = math.max(0, math.floor(tonumber(f[4]) or 0)),
					speed = math.clamp(tonumber(f[5]) or 1, 0.05, 20),
					typeIndex = typeIndex,
					keys = f[7] or TYPES[typeIndex].keys,
				}
				if #list >= MAX_ENTRIES then break end
			end
		end
		while #anim.entries > 0 do
			anim.entries[#anim.entries].remove()
		end
		for _, init in ipairs(list) do
			addEntry(init)
		end
		return true, #list
	end
	Custom.animSerialize, Custom.animLoad = serializeAnim, loadAnim

	local saveRow = addGrayRow(drawer, "Save / Load animations")
	local function saveButton(text, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, saveRow)
		outline(button)
		return button
	end
	local loadButton = saveButton("LOAD", 8)
	local saveCodeButton = saveButton("SAVE", 68)
	local codeRow = addGrayRow(drawer, "Code")
	local codeBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "save to get a code / paste one here",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, codeRow)
	outline(codeBox)
	listen(saveCodeButton.MouseButton1Click, function()
		local code = serializeAnim()
		codeBox.Text = code
		status.Text = Custom.copy(code) and "Saved! The code is in the box and copied to your clipboard." or "Saved! Copy the code from the box."
	end)
	listen(loadButton.MouseButton1Click, function()
		local ok, result = loadAnim(codeBox.Text)
		status.Text = ok and ("Loaded " .. tostring(result) .. " setting(s).") or ("Could not load: " .. tostring(result))
	end)

	listen(addButton.MouseButton1Click, function() addEntry() end)
	addEntry()
end)

-- Sound Changer (Misc tab): same idea as the Animation Changer, but it swaps Sound objects (death sound, hit sound ...)
safeBuild("Sound Changer", function()
	local page = pages["Misc"]
	local SoundService = game:GetService("SoundService")
	local MAX_ENTRIES = 30
	local TYPES = {
		{ name = "Death", keys = "death,die,dead,kill" },
		{ name = "Hit", keys = "hit,hurt,damage,pain,impact" },
		{ name = "Attack", keys = "attack,punch,swing,slash,shoot,fire" },
		{ name = "Spawn", keys = "spawn,summon" },
		{ name = "Step", keys = "step,walk,run" },
		{ name = "Custom", keys = "" },
	}
	local snd = { loop = false, token = 0, entries = {}, unitEdits = {}, unitDirty = true, touched = setmetatable({}, { __mode = "k" }), originals = setmetatable({}, { __mode = "k" }), hooks = {} }
	Custom.snd = snd

	local function folderFor(ally)
		local npcRoot = Workspace:FindFirstChild("NPCFolders")
		return npcRoot and npcRoot:FindFirstChild(ally and "FriendlyFolder" or "EnemyFolder")
	end

	local function keywordsOf(entry)
		local list = {}
		for word in string.gmatch(string.lower(entry.keys or ""), "[^,%s]+") do
			table.insert(list, word)
		end
		return list
	end

	local function original(sound)
		local saved = snd.originals[sound]
		if not saved then
			saved = { id = sound.SoundId, volume = sound.Volume, speed = sound.PlaybackSpeed }
			snd.originals[sound] = saved
		end
		return saved
	end

	local function restore(sound)
		local saved = snd.originals[sound]
		if saved then
			pcall(function()
				if saved.idSet then
					sound.SoundId = saved.id
					saved.idSet = nil
				end
				sound.Volume = saved.volume
				sound.PlaybackSpeed = saved.speed
			end)
		end
		snd.touched[sound] = nil
	end

	-- does this entry want this sound? (unit scope: it must live inside a matching battler)
	local function wants(entry, sound, words)
		if entry.anywhere then
			-- fine, every sound in the game can match
		else
			local folder = folderFor(entry.ally)
			if not folder then return false end
			local unit = sound
			while unit and unit.Parent ~= folder do
				unit = unit.Parent
				if unit == nil or unit == game then return false end
			end
			if not unit then return false end
			if entry.id > 0 and tonumber(unit:GetAttribute("ID")) ~= entry.id then return false end
		end
		local saved = snd.originals[sound]
		local name = string.lower(sound.Name)
		local id = string.lower(saved and saved.id or sound.SoundId)
		for _, word in ipairs(words) do
			if string.find(name, word, 1, true) or string.find(id, word, 1, true) then return true end
		end
		return false
	end

	-- the game often sets PlaybackSpeed / Volume itself right before it plays a sound (random pitch ...),
	-- which wiped our change. So we also re-apply when the sound plays or when the game changes those values.
	snd.hooked = snd.hooked or setmetatable({}, { __mode = "k" })
	local function reapply(sound)
		local entry = snd.touched[sound]
		local saved = snd.originals[sound]
		if not entry or not saved or not snd.loop then return end
		if entry.soundId > 0 then
			local want = "rbxassetid://" .. tostring(entry.soundId)
			if sound.SoundId ~= want then
				saved.idSet = true
				sound.SoundId = want
			end
		end
		local volume = math.clamp(saved.volume * entry.volume, 0, 10)
		if sound.Volume ~= volume then sound.Volume = volume end
		local speed = math.clamp(saved.speed * entry.pitch, 0.05, 20)
		if sound.PlaybackSpeed ~= speed then sound.PlaybackSpeed = speed end
	end
	local function hookSound(sound)
		if snd.hooked[sound] then return end
		snd.hooked[sound] = true
		local conns = {}
		local function watch(property, key)
			table.insert(conns, sound:GetPropertyChangedSignal(property):Connect(function()
				local entry, saved = snd.touched[sound], snd.originals[sound]
				if not entry or not saved or not snd.loop then return end
				local ours
				if property == "PlaybackSpeed" then
					ours = math.clamp(saved.speed * entry.pitch, 0.05, 20)
				elseif property == "Volume" then
					ours = math.clamp(saved.volume * entry.volume, 0, 10)
				end
				if ours and math.abs(sound[property] - ours) > 1e-4 then
					-- the game wrote a new value: take it as the new "original" and apply our multiplier on top
					saved[key] = sound[property]
					pcall(reapply, sound)
				end
			end))
		end
		watch("PlaybackSpeed", "speed")
		watch("Volume", "volume")
		table.insert(conns, sound.Played:Connect(function() pcall(reapply, sound) end))
		table.insert(snd.hooks, { Disconnect = function() for _, c in ipairs(conns) do c:Disconnect() end snd.hooked[sound] = nil end })
	end

	-- the sound ID and the pitch / volume are separate settings: an empty ID leaves the game's own sound alone
	local function applyTo(entry, sound, report)
		local saved = original(sound)
		if report then report.found += 1 end
		snd.touched[sound] = entry
		if entry.soundId > 0 then
			local want = "rbxassetid://" .. tostring(entry.soundId)
			if sound.SoundId ~= want then
				saved.idSet = true
				sound.SoundId = want
				if report then report.changed += 1 end
			end
		end
		local volume = math.clamp(saved.volume * entry.volume, 0, 10)
		if sound.Volume ~= volume then sound.Volume = volume end
		local speed = math.clamp(saved.speed * entry.pitch, 0.05, 20)
		if sound.PlaybackSpeed ~= speed then sound.PlaybackSpeed = speed end
		hookSound(sound)
	end

	local function apply(entry, sound, report)
		if not sound:IsA("Sound") or sound.Name == "OscarPreview" then return end
		local words = entry.words or keywordsOf(entry)
		if #words == 0 or not wants(entry, sound, words) then return end
		applyTo(entry, sound, report)
	end

	local function changesAnything(entry)
		return entry.soundId > 0 or entry.pitch ~= 1 or entry.volume ~= 1
	end

	-- puts the game's own sound ID back on every sound this entry changed (used when its ID box is cleared)
	local function restoreIds(owner)
		for sound, who in pairs(snd.touched) do
			local saved = snd.originals[sound]
			if who == owner and saved and saved.idSet then
				pcall(function() sound.SoundId = saved.id end)
				saved.idSet = nil
			end
		end
	end

	-- ===== unit sound edits (made with SCAN UNIT): one edit = one sound of one unit =====
	local function pathIn(unit, sound)
		local parts, node = {}, sound
		while node and node ~= unit do
			table.insert(parts, 1, node.Name)
			node = node.Parent
		end
		return table.concat(parts, "/")
	end

	local function unitIndex()
		if snd.unitIndex and not snd.unitDirty then return snd.unitIndex end
		local index = {
			has = { [true] = false, [false] = false },
			[true] = { byId = {}, byName = {} },
			[false] = { byId = {}, byName = {} },
		}
		for _, edit in ipairs(snd.unitEdits) do
			if edit.enabled and changesAnything(edit) then
				local side = index[edit.ally]
				local map, key
				if edit.id > 0 then map, key = side.byId, edit.id else map, key = side.byName, edit.unitName end
				map[key] = map[key] or {}
				table.insert(map[key], edit)
				index.has[edit.ally] = true
			end
		end
		snd.unitIndex, snd.unitDirty = index, false
		return index
	end

	local function unitEditFor(sound, ally, index)
		local folder = folderFor(ally)
		if not folder then return nil end
		local unit = sound
		while unit and unit.Parent ~= folder do
			unit = unit.Parent
			if unit == nil or unit == game then return nil end
		end
		if not unit or unit == sound then return nil end
		local side = (index or unitIndex())[ally]
		-- same idea as the "+ ADD" settings: match the sound by its NAME (and original ID) anywhere inside the unit,
		-- not by an exact path, so a sound that moved or was re-created still matches
		local saved = snd.originals[sound]
		local currentId = string.match(saved and saved.id or sound.SoundId, "%d+") or ""
		local function pick(list)
			for _, edit in ipairs(list or {}) do
				if edit.soundName == sound.Name and (edit.origId == "" or edit.origId == currentId) then
					return edit
				end
			end
			return nil
		end
		return pick(side.byId[tonumber(unit:GetAttribute("ID")) or 0]) or pick(side.byName[string.lower(unit.Name)])
	end

	-- fallback: when a scanned sound is not inside the unit right now (the game plays a copy somewhere else),
	-- an edit that found nothing in its unit applies to any sound in the game that has the same original ID
	local function globalEditFor(object)
		local saved = snd.originals[object]
		local id = string.match(saved and saved.id or object.SoundId, "%d+")
		if not id then return nil end
		for _, edit in ipairs(snd.unitEdits) do
			if edit.enabled and (edit.found or 0) == 0 and edit.origId == id and changesAnything(edit) then
				return edit
			end
		end
		return nil
	end

	-- one pass over the battlers per team, however many unit edits there are
	local function stepUnitEdits(full)
		if #snd.unitEdits == 0 then return end
		local index = unitIndex()
		for _, edit in ipairs(snd.unitEdits) do
			edit.found = 0
			if full then edit.globalHits = 0 end
		end
		for _, ally in ipairs({ true, false }) do
			if index.has[ally] then
				local folder = folderFor(ally)
				local ok, items = false, nil
				if folder then ok, items = pcall(function() return folder:GetDescendants() end) end
				if ok then
					for _, object in ipairs(items) do
						if object:IsA("Sound") and object.Name ~= "OscarPreview" then
							local edit = unitEditFor(object, ally, index)
							if edit then
								edit.found += 1
								edit.lastSound = object
								edit.appliedAt = edit.appliedAt or os.clock()
								pcall(applyTo, edit, object, nil)
							end
						end
					end
				end
			end
		end
		if full then
			local need = false
			for _, edit in ipairs(snd.unitEdits) do
				if edit.enabled and edit.found == 0 and edit.origId ~= "" and changesAnything(edit) then need = true end
			end
			if need then
				for _, root in ipairs({ Workspace, SoundService }) do
					local ok, items = pcall(function() return root:GetDescendants() end)
					for _, object in ipairs(ok and items or {}) do
						if object:IsA("Sound") and object.Name ~= "OscarPreview" then
							local edit = globalEditFor(object)
							if edit then
								edit.globalHits = (edit.globalHits or 0) + 1
								edit.lastSound = object
								edit.appliedAt = edit.appliedAt or os.clock()
								pcall(applyTo, edit, object, nil)
							end
						end
					end
				end
			end
		end
	end

	local function scanRoot(entry, root, report)
		local ok, items = pcall(function() return root:GetDescendants() end)
		if not ok then return end
		for _, object in ipairs(items) do
			if object:IsA("Sound") then pcall(apply, entry, object, report) end
		end
	end

	local function step(full)
		for _, entry in ipairs(snd.entries) do
			if entry.enabled then
				local report = { found = 0, changed = 0, err = nil }
				entry.report = report
				entry.words = keywordsOf(entry)
				if not changesAnything(entry) then
					report.err = "nothing to change yet: type a sound ID, or set a pitch / volume"
				elseif #entry.words == 0 then
					report.err = "'Sound name contains' is empty"
				elseif entry.anywhere then
					if full then
						scanRoot(entry, Workspace, report)
						scanRoot(entry, SoundService, report)
					else
						report.skip = true
					end
				else
					local folder = folderFor(entry.ally)
					if folder then
						scanRoot(entry, folder, report)
					else
						report.err = "no " .. (entry.ally and "FriendlyFolder" or "EnemyFolder") .. " yet"
					end
				end
				if report.skip then
					report.skip = nil
					entry.lastReport = entry.lastReport or report
					entry.report = entry.lastReport
				else
					entry.lastReport = report
				end
			end
		end
		stepUnitEdits(full)
	end

	local function reportText()
		local lines = {}
		for index, entry in ipairs(snd.entries) do
			local r = entry.report
			if entry.enabled and r then
				local text
				if r.err then
					text = "problem: " .. r.err
				elseif r.found == 0 then
					text = "no sound matching '" .. tostring(entry.keys) .. "' found yet (use the collector below to see the real sound names / IDs)"
				else
					text = "working on " .. r.found .. " sound(s)"
				end
				table.insert(lines, "Sound " .. index .. ": " .. text)
			end
		end
		local unitEdited, unitSounds = 0, 0
		for _, edit in ipairs(snd.unitEdits) do
			if edit.enabled and changesAnything(edit) then
				unitEdited += 1
				unitSounds += edit.found or 0
			end
		end
		if unitEdited > 0 then
			table.insert(lines, "Unit sounds: " .. unitEdited .. " edit(s) working on " .. unitSounds .. " sound(s)")
		end
		return #lines > 0 and table.concat(lines, "\n") or "Turn on the main toggle and at least one setting."
	end

	local function restoreAll()
		local list = {}
		for sound in pairs(snd.touched) do table.insert(list, sound) end
		for _, sound in ipairs(list) do restore(sound) end
	end

	local function stopLoop()
		snd.loop = false
		snd.token += 1
		for _, connection in ipairs(snd.hooks) do pcall(function() connection:Disconnect() end) end
		table.clear(snd.hooks)
		restoreAll()
		for _, edit in ipairs(snd.unitEdits) do
			if edit.refreshRow then pcall(edit.refreshRow) end
		end
	end

	local status

	local function startLoop()
		stopLoop()
		snd.loop = true
		local token = snd.token
		-- sounds created later (a death sound that is made and played at once) are changed the moment they appear
		local function onAdded(object)
			if not snd.loop or not object:IsA("Sound") then return end
			for _, entry in ipairs(snd.entries) do
				if entry.enabled and changesAnything(entry) then
					entry.words = entry.words or keywordsOf(entry)
					pcall(apply, entry, object, nil)
				end
			end
			if #snd.unitEdits > 0 and object.Name ~= "OscarPreview" then
				local handled = false
				for _, ally in ipairs({ true, false }) do
					local edit = unitEditFor(object, ally)
					if edit then
						handled = true
						pcall(applyTo, edit, object, nil)
					end
				end
				if not handled then
					local edit = globalEditFor(object)
					if edit then
						edit.globalHits = (edit.globalHits or 0) + 1
						edit.lastSound = object
						edit.appliedAt = edit.appliedAt or os.clock()
						pcall(applyTo, edit, object, nil)
					end
				end
			end
		end
		table.insert(snd.hooks, Workspace.DescendantAdded:Connect(onAdded))
		table.insert(snd.hooks, SoundService.DescendantAdded:Connect(onAdded))
		pcall(function()
			local gui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if gui then table.insert(snd.hooks, gui.DescendantAdded:Connect(onAdded)) end
		end)
		task.spawn(function()
			local ticks = 0
			while snd.loop and snd.token == token and not destroyed do
				step(ticks % 8 == 0)
				ticks += 1
				if ticks % 4 == 1 and status and os.clock() > (snd.hold or 0) then
					status.Text = reportText()
				end
				if ticks % 4 == 1 then
					for _, edit in ipairs(snd.unitEdits) do
						if edit.refreshRow then pcall(edit.refreshRow) end
					end
				end
				task.wait(0.25)
			end
		end)
	end
	Custom.soundStop = stopLoop

	local drawer, mainHeader, refreshMain = addToggleCogRow(page, "Sound Changer (death / hit / attack)", function()
		return snd.loop
	end, function(value)
		if value then startLoop() else stopLoop() end
	end)
	-- an edit does nothing while the main row is off, so the first edit switches it on by itself
	snd.autoOn = function()
		if not snd.loop then
			startLoop()
			if refreshMain then refreshMain() end
			return true
		end
		return false
	end

	local topRow = addGrayRow(drawer, "")
	local countLabel = topRow:FindFirstChildOfClass("TextLabel")
	local addButton = make("TextButton", {
		Size = UDim2.fromOffset(60, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "+ ADD",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, topRow)
	outline(addButton)
	if countLabel then countLabel.Size = UDim2.new(1, -90, 1, 0) end

	status = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		Text = "Turn the main Sound Changer row ON (it must be green). To edit ONE unit: type its ID or name in 'Unit sounds', press SCAN UNIT and change any of its sounds / pitch / volume. Or press + ADD to change a kind of sound (death / hit / attack) on every unit.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	-- ===== sound ID collector =====
	local collectState = { ally = true }
	local collectRow = addGrayRow(drawer, "")
	local collectTitle = collectRow:FindFirstChildOfClass("TextLabel")
	if collectTitle then
		collectTitle.Text = "ID collector"
		collectTitle.Size = UDim2.new(0, 90, 1, 0)
		collectTitle.TextSize = 12
	end
	local idBox = make("TextBox", {
		Size = UDim2.fromOffset(60, 24),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 96, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "unit ID",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		ClearTextOnFocus = false,
	}, collectRow)
	outline(idBox)
	local teamButton = make("TextButton", {
		Size = UDim2.fromOffset(64, 24),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 162, 0.5, 0),
		TextColor3 = BLACK,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		Text = "",
	}, collectRow)
	outline(teamButton)
	local function refreshCollectTeam()
		teamButton.Text = collectState.ally and "BLUE" or "RED"
		teamButton.BackgroundColor3 = collectState.ally and Color3.fromRGB(110, 170, 255) or Color3.fromRGB(235, 100, 100)
	end
	refreshCollectTeam()
	listen(teamButton.MouseButton1Click, function()
		collectState.ally = not collectState.ally
		refreshCollectTeam()
	end)
	local collectButton = make("TextButton", {
		Size = UDim2.fromOffset(70, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "COLLECT",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, collectRow)
	outline(collectButton)

	local allRow = addGrayRow(drawer, "")
	local allTitle = allRow:FindFirstChildOfClass("TextLabel")
	if allTitle then
		allTitle.Text = "All game sounds"
		allTitle.Size = UDim2.new(0, 130, 1, 0)
		allTitle.TextSize = 12
	end
	local filterBox = make("TextBox", {
		Size = UDim2.new(1, -230, 0, 24),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 136, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "filter (death, hit...)",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		ClearTextOnFocus = false,
	}, allRow)
	outline(filterBox)
	local scanButton = make("TextButton", {
		Size = UDim2.fromOffset(80, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "SCAN ALL",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, allRow)
	outline(scanButton)

	local results = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, drawer)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, results)

	-- the unit sound editor (filled in further down) lives here, between the collector and the settings
	local unitHolder = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, drawer)
	make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, unitHolder)

	local preview
	local function playPreview(id, volume, pitch)
		pcall(function()
			if preview then preview:Destroy() end
			preview = Instance.new("Sound")
			preview.Name = "OscarPreview"
			preview.SoundId = "rbxassetid://" .. tostring(id)
			preview.Volume = math.clamp(tonumber(volume) or 1, 0, 10)
			preview.PlaybackSpeed = math.clamp(tonumber(pitch) or 1, 0.05, 20)
			preview.Parent = SoundService
			preview:Play()
			local mine = preview
			task.delay(8, function()
				if mine and mine.Parent then mine:Destroy() end
			end)
		end)
	end
	Custom.soundPreview = playPreview

	local function addResult(order, name, id)
		local row = make("Frame", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = GRAY,
			LayoutOrder = order,
		}, results)
		outline(row)
		make("TextLabel", {
			Size = UDim2.new(1, -200, 1, 0),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 1,
			Text = name .. "  -  " .. id,
			TextColor3 = BLACK,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Font = Enum.Font.GothamBold,
		}, row)
		local function rowButton(text, offset, width)
			local button = make("TextButton", {
				Size = UDim2.fromOffset(width, 22),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -offset, 0.5, 0),
				BackgroundColor3 = WHITE,
				Text = text,
				TextColor3 = BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, row)
			outline(button)
			return button
		end
		local copy = rowButton("COPY", 6, 58)
		local use = rowButton("USE", 70, 48)
		local play = rowButton("PLAY", 124, 54)
		listen(play.MouseButton1Click, function()
			playPreview(id)
			status.Text = "Playing " .. name .. " (" .. id .. ")."
		end)
		listen(use.MouseButton1Click, function()
			local last = snd.entries[#snd.entries]
			if last and last.setSound then
				last.setSound(tonumber(id))
				status.Text = "Put " .. id .. " (" .. name .. ") into the last setting (Sound " .. #snd.entries .. ")."
			else
				status.Text = "Press + ADD first, then USE."
			end
		end)
		listen(copy.MouseButton1Click, function()
			local done = Custom.copy(id)
			copy.Text = done and "COPIED" or "no clip"
			task.delay(1.2, function()
				if copy.Parent then copy.Text = "COPY" end
			end)
			status.Text = (done and "Copied " or "Your executor can't copy; the ID is ") .. id .. " (" .. name .. ")."
		end)
	end

	local function clearResults()
		for _, child in ipairs(results:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
	end

	listen(collectButton.MouseButton1Click, function()
		clearResults()
		local wanted = math.max(0, math.floor(tonumber(idBox.Text) or 0))
		idBox.Text = wanted > 0 and tostring(wanted) or ""
		local folder = folderFor(collectState.ally)
		if not folder then
			status.Text = "No " .. (collectState.ally and "FriendlyFolder" or "EnemyFolder") .. " found. Start a battle first."
			return
		end
		local seen, found, units = {}, 0, 0
		for _, unit in folder:GetChildren() do
			if unit:IsA("Model") and (wanted == 0 or tonumber(unit:GetAttribute("ID")) == wanted) then
				units += 1
				pcall(function()
					for _, object in ipairs(unit:GetDescendants()) do
						if object:IsA("Sound") then
							local id = string.match(snd.originals[object] and snd.originals[object].id or object.SoundId, "%d+")
							if id and not seen[id] and found < 80 then
								seen[id] = true
								found += 1
								addResult(found, object.Name, id)
							end
						end
					end
				end)
			end
		end
		if found > 0 then
			status.Text = "Found " .. found .. " sound(s) on " .. units .. " battler(s). PLAY to hear one, COPY to copy it, USE to put it into your last setting."
		elseif units == 0 then
			status.Text = "No " .. (collectState.ally and "BLUE" or "RED") .. " battler" .. (wanted > 0 and (" with ID " .. wanted) or "") .. " on the field. Spawn it first or switch the team."
		else
			status.Text = units .. " battler(s) found but they hold no sounds (the game may create them only when they play). Try SCAN ALL during a fight."
		end
	end)

	listen(scanButton.MouseButton1Click, function()
		clearResults()
		local filter = string.lower((string.gsub(filterBox.Text or "", "^%s+", "")))
		local roots = { Workspace, SoundService, game:GetService("ReplicatedStorage") }
		pcall(function() table.insert(roots, game:GetService("ReplicatedFirst")) end)
		pcall(function() table.insert(roots, game:GetService("StarterPlayer")) end)
		pcall(function() table.insert(roots, game:GetService("Lighting")) end)
		local seen, list, scanned = {}, {}, 0
		status.Text = "Scanning..."
		for _, root in ipairs(roots) do
			local okScan, items = pcall(function() return root:GetDescendants() end)
			if okScan then
				for _, object in ipairs(items) do
					scanned += 1
					if scanned % 4000 == 0 then task.wait() end
					if object:IsA("Sound") and object.Name ~= "OscarPreview" then
						local id = string.match(snd.originals[object] and snd.originals[object].id or object.SoundId, "%d+")
						if id and not seen[id] then
							local owner = object.Parent and object.Parent.Name or "?"
							local label = object.Name .. " (" .. owner .. ")"
							if filter == "" or string.find(string.lower(label), filter, 1, true) or string.find(id, filter, 1, true) then
								seen[id] = true
								table.insert(list, { label = label, id = id })
							end
						end
					end
				end
			end
		end
		table.sort(list, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
		for index, item in ipairs(list) do
			if index > 250 then break end
			addResult(index, item.label, item.id)
		end
		status.Text = #list > 0 and ("Found " .. #list .. " sound(s)" .. (#list > 250 and " (showing 250, use the filter)" or "") .. ". PLAY hears it, USE puts it into your last setting.")
			or "Nothing found. The game may create its sounds only while they play: try again during a fight."
	end)

	local list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, drawer)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function refreshCount()
		if countLabel then
			countLabel.Text = "Settings: " .. tostring(#snd.entries) .. " / " .. tostring(MAX_ENTRIES)
		end
	end
	refreshCount()

	local function column(holderParent, x, width, label)
		local holder = make("Frame", {
			Size = UDim2.new(width, 0, 1, 0),
			Position = UDim2.new(x, 0, 0, 0),
			BackgroundTransparency = 1,
		}, holderParent)
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.fromOffset(0, 3),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, holder)
		return holder
	end
	local function textBox(holder, text, size, commit)
		local input = make("TextBox", {
			Size = UDim2.new(1, -12, 0, 24),
			Position = UDim2.fromOffset(6, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = size or 14,
			Font = Enum.Font.GothamBold,
			Text = text,
			ClearTextOnFocus = false,
		}, holder)
		outline(input)
		listen(input.FocusLost, function()
			commit(input)
		end)
		return input
	end

	-- ===== unit sound editor: scan one unit, then edit every sound it has =====
	local UNIT_MAX = 120
	local editState = { ally = true }
	snd.unitOrder = 0

	local function fmt(number)
		return tostring(math.floor(number * 100 + 0.5) / 100)
	end
	local function holdStatus(text)
		status.Text = text
		snd.hold = os.clock() + 8 -- keeps the loop's report from covering this message right away
	end
	local function untouch(edit)
		local mine = {}
		for sound, owner in pairs(snd.touched) do
			if owner == edit then table.insert(mine, sound) end
		end
		for _, sound in ipairs(mine) do restore(sound) end
	end

	local unitTop = addGrayRow(unitHolder, "")
	local unitTitle = unitTop:FindFirstChildOfClass("TextLabel")
	if unitTitle then
		unitTitle.Text = "Unit sounds"
		unitTitle.Size = UDim2.new(0, 78, 1, 0)
		unitTitle.TextSize = 12
	end
	local unitBox = make("TextBox", {
		Size = UDim2.new(1, -250, 0, 24),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 84, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "unit ID or name",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		ClearTextOnFocus = false,
	}, unitTop)
	outline(unitBox)
	local unitTeamButton = make("TextButton", {
		Size = UDim2.fromOffset(58, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -98, 0.5, 0),
		TextColor3 = BLACK,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
		Text = "",
	}, unitTop)
	outline(unitTeamButton)
	local function refreshUnitTeam()
		unitTeamButton.Text = editState.ally and "BLUE" or "RED"
		unitTeamButton.BackgroundColor3 = editState.ally and Color3.fromRGB(110, 170, 255) or Color3.fromRGB(235, 100, 100)
	end
	refreshUnitTeam()
	listen(unitTeamButton.MouseButton1Click, function()
		editState.ally = not editState.ally
		refreshUnitTeam()
	end)
	local unitScanButton = make("TextButton", {
		Size = UDim2.fromOffset(84, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "SCAN UNIT",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, unitTop)
	outline(unitScanButton)

	local unitCountRow = addGrayRow(unitHolder, "")
	local unitCountLabel = unitCountRow:FindFirstChildOfClass("TextLabel")
	if unitCountLabel then
		unitCountLabel.Size = UDim2.new(1, -110, 1, 0)
		unitCountLabel.TextSize = 12
	end
	local unitClearButton = make("TextButton", {
		Size = UDim2.fromOffset(90, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "CLEAR ALL",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, unitCountRow)
	outline(unitClearButton)

	local unitList = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, unitHolder)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, unitList)

	local function refreshUnitCount()
		if unitCountLabel then
			local edited = 0
			for _, edit in ipairs(snd.unitEdits) do
				if changesAnything(edit) then edited += 1 end
			end
			unitCountLabel.Text = "Scanned sounds: " .. #snd.unitEdits .. " / " .. UNIT_MAX .. "   (edited: " .. edited .. ")"
		end
	end
	refreshUnitCount()

	local function addUnitRow(edit)
		snd.unitOrder += 1
		local box = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = snd.unitOrder,
		}, unitList)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, box)

		local header = addGrayRow(box, "")
		header.LayoutOrder = 1
		local title = header:FindFirstChildOfClass("TextLabel")
		if title then
			title.Size = UDim2.new(1, -176, 1, 0)
			title.TextSize = 11
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.Text = edit.unitLabel .. "  -  " .. edit.soundName .. "  (" .. edit.origId .. ")"
		end
		local function headerButton(text, offset, width, color, textColor)
			local button = make("TextButton", {
				Size = UDim2.fromOffset(width, 22),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -offset, 0.5, 0),
				BackgroundColor3 = color or WHITE,
				Text = text,
				TextColor3 = textColor or BLACK,
				TextSize = 11,
				Font = Enum.Font.GothamBold,
			}, header)
			outline(button)
			return button
		end
		local removeButton = headerButton("X", 6, 30, Color3.fromRGB(230, 90, 90), WHITE)
		local resetButton = headerButton("RESET", 42, 50)
		local origButton = headerButton("PLAY ORIG", 98, 66)

		local fields = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 2,
		}, box)
		outline(fields)

		local baseTitle = title and title.Text or ""
		-- green only when the edit really reaches a sound in the game; yellow / red say what is wrong
		local function refreshRow()
			local color, tag = GRAY, ""
			if changesAnything(edit) then
				local refused = false
				pcall(function()
					local sound = edit.lastSound
					if edit.soundId > 0 and sound and sound.Parent and edit.appliedAt and os.clock() - edit.appliedAt > 2.5
						and sound.SoundId == "rbxassetid://" .. tostring(edit.soundId) and sound.TimeLength == 0 then
						refused = true
					end
				end)
				if not snd.loop then
					color, tag = Color3.fromRGB(255, 235, 150), "  main OFF"
				elseif (edit.found or 0) == 0 and (edit.globalHits or 0) > 0 then
					color, tag = Color3.fromRGB(200, 225, 200), "  OK (any)"
				elseif (edit.found or 0) == 0 then
					color, tag = Color3.fromRGB(255, 200, 140), "  not found"
				elseif refused then
					color, tag = Color3.fromRGB(240, 150, 150), "  ID refused"
				else
					color, tag = Color3.fromRGB(200, 225, 200), "  OK"
				end
			end
			header.BackgroundColor3 = color
			if title then title.Text = baseTitle .. tag end
		end
		edit.refreshRow = refreshRow
		local function changed()
			snd.unitDirty = true
			edit.appliedAt = nil
			if not changesAnything(edit) then
				untouch(edit)
			elseif snd.autoOn() then
				holdStatus("The Sound Changer main row was off, so I switched it ON for you.")
			end
			refreshRow()
			refreshUnitCount()
		end

		local idInput = textBox(column(fields, 0, 0.34, "New sound ID"), edit.soundId > 0 and tostring(edit.soundId) or "", 13, function(input)
			local number = tonumber(string.match(input.Text, "%d+"))
			edit.soundId = number and math.floor(number) or 0
			input.Text = edit.soundId > 0 and tostring(edit.soundId) or ""
			if edit.soundId <= 0 then restoreIds(edit) end
			changed()
		end)
		idInput.PlaceholderText = "original"
		idInput.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
		local pitchInput = textBox(column(fields, 0.34, 0.2, "Pitch x"), fmt(edit.pitch), 14, function(input)
			local number = tonumber(input.Text)
			edit.pitch = number and math.clamp(number, 0.05, 20) or 1
			input.Text = fmt(edit.pitch)
			changed()
		end)
		local volumeInput = textBox(column(fields, 0.54, 0.2, "Volume x"), fmt(edit.volume), 14, function(input)
			local number = tonumber(input.Text)
			edit.volume = number and math.clamp(number, 0, 10) or 1
			input.Text = fmt(edit.volume)
			changed()
		end)
		local playHolder = column(fields, 0.74, 0.26, "Hear it")
		local playNew = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = "PLAY NEW",
		}, playHolder)
		outline(playNew)

		-- previews use the sound's own loudness / speed as the starting point, like the game does
		local baseVolume = edit.origVolume > 0 and edit.origVolume or 1
		local baseSpeed = edit.origSpeed > 0 and edit.origSpeed or 1
		listen(playNew.MouseButton1Click, function()
			local id = edit.soundId > 0 and edit.soundId or tonumber(edit.origId)
			if not id then
				holdStatus("This sound has no ID to play.")
				return
			end
			playPreview(id, baseVolume * edit.volume, baseSpeed * edit.pitch)
			holdStatus("Playing " .. tostring(id) .. " at pitch " .. fmt(edit.pitch) .. ", volume " .. fmt(edit.volume) .. ". If you hear nothing, Roblox does not allow this sound ID in this game.")
		end)
		listen(origButton.MouseButton1Click, function()
			local id = tonumber(edit.origId)
			if not id then
				holdStatus("This sound has no ID to play.")
				return
			end
			playPreview(id, baseVolume, baseSpeed)
			holdStatus("Playing the original " .. tostring(id) .. " (" .. edit.soundName .. ").")
		end)
		listen(resetButton.MouseButton1Click, function()
			restoreIds(edit)
			edit.soundId, edit.pitch, edit.volume = 0, 1, 1
			idInput.Text = ""
			pitchInput.Text = fmt(edit.pitch)
			volumeInput.Text = fmt(edit.volume)
			changed()
			holdStatus(edit.soundName .. " is back to the game's own sound.")
		end)
		edit.remove = function()
			untouch(edit)
			local index = table.find(snd.unitEdits, edit)
			if index then table.remove(snd.unitEdits, index) end
			snd.unitDirty = true
			box:Destroy()
			refreshUnitCount()
		end
		listen(removeButton.MouseButton1Click, edit.remove)
		refreshRow()
	end

	snd.addUnitEdit = function(init)
		if #snd.unitEdits >= UNIT_MAX then return false end
		local edit = {
			enabled = true, ally = true, id = 0, unitName = "", unitLabel = "?", path = "", soundName = "?",
			origId = "", origVolume = 1, origSpeed = 1, soundId = 0, volume = 1, pitch = 1,
		}
		for key, value in pairs(init or {}) do edit[key] = value end
		table.insert(snd.unitEdits, edit)
		snd.unitDirty = true
		addUnitRow(edit)
		refreshUnitCount()
		return true
	end

	-- onlyUntouched = true keeps the rows you changed and drops the rest
	snd.clearUnitEdits = function(onlyUntouched)
		local copy = {}
		for _, edit in ipairs(snd.unitEdits) do table.insert(copy, edit) end
		for _, edit in ipairs(copy) do
			if not onlyUntouched or not changesAnything(edit) then edit.remove() end
		end
	end

	local function scanUnit()
		local query = string.lower(string.match(unitBox.Text or "", "^%s*(.-)%s*$") or "")
		if query == "" then
			holdStatus("Type a unit ID or name first (like 57 or deathbringer), then press SCAN UNIT.")
			return
		end
		local folder = folderFor(editState.ally)
		if not folder then
			holdStatus("No " .. (editState.ally and "FriendlyFolder" or "EnemyFolder") .. " found. Start a battle first.")
			return
		end
		local wantedId = tonumber(query)
		snd.clearUnitEdits(true)
		local seenUnit, units, soundsFound, skipped = {}, 0, 0, 0
		for _, unit in ipairs(folder:GetChildren()) do
			if unit:IsA("Model") then
				local uid = math.floor(tonumber(unit:GetAttribute("ID")) or 0)
				local uname = string.lower(unit.Name)
				local display = tostring(unit:GetAttribute("DisplayName") or "")
				local match
				if wantedId then
					match = uid == wantedId
				else
					match = string.find(uname, query, 1, true) or string.find(string.lower(display), query, 1, true)
				end
				local unitKey = tostring(uid) .. "|" .. uname
				if match and not seenUnit[unitKey] then
					seenUnit[unitKey] = true
					units += 1
					local label = display ~= "" and display or unit.Name
					local okScan, objects = pcall(function() return unit:GetDescendants() end)
					for _, object in ipairs(okScan and objects or {}) do
						if object:IsA("Sound") and object.Name ~= "OscarPreview" then
							soundsFound += 1
							local path = pathIn(unit, object)
							local exists = false
							for _, other in ipairs(snd.unitEdits) do
								if other.ally == editState.ally and other.id == uid and other.unitName == uname and other.path == path then
									exists = true
									break
								end
							end
							if not exists then
								local saved = snd.originals[object]
								local ok = snd.addUnitEdit({
									ally = editState.ally,
									id = uid,
									unitName = uname,
									unitLabel = label,
									path = path,
									soundName = object.Name,
									origId = string.match(saved and saved.id or object.SoundId, "%d+") or "",
									origVolume = saved and saved.volume or object.Volume,
									origSpeed = saved and saved.speed or object.PlaybackSpeed,
								})
								if not ok then skipped += 1 end
							end
						end
					end
				end
			end
		end
		if units == 0 then
			holdStatus("No " .. (editState.ally and "BLUE" or "RED") .. " unit matching '" .. query .. "' is on the field. Spawn it first or switch the team.")
		elseif soundsFound == 0 then
			holdStatus(units .. " unit(s) found but they hold no sounds right now (the game may create them only while they play). Try again while it fights.")
		else
			holdStatus("Found " .. soundsFound .. " sound(s) on " .. units .. " unit(s). Type a new sound ID and / or pitch / volume on any row, PLAY NEW to hear it." .. (snd.loop and "" or " Turn the main Sound Changer row ON to apply it in the game.") .. (skipped > 0 and (" The list is full, " .. skipped .. " skipped.") or ""))
		end
	end
	listen(unitScanButton.MouseButton1Click, scanUnit)
	listen(unitBox.FocusLost, function(enterPressed)
		if enterPressed then scanUnit() end
	end)
	listen(unitClearButton.MouseButton1Click, function()
		snd.clearUnitEdits(false)
		holdStatus("Cleared the scanned sounds. The game's own sounds are back.")
	end)

	local function addEntry(init)
		if #snd.entries >= MAX_ENTRIES then
			status.Text = "That is the maximum: " .. tostring(MAX_ENTRIES) .. " settings."
			return
		end
		local entry = { enabled = true, id = 0, ally = true, anywhere = false, typeIndex = 1, keys = TYPES[1].keys, soundId = 0, volume = 1, pitch = 1 }
		if type(init) == "table" then
			for key, value in pairs(init) do entry[key] = value end
		end
		table.insert(snd.entries, entry)

		local box = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = #snd.entries,
		}, list)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, box)

		local header = addGrayRow(box, "")
		local title = header:FindFirstChildOfClass("TextLabel")
		if title then
			title.Size = UDim2.new(1, -110, 1, 0)
			title.TextSize = 12
			title.TextTruncate = Enum.TextTruncate.AtEnd
		end
		local function refreshHeader()
			local index = table.find(snd.entries, entry) or 0
			if title then
				local scope = entry.anywhere and "anywhere" or ((entry.id > 0 and ("ID " .. tostring(entry.id)) or "every battler") .. (entry.ally and "  BLUE" or "  RED"))
				title.Text = "Sound " .. tostring(index) .. "  -  " .. TYPES[entry.typeIndex].name .. "  -  " .. scope
			end
			header.BackgroundColor3 = entry.enabled and Color3.fromRGB(200, 225, 200) or GRAY
		end
		entry.refreshHeader = refreshHeader

		local switchButton = make("TextButton", {
			Size = UDim2.fromOffset(44, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -44, 0.5, 0),
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, header)
		outline(switchButton)
		local function refreshSwitch()
			switchButton.Text = entry.enabled and "ON" or "OFF"
			switchButton.BackgroundColor3 = entry.enabled and ON_COLOR or WHITE
		end
		refreshSwitch()
		listen(switchButton.MouseButton1Click, function()
			entry.enabled = not entry.enabled
			refreshSwitch()
			refreshHeader()
			if not entry.enabled then
				local mine = {}
				for sound, owner in pairs(snd.touched) do
					if owner == entry then table.insert(mine, sound) end
				end
				for _, sound in ipairs(mine) do restore(sound) end
			end
		end)

		local removeButton = make("TextButton", {
			Size = UDim2.fromOffset(32, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(230, 90, 90),
			Text = "X",
			TextColor3 = WHITE,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
		}, header)
		outline(removeButton)
		entry.remove = function()
			local mine = {}
			for sound, owner in pairs(snd.touched) do
				if owner == entry then table.insert(mine, sound) end
			end
			for _, sound in ipairs(mine) do restore(sound) end
			local index = table.find(snd.entries, entry)
			if index then table.remove(snd.entries, index) end
			box:Destroy()
			for _, other in ipairs(snd.entries) do
				other.refreshHeader()
			end
			refreshCount()
		end
		listen(removeButton.MouseButton1Click, entry.remove)

		-- row 1: unit ID | sound ID | goes on
		local fields = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 2,
		}, box)
		outline(fields)
		textBox(column(fields, 0, 0.22, "Unit ID (0=all)"), tostring(entry.id), 14, function(input)
			local number = tonumber(input.Text)
			entry.id = (number and number > 0) and math.floor(number) or 0
			input.Text = tostring(entry.id)
			refreshHeader()
		end)
		local soundInput
		soundInput = textBox(column(fields, 0.22, 0.4, "New sound ID"), entry.soundId > 0 and tostring(entry.soundId) or "", 13, function(input)
			local number = tonumber(string.match(input.Text, "%d+"))
			entry.soundId = number and math.floor(number) or 0
			input.Text = entry.soundId > 0 and tostring(entry.soundId) or ""
			if entry.soundId <= 0 then restoreIds(entry) end
		end)
		entry.setSound = function(number)
			entry.soundId = number
			soundInput.Text = tostring(number)
		end
		local teamHolder = column(fields, 0.62, 0.38, "Goes on")
		local teamButton2 = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, teamHolder)
		outline(teamButton2)
		local function refreshTeam()
			teamButton2.Text = entry.ally and "BLUE unit" or "RED enemy"
			teamButton2.BackgroundColor3 = entry.ally and Color3.fromRGB(110, 170, 255) or Color3.fromRGB(235, 100, 100)
		end
		refreshTeam()
		listen(teamButton2.MouseButton1Click, function()
			entry.ally = not entry.ally
			refreshTeam()
			refreshHeader()
		end)

		-- row 2: replaces | name keywords | scope
		local second = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 3,
		}, box)
		outline(second)
		local typeHolder = column(second, 0, 0.22, "Replaces")
		local typeButton = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = TYPES[entry.typeIndex].name,
		}, typeHolder)
		outline(typeButton)
		local keysBox
		keysBox = textBox(column(second, 0.22, 0.5, "Sound name / ID contains (comma list)"), entry.keys, 12, function(input)
			entry.keys = input.Text
			if entry.typeIndex ~= #TYPES and string.lower(input.Text) ~= TYPES[entry.typeIndex].keys then
				entry.typeIndex = #TYPES
				typeButton.Text = TYPES[entry.typeIndex].name
				refreshHeader()
			end
		end)
		listen(typeButton.MouseButton1Click, function()
			entry.typeIndex = entry.typeIndex % #TYPES + 1
			if TYPES[entry.typeIndex].keys ~= "" then
				entry.keys = TYPES[entry.typeIndex].keys
				keysBox.Text = entry.keys
			end
			typeButton.Text = TYPES[entry.typeIndex].name
			refreshHeader()
		end)
		local scopeHolder = column(second, 0.72, 0.28, "Where")
		local scopeButton = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, scopeHolder)
		outline(scopeButton)
		local function refreshScope()
			scopeButton.Text = entry.anywhere and "ANYWHERE" or "ON BATTLER"
		end
		refreshScope()
		listen(scopeButton.MouseButton1Click, function()
			entry.anywhere = not entry.anywhere
			refreshScope()
			refreshHeader()
		end)

		-- row 3: volume | pitch | test
		local third = make("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = GRAY,
			LayoutOrder = 4,
		}, box)
		outline(third)
		textBox(column(third, 0, 0.3, "Volume x"), tostring(entry.volume), 14, function(input)
			local number = tonumber(input.Text)
			entry.volume = number and math.clamp(number, 0, 10) or 1
			input.Text = tostring(entry.volume)
		end)
		textBox(column(third, 0.3, 0.3, "Pitch / speed x"), tostring(entry.pitch), 14, function(input)
			local number = tonumber(input.Text)
			entry.pitch = number and math.clamp(number, 0.05, 20) or 1
			input.Text = tostring(entry.pitch)
		end)
		local testHolder = column(third, 0.6, 0.4, "Hear it")
		local testButton = make("TextButton", {
			Size = UDim2.new(1, -10, 0, 24),
			Position = UDim2.fromOffset(5, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "PLAY NEW SOUND",
		}, testHolder)
		outline(testButton)
		listen(testButton.MouseButton1Click, function()
			if entry.soundId > 0 then
				playPreview(entry.soundId, entry.volume, entry.pitch)
				status.Text = "Playing " .. tostring(entry.soundId) .. " at pitch " .. tostring(entry.pitch) .. ", volume " .. tostring(entry.volume) .. ". If you hear nothing, Roblox does not allow this sound ID in this game."
			else
				status.Text = "Type a sound ID first."
			end
		end)

		refreshHeader()
		refreshCount()
		status.Text = "Added setting " .. tostring(#snd.entries) .. "."
	end

	-- ===== save / load =====
	-- OSS2 also holds the unit sound edits (rows starting with U); OSS1 codes from before still load
	local function clean(value)
		return (string.gsub(tostring(value or ""), "[|~]", ""))
	end
	local function serializeSound()
		local rows = {}
		for _, entry in ipairs(snd.entries) do
			rows[#rows + 1] = table.concat({
				entry.enabled and 1 or 0, entry.ally and 1 or 0, entry.anywhere and 1 or 0, entry.id, entry.soundId,
				entry.volume, entry.pitch, entry.typeIndex, (string.gsub(entry.keys or "", "[|~]", "")),
			}, "~")
		end
		for _, edit in ipairs(snd.unitEdits) do
			rows[#rows + 1] = table.concat({
				"U", edit.enabled and 1 or 0, edit.ally and 1 or 0, edit.id, clean(edit.unitName), clean(edit.path),
				edit.soundId, edit.volume, edit.pitch, clean(edit.unitLabel), clean(edit.soundName), clean(edit.origId),
				edit.origVolume, edit.origSpeed,
			}, "~")
		end
		local body = Custom.encodeBase64(table.concat(rows, "|"))
		return "OSS2" .. body .. Custom.checksum(body)
	end
	local function loadSound(code)
		code = string.gsub(code or "", "%s", "")
		local head = string.sub(code, 1, 4)
		if (head ~= "OSS1" and head ~= "OSS2") or #code < 5 then
			return false, "That is not a valid sound code."
		end
		local body = string.sub(code, 5, #code - 1)
		if Custom.checksum(body) ~= string.sub(code, #code) then
			return false, "The code is damaged (a character is wrong or missing)."
		end
		local ok, decoded = pcall(decodeBase64, body)
		if not ok then return false, "The code could not be read." end
		local list, unitList = {}, {}
		if decoded ~= "" then
			for _, row in ipairs(string.split(decoded, "|")) do
				local f = string.split(row, "~")
				if f[1] == "U" then
					if #f < 14 then return false, "The code could not be read." end
					if #unitList < UNIT_MAX then
						unitList[#unitList + 1] = {
							enabled = f[2] == "1",
							ally = f[3] ~= "0",
							id = math.max(0, math.floor(tonumber(f[4]) or 0)),
							unitName = f[5],
							path = f[6],
							soundId = math.max(0, math.floor(tonumber(f[7]) or 0)),
							volume = math.clamp(tonumber(f[8]) or 1, 0, 10),
							pitch = math.clamp(tonumber(f[9]) or 1, 0.05, 20),
							unitLabel = f[10],
							soundName = f[11],
							origId = f[12],
							origVolume = tonumber(f[13]) or 1,
							origSpeed = tonumber(f[14]) or 1,
						}
					end
				else
					if #f < 8 then return false, "The code could not be read." end
					if #list < MAX_ENTRIES then
						local typeIndex = math.clamp(math.floor(tonumber(f[8]) or 1), 1, #TYPES)
						list[#list + 1] = {
							enabled = f[1] == "1",
							ally = f[2] ~= "0",
							anywhere = f[3] == "1",
							id = math.max(0, math.floor(tonumber(f[4]) or 0)),
							soundId = math.max(0, math.floor(tonumber(f[5]) or 0)),
							volume = math.clamp(tonumber(f[6]) or 1, 0, 10),
							pitch = math.clamp(tonumber(f[7]) or 1, 0.05, 20),
							typeIndex = typeIndex,
							keys = f[9] or TYPES[typeIndex].keys,
						}
					end
				end
			end
		end
		while #snd.entries > 0 do
			snd.entries[#snd.entries].remove()
		end
		snd.clearUnitEdits(false)
		for _, init in ipairs(list) do
			addEntry(init)
		end
		for _, init in ipairs(unitList) do
			snd.addUnitEdit(init)
		end
		return true, #list + #unitList
	end
	Custom.soundSerialize, Custom.soundLoad = serializeSound, loadSound

	local saveRow = addGrayRow(drawer, "Save / Load sounds")
	local function saveButton(text, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, saveRow)
		outline(button)
		return button
	end
	local loadButton = saveButton("LOAD", 8)
	local saveCodeButton = saveButton("SAVE", 68)
	local codeRow = addGrayRow(drawer, "Code")
	local codeBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "save to get a code / paste one here",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, codeRow)
	outline(codeBox)
	listen(saveCodeButton.MouseButton1Click, function()
		local code = serializeSound()
		codeBox.Text = code
		status.Text = Custom.copy(code) and "Saved! The code is in the box and copied to your clipboard." or "Saved! Copy the code from the box."
	end)
	listen(loadButton.MouseButton1Click, function()
		local ok, result = loadSound(codeBox.Text)
		status.Text = ok and ("Loaded " .. tostring(result) .. " setting(s).") or ("Could not load: " .. tostring(result))
	end)

	listen(addButton.MouseButton1Click, function() addEntry() end)
	addEntry()
end)

-- WEATHER CHANGER (Misc tab): lighting / day & night, rain, fog and a skybox you can recolour
-- POV Extender (Misc tab): field of view (screen bigger / smaller) and how far you can zoom out
safeBuild("POV Extender", function()
	local page = pages["Misc"]
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local pov = { on = false, fov = 70, maxZoom = 128, minZoom = 0.5, saved = nil, bound = false }
	Custom.pov = pov

	local function camera()
		return Workspace.CurrentCamera
	end

	local function applyZoomLimits()
		local player = Players.LocalPlayer
		if not player then return end
		pcall(function()
			player.CameraMinZoomDistance = pov.minZoom
			player.CameraMaxZoomDistance = math.max(pov.maxZoom, pov.minZoom + 0.5)
		end)
	end

	local function stop()
		pov.on = false
		if pov.bound then
			pov.bound = false
			pcall(function() RunService:UnbindFromRenderStep("OscarPOV") end)
		end
		if pov.saved then
			local cam = camera()
			if cam then pcall(function() cam.FieldOfView = pov.saved.fov end) end
			local player = Players.LocalPlayer
			if player then
				pcall(function()
					player.CameraMinZoomDistance = pov.saved.minZoom
					player.CameraMaxZoomDistance = pov.saved.maxZoom
				end)
			end
			pov.saved = nil
		end
	end

	local function start()
		stop()
		local cam, player = camera(), Players.LocalPlayer
		pov.saved = {
			fov = cam and cam.FieldOfView or 70,
			minZoom = player and player.CameraMinZoomDistance or 0.5,
			maxZoom = player and player.CameraMaxZoomDistance or 128,
		}
		pov.on = true
		applyZoomLimits()
		-- the game / camera script rewrites the field of view all the time, so it is set again after every camera update
		pov.bound = true
		RunService:BindToRenderStep("OscarPOV", Enum.RenderPriority.Camera.Value + 1, function()
			local current = camera()
			if current and pov.on and math.abs(current.FieldOfView - pov.fov) > 0.01 then
				current.FieldOfView = pov.fov
			end
		end)
	end
	Custom.povStop = stop

	local drawer = addToggleCogRow(page, "POV Extender (screen bigger / smaller)", function()
		return pov.on
	end, function(value)
		if value then start() else stop() end
	end)

	local info = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text = "Turn the main row ON. FOV 1-120: a bigger number shows MORE of the world (screen zoomed out), a smaller number zooms IN. Max zoom lets you scroll the camera much farther away.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local fovBox
	local function setFov(value)
		pov.fov = math.clamp(value, 1, 120)
		if fovBox then fovBox.Text = tostring(math.floor(pov.fov * 10 + 0.5) / 10) end
	end

	local fovRow = addGrayRow(drawer, "Field of view (1-120)")
	fovBox = addNumberBox(fovRow, tostring(pov.fov), function(box)
		local number = tonumber(box.Text)
		setFov(number or pov.fov)
		box.Text = tostring(math.floor(pov.fov * 10 + 0.5) / 10)
		if not pov.on then start() end
	end)

	local presetRow = addGrayRow(drawer, "Quick FOV")
	local function presetButton(text, offset, width, value)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, presetRow)
		outline(button)
		listen(button.MouseButton1Click, function()
			setFov(value)
			if not pov.on then start() end
		end)
	end
	presetButton("ZOOM IN 30", 8, 74, 30)
	presetButton("NORMAL 70", 88, 78, 70)
	presetButton("WIDE 120", 172, 74, 120)

	local maxRow = addGrayRow(drawer, "Max zoom out distance")
	addNumberBox(maxRow, tostring(pov.maxZoom), function(box)
		local number = tonumber(box.Text)
		pov.maxZoom = number and math.clamp(number, 1, 100000) or pov.maxZoom
		box.Text = tostring(pov.maxZoom)
		if pov.on then applyZoomLimits() else start() end
	end)

	local minRow = addGrayRow(drawer, "Min zoom in distance")
	addNumberBox(minRow, tostring(pov.minZoom), function(box)
		local number = tonumber(box.Text)
		pov.minZoom = number and math.clamp(number, 0, 1000) or pov.minZoom
		box.Text = tostring(pov.minZoom)
		if pov.on then applyZoomLimits() else start() end
	end)
end)

-- View From Their Perspective (Misc tab): the camera sits in the head of a battler / unit and looks where it looks.
-- Switch it OFF and the camera goes back to normal.
safeBuild("Their Perspective", function()
	local page = pages["Misc"]
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local view = { on = false, team = 2, unitId = 0, target = nil, bound = false, saved = nil, hidden = {}, hideAcc = true, refreshAt = 0, fov = 80, forward = 0, autoNext = true, spin = 0, angle = 0, spinAngle = 0, lastRender = nil, yaw = 0, yawSpin = 0, yawSpinAngle = 0, side = 0, pitch = 0, levelMode = 1, third = false, dist = 12, orbitYaw = 0, orbitPitch = 15, orbitInit = false, inputConns = {}, pinchStart = 12 }
	Custom.theirView = view

	local function camera()
		return Workspace.CurrentCamera
	end

	local function isAlive(model)
		if not model or not model.Parent then return false end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		return model:FindFirstChild("Head") ~= nil and (not humanoid or humanoid.Health > 0)
	end

	-- every living battler that matches the chosen team / battler ID, in a steady order
	local function candidates()
		local list = {}
		for _, folderName in ipairs({ "EnemyFolder", "FriendlyFolder" }) do
			local isAlly = folderName == "FriendlyFolder"
			if view.team == 2 or (view.team == 1) == isAlly then
				local folder = npcFolder(folderName)
				if folder then
					for _, npc in ipairs(folder:GetChildren()) do
						if npc:IsA("Model") and isAlive(npc) and (view.unitId <= 0 or tonumber(npc:GetAttribute("ID")) == view.unitId) then
							table.insert(list, npc)
						end
					end
				end
			end
		end
		return list
	end

	-- From inside the head the head itself, and everything on it (hats, hair, helmets, masks ...), would fill the
	-- screen, so they are made invisible for YOU only (LocalTransparencyModifier, nobody else sees a change).
	-- view.hidden remembers the old value of every part, so everything becomes visible again when the view is
	-- switched off, the target changes, the setting is turned off or the script is deleted.
	local BODY_PARTS = {
		Torso = true, HumanoidRootPart = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
		UpperTorso = true, LowerTorso = true, LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
		RightUpperArm = true, RightLowerArm = true, RightHand = true, LeftUpperLeg = true, LeftLowerLeg = true,
		LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	}

	local function remember(object)
		if object:IsA("BasePart") and view.hidden[object] == nil then
			view.hidden[object] = object.LocalTransparencyModifier
		end
	end

	local HEAD_ATTACHMENTS = {
		HatAttachment = true, HairAttachment = true, FaceFrontAttachment = true, FaceCenterAttachment = true,
	}

	-- true when this part is worn on the head (hat / hair / face / mask) - and NOT a weapon held in a hand
	local function isOnHead(part, head)
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("Attachment") and HEAD_ATTACHMENTS[child.Name] then return true end
			if child:IsA("JointInstance") or child:IsA("WeldConstraint") then
				if child.Part0 == head or child.Part1 == head then return true end
			end
		end
		return (part.Position - head.Position).Magnitude < 1.8
	end

	-- finds every part that has to disappear (new accessories that show up later are picked up too)
	local function refreshHidden(model)
		if not model then return end
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			remember(head)
			for _, child in ipairs(head:GetDescendants()) do remember(child) end
		end
		if not view.hideAcc or not (head and head:IsA("BasePart")) then return end
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("Accessory") or object:IsA("Accoutrement") then
				-- hats / hair / masks only: an accessory that is not on the head (a weapon, a backpack) stays visible
				local handle = object:FindFirstChild("Handle")
				if not handle or (handle:IsA("BasePart") and isOnHead(handle, head)) then
					for _, part in ipairs(object:GetDescendants()) do remember(part) end
				end
			elseif object:IsA("BasePart") and object ~= head and not BODY_PARTS[object.Name]
				and not object:IsDescendantOf(head) and not object:FindFirstAncestorWhichIsA("Accessory")
				and not object:FindFirstAncestorWhichIsA("Tool") then
				-- loose helmet / hair / mask parts that are not an Accessory but are joined to the head
				if isOnHead(object, head) then remember(object) end
			end
		end
	end

	local function applyHidden()
		for object in pairs(view.hidden) do
			if object.Parent then
				pcall(function() object.LocalTransparencyModifier = 1 end)
			end
		end
	end

	local function restoreHidden()
		for object, old in pairs(view.hidden) do
			pcall(function() object.LocalTransparencyModifier = old end)
		end
		table.clear(view.hidden)
	end

	local function setTarget(model)
		view.target = model
		restoreHidden()
		view.refreshAt = 0
		view.orbitInit = false
		if model and not view.third then
			refreshHidden(model)
			applyHidden()
		end
	end

	local function pickNext()
		local list = candidates()
		if #list == 0 then
			setTarget(nil)
			return nil
		end
		local index = table.find(list, view.target)
		setTarget(list[index and (index % #list + 1) or 1])
		return view.target
	end

	-- the view uses a camera of its own: the game keeps rewriting the normal camera every frame (that is why
	-- the head just went invisible and nothing moved), but it cannot touch a camera it has never seen
	local function restoreCamera()
		local saved = view.saved
		if not saved then return end
		pcall(function()
			local original = saved.camera
			if original and original.Parent then
				Workspace.CurrentCamera = original
				original.CameraType = saved.cameraType
				original.FieldOfView = saved.fov
				local player = Players.LocalPlayer
				local character = player and player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				original.CameraSubject = saved.subject or humanoid
			end
		end)
		if view.ownCamera then
			pcall(function() view.ownCamera:Destroy() end)
			view.ownCamera = nil
		end
	end

	local function stop()
		view.on = false
		if view.bound then
			view.bound = false
			pcall(function() RunService:UnbindFromRenderStep("OscarTheirView") end)
		end
		for _, connection in ipairs(view.inputConns) do pcall(function() connection:Disconnect() end) end
		table.clear(view.inputConns)
		setTarget(nil)
		restoreCamera()
		view.saved = nil
	end

	local UserInputService = game:GetService("UserInputService")

	local function start()
		stop()
		local cam = camera()
		if not cam then return end
		view.saved = { camera = cam, cameraType = cam.CameraType, subject = cam.CameraSubject, fov = cam.FieldOfView }
		local own = Instance.new("Camera")
		own.Name = "OscarTheirViewCamera"
		own.CameraType = Enum.CameraType.Scriptable
		own.FieldOfView = view.fov
		own.CFrame = cam.CFrame
		own.Parent = Workspace
		view.ownCamera = own
		view.on = true
		view.spinAngle, view.yawSpinAngle, view.lastRender = 0, 0, nil
		pickNext()
		-- third person controls: drag (finger / right mouse button) turns around the battler, wheel / pinch zooms
		table.insert(view.inputConns, UserInputService.InputChanged:Connect(function(input, processed)
			if not view.on or not view.third then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
					view.orbitYaw -= input.Delta.X * 0.3
					view.orbitPitch = math.clamp(view.orbitPitch + input.Delta.Y * 0.3, -80, 80)
				end
			elseif input.UserInputType == Enum.UserInputType.Touch then
				if processed then return end
				view.orbitYaw += input.Delta.X * 0.3
				view.orbitPitch = math.clamp(view.orbitPitch - input.Delta.Y * 0.3, -80, 80)
			elseif input.UserInputType == Enum.UserInputType.MouseWheel then
				view.dist = math.clamp(view.dist - input.Position.Z * 3, 1, 200)
			end
		end))
		table.insert(view.inputConns, UserInputService.TouchPinch:Connect(function(_, scale, _, state)
			if not view.on or not view.third then return end
			if state == Enum.UserInputState.Begin then view.pinchStart = view.dist end
			view.dist = math.clamp(view.pinchStart / math.max(scale, 0.05), 1, 200)
		end))
		view.bound = true
		-- the very last render step, so the game's own camera script can never overwrite it
		RunService:BindToRenderStep("OscarTheirView", Enum.RenderPriority.Last.Value + 10, function()
			local own = view.ownCamera
			if not own or not own.Parent or not view.on then return end
			if not isAlive(view.target) then
				if view.autoNext then pickNext() else setTarget(nil) end
			end
			local target = view.target
			local head = target and target:FindFirstChild("Head")
			if target then
				if view.third then
					if next(view.hidden) then restoreHidden() end -- third person: the head is visible again
				else
					if os.clock() >= view.refreshAt then
						view.refreshAt = os.clock() + 0.3
						refreshHidden(target)
					end
					applyHidden() -- every frame, in case the game shows them again
				end
			end
			if head and head:IsA("BasePart") then
				if Workspace.CurrentCamera ~= own then
					Workspace.CurrentCamera = own -- if the game switched cameras back, take it again
				end
				if own.CameraType ~= Enum.CameraType.Scriptable then
					own.CameraType = Enum.CameraType.Scriptable
				end
				own.FieldOfView = view.fov
				local now = os.clock()
				local frameTime = view.lastRender and math.min(now - view.lastRender, 0.1) or 0
				view.lastRender = now
				-- rotate changer: a fixed tilt plus a steady spin (turns per second, decimals ok, negative = the other way)
				view.spinAngle = (view.spinAngle + view.spin * 360 * frameTime) % 360
				local roll = view.angle + view.spinAngle
				local position = head.Position
				local look = head.CFrame.LookVector
				local base
				if view.third then
					-- third person: orbit around the battler like the normal Roblox camera
					if not view.orbitInit then
						view.orbitInit = true
						local root = target:FindFirstChild("HumanoidRootPart")
						local facing = root and root.CFrame.LookVector or look
						view.orbitYaw = math.deg(math.atan2(-facing.X, -facing.Z))
					end
					local focus = position + Vector3.new(0, 1, 0)
					local direction = (CFrame.Angles(0, math.rad(view.orbitYaw), 0) * CFrame.Angles(-math.rad(view.orbitPitch), 0, 0)).LookVector
					base = CFrame.lookAt(focus - direction * view.dist, focus)
				else
					-- first person: View direction 0 = the head exactly as it is (it can be tilted), 1 = upright, 2 = where the body faces
					if view.levelMode == 2 then
						local root = target:FindFirstChild("HumanoidRootPart")
						if root then
							look = root.CFrame.LookVector
							look = Vector3.new(look.X, math.clamp(look.Y, -0.5, 0.5), look.Z)
						end
					end
					if view.levelMode ~= 0 and look.Magnitude > 0.01 and math.abs(look.Unit.Y) < 0.98 then
						base = CFrame.lookAt(position, position + look)
					else
						base = head.CFrame
					end
					if view.forward ~= 0 or view.side ~= 0 then base = base * CFrame.new(view.side, 0, -view.forward) end
					-- left / right: turns the view sideways (positive = right, negative = left); the spin keeps turning
					view.yawSpinAngle = (view.yawSpinAngle + view.yawSpin * 360 * frameTime) % 360
					local turn = view.yaw + view.yawSpinAngle
					if turn ~= 0 then base = base * CFrame.Angles(0, -math.rad(turn), 0) end
					if view.pitch ~= 0 then base = base * CFrame.Angles(math.rad(view.pitch), 0, 0) end
				end
				own.CFrame = roll == 0 and base or base * CFrame.Angles(0, 0, math.rad(roll))
			else
				-- nobody to look through right now: the normal camera until one shows up
				local original = view.saved and view.saved.camera
				if original and original.Parent and Workspace.CurrentCamera ~= original then
					Workspace.CurrentCamera = original
				end
			end
		end)
	end
	Custom.theirViewStop = stop

	local drawer = addToggleCogRow(page, "Battler POV (view from a battler / unit head)", function()
		return view.on
	end, function(value)
		if value then start() else stop() end
	end)

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text = "Turn the main row ON: your camera sits in the head of a battler / unit (first person). Switch it OFF and the camera goes back to normal. NEXT jumps to another battler.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	-- warning
	make("TextLabel", {
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(120, 0, 0),
		BackgroundTransparency = 0.2,
		Text = "WARNING: turning this OFF will break the camera.",
		TextColor3 = WHITE,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, drawer)

	local teamRow = addGrayRow(drawer, "Whose view")
	local teamButton = make("TextButton", {
		Size = UDim2.fromOffset(110, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = Custom.TEAM_NAMES[view.team],
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, teamRow)
	outline(teamButton)
	listen(teamButton.MouseButton1Click, function()
		view.team = (view.team + 1) % 3
		teamButton.Text = Custom.TEAM_NAMES[view.team]
		if view.on then setTarget(nil); pickNext() end
	end)

	addNumberBox(addGrayRow(drawer, "Battler ID (0 = any)"), "0", function(box)
		local number = tonumber(box.Text)
		view.unitId = (number and number > 0) and math.floor(number) or 0
		box.Text = tostring(view.unitId)
		if view.on then setTarget(nil); pickNext() end
	end)

	local nextRow = addGrayRow(drawer, "Switch battler")
	local nextButton = make("TextButton", {
		Size = UDim2.fromOffset(80, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "NEXT",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, nextRow)
	outline(nextButton)
	listen(nextButton.MouseButton1Click, function()
		if not view.on then start() else pickNext() end
	end)

	addSwitch(addGrayRow(drawer, "Jump to another battler when it dies"), function()
		return view.autoNext
	end, function(value)
		view.autoNext = value
	end)

	addSwitch(addGrayRow(drawer, "Hide head accessories (hats, hair, helmets)"), function()
		return view.hideAcc
	end, function(value)
		view.hideAcc = value
		if view.on and view.target then setTarget(view.target) end
	end)

	addNumberBox(addGrayRow(drawer, "Field of view (1-120)"), tostring(view.fov), function(box)
		local number = tonumber(box.Text)
		view.fov = number and math.clamp(number, 1, 120) or view.fov
		box.Text = tostring(view.fov)
	end)

	-- camera extender: moves the camera away from the head, in the direction the head faces (limit 100 studs)
	local forwardBox, sideBox
	local function showOffsets()
		if forwardBox then forwardBox.Text = tostring(view.forward) end
		if sideBox then sideBox.Text = tostring(view.side) end
	end
	forwardBox = addNumberBox(addGrayRow(drawer, "Camera front / back offset (-100 to 100, negative = back)"), tostring(view.forward), function(box)
		local number = tonumber(box.Text)
		view.forward = number and math.clamp(number, -100, 100) or view.forward
		showOffsets()
	end)
	sideBox = addNumberBox(addGrayRow(drawer, "Camera left / right offset (-100 to 100, negative = left)"), tostring(view.side), function(box)
		local number = tonumber(box.Text)
		view.side = number and math.clamp(number, -100, 100) or view.side
		showOffsets()
	end)

	local extendRow = addGrayRow(drawer, "Extend camera (+5 studs each press)")
	local function extendButton(text, offset, width, onPress)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, extendRow)
		outline(button)
		listen(button.MouseButton1Click, function()
			onPress()
			view.forward = math.clamp(view.forward, -100, 100)
			view.side = math.clamp(view.side, -100, 100)
			showOffsets()
		end)
	end
	extendButton("RESET", 8, 54, function() view.forward, view.side = 0, 0 end)
	extendButton("RIGHT", 68, 50, function() view.side += 5 end)
	extendButton("LEFT", 124, 50, function() view.side -= 5 end)
	extendButton("BACK", 180, 50, function() view.forward -= 5 end)
	extendButton("FRONT", 236, 54, function() view.forward += 5 end)

	addNumberBox(addGrayRow(drawer, "Rotate speed (turns/second, e.g. 0.5 - negative = other way)"), tostring(view.spin), function(box)
		local number = tonumber(box.Text)
		view.spin = number and math.clamp(number, -20, 20) or view.spin
		box.Text = tostring(view.spin)
	end)

	addNumberBox(addGrayRow(drawer, "Rotate by (degrees, negative = other way)"), tostring(view.angle), function(box)
		local number = tonumber(box.Text)
		view.angle = number and math.clamp(number, -360, 360) or view.angle
		box.Text = tostring(view.angle)
	end)

	-- left / right rotation of the view
	local yawBox
	local function setYaw(value)
		view.yaw = math.clamp(value, -360, 360)
		if yawBox then yawBox.Text = tostring(math.floor(view.yaw * 10 + 0.5) / 10) end
	end
	yawBox = addNumberBox(addGrayRow(drawer, "Turn left / right (degrees, negative = left)"), tostring(view.yaw), function(box)
		local number = tonumber(box.Text)
		setYaw(number or view.yaw)
	end)

	local nudgeRow = addGrayRow(drawer, "Turn view")
	local function nudgeButton(text, offset, width, delta)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, nudgeRow)
		outline(button)
		listen(button.MouseButton1Click, function()
			if delta == 0 then setYaw(0) else setYaw(view.yaw + delta) end
		end)
	end
	nudgeButton("RIGHT >", 8, 66, 15)
	nudgeButton("CENTER", 80, 64, 0)
	nudgeButton("< LEFT", 150, 66, -15)

	addNumberBox(addGrayRow(drawer, "Turn speed left / right (turns/second, negative = left)"), tostring(view.yawSpin), function(box)
		local number = tonumber(box.Text)
		view.yawSpin = number and math.clamp(number, -20, 20) or view.yawSpin
		box.Text = tostring(view.yawSpin)
	end)

	-- fix for a tilted / sideways view
	local LEVEL_NAMES = { [0] = "HEAD (as is)", [1] = "UPRIGHT", [2] = "BODY" }
	local levelRow = addGrayRow(drawer, "View direction (fixes a tilted / sideways view)")
	local levelButton = make("TextButton", {
		Size = UDim2.fromOffset(110, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = LEVEL_NAMES[view.levelMode],
		TextColor3 = BLACK,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
	}, levelRow)
	outline(levelButton)
	listen(levelButton.MouseButton1Click, function()
		view.levelMode = (view.levelMode + 1) % 3
		levelButton.Text = LEVEL_NAMES[view.levelMode]
	end)

	addNumberBox(addGrayRow(drawer, "Look up / down (degrees, negative = down)"), tostring(view.pitch), function(box)
		local number = tonumber(box.Text)
		view.pitch = number and math.clamp(number, -89, 89) or view.pitch
		box.Text = tostring(view.pitch)
	end)

	-- third person (the camera most players use): turns around the battler
	addSwitch(addGrayRow(drawer, "Third person (orbit around the battler)"), function()
		return view.third
	end, function(value)
		view.third = value
		view.orbitInit = false
		view.refreshAt = 0
		if view.on and view.target then setTarget(view.target) end
	end)

	local distBox
	distBox = addNumberBox(addGrayRow(drawer, "Third person distance (1-200)"), tostring(view.dist), function(box)
		local number = tonumber(box.Text)
		view.dist = number and math.clamp(number, 1, 200) or view.dist
		box.Text = tostring(view.dist)
	end)

	local orbitRow = addGrayRow(drawer, "Orbit view (drag / mouse wheel / pinch also work)")
	local function orbitButton(text, offset, width, onPress)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, orbitRow)
		outline(button)
		listen(button.MouseButton1Click, onPress)
	end
	orbitButton("DOWN", 8, 46, function() view.orbitPitch = math.clamp(view.orbitPitch - 10, -80, 80) end)
	orbitButton("UP", 60, 36, function() view.orbitPitch = math.clamp(view.orbitPitch + 10, -80, 80) end)
	orbitButton("RIGHT", 102, 46, function() view.orbitYaw -= 15 end)
	orbitButton("LEFT", 154, 42, function() view.orbitYaw += 15 end)
end)

-- Mobile Cinematic Mode (Misc tab): hides the game's HUD (title, health bar, money, level, FIRE, Menu ...) so
-- nothing can be seen or tapped until the switch is turned off again. Oscar's own panel / icon stay visible.
-- Invisible character (Misc tab): hides your own character AND the weapon / tool / accessories, for you only
safeBuild("Invisible Character", function()
	local page = pages["Misc"]
	local RunService = game:GetService("RunService")
	local state = { on = false, hidden = {}, bound = false, refreshAt = 0 }
	Custom.invisible = state

	local function remember(object)
		if object:IsA("BasePart") and state.hidden[object] == nil then
			state.hidden[object] = object.LocalTransparencyModifier
		end
	end

	-- finds every part of the character, including held tools / weapons and accessories (and new ones later)
	local function collect()
		local character = Players.LocalPlayer.Character
		if not character then return end
		for _, object in ipairs(character:GetDescendants()) do
			remember(object)
		end
	end

	local function apply()
		for object in pairs(state.hidden) do
			if object.Parent then
				pcall(function() object.LocalTransparencyModifier = 1 end)
			else
				state.hidden[object] = nil -- part is gone (respawn, weapon unequipped)
			end
		end
	end

	local function restore()
		for object, old in pairs(state.hidden) do
			pcall(function() object.LocalTransparencyModifier = old end)
		end
		table.clear(state.hidden)
	end

	local function stop()
		state.on = false
		if state.bound then
			state.bound = false
			pcall(function() RunService:UnbindFromRenderStep("OscarInvisibleCharacter") end)
		end
		restore() -- everything becomes visible again
	end
	Custom.invisibleStop = stop

	local function start()
		stop()
		state.on = true
		state.refreshAt = 0
		state.bound = true
		-- every frame, after the game's own scripts, so nothing can make the character visible again
		RunService:BindToRenderStep("OscarInvisibleCharacter", Enum.RenderPriority.Last.Value + 5, function()
			if not state.on or destroyed then return end
			if os.clock() >= state.refreshAt then
				state.refreshAt = os.clock() + 0.3
				collect()
			end
			apply()
		end)
	end

	addSwitch(addGrayRow(page, "Invisible character (including the weapon)"), function()
		return state.on
	end, function(value)
		if value then start() else stop() end
	end)
end)

-- Battler Sprites (Misc tab): the chosen battlers / enemies turn invisible (for you only) and a block with your picture
-- takes their place and follows them. Like the Animation Changer, every setting is for ONE kind of animation
-- (Idle / Walk / Punch / Custom words): the picture changes with what the battler is doing right now.
safeBuild("Battler Image Block", function()
	local page = pages["Misc"]
	local RunService = game:GetService("RunService")
	local MAX_ENTRIES = 30
	local TYPES = {
		{ name = "Idle", keys = "idle" },
		{ name = "Walk", keys = "walk,run" },
		{ name = "Punch", keys = "punch,attack,swing,slash,melee,hit" },
		{ name = "Custom", keys = "" },
	}
	local block = {
		on = false, sizeX = 5, sizeY = 6, sizeZ = 1, raise = 0,
		blockTransparency = 0, imageTransparency = 0, faceCamera = false,
		spin = 0, angle = 0, axis = 1, spinAngle = 0, lastRender = nil,
		entries = {}, units = {}, bound = false, scanAt = 0, stateAt = 0,
		cache = setmetatable({}, { __mode = "k" }),
	}
	Custom.imageBlock = block

	-- Roblox "asset IDs": a Decal asset (the number of a decal) holds the real image inside it, so the real image is
	-- looked up once (GetObjects) and cached; image asset IDs simply work. Until it is known the plain ID is used.
	local ContentProvider = game:GetService("ContentProvider")
	local resolved, pending = {}, {}
	local function sourceOf(id)
		local known = resolved[id]
		if known then return known end
		if not pending[id] then
			pending[id] = true
			task.spawn(function()
				local final = "rbxassetid://" .. id
				local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
				if ok and type(objects) == "table" then
					for _, object in ipairs(objects) do
						local texture
						pcall(function()
							if object:IsA("Decal") or object:IsA("Texture") then
								texture = object.Texture
							elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
								texture = object.Image
							end
						end)
						if texture and texture ~= "" then
							final = texture
							break
						end
					end
					for _, object in ipairs(objects) do pcall(function() object:Destroy() end) end
				end
				pcall(function() ContentProvider:PreloadAsync({ final }) end)
				resolved[id] = final
			end)
		end
		return "rbxassetid://" .. id
	end

	-- 12345, rbxassetid://12345, roblox.com/asset/?id=12345 - several can be given, separated by commas or spaces
	local function parseIds(text)
		local list = {}
		for token in string.gmatch(tostring(text or ""), "[^,%s]+") do
			local id = string.match(token, "id=(%d+)") or string.match(token, "%d+")
			if id then table.insert(list, id) end
		end
		return list
	end

	local function isAlive(model)
		if not model or not model.Parent then return false end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		return model:FindFirstChild("Head") ~= nil and (not humanoid or humanoid.Health > 0)
	end

	local function rootOf(model)
		return model.PrimaryPart
			or model:FindFirstChild("HumanoidRootPart")
			or model:FindFirstChild("Torso")
			or model:FindFirstChild("UpperTorso")
			or model:FindFirstChild("Head")
	end

	local function entryCovers(entry, model, isAlly)
		if not entry.enabled then return false end
		if entry.team ~= 2 and (entry.team == 1) ~= isAlly then return false end
		if entry.id > 0 and tonumber(model:GetAttribute("ID")) ~= entry.id then return false end
		return true
	end

	-- ===== what is the battler doing? (same idea as the Animation Changer's scanner) =====
	local function wordsOf(keys)
		local list = {}
		for word in string.gmatch(string.lower(keys or ""), "[^,%s]+") do
			table.insert(list, word)
		end
		return list
	end

	-- the game keeps Animation objects named "Idle" / "Walk" / "Punch" inside each battler, but the playing
	-- track is often just called "Animation": so the IDs of the matching objects are collected too
	local function idsOfNamed(unit, words)
		local ids = {}
		for _, object in ipairs(unit:GetDescendants()) do
			if object:IsA("Animation") and not object:GetAttribute("OscarMade") then
				local lowered = string.lower(object.Name)
				for _, word in ipairs(words) do
					if string.find(lowered, word, 1, true) then
						ids[string.lower(object.AnimationId)] = true
						break
					end
				end
			end
		end
		return ids
	end

	local function unitInfo(unit, now)
		local info = block.cache[unit]
		if info and now - info.time < 1.5 then return info end
		info = { time = now, sources = {}, idsByKeys = {} }
		for _, object in ipairs(unit:GetDescendants()) do
			if object:IsA("Animator") or object:IsA("Humanoid") or object:IsA("AnimationController") then
				table.insert(info.sources, object)
			end
		end
		block.cache[unit] = info
		return info
	end

	local function playingTracks(info)
		local result, seen = {}, {}
		for _, object in ipairs(info.sources) do
			local ok, list = pcall(function() return object:GetPlayingAnimationTracks() end)
			if ok and type(list) == "table" then
				for _, track in ipairs(list) do
					if not seen[track] then
						seen[track] = true
						table.insert(result, track)
					end
				end
			end
		end
		return result
	end

	local function keysMatch(unit, info, tracks, keys)
		local words = wordsOf(keys)
		if #words == 0 then return false end
		local ids = info.idsByKeys[keys]
		if not ids then
			ids = idsOfNamed(unit, words)
			info.idsByKeys[keys] = ids
		end
		for _, track in ipairs(tracks) do
			local weight = 1
			pcall(function() weight = track.WeightCurrent end)
			if weight > 0.05 then
				local names = { string.lower(track.Name or "") }
				pcall(function()
					if track.Animation then
						table.insert(names, string.lower(track.Animation.Name))
						table.insert(names, string.lower(track.Animation.AnimationId))
						if ids[string.lower(track.Animation.AnimationId)] then names[#names + 1] = "\0match" end
					end
				end)
				for _, name in ipairs(names) do
					if name == "\0match" then return true end
					for _, word in ipairs(words) do
						if string.find(name, word, 1, true) then return true end
					end
				end
			end
		end
		return false
	end

	-- picks the setting whose animation kind the battler is showing right now
	local function chooseEntry(unit, state, covering, now)
		local info = unitInfo(unit, now)
		local tracks = playingTracks(info)
		local function firstOf(kind)
			for _, entry in ipairs(covering) do
				if entry.typeIndex == kind then return entry end
			end
		end
		-- Custom words and Punch win, then Walk, then Idle
		for _, entry in ipairs(covering) do
			if entry.typeIndex == 4 and keysMatch(unit, info, tracks, entry.keys) then return entry end
		end
		for _, entry in ipairs(covering) do
			if entry.typeIndex == 3 and keysMatch(unit, info, tracks, entry.keys) then
				state.punchEntry, state.punchUntil = entry, now + 0.25 -- do not flicker
				return entry
			end
		end
		if state.punchEntry and now < state.punchUntil and table.find(covering, state.punchEntry) then
			return state.punchEntry
		end
		for _, entry in ipairs(covering) do
			if entry.typeIndex == 2 and (state.speed > 1 or keysMatch(unit, info, tracks, entry.keys)) then return entry end
		end
		return firstOf(1) or covering[1]
	end

	-- ===== the blocks =====
	local function updateLook(state)
		state.part.Transparency = block.blockTransparency
		for _, decal in ipairs(state.decals) do
			decal.Transparency = block.imageTransparency
		end
		for _, face in ipairs(state.sheets) do
			face.image.ImageTransparency = block.imageTransparency
		end
	end

	local function remove(model)
		local state = block.units[model]
		if not state then return end
		for object, old in pairs(state.hidden) do
			pcall(function() object.LocalTransparencyModifier = old end) -- the battler is visible again
		end
		pcall(function() state.part:Destroy() end)
		block.units[model] = nil
	end

	local function add(model, isAlly)
		local part = Instance.new("Part")
		part.Name = "OscarBattlerBlock"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.SmoothPlastic
		part.Color = Color3.new(1, 1, 1)
		part.Size = Vector3.new(math.max(block.sizeX, 0.05), math.max(block.sizeY, 0.05), math.max(block.sizeZ, 0.05))
		local decals, sheets = {}, {}
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }) do
			local decal = Instance.new("Decal")
			decal.Face = face
			decal.Parent = part
			table.insert(decals, decal)

			-- spritesheet face: the sheet is drawn inside a frame that only shows ONE cell (a scaled, clipped ImageLabel)
			local gui = Instance.new("SurfaceGui")
			gui.Face = face
			gui.Adornee = part
			gui.LightInfluence = 0
			gui.AlwaysOnTop = false
			gui.ResetOnSpawn = false
			gui.Enabled = true
			gui.Parent = part
			local clip = Instance.new("Frame")
			clip.Size = UDim2.fromScale(1, 1)
			clip.BackgroundTransparency = 1
			clip.BorderSizePixel = 0
			clip.ClipsDescendants = true
			clip.Parent = gui
			local image = Instance.new("ImageLabel")
			image.BackgroundTransparency = 1
			image.BorderSizePixel = 0
			image.Size = UDim2.fromScale(1, 1)
			image.Parent = clip
			table.insert(sheets, { gui = gui, image = image })
		end
		part.Parent = Workspace
		local state = {
			part = part, decals = decals, sheets = sheets, mode = "decal", hidden = {}, ally = isAlly, texture = nil,
			speed = 0, lastPos = nil, lastTime = os.clock(), entry = nil, since = os.clock(), covering = {},
		}
		block.units[model] = state
		updateLook(state)
	end

	local function hideModel(model, state)
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("BasePart") and state.hidden[object] == nil then
				state.hidden[object] = object.LocalTransparencyModifier
			end
		end
	end

	-- which living battlers are covered by at least one ON setting
	local function rescan()
		local wanted = {}
		for _, folderName in ipairs({ "EnemyFolder", "FriendlyFolder" }) do
			local isAlly = folderName == "FriendlyFolder"
			local folder = npcFolder(folderName)
			if folder then
				for _, npc in ipairs(folder:GetChildren()) do
					if npc:IsA("Model") and isAlive(npc) then
						local covering = {}
						for _, entry in ipairs(block.entries) do
							if entryCovers(entry, npc, isAlly) then table.insert(covering, entry) end
						end
						if #covering > 0 then
							-- a setting for one unit ID beats a setting for "every battler"
							table.sort(covering, function(a, b)
								if (a.id > 0) ~= (b.id > 0) then return a.id > 0 end
								return table.find(block.entries, a) < table.find(block.entries, b)
							end)
							wanted[npc] = { covering = covering, ally = isAlly }
						end
					end
				end
			end
		end
		for model in pairs(block.units) do
			if not wanted[model] then remove(model) end
		end
		for model, info in pairs(wanted) do
			if not block.units[model] then add(model, info.ally) end
			local state = block.units[model]
			state.covering = info.covering
			hideModel(model, state)
		end
	end

	local function stop()
		block.on = false
		if block.bound then
			block.bound = false
			pcall(function() RunService:UnbindFromRenderStep("OscarBattlerBlock") end)
		end
		for model in pairs(block.units) do
			remove(model)
		end
	end
	Custom.imageBlockStop = stop

	local function start()
		stop()
		block.on = true
		block.spinAngle, block.lastRender = 0, nil
		block.scanAt, block.stateAt = 0, 0
		block.bound = true
		local function renderStep()
			if not block.on or destroyed then return end
			local now = os.clock()
			if now >= block.scanAt then
				block.scanAt = now + 0.3
				rescan()
			end
			-- rotation: a fixed angle plus a steady spin (turns per second, negative = the other way round)
			local frameTime = block.lastRender and math.min(now - block.lastRender, 0.2) or 0
			block.lastRender = now
			block.spinAngle = (block.spinAngle + block.spin * 360 * frameTime) % 360
			local turn = math.rad(block.angle + block.spinAngle)
			local rotation = CFrame.Angles(0, turn, 0)
			if block.axis == 2 then
				rotation = CFrame.Angles(0, 0, turn)
			elseif block.axis == 3 then
				rotation = CFrame.Angles(turn, 0, 0)
			end

			local doState = now >= block.stateAt
			if doState then block.stateAt = now + 0.1 end

			local camera = Workspace.CurrentCamera
			local size = Vector3.new(math.max(block.sizeX, 0.05), math.max(block.sizeY, 0.05), math.max(block.sizeZ, 0.05))
			for model, state in pairs(block.units) do
				local root = model.Parent and rootOf(model)
				if not root then
					remove(model)
				else
					-- walking = how fast it really moves (works for tweened / scripted movement too)
					if doState then
						local position = root.Position
						local elapsed = now - state.lastTime
						if state.lastPos and elapsed > 0 then
							state.speed = Vector3.new(position.X - state.lastPos.X, 0, position.Z - state.lastPos.Z).Magnitude / elapsed
						end
						state.lastPos, state.lastTime = position, now
						local chosen = chooseEntry(model, state, state.covering, now)
						if chosen ~= state.entry then
							state.entry, state.since = chosen, now
						end
					end

					-- the picture: a spritesheet (columns x rows, played at frames/s), or one image, or several IDs
					-- flipped through like frames. It is drawn the same way as the little preview on the setting.
					local entry = state.entry
					local ids = entry and entry.ids or {}
					local cells = entry and (entry.cols * entry.rows) or 1
					local source, sizeScale, offsetScale = "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0)
					if entry and #ids > 0 then
						if cells > 1 then
							local total = (entry.frames > 0) and math.min(entry.frames, cells) or cells
							local frame = math.floor((now - state.since) * entry.fps) % total
							source = sourceOf(ids[1])
							sizeScale = UDim2.fromScale(entry.cols, entry.rows)
							offsetScale = UDim2.fromScale(-(frame % entry.cols), -math.floor(frame / entry.cols))
						else
							local index = 1
							if #ids > 1 then
								index = math.floor((now - state.since) * entry.fps) % #ids + 1
							end
							source = sourceOf(ids[index])
						end
					end
					for _, face in ipairs(state.sheets) do
						local image = face.image
						if image.Image ~= source then image.Image = source end
						if image.Size ~= sizeScale then image.Size = sizeScale end
						if image.Position ~= offsetScale then image.Position = offsetScale end
					end
					-- backup: if the picture could not be drawn on the block's faces within 2 seconds, a plain Decal gets it
					if source ~= state.source then
						state.source, state.sourceTime, state.decalOn = source, now, false
						for _, decal in ipairs(state.decals) do decal.Texture = "" end
					end
					state.loaded = state.sheets[1] and state.sheets[1].image.IsLoaded
					if source ~= "" and cells <= 1 and not state.loaded and not state.decalOn and now - state.sourceTime > 2 then
						state.decalOn = true
						for _, decal in ipairs(state.decals) do decal.Texture = source end
					end

					for object in pairs(state.hidden) do
						if object.Parent then
							pcall(function() object.LocalTransparencyModifier = 1 end) -- every frame, the game cannot show it again
						end
					end
					if state.part.Size ~= size then state.part.Size = size end
					local position = root.Position + Vector3.new(0, block.raise, 0)
					if block.faceCamera and camera then
						local cameraPosition = camera.CFrame.Position
						state.part.CFrame = CFrame.lookAt(position, Vector3.new(cameraPosition.X, position.Y, cameraPosition.Z)) * rotation
					else
						state.part.CFrame = CFrame.new(position) * (root.CFrame - root.CFrame.Position) * rotation
					end
				end
			end
		end
		RunService:BindToRenderStep("OscarBattlerBlock", Enum.RenderPriority.Last.Value + 5, function()
			local ok, err = pcall(renderStep)
			if not ok and not block.warned then
				block.warned = true
				warn("Oscar's Cool Panel: battler sprites: " .. tostring(err))
			end
		end)
	end

	local function refreshAll()
		for _, state in pairs(block.units) do updateLook(state) end
	end

	-- ===== UI =====
	local drawer = addToggleCogRow(page, "Battler Sprite's (image block replaces a battler)", function()
		return block.on
	end, function(value)
		if value then start() else stop() end
	end)

	local topRow = addGrayRow(drawer, "")
	local countLabel = topRow:FindFirstChildOfClass("TextLabel")
	local addButton = make("TextButton", {
		Size = UDim2.fromOffset(60, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = "+ ADD",
		TextColor3 = BLACK,
		TextSize = 12,
		Font = Enum.Font.GothamBold,
	}, topRow)
	outline(addButton)
	if countLabel then countLabel.Size = UDim2.new(1, -90, 1, 0) end

	local status = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundTransparency = 1,
		Text = "Turn the main row ON: the battlers your settings cover become invisible for you and a block with your picture takes their place. Press + ADD for every animation: Idle, Walk, Punch (or your own words), paste a Roblox asset ID (a decal or an image) - or several IDs for a flip-book - and the picture changes with what the battler is doing. For a spritesheet paste its asset ID, then enter its Columns and Rows (and Frames if the last row is not full); it plays at Frames/s (a negative number plays it backwards). Spin speed and the angle can be decimals like 0.5 and negative to turn the other way. The little preview on every setting shows how it will look. Saving the Custom Spawner setup saves these too.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local liveLabel = make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Text = "Live: switch the main row ON",
		TextColor3 = Color3.fromRGB(255, 230, 120),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, drawer)

	local function number(label, key, low, high, default)
		addNumberBox(addGrayRow(drawer, label), tostring(block[key]), function(box)
			local value = tonumber(box.Text)
			block[key] = value and math.clamp(value, low, high) or default
			box.Text = tostring(block[key])
			refreshAll()
		end)
	end
	number("Block width (studs)", "sizeX", 0, 200, 5)
	number("Block height (studs)", "sizeY", 0, 200, 6)
	number("Block depth (studs)", "sizeZ", 0, 200, 1)
	number("Raise the block (studs)", "raise", -50, 50, 0)
	number("Block see-through (0 solid - 1 invisible)", "blockTransparency", 0, 1, 0)
	number("Image see-through (0 solid - 1 invisible)", "imageTransparency", 0, 1, 0)
	number("Spin speed (turns/second, e.g. 0.5 - negative = other way)", "spin", -20, 20, 0)
	number("Rotate by (degrees, negative = other way)", "angle", -360, 360, 0)
	addSwitch(addGrayRow(drawer, "Always face the camera"), function()
		return block.faceCamera
	end, function(value)
		block.faceCamera = value
	end)

	local AXIS_NAMES = { "Up (like a turntable)", "Roll (flat, like a wheel)", "Tilt (forwards / back)" }
	local axisRow = addGrayRow(drawer, "Rotate around")
	local axisButton = make("TextButton", {
		Size = UDim2.fromOffset(150, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		Text = AXIS_NAMES[block.axis],
		TextColor3 = BLACK,
		TextSize = 11,
		Font = Enum.Font.GothamBold,
	}, axisRow)
	outline(axisButton)
	listen(axisButton.MouseButton1Click, function()
		block.axis = block.axis % #AXIS_NAMES + 1
		axisButton.Text = AXIS_NAMES[block.axis]
	end)
	block.refreshAxis = function() axisButton.Text = AXIS_NAMES[block.axis] end

	local list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, drawer)
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function refreshCount()
		if countLabel then
			countLabel.Text = "Sprite settings: " .. tostring(#block.entries) .. " / " .. tostring(MAX_ENTRIES)
		end
	end
	refreshCount()

	local TEAM_LABELS = { [0] = "RED enemies", [1] = "BLUE units", [2] = "BOTH teams" }

	local function column(holderParent, x, width, label)
		local holder = make("Frame", {
			Size = UDim2.new(width, 0, 1, 0),
			Position = UDim2.new(x, 0, 0, 0),
			BackgroundTransparency = 1,
		}, holderParent)
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.fromOffset(0, 3),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = BLACK,
			TextSize = 11,
			Font = Enum.Font.GothamBold,
		}, holder)
		return holder
	end
	local function textBox(holder, text, size, commit)
		local input = make("TextBox", {
			Size = UDim2.new(1, -12, 0, 24),
			Position = UDim2.fromOffset(6, 22),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			TextSize = size or 14,
			Font = Enum.Font.GothamBold,
			Text = text,
			ClearTextOnFocus = false,
		}, holder)
		outline(input)
		listen(input.FocusLost, function()
			commit(input)
		end)
		return input
	end
	local function cellButton(holder, text, onClick)
		local button = make("TextButton", {
			Size = UDim2.new(1, -12, 0, 24),
			Position = UDim2.fromOffset(6, 22),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, holder)
		outline(button)
		listen(button.MouseButton1Click, function()
			onClick(button)
		end)
		return button
	end

	local function addEntry(init)
		if #block.entries >= MAX_ENTRIES then
			status.Text = "That is the maximum: " .. tostring(MAX_ENTRIES) .. " settings."
			return
		end
		local entry = { enabled = true, id = 0, team = 2, typeIndex = 1, keys = TYPES[1].keys, sprite = "", ids = {}, fps = 8, cols = 1, rows = 1, frames = 0 }
		if type(init) == "table" then
			for key, value in pairs(init) do entry[key] = value end
		end
		entry.ids = parseIds(entry.sprite)
		table.insert(block.entries, entry)
		block.scanAt = 0

		local box = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = #block.entries,
		}, list)
		make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, box)

		local header = addGrayRow(box, "")
		local title = header:FindFirstChildOfClass("TextLabel")
		if title then
			title.Size = UDim2.new(1, -110, 1, 0)
			title.TextSize = 12
			title.TextTruncate = Enum.TextTruncate.AtEnd
		end
		local function refreshHeader()
			local index = table.find(block.entries, entry) or 0
			if title then
				title.Text = "Sprite " .. tostring(index) .. "  -  " .. TYPES[entry.typeIndex].name .. "  -  "
					.. (entry.id > 0 and ("ID " .. tostring(entry.id)) or "every battler") .. "  -  " .. TEAM_LABELS[entry.team]
			end
			header.BackgroundColor3 = entry.enabled and Color3.fromRGB(200, 225, 200) or GRAY
		end
		entry.refreshHeader = refreshHeader

		local switchButton = make("TextButton", {
			Size = UDim2.fromOffset(44, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -44, 0.5, 0),
			AutoButtonColor = false,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Text = "",
		}, header)
		outline(switchButton)
		local function refreshSwitch()
			switchButton.Text = entry.enabled and "ON" or "OFF"
			switchButton.BackgroundColor3 = entry.enabled and ON_COLOR or WHITE
		end
		refreshSwitch()
		listen(switchButton.MouseButton1Click, function()
			entry.enabled = not entry.enabled
			refreshSwitch()
			refreshHeader()
			block.scanAt = 0
		end)

		local removeButton = make("TextButton", {
			Size = UDim2.fromOffset(32, 26),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(230, 90, 90),
			Text = "X",
			TextColor3 = WHITE,
			TextSize = 13,
			Font = Enum.Font.GothamBold,
		}, header)
		outline(removeButton)
		entry.remove = function()
			local index = table.find(block.entries, entry)
			if index then table.remove(block.entries, index) end
			box:Destroy()
			for _, other in ipairs(block.entries) do other.refreshHeader() end
			refreshCount()
			block.scanAt = 0
		end
		listen(removeButton.MouseButton1Click, entry.remove)

		-- row 1: unit ID | sprite ID(s) | frames per second | team
		local fields = make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = GRAY, LayoutOrder = 2 }, box)
		outline(fields)
		textBox(column(fields, 0, 0.18, "Unit ID (0=all)"), tostring(entry.id), 14, function(input)
			local value = tonumber(input.Text)
			entry.id = (value and value > 0) and math.floor(value) or 0
			input.Text = tostring(entry.id)
			refreshHeader()
			block.scanAt = 0
		end)
		textBox(column(fields, 0.18, 0.4, "Asset ID(s)"), entry.sprite, 12, function(input)
			entry.sprite = input.Text
			entry.ids = parseIds(input.Text)
			input.Text = table.concat(entry.ids, ", ")
			entry.sprite = input.Text
		end)
		textBox(column(fields, 0.58, 0.14, "Frames/s"), tostring(entry.fps), 14, function(input)
			local value = tonumber(input.Text)
			if not value then
				entry.fps = 8
			else
				value = math.clamp(value, -60, 60) -- negative = the frames play backwards, 0 = frozen on the first frame
				if value ~= 0 and math.abs(value) < 0.1 then value = value > 0 and 0.1 or -0.1 end
				entry.fps = value
			end
			input.Text = tostring(entry.fps)
		end)
		cellButton(column(fields, 0.72, 0.28, "Goes on"), TEAM_LABELS[entry.team], function(button)
			entry.team = (entry.team + 1) % 3
			button.Text = TEAM_LABELS[entry.team]
			refreshHeader()
			block.scanAt = 0
		end)

		-- row 2: animation kind | the words the scanner looks for
		local fields2 = make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = GRAY, LayoutOrder = 3 }, box)
		outline(fields2)
		local keysInput
		cellButton(column(fields2, 0, 0.28, "Plays during"), TYPES[entry.typeIndex].name, function(button)
			entry.typeIndex = entry.typeIndex % #TYPES + 1
			button.Text = TYPES[entry.typeIndex].name
			if entry.typeIndex ~= 4 then
				entry.keys = TYPES[entry.typeIndex].keys
				if keysInput then keysInput.Text = entry.keys end
			end
			refreshHeader()
		end)
		keysInput = textBox(column(fields2, 0.28, 0.72, "Animation name words (comma)"), entry.keys, 12, function(input)
			entry.keys = input.Text
		end)

		-- row 3: spritesheet layout + a live preview of what the edited sprite looks like
		local fields3 = make("Frame", { Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = GRAY, LayoutOrder = 4 }, box)
		outline(fields3)
		local function sheetBox(x, width, label, key, low, high, default)
			textBox(column(fields3, x, width, label), tostring(entry[key]), 14, function(input)
				local value = tonumber(input.Text)
				entry[key] = value and math.clamp(math.floor(value), low, high) or default
				input.Text = tostring(entry[key])
				for _, state in pairs(block.units) do state.since = os.clock() end
			end)
		end
		sheetBox(0, 0.2, "Columns", "cols", 1, 64, 1)
		sheetBox(0.2, 0.2, "Rows", "rows", 1, 64, 1)
		sheetBox(0.4, 0.26, "Frames (0=all)", "frames", 0, 4096, 0)
		local previewFrame = make("Frame", {
			Size = UDim2.fromOffset(64, 64),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(215, 215, 225),
			ClipsDescendants = true,
		}, fields3)
		outline(previewFrame)
		local previewImage = make("ImageLabel", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, previewFrame)
		entry.previewImage = previewImage

		refreshHeader()
		refreshCount()
		return entry
	end

	-- ===== live preview on every setting: plays the sheet / frames exactly like the battler's block will =====
	listen(RunService.RenderStepped, function()
		local now = os.clock()
		if block.on then
			local covered, drawn, withPicture = 0, 0, 0
			for _, state in pairs(block.units) do
				covered += 1
				if state.loaded then drawn += 1 end
				if state.source and state.source ~= "" then withPicture += 1 end
			end
			liveLabel.Text = "Live: " .. covered .. " battler(s) covered, " .. withPicture .. " with a picture, " .. drawn .. " picture(s) loaded"
				.. (block.warned and "  (error - see console)" or "")
		else
			liveLabel.Text = "Live: switch the main row ON"
		end
		for _, entry in ipairs(block.entries) do
			local image = entry.previewImage
			if image and image.Parent then
				local ids = entry.ids
				if #ids == 0 then
					if image.Image ~= "" then image.Image = "" end
				else
					local cells = entry.cols * entry.rows
					local sizeScale, offsetScale, source = UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), nil
					if cells > 1 then
						local total = (entry.frames > 0) and math.min(entry.frames, cells) or cells
						local frame = math.floor(now * entry.fps) % total
						sizeScale = UDim2.fromScale(entry.cols, entry.rows)
						offsetScale = UDim2.fromScale(-(frame % entry.cols), -math.floor(frame / entry.cols))
						source = sourceOf(ids[1])
					else
						local index = #ids > 1 and (math.floor(now * entry.fps) % #ids + 1) or 1
						source = sourceOf(ids[index])
					end
					if image.Image ~= source then image.Image = source end
					if image.Size ~= sizeScale then image.Size = sizeScale end
					if image.Position ~= offsetScale then image.Position = offsetScale end
				end
			end
		end
	end)

	-- ===== save / load =====
	local function clean(text)
		return (string.gsub(text or "", "[|~]", ""))
	end
	local function serializeSprites()
		local rows = {
			table.concat({ "G", block.sizeX, block.sizeY, block.sizeZ, block.raise, block.blockTransparency,
				block.imageTransparency, block.faceCamera and 1 or 0, block.spin, block.angle, block.axis }, "~"),
		}
		for _, entry in ipairs(block.entries) do
			rows[#rows + 1] = table.concat({
				"E", entry.enabled and 1 or 0, entry.team, entry.id, entry.typeIndex, clean(entry.keys), clean(entry.sprite), entry.fps,
				entry.cols, entry.rows, entry.frames,
			}, "~")
		end
		local body = Custom.encodeBase64(table.concat(rows, "|"))
		return "OSB1" .. body .. Custom.checksum(body)
	end
	local function loadSprites(code)
		code = string.gsub(code or "", "%s", "")
		if string.sub(code, 1, 4) ~= "OSB1" or #code < 5 then
			return false, "That is not a valid sprite code."
		end
		local body = string.sub(code, 5, #code - 1)
		if Custom.checksum(body) ~= string.sub(code, #code) then
			return false, "The code is damaged (a character is wrong or missing)."
		end
		local ok, decoded = pcall(decodeBase64, body)
		if not ok or decoded == "" then return false, "The code could not be read." end
		local globals, list = nil, {}
		for _, row in ipairs(string.split(decoded, "|")) do
			local f = string.split(row, "~")
			if f[1] == "G" then
				globals = f
			elseif f[1] == "E" then
				if #f < 8 then return false, "The code could not be read." end
				local typeIndex = math.clamp(math.floor(tonumber(f[5]) or 1), 1, #TYPES)
				list[#list + 1] = {
					enabled = f[2] == "1",
					team = math.clamp(math.floor(tonumber(f[3]) or 2), 0, 2),
					id = math.max(0, math.floor(tonumber(f[4]) or 0)),
					typeIndex = typeIndex,
					keys = f[6] or TYPES[typeIndex].keys,
					sprite = f[7] or "",
					fps = math.clamp(tonumber(f[8]) or 8, -60, 60),
					cols = math.clamp(math.floor(tonumber(f[9]) or 1), 1, 64), -- older codes have no sheet fields
					rows = math.clamp(math.floor(tonumber(f[10]) or 1), 1, 64),
					frames = math.clamp(math.floor(tonumber(f[11]) or 0), 0, 4096),
				}
				if #list >= MAX_ENTRIES then break end
			else
				return false, "The code could not be read."
			end
		end
		if globals then
			block.sizeX = math.clamp(tonumber(globals[2]) or 5, 0, 200)
			block.sizeY = math.clamp(tonumber(globals[3]) or 6, 0, 200)
			block.sizeZ = math.clamp(tonumber(globals[4]) or 1, 0, 200)
			block.raise = math.clamp(tonumber(globals[5]) or 0, -50, 50)
			block.blockTransparency = math.clamp(tonumber(globals[6]) or 0, 0, 1)
			block.imageTransparency = math.clamp(tonumber(globals[7]) or 0, 0, 1)
			block.faceCamera = globals[8] == "1"
			block.spin = math.clamp(tonumber(globals[9]) or 0, -20, 20) -- older codes have no rotation
			block.angle = math.clamp(tonumber(globals[10]) or 0, -360, 360)
			block.axis = math.clamp(math.floor(tonumber(globals[11]) or 1), 1, 3)
			if block.refreshAxis then block.refreshAxis() end
		end
		while #block.entries > 0 do
			block.entries[#block.entries].remove()
		end
		for _, init in ipairs(list) do
			addEntry(init)
		end
		refreshAll()
		return true, #list
	end
	Custom.spriteSerialize, Custom.spriteLoad = serializeSprites, loadSprites
	Custom.spriteCount = function() return #block.entries end

	local saveRow = addGrayRow(drawer, "Save / Load sprites")
	local function saveButton(text, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, saveRow)
		outline(button)
		return button
	end
	local loadButton = saveButton("LOAD", 8)
	local saveCodeButton = saveButton("SAVE", 68)
	local codeRow = addGrayRow(drawer, "Code")
	local codeBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "save to get a code / paste one here",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, codeRow)
	outline(codeBox)
	listen(saveCodeButton.MouseButton1Click, function()
		local code = serializeSprites()
		codeBox.Text = code
		status.Text = Custom.copy(code) and "Saved! The code is in the box and copied to your clipboard." or "Saved! Copy the code from the box."
	end)
	listen(loadButton.MouseButton1Click, function()
		local ok, result = loadSprites(codeBox.Text)
		status.Text = ok and ("Loaded " .. tostring(result) .. " sprite setting(s).") or ("Could not load: " .. tostring(result))
	end)

	listen(addButton.MouseButton1Click, function() addEntry() end)
	addEntry()
end)

safeBuild("Cinematic Mode", function()
	local page = pages["Misc"]
	local StarterGui = game:GetService("StarterGui")
	local cine = { on = false, token = 0, hidden = {}, bars = {}, hideBars = false, keepMove = true, core = nil, topbar = nil, conn = nil,
		ghost = {}, ghostGuis = {}, keepSet = {}, keepCount = 0,
		keepWords = "left,right,move,arrow,camera,pan,swipe,drag,joystick,thumbstick,slide,scroll" }
	Custom.cine = cine

	-- the thumbstick / jump button must stay, otherwise you could not move on mobile
	local KEEP = { TouchGui = true, ControlGui = true }

	local function isOurs(gui)
		return string.sub(gui.Name, 1, 6) == "Oscars" or (cine.keepMove and KEEP[gui.Name] == true)
	end

	-- ===== "keep moving": the game's own left / right (camera pan) controls stay usable but invisible =====
	local VISUALS = { "BackgroundTransparency", "TextTransparency", "TextStrokeTransparency", "ImageTransparency", "ScrollBarImageTransparency" }

	local function wordsList()
		local list = {}
		for word in string.gmatch(string.lower(cine.keepWords or ""), "[^,%s]+") do table.insert(list, word) end
		return list
	end

	local function wantsKeep(object, words, viewport)
		local name = string.lower(object.Name)
		for _, word in ipairs(words) do
			if string.find(name, word, 1, true) then return true end
		end
		-- a big tappable / draggable area (swipe to move the camera left and right) also counts
		local big = object.AbsoluteSize.X >= viewport.X * 0.45 and object.AbsoluteSize.Y >= viewport.Y * 0.45
		return big and (object:IsA("GuiButton") or object.Active)
	end

	local function markKeep(object, gui)
		cine.keepSet[object] = true
		local node = object.Parent
		while node and node ~= gui do
			if node:IsA("GuiObject") then cine.keepSet[node] = true end
			node = node.Parent
		end
	end

	-- decides (once, before the screen is switched off) which controls of this game screen are kept
	local function scanKeep(gui)
		local words = wordsList()
		local camera = Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1000, 600)
		local found = false
		local ok, items = pcall(function() return gui:GetDescendants() end)
		for _, object in ipairs(ok and items or {}) do
			if object:IsA("GuiObject") and not cine.keepSet[object] and wantsKeep(object, words, viewport) then
				markKeep(object, gui)
				cine.keepCount += 1
				found = true
			end
		end
		return found
	end

	local function ghostPass(gui)
		local ok, items = pcall(function() return gui:GetDescendants() end)
		for _, object in ipairs(ok and items or {}) do
			if object:IsA("UIStroke") then
				if cine.ghost[object] == nil then cine.ghost[object] = { Enabled = object.Enabled } end
				if object.Enabled then object.Enabled = false end
			elseif object:IsA("GuiObject") then
				local saved = cine.ghost[object]
				if saved == nil then
					saved = { Visible = object.Visible }
					for _, name in ipairs(VISUALS) do
						local okRead, value = pcall(function() return object[name] end)
						if okRead then saved[name] = value end
					end
					cine.ghost[object] = saved
				end
				for _, name in ipairs(VISUALS) do
					if saved[name] ~= nil and object[name] < 1 then object[name] = 1 end
				end
				if cine.keepSet[object] then
					if saved.Visible and not object.Visible then object.Visible = true end
				elseif object.Visible then
					object.Visible = false
				end
			end
		end
	end

	local function unghostAll()
		for object, saved in pairs(cine.ghost) do
			if object.Parent then
				for key, value in pairs(saved) do
					pcall(function() object[key] = value end)
				end
			end
		end
		table.clear(cine.ghost)
		table.clear(cine.ghostGuis)
		table.clear(cine.keepSet)
		cine.keepCount = 0
	end

	local function hideGui(gui)
		if not gui:IsA("ScreenGui") or isOurs(gui) then return end
		if cine.ghostGuis[gui] then
			ghostPass(gui)
			return
		end
		if cine.hidden[gui] == nil then
			-- decide before the screen is switched off (switched-off screens have no size to measure)
			if cine.keepMove and gui.Enabled and scanKeep(gui) then
				cine.ghostGuis[gui] = true
				ghostPass(gui)
				return
			end
			cine.hidden[gui] = gui.Enabled
		end
		if gui.Enabled then gui.Enabled = false end
	end

	local function hideBar(bar)
		if not bar:IsA("BillboardGui") then return end
		if cine.bars[bar] == nil then cine.bars[bar] = bar.Enabled end
		if bar.Enabled then bar.Enabled = false end
	end

	local function sweep()
		for _, gui in ipairs(playerGui:GetChildren()) do
			pcall(hideGui, gui)
		end
		if cine.hideBars then
			local npcRoot = Workspace:FindFirstChild("NPCFolders")
			if npcRoot then
				local ok, items = pcall(function() return npcRoot:GetDescendants() end)
				for _, object in ipairs(ok and items or {}) do
					pcall(hideBar, object)
				end
			end
		end
	end

	local function restoreBars()
		for bar, was in pairs(cine.bars) do
			if bar.Parent then pcall(function() bar.Enabled = was end) end
		end
		table.clear(cine.bars)
	end

	local function stop()
		cine.on = false
		cine.token += 1
		if cine.conn then
			pcall(function() cine.conn:Disconnect() end)
			cine.conn = nil
		end
		for gui, was in pairs(cine.hidden) do
			if gui.Parent then pcall(function() gui.Enabled = was end) end
		end
		table.clear(cine.hidden)
		unghostAll()
		restoreBars()
		if cine.core then
			for coreType, was in pairs(cine.core) do
				pcall(function() StarterGui:SetCoreGuiEnabled(coreType, was) end)
			end
			cine.core = nil
		end
		pcall(function() StarterGui:SetCore("TopbarEnabled", cine.topbar ~= false) end)
		cine.topbar = nil
	end

	local function start()
		stop()
		cine.on = true
		local token = cine.token
		-- the Roblox buttons (logo / menu), chat and backpack
		cine.core = {}
		for _, coreType in ipairs(Enum.CoreGuiType:GetEnumItems()) do
			if coreType ~= Enum.CoreGuiType.All then
				pcall(function()
					cine.core[coreType] = StarterGui:GetCoreGuiEnabled(coreType)
					StarterGui:SetCoreGuiEnabled(coreType, false)
				end)
			end
		end
		pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
		cine.topbar = true
		sweep()
		-- anything the game adds or switches back on while the mode is on is hidden again
		cine.conn = playerGui.ChildAdded:Connect(function(child)
			task.defer(function()
				if cine.on and child.Parent then pcall(hideGui, child) end
			end)
		end)
		task.spawn(function()
			while cine.on and cine.token == token and not destroyed do
				sweep()
				task.wait(0.4)
			end
		end)
	end
	Custom.cineStop = stop

	local drawer = addToggleCogRow(page, "Mobile Cinematic Mode (hide game HUD)", function()
		return cine.on
	end, function(value)
		if value then start() else stop() end
	end)

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		Text = "ON: the game's HUD (stage title, health bar, money, level, FIRE, Menu, Roblox buttons) is hidden and can't be tapped. The walk stick stays (you can switch that with 'Keep moving'). Oscar's panel stays too: tap the Oscar icon at the top to open it and turn this OFF again.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local moveRow = addGrayRow(drawer, "Keep moving (walk stick + jump stay)")
	addSwitch(moveRow, function() return cine.keepMove end, function(value)
		cine.keepMove = value
		if cine.on then
			-- re-decide everything with the new setting
			unghostAll()
			for gui, was in pairs(cine.hidden) do
				if gui.Parent then pcall(function() gui.Enabled = was end) end
			end
			table.clear(cine.hidden)
			sweep()
		end
	end)

	local wordsRow = addGrayRow(drawer, "Keep these controls (name contains)")
	local wordsLabel = wordsRow:FindFirstChildOfClass("TextLabel")
	if wordsLabel then
		wordsLabel.Size = UDim2.new(1, -230, 1, 0)
		wordsLabel.TextSize = 11
	end
	local wordsBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		Text = cine.keepWords,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, wordsRow)
	outline(wordsBox)
	listen(wordsBox.FocusLost, function()
		cine.keepWords = wordsBox.Text
		if cine.on then
			-- apply the new words right now
			unghostAll()
			for gui, was in pairs(cine.hidden) do
				if gui.Parent then pcall(function() gui.Enabled = was end) end
			end
			table.clear(cine.hidden)
			sweep()
		end
	end)
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text = "Keep moving also keeps the game's own left / right controls working, but invisible. It guesses them by name (words above) and by big swipe areas. If you can't move left / right, add the control's name here.",
		TextColor3 = WHITE,
		TextSize = 11,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
	}, drawer)

	local barRow = addGrayRow(drawer, "Also hide health bars above units")
	addSwitch(barRow, function() return cine.hideBars end, function(value)
		cine.hideBars = value
		if not value then restoreBars() end
	end)
end)

safeBuild("Weather Changer", function()
	local page = pages["Misc"]
	local Lighting = game:GetService("Lighting")
	local RunService = game:GetService("RunService")

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = "WEATHER CHANGER",
		TextColor3 = WHITE,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, page)

	local world = {
		light = { on = false, clock = 0, brightness = 1, exposure = 0, ambient = { 40, 40, 70 }, outdoor = { 40, 40, 70 }, saved = nil, token = 0 },
		rain = { on = false, texture = "", color = { 170, 190, 255 }, visibility = 0.8, amount = 500, speed = 110, width = 50, height = 45, part = nil, emitter = nil },
		fog = { on = false, texture = "", color = { 200, 205, 215 }, visibility = 6, part = nil, emitter = nil, saved = nil },
		sky = { on = false, texture = "", color = { 255, 255, 255 }, visibility = 1, folder = nil, images = {} },
		follow = nil,
	}
	Custom.world = world

	local function color3(rgb)
		return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	end

	local refreshers = {} -- redraw the boxes after a LOAD

	-- ===== small UI helpers =====
	local function addTextRow(drawer, label, placeholder, getText, onCommit)
		local row = addGrayRow(drawer, label)
		local box = make("TextBox", {
			Size = UDim2.fromOffset(130, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = WHITE,
			TextColor3 = BLACK,
			PlaceholderText = placeholder,
			PlaceholderColor3 = GRAY,
			Text = getText(),
			TextSize = 12,
			Font = Enum.Font.Code,
			ClearTextOnFocus = false,
		}, row)
		outline(box)
		listen(box.FocusLost, function()
			onCommit(box.Text, box)
		end)
		table.insert(refreshers, function()
			box.Text = getText()
		end)
		return box
	end

	local function addRgbRow(drawer, label, rgb, onChange)
		local row = addGrayRow(drawer, label)
		local previewBox = make("Frame", {
			Size = UDim2.fromOffset(24, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			BackgroundColor3 = color3(rgb),
		}, row)
		outline(previewBox)
		local rgbBoxes = {}
		table.insert(refreshers, function()
			for boxIndex, rgbBox in ipairs(rgbBoxes) do
				rgbBox.Text = tostring(rgb[boxIndex])
			end
			previewBox.BackgroundColor3 = color3(rgb)
		end)
		for index, offset in ipairs({ 124, 82, 40 }) do
			local box = make("TextBox", {
				Size = UDim2.fromOffset(38, 24),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -offset, 0.5, 0),
				BackgroundColor3 = WHITE,
				TextColor3 = BLACK,
				TextSize = 13,
				Font = Enum.Font.GothamBold,
				Text = tostring(rgb[index]),
				ClearTextOnFocus = false,
			}, row)
			outline(box)
			rgbBoxes[index] = box
			listen(box.FocusLost, function()
				local number = tonumber(box.Text)
				if number then
					rgb[index] = math.clamp(math.floor(number), 0, 255)
				end
				box.Text = tostring(rgb[index])
				previewBox.BackgroundColor3 = color3(rgb)
				onChange()
			end)
		end
	end

	local function addNumberRow(drawer, label, getValue, minValue, maxValue, onChange)
		local numberBoxRef = addNumberBox(addGrayRow(drawer, label), tostring(getValue()), function(box)
			local number = tonumber(box.Text)
			local value = number and math.clamp(number, minValue, maxValue) or getValue()
			onChange(value)
			box.Text = tostring(getValue())
		end)
		table.insert(refreshers, function()
			numberBoxRef.Text = tostring(getValue())
		end)
	end

	local function resolveImage(text, done)
		task.spawn(function()
			local image = ""
			if string.gsub(text or "", "%s", "") ~= "" then
				image = Avatar.resolveTexture(text) or ""
			end
			done(image)
		end)
	end

	local function statusLabel(drawer)
		return make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = "",
			TextColor3 = WHITE,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.Gotham,
			LayoutOrder = nextOrder(),
		}, drawer)
	end

	-- parts that follow the camera (rain / fog emitters and the skybox)
	local function camera()
		return Workspace.CurrentCamera
	end

	local function updateFollow()
		local cam = camera()
		if not cam then return end
		local position = cam.CFrame.Position
		if world.rain.part then
			world.rain.part.CFrame = CFrame.new(position + Vector3.new(0, world.rain.height, 0))
		end
		if world.fog.part then
			world.fog.part.CFrame = CFrame.new(position + Vector3.new(0, 6, 0))
		end
		if world.sky.folder then
			local distance = 900
			for index, wall in ipairs(world.sky.folder:GetChildren()) do
				local direction = wall:GetAttribute("Dir")
				if direction then
					wall.CFrame = CFrame.lookAt(position + direction * distance, position)
				end
			end
		end
	end

	local function refreshFollow()
		local needed = world.rain.part or world.fog.part or world.sky.folder
		if needed and not world.follow then
			world.follow = RunService.RenderStepped:Connect(updateFollow)
		elseif not needed and world.follow then
			world.follow:Disconnect()
			world.follow = nil
		end
	end

	local function newEmitterPart(name, size)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = size
		part.Parent = Workspace
		local emitter = Instance.new("ParticleEmitter")
		emitter.Parent = part
		return part, emitter
	end

	-- ===== Lighting / day & night =====
	local light = world.light
	local LIGHT_PROPS = { "ClockTime", "Brightness", "ExposureCompensation", "Ambient", "OutdoorAmbient" }

	local function applyLight()
		pcall(function()
			Lighting.ClockTime = light.clock
			Lighting.Brightness = light.brightness
			Lighting.ExposureCompensation = light.exposure
			Lighting.Ambient = color3(light.ambient)
			Lighting.OutdoorAmbient = color3(light.outdoor)
		end)
	end

	local function stopLight()
		light.on = false
		light.token += 1
		if light.saved then
			for property, value in pairs(light.saved) do
				pcall(function()
					Lighting[property] = value
				end)
			end
			light.saved = nil
		end
	end

	local function startLight()
		stopLight()
		light.on = true
		local token = light.token
		light.saved = {}
		for _, property in ipairs(LIGHT_PROPS) do
			pcall(function()
				light.saved[property] = Lighting[property]
			end)
		end
		task.spawn(function()
			while light.on and light.token == token and not destroyed do
				applyLight() -- held, in case the game changes it back
				task.wait(0.3)
			end
		end)
	end

	local lightDrawer = addToggleCogRow(page, "Lighting (day / night)", function()
		return light.on
	end, function(value)
		if value then startLight() else stopLight() end
	end)
	local function lightChanged()
		if light.on then applyLight() end
	end
	addNumberRow(lightDrawer, "Time of day (0-24, 0 = midnight, 14 = day)", function() return light.clock end, 0, 24, function(v) light.clock = v lightChanged() end)
	local presetRow = addGrayRow(lightDrawer, "Presets")
	local function presetButton(text, offset, width, clock, brightness, ambient)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(width, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, presetRow)
		outline(button)
		listen(button.MouseButton1Click, function()
			light.clock, light.brightness = clock, brightness
			light.ambient = { ambient[1], ambient[2], ambient[3] }
			light.outdoor = { ambient[1], ambient[2], ambient[3] }
			if not light.on then startLight() else applyLight() end
		end)
	end
	presetButton("NIGHT", 8, 64, 0, 0.4, { 30, 30, 60 })
	presetButton("DAY", 78, 64, 14, 2.5, { 120, 120, 120 })
	presetButton("SUNSET", 148, 70, 18, 1.5, { 110, 70, 60 })
	addNumberRow(lightDrawer, "Brightness (0-10)", function() return light.brightness end, 0, 10, function(v) light.brightness = v lightChanged() end)
	addNumberRow(lightDrawer, "Exposure (-3 to 3)", function() return light.exposure end, -3, 3, function(v) light.exposure = v lightChanged() end)
	addRgbRow(lightDrawer, "Ambient colour RGB", light.ambient, lightChanged)
	addRgbRow(lightDrawer, "Outdoor ambient RGB", light.outdoor, lightChanged)

	-- ===== Rain =====
	local rain = world.rain
	local function applyRain()
		local emitter = rain.emitter
		if not emitter then return end
		emitter.Texture = rain.texture ~= "" and rain.texture or "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(color3(rain.color))
		emitter.Transparency = NumberSequence.new(1 - rain.visibility)
		emitter.Rate = rain.amount
		emitter.Speed = NumberRange.new(rain.speed * 0.9, rain.speed * 1.1)
		emitter.Lifetime = NumberRange.new(math.max(0.3, rain.height / rain.speed), math.max(0.4, rain.height / rain.speed * 1.2))
		if rain.part then rain.part.Size = Vector3.new(rain.width * 2.8, 1, rain.width * 2.8) end
		emitter.Size = NumberSequence.new(0.5)
		emitter.Squash = NumberSequence.new(-0.9)
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.SpreadAngle = Vector2.new(2, 2)
		emitter.LightEmission = 0
		emitter.LightInfluence = 0
		emitter.Acceleration = Vector3.new(0, -60, 0)
		emitter.Enabled = true
	end
	local function stopRain()
		rain.on = false
		if rain.part then rain.part:Destroy() end
		rain.part, rain.emitter = nil, nil
		refreshFollow()
	end
	local function startRain()
		stopRain()
		rain.on = true
		rain.part, rain.emitter = newEmitterPart("OscarsRain", Vector3.new(140, 1, 140))
		applyRain()
		updateFollow()
		refreshFollow()
	end
	local rainDrawer = addToggleCogRow(page, "Rain", function()
		return rain.on
	end, function(value)
		if value then startRain() else stopRain() end
	end)
	local rainStatus
	addTextRow(rainDrawer, "Texture / decal ID (blank = default)", "image ID", function() return rain.texture end, function(text, box)
		resolveImage(text, function(image)
			rain.texture = image
			box.Text = image
			applyRain()
			if rainStatus then rainStatus.Text = image ~= "" and "Rain texture set." or "Rain uses the default drop." end
		end)
	end)
	addRgbRow(rainDrawer, "Rain colour RGB", rain.color, applyRain)
	addNumberRow(rainDrawer, "Visibility (0 = invisible, 1 = fully visible)", function() return rain.visibility end, 0, 1, function(v) rain.visibility = v applyRain() end)
	addNumberRow(rainDrawer, "Amount (1-3000)", function() return rain.amount end, 1, 3000, function(v) rain.amount = v applyRain() end)
	addNumberRow(rainDrawer, "Rain width (1-100)", function() return rain.width end, 1, 100, function(v) rain.width = v applyRain() end)
	addNumberRow(rainDrawer, "Rain height (1-100)", function() return rain.height end, 1, 100, function(v) rain.height = v applyRain() updateFollow() end)
	addNumberRow(rainDrawer, "Fall speed (10-400)", function() return rain.speed end, 10, 400, function(v) rain.speed = v applyRain() end)
	rainStatus = statusLabel(rainDrawer)

	-- ===== Fog =====
	local fog = world.fog
	local FOG_PROPS = { "FogColor", "FogStart", "FogEnd" }
	local function applyFog()
		pcall(function()
			Lighting.FogColor = color3(fog.color)
			Lighting.FogStart = 0
			-- visibility 0 = no fog at all, 10 = thick fog close to you
			local density = fog.visibility / 10
			Lighting.FogEnd = density <= 0 and 1000000 or (60 + ((1 - density) ^ 3) * 5000)
		end)
		local emitter = fog.emitter
		if emitter then
			emitter.Texture = fog.texture ~= "" and fog.texture or "rbxasset://textures/particles/smoke_main.dds"
			emitter.Color = ColorSequence.new(color3(fog.color))
			emitter.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.25, 1 - (fog.visibility / 10) * 0.6),
				NumberSequenceKeypoint.new(0.75, 1 - (fog.visibility / 10) * 0.6),
				NumberSequenceKeypoint.new(1, 1),
			})
			emitter.Rate = 6
			emitter.Lifetime = NumberRange.new(7, 9)
			emitter.Speed = NumberRange.new(1, 3)
			emitter.Size = NumberSequence.new(35)
			emitter.Rotation = NumberRange.new(0, 360)
			emitter.RotSpeed = NumberRange.new(-8, 8)
			emitter.LightInfluence = 0
			emitter.SpreadAngle = Vector2.new(180, 180)
			emitter.Acceleration = Vector3.new(0, 0, 0)
			emitter.Enabled = true
		end
	end
	local function stopFog()
		fog.on = false
		if fog.part then fog.part:Destroy() end
		fog.part, fog.emitter = nil, nil
		if fog.saved then
			for property, value in pairs(fog.saved) do
				pcall(function()
					Lighting[property] = value
				end)
			end
			fog.saved = nil
		end
		refreshFollow()
	end
	local function startFog()
		stopFog()
		fog.on = true
		fog.saved = {}
		for _, property in ipairs(FOG_PROPS) do
			pcall(function()
				fog.saved[property] = Lighting[property]
			end)
		end
		fog.part, fog.emitter = newEmitterPart("OscarsFog", Vector3.new(90, 4, 90))
		applyFog()
		updateFollow()
		refreshFollow()
	end
	local fogDrawer = addToggleCogRow(page, "Fog", function()
		return fog.on
	end, function(value)
		if value then startFog() else stopFog() end
	end)
	local fogStatus
	addTextRow(fogDrawer, "Texture / decal ID (blank = default)", "image ID", function() return fog.texture end, function(text, box)
		resolveImage(text, function(image)
			fog.texture = image
			box.Text = image
			if fog.on then applyFog() end
			if fogStatus then fogStatus.Text = image ~= "" and "Fog texture set." or "Fog uses the default cloud." end
		end)
	end)
	addRgbRow(fogDrawer, "Fog colour RGB", fog.color, function() if fog.on then applyFog() end end)
	addNumberRow(fogDrawer, "Fog strength (0 = none, 10 = thickest)", function() return fog.visibility end, 0, 10, function(v) fog.visibility = v if fog.on then applyFog() end end)
	fogStatus = statusLabel(fogDrawer)

	-- ===== Skybox =====
	local sky = world.sky
	local SKY_DIRECTIONS = {
		Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 1, 0),
		Vector3.new(0, -1, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
	}
	local function applySky()
		for _, image in ipairs(sky.images) do
			image.Image = sky.texture
			image.ImageColor3 = color3(sky.color)
			image.ImageTransparency = 1 - sky.visibility
		end
	end
	local function stopSky()
		sky.on = false
		if sky.folder then sky.folder:Destroy() end
		sky.folder = nil
		sky.images = {}
		refreshFollow()
	end
	local function startSky()
		stopSky()
		if sky.texture == "" then return false end
		sky.on = true
		local folder = Instance.new("Folder")
		folder.Name = "OscarsSkybox"
		for _, direction in ipairs(SKY_DIRECTIONS) do
			local wall = Instance.new("Part")
			wall.Name = "Wall"
			wall.Anchored = true
			wall.CanCollide = false
			wall.CanTouch = false
			wall.CanQuery = false
			wall.CastShadow = false
			wall.Material = Enum.Material.SmoothPlastic
			wall.Color = Color3.new(0, 0, 0)
			wall.Size = Vector3.new(2100, 2100, 1)
			wall:SetAttribute("Dir", direction)
			local gui3d = Instance.new("SurfaceGui")
			gui3d.Face = Enum.NormalId.Front
			gui3d.LightInfluence = 0
			gui3d.CanvasSize = Vector2.new(1024, 1024)
			gui3d.Parent = wall
			local image = Instance.new("ImageLabel")
			image.Size = UDim2.fromScale(1, 1)
			image.BackgroundTransparency = 1
			image.ScaleType = Enum.ScaleType.Stretch
			image.Parent = gui3d
			table.insert(sky.images, image)
			wall.Parent = folder
		end
		folder.Parent = Workspace
		sky.folder = folder
		applySky()
		updateFollow()
		refreshFollow()
		return true
	end
	local skyStatus
	local skyDrawer = addToggleCogRow(page, "Skybox", function()
		return sky.on
	end, function(value)
		if value then
			if not startSky() then
				if skyStatus then skyStatus.Text = "Type a texture / decal ID first." end
			end
		else
			stopSky()
		end
	end)
	addTextRow(skyDrawer, "Texture / decal ID", "image ID", function() return sky.texture end, function(text, box)
		resolveImage(text, function(image)
			sky.texture = image
			box.Text = image
			if image == "" then
				stopSky()
				if skyStatus then skyStatus.Text = "Skybox off: no texture." end
			elseif sky.on then
				applySky()
			else
				startSky()
				if skyStatus then skyStatus.Text = "Skybox on. Use the header switch to turn it off." end
			end
		end)
	end)
	addRgbRow(skyDrawer, "Skybox colour RGB (255 = original)", sky.color, function() if sky.on then applySky() end end)
	addNumberRow(skyDrawer, "Visibility (0 = invisible, 1 = fully visible)", function() return sky.visibility end, 0, 1, function(v) sky.visibility = v if sky.on then applySky() end end)
	skyStatus = statusLabel(skyDrawer)

	-- ===== Save / Load the world settings =====
	local function numbers(...)
		local list = {}
		for _, value in ipairs({ ... }) do list[#list + 1] = tostring(value) end
		return list
	end
	local function clean(text)
		return (string.gsub(text or "", "[|%s]", ""))
	end
	local function serializeWorld()
		local f = {}
		local function add(...)
			for _, value in ipairs({ ... }) do f[#f + 1] = tostring(value) end
		end
		add(light.clock, light.brightness, light.exposure, light.ambient[1], light.ambient[2], light.ambient[3], light.outdoor[1], light.outdoor[2], light.outdoor[3])
		add(clean(rain.texture), rain.color[1], rain.color[2], rain.color[3], rain.visibility, rain.amount, rain.speed, rain.width, rain.height)
		add(clean(fog.texture), fog.color[1], fog.color[2], fog.color[3], fog.visibility)
		add(clean(sky.texture), sky.color[1], sky.color[2], sky.color[3], sky.visibility)
		local body = Custom.encodeBase64(table.concat(f, "|"))
		return "OSW1" .. body .. Custom.checksum(body)
	end
	local WORLD_FIELDS = 9 + 9 + 5 + 5

	local function loadWorld(code)
		code = string.gsub(code or "", "%s", "")
		if string.sub(code, 1, 4) ~= "OSW1" or #code < 7 then
			return false, "That is not a valid world code."
		end
		local body = string.sub(code, 5, #code - 1)
		if Custom.checksum(body) ~= string.sub(code, #code) then
			return false, "The code is damaged (a character is wrong or missing)."
		end
		local ok, decoded = pcall(decodeBase64, body)
		if not ok then return false, "The code could not be read." end
		local f = string.split(decoded, "|")
		if #f ~= WORLD_FIELDS then return false, "The code could not be read." end
		local at = 0
		local function num(minValue, maxValue, fallback)
			at += 1
			local value = tonumber(f[at])
			return value and math.clamp(value, minValue, maxValue) or fallback
		end
		local function text()
			at += 1
			return f[at] or ""
		end
		local function rgb(target)
			for i = 1, 3 do target[i] = math.floor(num(0, 255, target[i])) end
		end
		light.clock = num(0, 24, light.clock)
		light.brightness = num(0, 10, light.brightness)
		light.exposure = num(-3, 3, light.exposure)
		rgb(light.ambient)
		rgb(light.outdoor)
		rain.texture = text()
		rgb(rain.color)
		rain.visibility = num(0, 1, rain.visibility)
		rain.amount = num(1, 3000, rain.amount)
		rain.speed = num(10, 400, rain.speed)
		rain.width = num(1, 100, rain.width)
		rain.height = num(1, 100, rain.height)
		fog.texture = text()
		rgb(fog.color)
		fog.visibility = num(0, 10, fog.visibility)
		sky.texture = text()
		rgb(sky.color)
		sky.visibility = num(0, 1, sky.visibility)

		for _, refreshBox in ipairs(refreshers) do
			refreshBox()
		end
		if light.on then applyLight() end
		if rain.on then applyRain() end
		if fog.on then applyFog() end
		if sky.on then
			if sky.texture == "" then stopSky() else applySky() end
		end
		return true
	end

	local saveRow = addGrayRow(page, "Save / Load world settings")
	local function saveButton(text, offset)
		local button = make("TextButton", {
			Size = UDim2.fromOffset(54, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -offset, 0.5, 0),
			BackgroundColor3 = WHITE,
			Text = text,
			TextColor3 = BLACK,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}, saveRow)
		outline(button)
		return button
	end
	local worldLoadButton = saveButton("LOAD", 8)
	local worldSaveButton = saveButton("SAVE", 68)
	local codeRow = addGrayRow(page, "Code")
	local worldCodeBox = make("TextBox", {
		Size = UDim2.fromOffset(210, 24),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundColor3 = WHITE,
		TextColor3 = BLACK,
		PlaceholderText = "save to get a code / paste one here",
		PlaceholderColor3 = GRAY,
		Text = "",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
	}, codeRow)
	outline(worldCodeBox)
	local worldStatus = statusLabel(page)
	listen(worldSaveButton.MouseButton1Click, function()
		local code = serializeWorld()
		worldCodeBox.Text = code
		worldStatus.Text = Custom.copy(code) and "Saved! The code is in the box and copied to your clipboard." or "Saved! Copy the code from the box."
	end)
	listen(worldLoadButton.MouseButton1Click, function()
		local ok, reason = loadWorld(worldCodeBox.Text)
		worldStatus.Text = ok and "Loaded! Switch the features on to see them (the ones already on were updated)." or ("Could not load: " .. tostring(reason))
	end)

	Custom.worldSerialize, Custom.worldLoad = serializeWorld, loadWorld

	Custom.worldStop = function()
		pcall(stopLight)
		pcall(stopRain)
		pcall(stopFog)
		pcall(stopSky)
	end
end)

-- OSCAR'S CHALLENGES (Misc tab)
safeBuild("Oscar's Challenges", function()
	local page = pages["Misc"]
	local TweenService = game:GetService("TweenService")

	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Text = "OSCAR'S CHALLENGES",
		TextColor3 = WHITE,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.GothamBold,
		LayoutOrder = nextOrder(),
	}, page)

	-- ===== OSCAR'S POPUPS =====
	-- every few seconds a popup appears, keeps changing its height and length with fast tweens,
	-- and only goes away when you click its X
	local popups = { on = false, token = 0, minTime = 2, maxTime = 4, gui = nil, count = 0 }
	Custom.popups = popups
	-- Bombzcar: click him and he explodes into a black stain; leave him alone and he despawns
	local bomb = { on = true, chance = 25, max = 3, stainTime = 15, despawn = 5, maxStains = 10, size = 150, count = 0, stains = {} }
	Custom.bomb = bomb

	-- the six Oscar pictures (resized, base64); loaded once through the executor's file functions
	local IMAGE_DATA = {
		table.concat({
			"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",
			"/s26nIpVTjPlVcG6CpFYqVNSplH/2Q==",
		}),
		table.concat({
			"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",
		}),
		table.concat({
			"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",
		}),
		table.concat({
			"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",
		}),
		table.concat({
			"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",
			"d3OFy7xvG5/DJrqjjeKQ76WPeT9F28clxj4UmKDidxlkIfLCWRt0/MeZP5BdnHJdsfTKqiIrYIiICIiAiIgIiICIiAiKMvN7obND4lZMGuI8kb",
			"d3P9glvD7SLnBoJcQAOq0ziXjqmt7HQ2wNqpzsZB8jP7/0Wq3/AItrbvHIwf4ejPKJjt3D1PX+i1VzHwtJi1GHOcDmFz+cvqOnws91mXOurLjV",
			"GsnnfUE/hceXsOixIW5BkgI1Dm3uqEAt8SI4zzA6r0xokGqE4kHRSpbqzqimmhzE8Ny8DqohtXI54a+QEdsKbeGzN3GmXOHZ5YWtXSjbRzNcyT",
			"d24YTuPUei6ePGd3lTvVzExaqB1yuccDNwTlx7BbjPdRTziB8TasRjAkdgOB91D8M5t3Dc1dMPv5xoYcbheaAtDZKyqyY48uPr2C43ubx3zmfD",
			"tS1xuEtPQslMcQe/JaOw6LQpXOlc9zt3PJcfcqYrrqa9zpJ5mA4wxjeQHQKIbzAKdv65bmZ9PLHNbgPJB9BlX2OiOS0k4GTkKIfUuMp2GkHCzK",
			"WVpicR+LDcY3G663w6zO1zzqW8bJYLo6z3Snr2RanR5xqyWkEY6cl0y2fEe21PlqopIHdXN87f7rkTAx3+WA494XaHfkUdjVvpLu0jdDvzUS8X",
			"ZK+iKG7UFwbqo6uGX0a4ZH05rNyvm6Oolic1zJJI8HILvMB9Qtr4a4wusF1pYJap89NJK1jgSHjBOPcK/km5dmVVRVVoEREBERAREQERUygLiH",
			"xMrXs44qA06msjY0tJ2+UH9V2OtuNPSbPdqf0aOa5Dx3U2Oepqp3sMtznIILH7R4GBn6dFOp2Kz6qFglZPAwsdqwd29vdXGl40/N4b9ua1+N74",
			"Hh8TvfPVTlHVMqYw3Olw5t7Lhzjv3rxNGGHVDy6t9VVgbMfu/K4D2V84blxbp0jI32UFc7nqljZTnSdzJKOZA7dlU9pvplXG4aGuhgYZKtpxtv",
			"pz3UVR0M11ubWOe7UXYeXdGjmrnD9HV3C5MpKSCSaWUZLYxkjPU+i2htRLba6ajrmgzx+SVpID29hnsqurn6M5mvtmVNM+ukho6UEU8I0t9fUr",
			"XeKKsspxQ0Zyxp8zmdT1P6fmpyv4gp6agMFGwwmUed5IL3eg9Fp08+XOkeBlRib1qSTteqzFz23kQpZK3k14x6KabK19B45+YN391UuPhtc8At",
			"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",
		}),
		table.concat({
			"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",
		}),
	}
	local BOMBZCAR_IMG = table.concat({
		"/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUDBAQEAwUEBAQFBQUGBwwIBwcHBw8LCwkMEQ8SEhEPERETFhwXExQaFRERGCEYGh0dHx8fExciJCIeJBweHx7/",
		"2wBDAQUFBQcGBw4ICA4eFBEUHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh7/wAARCADtANUDASIAAhEBAxEB/8QA",
		"HwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkK",
		"FhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXG",
		"x8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC",
		"AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOE",
		"hYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3qz1CKX/l",
		"pV391Xn2m3UX/LOSuit76L/nrXVWwfLL3Qo4qNQ28RU7bWfb3ltL/wAtauxyVxyp8p0xmpE601mpKVmrMZH5tI08VP8AMiqtcLHWkYxkBNvqGSWmwxxVM0VV",
		"yxiBSaeKmNPFUtxaR1Sk0+tIxiTLmGTeVTWapGtaGtq6OaJjylSaeqjSVdms/KqtJH5VdFOUTnqRkV/Np3mVFNUG2WtuUx5i9HJUnm1nLHLVlYJamUTSMi7H",
		"JTmuaqRxS05raWseWJtGUifzPNoaoo4PKp9HKTzDdtFDNUTNVRiZykOoqIy0Vpyk8xh3Wh30f+r8yqsiX0X+t8yu/wDtNUrxYpa6KeNl9pHLUwMY/wAORxcc",
		"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",
	})
	local BOOM_IMG = table.concat({
		"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",
	})
	local GREENX_IMG = table.concat({
		"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",
		"AADgysEY//8Do2VXzxOHSMAAAAAASUVORK5CYII=",
	})
	local FATBOY_MP3 = table.concat({
		"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",
		"XI8Ru7dCpql0latSd/U9OeePJlIyY10v5SSV4J///NECMnf9/2fO1/8S6xff/ysCKH4QwHJk02xIrBTWqiqCxJt//k1K1NXmas0silqu1NzVSvLVQ4oimCSS",
		"U43FYvCaexyzz2ToqLsyFW1sZBZWPQmSdiI5yxpEk46bR+dmBfRBeIaswUMDxminKY36mmi1///3e2SqpRAAgGoj78ysBHZaPuRw//tkxOcBDEzPPaexCwHc",
		"IiJE9I6gTav1Hif6PTKmljPV5Wf5Sqc2HTDB/+JlEJXkSP9wrYLPTVPKLv02hTcDhdSlh4KGQNx8vrJQsS//ULgW81C8ljzEHKauiMwKWUgk4rPSdaP/W5i3",
		"//zIect3f9I+0MqvqaxrTv1N/mi8WShK1Tp0qLSGP/////8XgCRofzk3dyxtqPUOmGiY5zTyKpTWurop+6cW19LBLi3CvFc4xFKqBySikMMnBBJML4jZ//oB",
		"fImhZQtxuyIuhW5ktA+BzRmI7AsqC2/////7pLJ3rNdK61f6/0nSZ91Xdy7M//tkxOeDzyVa+qYlc8Gsq55AhKtYj9UAACvD+DMrBm5eFUYMb/////1AWAVr",
		"NddmWjoBQfPMmLkY4iK5dadPrUItMrT2CnlUGrjLB8PIjQsnKiMxpvzMzMzPWSuCEO0dpk6Pt6xdAKSAall3//1759755mTgotKSMvMz2qiWz//2sjCTaoVK",
		"oT9Li8fWtata1rWtYMJ8fwtwuS2SkhKGl+Lk5vdQYuLPWpRRhqpMQU1FMy4xMDCqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
		"qqqqqqqqqqqqqqqqqqqq//tkxOKBzeGA4QElvkHwu9nAp8vIqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
		"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
		"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq//tkxNoDiu02xyAJkYD3",
		"J1YIAz/Nqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
		"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
		"qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",
	})
	local BOOM_MP3 = table.concat({
		"SUQzBAAAAAABBlRYWFgAAAASAAADbWFqb3JfYnJhbmQAaXNvbQBUWFhYAAAAEwAAA21pbm9yX3ZlcnNpb24ANTEyAFRYWFgAAAAgAAADY29tcGF0aWJsZV9i",
		"cmFuZHMAaXNvbWlzbzJtcDQxAFRTU0UAAAAPAAADTGF2ZjYwLjE2LjEwMAAAAAAAAAAAAAAA//tgwAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAABBAABD",
		"WQAHCwsPExMXGxsfIiImKiouMjI2Ojo+PkFFRUlNTVFVVVldXWBkZGhsbHBwdHh4fH9/g4eHi4+Pk5eXm5+foqKmqqqusrK2urq+wcHFycnN0dHV1dnd3eDk",
		"5Ojs7PD09Pj8/P8AAAAATGF2YzYwLjMxAAAAAAAAAAAAAAAAJAJAAAAAAAAAQ1nUEUuQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
		"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//tgxAADwAABpAAAACAAADSAAAAETEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVTEFNRTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tixHgDwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVTEFN",
		"RTMuMTAwVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7YMSHg8AAAaQAAAAgAAA0gAAABFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVTEFNRTMuMTAwVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVf/7YMSHg8AAAaQAAAAgAAA0gAAABFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVf/7YMSHg8AAAaQAAAAgAAA0gAAABFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"Vf/7YsSHA8AAAaQAAAAgAAA0gAAABFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PA",
		"AAGkAAAAIAAANIAAAARVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PAAAGkAAAAIAAA",
		"NIAAAARVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PAAAGkAAAAIAAANIAAAARVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2LEhwPAAAGkAAAAIAAANIAAAARVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tgxIeDwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tgxIeDwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUA",
		"WpHoHoJY6J+EfAziZtJfydnWzwEMLYF4AsGFCmHA//tgxIeDwAABpAAAACAAADSAAAAEqfZxFPruGu9AIlYwtAOweX3JxaZcRdgIEGSKGMBAAQZY4PHTQtTz",
		"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",
		"AgxhVsSipLeBeSrTQGMWeVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7YsSIA8A4AgAIAAAg",
		"AAAAAAAABFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PAAAGkAAAAIAAANIAAAARV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PAAAGkAAAAIAAANIAAAARVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjEwMFVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PAAAGkAAAAIAAANIAAAARVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2DEh4PAAAGkAAAAIAAANIAAAARVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+2LEhwPAAAGkAAAAIAAANIAAAARVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tgxIeDwAABpAAAACAAADSAAAAEVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV",
		"VVVVVVVVVVVVVVVVVVVV",
	})
	local bombAssets = {}
	local function bombAsset(kind)
		if bombAssets[kind] == nil then
			if kind == "bomb" then
				bombAssets[kind] = loadEmbeddedImage("OscarBombzcar.jpg", BOMBZCAR_IMG) or false
			elseif kind == "greenx" then
				bombAssets[kind] = loadEmbeddedImage("OscarGreenX.png", GREENX_IMG) or false
			elseif kind == "fatboy" then
				bombAssets[kind] = loadEmbeddedImage("OscarFatboySpawn.mp3", FATBOY_MP3) or false
			elseif kind == "boomsound" then
				bombAssets[kind] = loadEmbeddedImage("OscarBoomSound.mp3", BOOM_MP3) or false
			else
				bombAssets[kind] = loadEmbeddedImage("OscarBoom.png", BOOM_IMG) or false
			end
		end
		return bombAssets[kind] or nil
	end
	local function playBombSound(kind, parent, volume)
		task.spawn(function()
			pcall(function()
				local id = bombAsset(kind)
				if not id then return end
				local sound = Instance.new("Sound")
				sound.SoundId = id
				sound.Volume = volume or 1
				sound.Parent = parent
				sound:Play()
				Debris:AddItem(sound, 6)
			end)
		end)
	end
	local imageAssets = {}
	local function popupImage(index)
		if imageAssets[index] == nil then
			imageAssets[index] = loadEmbeddedImage("OscarPopup" .. index .. ".jpg", IMAGE_DATA[index]) or false
		end
		return imageAssets[index] or nil
	end

	local function clearPopups()
		if popups.gui then
			pcall(function()
				popups.gui:Destroy()
			end)
			popups.gui = nil
		end
		popups.count = 0
		bomb.count = 0
		table.clear(bomb.stains)
	end

	local function ensureGui()
		if popups.gui and popups.gui.Parent then return popups.gui end
		local popupGui = make("ScreenGui", {
			Name = "OscarsPopups",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 200,
		}, playerGui)
		popups.gui = popupGui
		return popupGui
	end

	local function spawnPopup(token)
		local popupGui = ensureGui()
		local screen = popupGui.AbsoluteSize
		if screen.X < 50 then screen = Vector2.new(800, 600) end
		local maxW, maxH = math.floor(math.min(360, screen.X - 20)), math.floor(math.min(320, screen.Y - 20))
		local minW, minH = math.min(170, maxW), math.min(150, maxH)

		local width, height = math.random(minW, maxW), math.random(minH, maxH)
		local x = math.random(0, math.max(0, math.floor(screen.X - width)))
		local y = math.random(0, math.max(0, math.floor(screen.Y - height)))

		local GREEN = Color3.fromRGB(70, 255, 110)
		local frame = make("Frame", {
			Size = UDim2.fromOffset(20, 20),
			Position = UDim2.fromOffset(x + width / 2, y + height / 2),
			BackgroundColor3 = Color3.fromRGB(8, 4, 4),
			ClipsDescendants = true,
		}, popupGui)
		make("UICorner", { CornerRadius = UDim.new(0, 4) }, frame)

		-- no title bar at all: the picture fills the popup and only the green X sits on top
		local bar = make("Frame", {
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, frame)

		local imageIndex = math.random(#IMAGE_DATA)
		local assetId = popupImage(imageIndex)
		if assetId then
			make("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				Image = assetId,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 1,
			}, frame)
		else
			make("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				TextColor3 = GREEN,
				TextSize = 28,
				Font = Enum.Font.GothamBlack or Enum.Font.GothamBold,
				ZIndex = 1,
			}, frame)
		end
		bar.ZIndex = 3

		-- spawn sound, high pitched
		task.spawn(function()
			pcall(function()
				if popups.soundFile == nil then
					local write = Custom.exec("writefile", "write_file")
					local asset = Custom.exec("getcustomasset", "getsynasset", "get_custom_asset")
					popups.soundFile = false
					if write and asset then
						write("OscarPopupSpawn.mp3", decodeBase64(SPAWN_MP3_BASE64))
						popups.soundFile = asset("OscarPopupSpawn.mp3") or false
					end
				end
				if popups.soundFile then
					local sound = Instance.new("Sound")
					sound.SoundId = popups.soundFile
					sound.Volume = 0.8
					sound.PlaybackSpeed = 1.9
					sound.Parent = popupGui
					sound:Play()
					Debris:AddItem(sound, 4)
				end
			end)
		end)

		local closed = false
		local greenId = bombAsset("greenx")
		local close = make("ImageButton", {
			Size = UDim2.fromOffset(28, 28),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 4),
			BackgroundTransparency = 1,
			Image = greenId or "",
			AutoButtonColor = false,
			ZIndex = 5,
		}, frame)
		if not greenId then
			make("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "X",
				TextColor3 = Color3.fromRGB(40, 200, 60),
				TextSize = 24,
				Font = Enum.Font.GothamBlack,
				ZIndex = 6,
			}, close)
		end
		popups.count += 1
		listen(close.MouseButton1Click, function()
			if closed then return end
			closed = true
			popups.count = math.max(0, popups.count - 1)
			TweenService:Create(frame, TweenInfo.new(0.12), { Size = UDim2.fromOffset(0, 0) }):Play()
			task.delay(0.13, function()
				frame:Destroy()
			end)
		end)

		-- pop in, then keep changing height and length (smooth, slower tweens) until it is closed
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(width, height),
			Position = UDim2.fromOffset(x, y),
		}):Play()

		-- small shake: the popup trembles (rotation, so it never fights the size / position tweens)
		task.spawn(function()
			while not closed and frame.Parent do
				frame.Rotation = (math.random() - 0.5) * 5
				task.wait(0.045)
			end
		end)

		task.spawn(function()
			while not closed and frame.Parent and popups.on and popups.token == token do
				task.wait(0.9)
				if closed or not frame.Parent then return end
				local newW, newH = math.random(minW, maxW), math.random(minH, maxH)
				local screenNow = popupGui.AbsoluteSize
				local newX = math.clamp(frame.Position.X.Offset, 0, math.max(0, screenNow.X - newW))
				local newY = math.clamp(frame.Position.Y.Offset, 0, math.max(0, screenNow.Y - newH))
				TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Size = UDim2.fromOffset(newW, newH),
					Position = UDim2.fromOffset(newX, newY),
				}):Play()
			end
		end)
	end


	-- the black stain: the explosion picture painted black, gone after bomb.stainTime seconds
	local function makeStain(popupGui, cx, cy, radius)
		while #bomb.stains >= math.max(1, bomb.maxStains) do
			local old = table.remove(bomb.stains, 1)
			if old and old.Parent then old:Destroy() end
		end
		local full = radius * 2.6
		local boomId = bombAsset("boom")
		local stain
		if boomId then
			stain = make("ImageLabel", {
				Size = UDim2.fromOffset(full * 0.3, full * 0.3),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(cx, cy),
				BackgroundTransparency = 1,
				Image = boomId,
				ImageColor3 = Color3.new(0, 0, 0),
				Rotation = math.random(-25, 25),
				ZIndex = 10,
			}, popupGui)
		else
			stain = make("Frame", {
				Size = UDim2.fromOffset(full * 0.3, full * 0.3),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(cx, cy),
				BackgroundColor3 = Color3.new(0, 0, 0),
				ZIndex = 10,
			}, popupGui)
			make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, stain)
		end
		table.insert(bomb.stains, stain)
		TweenService:Create(stain, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(full, full),
		}):Play()
		task.delay(math.max(1, bomb.stainTime), function()
			if not stain.Parent then return end
			local fade = {}
			if stain:IsA("ImageLabel") then fade.ImageTransparency = 1 else fade.BackgroundTransparency = 1 end
			TweenService:Create(stain, TweenInfo.new(1.2), fade):Play()
			task.delay(1.3, function()
				local index = table.find(bomb.stains, stain)
				if index then table.remove(bomb.stains, index) end
				if stain.Parent then stain:Destroy() end
			end)
		end)
	end

	local function spawnBombzcar(token)
		local popupGui = ensureGui()
		local screen = popupGui.AbsoluteSize
		if screen.X < 50 then screen = Vector2.new(800, 600) end
		local height = math.floor(math.clamp(bomb.size, 60, math.min(400, screen.Y - 20)))
		local width = math.floor(height * 0.9)
		local x = math.random(0, math.max(0, math.floor(screen.X - width)))
		local y = math.random(0, math.max(0, math.floor(screen.Y - height)))
		local cx, cy = x + width / 2, y + height / 2

		local holder = make("Frame", {
			Size = UDim2.fromOffset(width * 0.2, height * 0.2),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(cx, cy),
			BackgroundTransparency = 1,
			ZIndex = 8,
		}, popupGui)
		local assetId = bombAsset("bomb")
		local button = make("ImageButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			Image = assetId or "",
			ScaleType = Enum.ScaleType.Crop,
			AutoButtonColor = false,
			ZIndex = 8,
		}, holder)
		make("UICorner", { CornerRadius = UDim.new(0, 10) }, button)
		if not assetId then
			make("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "BOMBZCAR",
				TextColor3 = Color3.fromRGB(255, 40, 40),
				TextSize = 18,
				Font = Enum.Font.GothamBlack,
				ZIndex = 9,
			}, button)
		end
		bomb.count += 1
		local done = false
		local function finish()
			if done then return false end
			done = true
			bomb.count = math.max(0, bomb.count - 1)
			return true
		end

		TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(width, height),
		}):Play()
		playBombSound("fatboy", popupGui, 1)

		-- nervous wobble
		task.spawn(function()
			while not done and holder.Parent do
				holder.Rotation = (math.random() - 0.5) * 8
				task.wait(0.06)
			end
		end)

		listen(button.MouseButton1Click, function()
			if not finish() then return end
			holder:Destroy()
			playBombSound("boomsound", popupGui, 1)
			-- boom
			local boomId = bombAsset("boom")
			local boom
			if boomId then
				boom = make("ImageLabel", {
					Size = UDim2.fromOffset(height * 0.5, height * 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(cx, cy),
					BackgroundTransparency = 1,
					Image = boomId,
					ZIndex = 12,
				}, popupGui)
			else
				boom = make("Frame", {
					Size = UDim2.fromOffset(height * 0.5, height * 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromOffset(cx, cy),
					BackgroundColor3 = Color3.fromRGB(255, 170, 30),
					ZIndex = 12,
				}, popupGui)
				make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, boom)
			end
			TweenService:Create(boom, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(height * 2.4, height * 2.4),
				Rotation = (math.random() - 0.5) * 40,
			}):Play()
			task.delay(0.18, function()
				if not boom.Parent then return end
				local fade = { }
				if boom:IsA("ImageLabel") then fade.ImageTransparency = 1 else fade.BackgroundTransparency = 1 end
				TweenService:Create(boom, TweenInfo.new(0.3), fade):Play()
			end)
			Debris:AddItem(boom, 0.6)
			makeStain(popupGui, cx, cy, height * 0.8)
		end)

		-- left alone: he gives up and disappears
		task.delay(math.max(0.5, bomb.despawn), function()
			if not finish() then return end
			if holder.Parent then
				TweenService:Create(holder, TweenInfo.new(0.2), { Size = UDim2.fromOffset(0, 0) }):Play()
				task.delay(0.22, function()
					holder:Destroy()
				end)
			end
		end)
	end

	local function stopPopups()
		popups.on = false
		popups.token += 1
		clearPopups()
	end

	local function startPopups()
		stopPopups()
		popups.on = true
		local token = popups.token
		task.spawn(function()
			while popups.on and popups.token == token and not destroyed do
				local low, high = popups.minTime, math.max(popups.minTime, popups.maxTime)
				task.wait(low + math.random() * (high - low))
				if not (popups.on and popups.token == token) then return end
				if bomb.on and bomb.count < bomb.max and math.random() * 100 < bomb.chance then
					pcall(spawnBombzcar, token)
				else
					pcall(spawnPopup, token)
				end
			end
		end)
	end
	Custom.popupStop = stopPopups

	local popupDrawer = addToggleCogRow(page, "OSCAR'S POPUPS", function()
		return popups.on
	end, function(value)
		if value then
			startPopups()
		else
			stopPopups()
		end
	end)

	addNumberBox(addGrayRow(popupDrawer, "Fastest (seconds)"), tostring(popups.minTime), function(box)
		local number = tonumber(box.Text)
		popups.minTime = (number and number >= 0.2) and number or 2
		if popups.maxTime < popups.minTime then popups.maxTime = popups.minTime end
		box.Text = tostring(popups.minTime)
	end)
	addNumberBox(addGrayRow(popupDrawer, "Slowest (seconds)"), tostring(popups.maxTime), function(box)
		local number = tonumber(box.Text)
		popups.maxTime = (number and number >= popups.minTime) and number or math.max(4, popups.minTime)
		box.Text = tostring(popups.maxTime)
	end)

	-- ===== Bombzcar settings =====
	addSwitch(addGrayRow(popupDrawer, "Include Bombzcar (click him = boom + black stain)"), function()
		return bomb.on
	end, function(value)
		bomb.on = value
	end)
	local function bombNumber(label, key, low, high, default)
		addNumberBox(addGrayRow(popupDrawer, label), tostring(bomb[key]), function(box)
			local number = tonumber(box.Text)
			bomb[key] = number and math.clamp(number, low, high) or default
			box.Text = tostring(bomb[key])
		end)
	end
	bombNumber("Bombzcar chance (% of popups)", "chance", 0, 100, 25)
	bombNumber("Bombzcar max on screen", "max", 1, 30, 3)
	bombNumber("Bombzcar leaves after (seconds)", "despawn", 0.5, 120, 5)
	bombNumber("Black stain lasts (seconds)", "stainTime", 1, 600, 15)
	bombNumber("Max stains on screen", "maxStains", 1, 60, 10)
	bombNumber("Bombzcar size (pixels tall)", "size", 60, 400, 150)
end)


showTab("Main Chapters")

-- startup sound
task.spawn(function()
	local sound
	pcall(function()
		sound = playEmbeddedSound("OscarsCoolPanelSpawn.mp3", SPAWN_MP3_BASE64, SoundService, 1)
	end)
	if sound then
		Debris:AddItem(sound, 10)
	end
end)

_G.SandboxMenuCleanup = function()
	for _, setEnabled in spawners do
		pcall(setEnabled, false)
	end
	for _, connection in connections do
		pcall(function()
			connection:Disconnect()
		end)
	end
	if doomStop then pcall(doomStop) end
	if Custom.musicStop then pcall(Custom.musicStop) end
	if Custom.renameStop then pcall(Custom.renameStop) end
	if Custom.puzzleStop then pcall(Custom.puzzleStop) end
	if Custom.popupStop then pcall(Custom.popupStop) end
	if Custom.counterStop then pcall(Custom.counterStop) end
	if Custom.sizeStop then pcall(Custom.sizeStop) end
	if Custom.worldStop then pcall(Custom.worldStop) end
	if Custom.animStop then pcall(Custom.animStop) end
	if Custom.soundStop then pcall(Custom.soundStop) end
	if Custom.povStop then pcall(Custom.povStop) end
	if Custom.theirViewStop then pcall(Custom.theirViewStop) end
	if Custom.invisibleStop then pcall(Custom.invisibleStop) end
	if Custom.imageBlockStop then pcall(Custom.imageBlockStop) end
	if Custom.cineStop then pcall(Custom.cineStop) end
	pcall(Avatar.clearAccessories)
	pcall(CrimsonSkies.stop)
	Avatar.stop()
	destroyed = true
	libertyStop()
	resetCannon()
	gui:Destroy()
	_G.SandboxMenuCleanup = nil
end
