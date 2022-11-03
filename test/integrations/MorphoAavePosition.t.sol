// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "../utils/Utilities.sol";
import {console} from "../utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {MorphoAavePosition} from "../../contracts/integrations/MorphoAavePosition.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

contract MorphoAavePositionTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    address[] internal updatedMarkets;

    IWETH9 public WETH;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);

        WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    function testExample() public {
        address payable alice = users[0];
        // labels alice's address in call traces as "Alice [<address>]"
        vm.label(alice, "Alice");
        console.log("alice's address", alice);
        address payable bob = users[1];
        vm.label(bob, "Bob");

        vm.prank(alice);
        (bool sent, ) = bob.call{value: 10 ether}("");
        assertTrue(sent);
        assertGt(bob.balance, alice.balance);
    }

    function testCreatePosition() public {
        address MORPHO = 0x777777c9898D384F785Ee44Acfe945efDFf5f3E0;
        address MORPHO_LENS = 0x507fA343d0A90786d86C7cd885f5C49263A91FF4;

        address alice = users[0];
        vm.label(alice, "Alice");
        vm.startPrank(alice);
        address AETH = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
        address AUSDC = 0xBcca60bB61934080951369a648Fb03DF4F96263C;
        // deposit
        WETH.deposit{value: 1 ether}();
        address collateralAddress = address(WETH);
        address exposureTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        uint256 leverage = 50;
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        MorphoAavePosition position = new MorphoAavePosition(
            MORPHO,
            MORPHO_LENS
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: collateralAddress,
                tokenOut: exposureTokenAddress, // USDC
                fee: 3000,
                recipient: alice,
                deadline: block.timestamp,
                amountOut: 10**8,
                amountInMaximum: 2**256 - 1,
                sqrtPriceLimitX96: 0
            });

        IERC20(collateralAddress).approve(swapRouter, 10**18);
        ISwapRouter(swapRouter).exactOutputSingle(params);

        uint256 amountDebt = IERC20(exposureTokenAddress).balanceOf(alice);

        IERC20(exposureTokenAddress).approve(address(position), amountDebt);

        position.createPosition(
            collateralAddress,
            AETH,
            exposureTokenAddress,
            AUSDC,
            amountDebt,
            leverage
        );

        console.log(position.getHealthFactor());
        console.log(position.getDebtBalance());
        console.logInt(position.getFundingRate());

        position.closePosition();

        vm.stopPrank();
    }
}
