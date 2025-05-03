// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import {Test, console2} from "forge-std/Test.sol";
// import {Test, console2} from "../lib/forge-std/src/Test.sol";
// import {ILQTYStaking} from "../src/interfaces/ILQTYStaking.sol";
import {MockStakingV1} from "./Mocks/MockStakingV1.sol";
import {MockStakingV1Deployer} from "./Mocks/MockStakingV1Deployer.sol";
import {MockERC20Tester} from "./Mocks/MockERC20Tester.sol";
import {Governance} from "../src/Governance.sol";
import {IGovernance} from "../src/interfaces/IGovernance.sol";
import {IBribeInitiative} from "../src/interfaces/IBribeInitiative.sol";
import {BribeInitiative} from "../src/BribeInitiative.sol";
import {IUserProxy} from "../src/interfaces/IUserProxy.sol";
import "./utils/utils.sol";
// import {BaseSetup} from "@chimera/BaseSetup.sol";
// import {hevm} from "@chimera/Hevm.sol";


// echidna . --contract Properties/GovernanceProperties.sol --config config.yaml
    // constructor(
    //     address _lqty, ERC20
    //     address _lusd, ERC20
    //     address _stakingV1, -- need this one import 
    //     address _bold, ERC20
    //     Configuration memory _config, -- need this one import  from unit test cases 
    //     address _owner,
    //     address[] memory _initiatives
    // ) UserProxyFactory(_lqty, _lusd, _stakingV1) Ownable(_owner)


    // struct Configuration {
    //     uint256 registrationFee;
    //     uint256 registrationThresholdFactor;
    //     uint256 unregistrationThresholdFactor;
    //     uint256 unregistrationAfterEpochs;
    //     uint256 votingThresholdFactor;
    //     uint256 minClaim;
    //     uint256 minAccrual;
    //     uint256 epochStart;
    //     uint256 epochDuration;
    //     uint256 epochVotingCutoff;
    // }

contract SelfSetup is  MockStakingV1Deployer{

    // event Error(string);

    IHevm hevm = IHevm(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D));

    MockERC20Tester internal lqty;
    MockERC20Tester internal lusd;
    MockERC20Tester internal bold;
    MockStakingV1 internal stakingV1;  // Construtor requirements are 
    Governance internal governance;


    uint128 private constant REGISTRATION_FEE = 100e18;
    uint128 private constant REGISTRATION_THRESHOLD_FACTOR = 0.001e18;
    uint128 private constant UNREGISTRATION_THRESHOLD_FACTOR = 3e18;
    uint16 private constant UNREGISTRATION_AFTER_EPOCHS = 4;
    uint128 private constant VOTING_THRESHOLD_FACTOR = 0.03e18;
    uint88 private constant MIN_CLAIM = 500e18;
    uint88 private constant MIN_ACCRUAL = 1000e18;
    uint32 private constant EPOCH_DURATION = 604800; // 7 days
    uint32 private constant EPOCH_VOTING_CUTOFF = 518400;  // 6 days

    address deployer = address(0x1000000000000000000000000000000000000000);
    address[] internal users;
    address[] internal deployedInitiatives;
    IBribeInitiative internal initiative1;
    uint256 internal initialLqtyAllocatedPerUser = type(uint88).max;
    uint256 internal initialBoldAllocatedPerUser = type(uint88).max;
    address internal user1Proxy;
    address internal user2Proxy;
    bool internal user2ProxyCreated;



    function setup() internal {
        (stakingV1 ,lqty, lusd)  = deployMockStakingV1();
        bold = new MockERC20Tester("BOLD Stablecoin", "BOLD");
        users.push(address(0x2000000000000000000000000000000000000000));
        users.push(address(0x3000000000000000000000000000000000000000));
        users.push(address(0x4000000000000000000000000000000000000000));
        users.push(address(0x5000000000000000000000000000000000000000));

        IGovernance.Configuration memory config  = IGovernance.Configuration({
            registrationFee: REGISTRATION_FEE,
            registrationThresholdFactor: REGISTRATION_THRESHOLD_FACTOR,
            unregistrationThresholdFactor: UNREGISTRATION_THRESHOLD_FACTOR,
            unregistrationAfterEpochs: UNREGISTRATION_AFTER_EPOCHS,
            votingThresholdFactor: VOTING_THRESHOLD_FACTOR,
            minClaim: MIN_CLAIM,
            minAccrual: MIN_ACCRUAL,
            epochStart:block.timestamp - EPOCH_DURATION,
            epochDuration: EPOCH_DURATION,
            epochVotingCutoff: EPOCH_VOTING_CUTOFF
        });

        for(uint256 i; i<users.length; i++){
            bold.mint(users[i],initialBoldAllocatedPerUser);
        }

        lqty.mint(users[0], initialLqtyAllocatedPerUser);
        lqty.mint(users[1], initialLqtyAllocatedPerUser);
        lusd.mint(users[2], initialLqtyAllocatedPerUser);
        
        hevm.prank(deployer);
        governance = new Governance(address(lqty), address(lusd), address(stakingV1), address(bold), config, deployer, deployedInitiatives);
        

        user1Proxy = governance.deployUserProxy();
        hevm.prank(users[0]);
        lqty.approve(address(user1Proxy), type(uint256).max);
        hevm.prank(users[0]);
        lusd.approve(address(user1Proxy), type(uint256).max);

        hevm.prank(users[0]);
        lqty.approve(address(governance), type(uint256).max);
        hevm.prank(users[0]);
        lusd.approve(address(governance), type(uint256).max);



        initiative1 = IBribeInitiative(address(new BribeInitiative(address(governance), address(lusd), address(lqty))));
        deployedInitiatives.push(address(initiative1));
        hevm.prank(deployer);
        governance.registerInitialInitiatives(deployedInitiatives);

        // assert((lqty.balanceOf(users[1]) == initialLqtyAllocatedPerUser));
        // assert();
    }

    function _getRandomUser(uint8 val) internal view returns(address user , address proxy) {
        // return users[val % users.length];
        user = users[val % users.length];
        proxy = governance.deriveUserProxyAddress(user);
    }

    function _getRandomInitiative(uint8 val) internal view returns(address intiative){
        intiative = deployedInitiatives[val % deployedInitiatives.length];
    }

    // function _makeInitiative() internal 

}
