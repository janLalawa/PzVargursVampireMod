return {
    VargursHumanBlood = {
        calories = 750,
        carbohydrates = 0.0,
        proteins = 140,
        lipids = 5,
        enduranceChange = 0.40,
        generalHealthChange = 17.5,
        hungerChange = -0.75,
        thirstChange = -0.85,
        foodSicknessChange = -20.0,
        poisonChange = -15.0,
        stressChange = -0.50,
        intoxicationChange = 30.0,
        panicChange = -20.0,
        boredomChange = -25.0,
        unhappinessChange = -30.0,
    },
    VargursZombieBlood = {
        calories = 450,
        carbohydrates = 0.0,
        proteins = 100,
        lipids = 5,
        enduranceChange = 0.2,
        generalHealthChange = 7.5,
        hungerChange = -0.75,
        thirstChange = -0.85,
        foodSicknessChange = 0.0,
        poisonChange = 120.0,
        stressChange = 1.5,
        intoxicationChange = 40,
        panicChange = 30.0,
        boredomChange = 0.0,
        unhappinessChange = 25.0,
    },
    AnimalBlood = {
        calories = 550,
        carbohydrates = 0.0,
        proteins = 105,
        lipids = 4,
        enduranceChange = 0.35,
        generalHealthChange = 10.0,
        hungerChange = -0.6,
        thirstChange = -0.75,
        foodSicknessChange = -10.0,
        poisonChange = -5.0,
        stressChange = -0.30,
        intoxicationChange = 20.0,
        panicChange = -20.0,
        boredomChange = -10.0,
        unhappinessChange = -15.0,
    },
}

--[[ Vanilla Build 42 references (profiles apply per 1.0 fluid unit)

- 0.2-unit glass equivalents are less relevant for nutrition since we can match the game exactly :)
- calories: CowMilk = 615; Wine = 481 per unit.
- carbohydrates: CowMilk = 46 per unit.
- proteins: CowMilk = 33 per unit.
- lipids: CowMilk = 22 per unit.

- hungerChange: CowMilk script HungerChange = -50; equivalent here = -0.5 per unit.
- thirstChange: Water script ThirstChange = -50; equivalent here = -0.5 per unit.

- foodSicknessChange: Lemongrass script = -12 per item. 0.2-unit glass equivalent = -60
- stressChange: Magazine script StressChange = -0.15. 0.2-unit glass equivalent = -0.75
- intoxicationChange: Wine's alcohol = 0.12. 0.2-unit glass equivalent approximately 60
- panicChange: Panic is 0-100. 0.2-unit glass equivalent = 10
- boredomChange: Magazine script BoredomChange = -20. 0.2-unit glass equivalent = -100
- unhappinessChange: Wine script UnhappyChange = -20. -20 is equivalent since the wine script is based on a 1.0-unit bottle.
]]
