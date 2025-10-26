// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract LiskGarden {
    enum GrowthStage {
        SEED,
        SPROUT, 
        GROWING, 
        BLOOMING
    }

    struct Plant {
        uint256 id;
        address owner;
        GrowthStage stage;
        uint256 plantedDate;
        uint256 lastWatered;
        uint8 waterLevel;
        bool exist;
        bool isDead;
    }
    
    mapping(uint256 => Plant) public plants;
    mapping(address => uint256[]) public  userPlants;
    uint256 public  plantCounter;
    address public  owner;

    // 3. Constants
    uint256 public  constant PLANT_PRICE = 0.001 ether;
    uint256 public  constant HARVEST_REWARD = 0.003 ether;
    uint256 public  constant STAGE_DURATION = 1 minutes;
    uint256 public  constant WATER_DEPLETION_TIME = 30 seconds;
    uint8 public  constant WATER_DEPLETION_RATE  = 2;

    // 4. Events
    event PlantSeeded(address indexed owner, uint256 indexed plantId);
    event PlantWatered(uint256 indexed plantId, uint8 newWaterLevel);
    event PlantHarvested(uint256 indexed plantId, address indexed owner, uint256 reward);
    event StageAdvanced(uint256 indexed plantId, GrowthStage newStage);
    event PlantDied(uint256 indexed plantId);

    // 5. Constructor
    constructor() {
        owner = msg.sender;
    }

    // 6. Main Functions (8 functions)
    function deposit() public payable {
        require(msg.value >= 0.003 ether, "Perlu 0.003 ETH");
    }

    function plantSeed() external payable returns (uint256) { 
        require(msg.value >= PLANT_PRICE, "Perlu 0.001 ETH");
        plantCounter++;
        uint256 newPlantId = plantCounter;

        Plant memory newPlant = Plant({
            id: newPlantId,
            owner: msg.sender,
            stage: GrowthStage.SEED,
            plantedDate: block.timestamp,
            lastWatered: block.timestamp,
            waterLevel: 100,
            exist: true,
            isDead: false
        });

        plants[plantCounter] = newPlant;
        userPlants[msg.sender].push(newPlantId);

        emit PlantSeeded(msg.sender, newPlantId);

        return newPlantId;
    }

    function calculateWaterLevel(uint256 plantId) public view returns (uint8) {
       Plant memory _plants = plants[plantId];

        if (!_plants.exist || _plants.isDead){
            return 0;
        }
        uint256 timeSinceWatered = block.timestamp - _plants.lastWatered;
        uint256 depletionIntervals = timeSinceWatered / WATER_DEPLETION_TIME;
        uint256 waterLost = depletionIntervals * WATER_DEPLETION_RATE;

        if (waterLost >= _plants.waterLevel) {
            return 0;
        }

        return uint8(_plants.waterLevel - waterLost);
    }

    function updateWaterLevel(uint256 plantId) internal {
        Plant memory _plant = plants[plantId];

        uint256 currentWater = calculateWaterLevel(_plant.id);

        _plant.waterLevel = uint8(currentWater);

        if (currentWater == 0 && !_plant.isDead) {
            _plant.isDead = true;

            emit PlantDied(plantId);
        }
    }

    function waterPlant(uint256 plantId) external {
        Plant memory _plant = plants[plantId];
        
        require(_plant.exist, "Plant not Exist");
        require(_plant.owner == msg.sender, "You are not the owner");
        require(!_plant.isDead, "Plant is dead");

        uint8 newLevel = 100;
        _plant.waterLevel = newLevel;
        _plant.lastWatered = block.timestamp;

        emit PlantWatered(plantId, newLevel);

        updatePlantStage(plantId);
    }

    function updatePlantStage(uint256 plantId) public {
        Plant memory _plant = plants[plantId];

        require(_plant.exist, "Plant not Exist");

        updateWaterLevel(plantId);

        if (_plant.isDead) {
            return;
        }

        uint256 timeSincePlanted = block.timestamp - _plant.plantedDate;

        GrowthStage oldState = _plant.stage;
        
        if (timeSincePlanted >= STAGE_DURATION && oldState == GrowthStage.SEED) {
            _plant.stage = GrowthStage.SPROUT;
            emit StageAdvanced(plantId, GrowthStage.SPROUT);
        } else if (timeSincePlanted >= (STAGE_DURATION * 2) && oldState == GrowthStage.SPROUT) {
            _plant.stage = GrowthStage.GROWING;
            emit StageAdvanced(plantId, GrowthStage.GROWING);
        } else if (timeSincePlanted >= (STAGE_DURATION * 3) && oldState == GrowthStage.GROWING) {
            _plant.stage = GrowthStage.BLOOMING;
            emit StageAdvanced(plantId, GrowthStage.BLOOMING);
        }
    }

    function harvestPlant(uint256 plantId) external {
        Plant memory _plant = plants[plantId];
        require(_plant.exist, "Plant not Exist");
        require(_plant.stage == GrowthStage.BLOOMING, "Plant not ready to harvest");
        require(_plant.owner == msg.sender, "Only the owner can harvest");

        updatePlantStage(plantId);

        require(_plant.stage == GrowthStage.BLOOMING, "Plant not ready to harvest");
        
        _plant.exist = false;

        emit PlantHarvested(plantId, _plant.owner, HARVEST_REWARD);

        (bool success, ) = _plant.owner.call{value: HARVEST_REWARD}("");
        require(success, "Transfer gagal");
    }

    // // 7. Helper Functions (3 functions)
    function getPlant(uint256 plantId) external view returns (Plant memory) {
        Plant memory plant = plants[plantId];
        plant.waterLevel = calculateWaterLevel(plantId);
        return plant;
    }

    function getUserPlants(address user) external view returns (uint256[] memory) {
        return userPlants[user];
    }

    function withdraw() external {
        require(msg.sender == owner, "Bukan owner");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer gagal");
    }

    // // 8. Receive ETH
    receive() external payable {}
}