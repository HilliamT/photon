pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/// @title UniswapSwapper
/// @author Hilliam
/// @notice Implementation to swap exactly an input amount or exactly for an output amount
contract UniswapSwapper {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Uniswap Swap Router
    address constant swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    function swapWithExactInput(
        address inputToken,
        address outputToken,
        uint256 amountIn
    ) public returns (uint256 amountOut) {
        IERC20(inputToken).approve(swapRouter, amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: inputToken,
                tokenOut: outputToken,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = ISwapRouter(swapRouter).exactInputSingle(params);

        // Removal approval off swapRouter
        IERC20(inputToken).approve(swapRouter, 0);
    }

    function swapForExactOutput(
        address inputToken,
        address outputToken,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public returns (uint256 amountIn) {
        IERC20(inputToken).approve(swapRouter, amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: inputToken,
                tokenOut: outputToken,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = ISwapRouter(swapRouter).exactOutputSingle(params);

        // Remove approval off swapRouter
        IERC20(inputToken).approve(swapRouter, 0);
    }
}
