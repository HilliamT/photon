pragma solidity ^0.8.0;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {BalancerLoanReceiver} from "./utility/BalancerLoanReceiver.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

abstract contract KnockoutPosition is Ownable, BalancerLoanReceiver {
    bool internal created;
    address internal collateralTokenAddress;
    address internal poolCollateralTokenAddress;
    address internal debtTokenAddress;
    address internal poolDebtTokenAddress;
    ISwapRouter internal swapRouter;

    /*//////////////////////////////////////////////////////////////
                          POSITION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function createPosition(
        address _collateralAddress,
        address _poolCollateralTokenAddress,
        address _debtTokenAddress,
        address _poolDebtTokenAddress,
        uint256 _amountDebt,
        uint256 _leverage,
        address _swapRouterAddress
    ) public {
        require(!created, "Position already exists");

        collateralTokenAddress = _collateralAddress;
        poolCollateralTokenAddress = _poolCollateralTokenAddress;
        debtTokenAddress = _debtTokenAddress;
        poolDebtTokenAddress = _poolDebtTokenAddress;

        swapRouter = ISwapRouter(_swapRouterAddress);

        IERC20(_debtTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amountDebt
        );

        // Allow for a flash loan to take place
        flashWallOn = false;

        // Calculate amount to flash
        flashLoan(
            _debtTokenAddress,
            (_amountDebt * (100 - _leverage)) / _leverage
        );

        created = true;
    }

    function closePosition() public {
        require(created, "Position has not been created");

        flashWallOn = false;

        // Flash loan enough to pay off the loan
        flashLoan(debtTokenAddress, getDebtBalance());

        created = false;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function receiveFlashLoan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata, /* feeAmounts */
        bytes calldata /* userData */
    ) public override {
        if (msg.sender != balancerAddress) revert();
        if (flashWallOn) revert();

        if (!created) {
            _createPositionLogic(address(tokens[0]), amounts[0]);
        } else {
            _closePositionLogic(address(tokens[0]), amounts[0]);
        }

        // repay flash loan
        tokens[0].transfer(balancerAddress, amounts[0]);

        flashWallOn = true;
    }

    function _createPositionLogic(address receivedToken, uint256 receivedAmount)
        public
    {
        uint256 receivedTokenBalance = IERC20(receivedToken).balanceOf(
            address(this)
        );

        IERC20(receivedToken).approve(
            address(swapRouter),
            receivedTokenBalance
        );

        // Use collateral to buy exposure token
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: receivedToken,
                tokenOut: collateralTokenAddress,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: receivedTokenBalance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 collateralAmount = swapRouter.exactInputSingle(params);

        _supply(collateralAmount);
        _borrow(receivedAmount);
    }

    function _closePositionLogic(address receivedToken, uint256 receivedAmount)
        public
    {
        _repay();
        _withdraw();

        uint256 amountInMaximum = IERC20(collateralTokenAddress).balanceOf(
            address(this)
        );
        IERC20(collateralTokenAddress).approve(
            address(swapRouter),
            amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: collateralTokenAddress,
                tokenOut: receivedToken,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: receivedAmount,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        uint256 amountIn = swapRouter.exactOutputSingle(params);
        if (amountIn < amountInMaximum) {
            // transfer
            IERC20(collateralTokenAddress).approve(address(swapRouter), 0);
            IERC20(collateralTokenAddress).transfer(
                owner(),
                amountInMaximum - amountIn
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                                VIRTUAL
    //////////////////////////////////////////////////////////////*/

    function _supply(uint256 collateralAmount) internal virtual;

    function _borrow(uint256 borrowingAmount) internal virtual;

    function _repay() internal virtual;

    function _withdraw() internal virtual;

    function getCollateralBalance() public virtual returns (uint256);

    function getDebtBalance() public virtual returns (uint256);

    function getHealthFactor() external virtual returns (uint256);

    function getFundingRate() external virtual returns (int256);
}
