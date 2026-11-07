---@class VargursBloodExtractionProfile
---@field fluidType string
---@field minimumYield number
---@field maximumYield number

local animalFluid = "AnimalBlood"

return {
    zombie = { fluidType = "VargursZombieBlood", minimumYield = 0.15, maximumYield = 0.25 },
    human = { fluidType = "VargursHumanBlood", minimumYield = 0.30, maximumYield = 0.50 },
    animalDefault = { fluidType = animalFluid, minimumYield = 0.15, maximumYield = 0.25 },
    animals = {
        chick = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.02 },
        hen = { fluidType = animalFluid, minimumYield = 0.05, maximumYield = 0.10 },
        cockerel = { fluidType = animalFluid, minimumYield = 0.05, maximumYield = 0.10 },
        cowcalf = { fluidType = animalFluid, minimumYield = 5.0, maximumYield = 10.0 },
        cow = { fluidType = animalFluid, minimumYield = 10.0, maximumYield = 35.0 },
        bull = { fluidType = animalFluid, minimumYield = 10.0, maximumYield = 35.0 },
        fawn = { fluidType = animalFluid, minimumYield = 2.0, maximumYield = 6.0 },
        doe = { fluidType = animalFluid, minimumYield = 8.0, maximumYield = 25.0 },
        buck = { fluidType = animalFluid, minimumYield = 8.0, maximumYield = 25.0 },
        mousepups = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.01 },
        mousefemale = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.02 },
        mouse = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.02 },
        piglet = { fluidType = animalFluid, minimumYield = 2.0, maximumYield = 6.0 },
        sow = { fluidType = animalFluid, minimumYield = 8.0, maximumYield = 25.0 },
        boar = { fluidType = animalFluid, minimumYield = 8.0, maximumYield = 25.0 },
        rabkitten = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.02 },
        rabdoe = { fluidType = animalFluid, minimumYield = 0.05, maximumYield = 0.15 },
        rabbuck = { fluidType = animalFluid, minimumYield = 0.05, maximumYield = 0.15 },
        raccoonkit = { fluidType = animalFluid, minimumYield = 0.02, maximumYield = 0.05 },
        raccoonsow = { fluidType = animalFluid, minimumYield = 0.10, maximumYield = 0.25 },
        raccoonboar = { fluidType = animalFluid, minimumYield = 0.10, maximumYield = 0.25 },
        ratbaby = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.01 },
        ratfemale = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.03 },
        rat = { fluidType = animalFluid, minimumYield = 0.01, maximumYield = 0.03 },
        lamb = { fluidType = animalFluid, minimumYield = 2.0, maximumYield = 6.0 },
        ewe = { fluidType = animalFluid, minimumYield = 8.0, maximumYield = 25.0 },
        ram = { fluidType = animalFluid, minimumYield = 8.0, maximumYield = 25.0 },
        turkeypoult = { fluidType = animalFluid, minimumYield = 0.02, maximumYield = 0.05 },
        turkeyhen = { fluidType = animalFluid, minimumYield = 0.15, maximumYield = 0.30 },
        gobblers = { fluidType = animalFluid, minimumYield = 0.20, maximumYield = 0.40 },
    },
}