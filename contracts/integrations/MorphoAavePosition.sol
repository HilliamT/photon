pragma solidity ^0.8.0;

import {MorphoAave} from "../libraries/MorphoAave.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {KnockoutPosition} from "./KnockoutPosition.sol";

contract MorphoAavePosition is KnockoutPosition {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using MorphoAave for address;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address internal morphoContract;
    address internal morphoLensContract;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _morphoContract, address _morphoLensContract) {
        morphoContract = _morphoContract;
        morphoLensContract = _morphoLensContract;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _supply(uint256 collateralAmount) internal override {
        IERC20(collateralTokenAddress).approve(morphoContract, 2**256 - 1);
        morphoContract.supply(poolCollateralTokenAddress, collateralAmount);
    }

    function _borrow(uint256 borrowingAmount) internal override {
        morphoContract.borrow(poolDebtTokenAddress, borrowingAmount);
    }

    function _repay() internal override {
        // Set as MATH_MAX.
        IERC20(debtTokenAddress).approve(morphoContract, 2**256 - 1);
        morphoContract.repay(poolDebtTokenAddress, 2**256 - 1);
    }

    function _withdraw() internal override {
        // Set at MATH_MAX.
        morphoContract.withdraw(poolCollateralTokenAddress, 2**256 - 1);
    }

    /*//////////////////////////////////////////////////////////////
                                  VIEW
    //////////////////////////////////////////////////////////////*/

    function getCollateralBalance() public override returns (uint256) {
        return
            morphoLensContract.getCollateralBalance(poolCollateralTokenAddress);
    }

    function getDebtBalance() public override returns (uint256) {
        return morphoLensContract.getDebtBalance(poolDebtTokenAddress);
    }

    function getHealthFactor() public override returns (uint256) {
        return morphoLensContract.getHealthFactor();
    }

    function getFundingRate() public override returns (int256) {
        return
            morphoLensContract.getFundingRatePerYear(
                poolDebtTokenAddress,
                poolCollateralTokenAddress
            );
    }
}
