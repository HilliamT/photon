pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IBalancer} from "../../interfaces/IBalancer.sol";

/// @title BalancerLoanReceiver
/// @author Hilliam
/// @notice Minimal implementation to receive a Balancer flash loan
abstract contract BalancerLoanReceiver {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Balancer Vault Contract
    address constant balancerAddress =
        0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Flag for guarding `receiveFlashLoan`
    /// @dev Before calling `flashLoan`, set the flag to `false`.
    /// @dev After calling `flashLoan`, set the flag to `true`.
    bool public flashWallOn = true;
    IBalancer constant balancer = IBalancer(balancerAddress);

    /*//////////////////////////////////////////////////////////////
                               FLASH LOAN
    //////////////////////////////////////////////////////////////*/

    function flashLoan(address token, uint256 amount) public {
        address[] memory tokens = new address[](1);
        tokens[0] = token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        balancer.flashLoan(address(this), tokens, amounts, "");
    }

    function receiveFlashLoan(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata, /* feeAmounts */
        bytes calldata /* userData */
    ) public virtual;
}
