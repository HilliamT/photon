pragma solidity ^0.8.0;

import {ILens} from "@morpho-dao/morpho-core-v1/contracts/aave-v2/interfaces/ILens.sol";
import {IMorpho} from "@morpho-dao/morpho-core-v1/contracts/aave-v2/interfaces/IMorpho.sol";

import "@morpho-dao/morpho-core-v1/contracts/aave-v2/libraries/Types.sol";

/// @title Morpho Aave Library
/// @author Hilliam
/// @notice Library to abstract usage of Morpho Aave contract functions
library MorphoAave {
    /*//////////////////////////////////////////////////////////////
                                LENDING
    //////////////////////////////////////////////////////////////*/

    /// @notice Supply the amount of the underlying asset into Morpho
    /// @dev https://developers.morpho.xyz/get-started/interact-with-morpho/supply
    /// @param _morphoContract Morpho contract.
    /// @param _poolCollateralTokenAddress aToken address e.g aWETH. Aave pool to deposit into.
    /// @param _amount Amount of the underlying asset e.g WETH to supply.
    function supply(
        address _morphoContract,
        address _poolCollateralTokenAddress,
        uint256 _amount
    ) public {
        IMorpho(_morphoContract).supply(
            _poolCollateralTokenAddress,
            address(this),
            _amount
        );
    }

    /// @notice Withdraw amount of the underlying asset
    /// @dev https://developers.morpho.xyz/get-started/interact-with-morpho/withdraw
    /// @param _morphoContract Morpho contract.
    /// @param _poolCollateralTokenAddress aToken address e.g aWETH. Aave pool to withdraw from.
    /// @param _amount Amount of the underlying asset e.g WETH to withdraw.
    function withdraw(
        address _morphoContract,
        address _poolCollateralTokenAddress,
        uint256 _amount
    ) public {
        IMorpho(_morphoContract).withdraw(_poolCollateralTokenAddress, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                               BORROWING
    //////////////////////////////////////////////////////////////*/

    /// @notice Borrows amount of the underlying asset against deposited collateral
    /// @dev https://developers.morpho.xyz/get-started/interact-with-morpho/borrow
    /// @param _morphoContract Morpho contract.
    /// @param _poolDebtTokenAddress aToken address e.g aWETH. Aave pool to borrow against.
    /// @param _amount Amount to borrow.
    function borrow(
        address _morphoContract,
        address _poolDebtTokenAddress,
        uint256 _amount
    ) public {
        IMorpho(_morphoContract).borrow(_poolDebtTokenAddress, _amount);
    }

    /// @notice Repays debt amount of the asset
    /// @dev https://developers.morpho.xyz/get-started/interact-with-morpho/repay
    /// @param _morphoContract Morpho contract.
    /// @param _poolDebtTokenAddress aToken address e.g aWETH. Aave pool to repay.
    /// @param _amount Amount to repay.
    function repay(
        address _morphoContract,
        address _poolDebtTokenAddress,
        uint256 _amount
    ) public {
        IMorpho(_morphoContract).repay(
            _poolDebtTokenAddress,
            address(this),
            _amount
        );
    }

    /*//////////////////////////////////////////////////////////////
                                  QOL
    //////////////////////////////////////////////////////////////*/

    function claimRewards(address _morphoContract, address[] memory) public {
        revert("Aave does not have any rewards.");
    }

    /*//////////////////////////////////////////////////////////////
                                  VIEW
    //////////////////////////////////////////////////////////////*/

    // https://github.com/morpho-dao/morpho-core-v1/blob/main/contracts/compound/lens/UsersLens.sol#L151
    function getUserBalanceStates(address _morphoLensContract)
        public
        view
        returns (
            uint256 collateralValue,
            uint256 debtValue,
            uint256 liquidationThreshold
        )
    {
        Types.LiquidityData memory balance = ILens(_morphoLensContract)
            .getUserBalanceStates(address(this));
        return (balance.collateral, balance.debt, balance.liquidationThreshold);
    }

    function getCollateralBalance(
        address _morphoLensContract,
        address _poolCollateralTokenAddress
    ) public returns (uint256 totalBalance) {
        (, , totalBalance) = ILens(_morphoLensContract)
            .getCurrentSupplyBalanceInOf(
                _poolCollateralTokenAddress,
                address(this)
            );
    }

    function getDebtBalance(
        address _morphoLensContract,
        address _poolDebtTokenAddress
    ) public returns (uint256 totalBalance) {
        (, , totalBalance) = ILens(_morphoLensContract)
            .getCurrentBorrowBalanceInOf(_poolDebtTokenAddress, address(this));
    }

    function getFundingRatePerYear(
        address _morphoLensContract,
        address _poolDebtTokenAddress,
        address _poolCollateralTokenAddress
    ) public returns (int256) {
        uint256 usersBorrowRatePerYear = ILens(_morphoLensContract)
            .getCurrentUserBorrowRatePerYear(
                _poolDebtTokenAddress,
                address(this)
            );

        uint256 usersSupplyRatePerYear = ILens(_morphoLensContract)
            .getCurrentUserSupplyRatePerYear(
                _poolCollateralTokenAddress,
                address(this)
            );

        int256 usersFundingRatePerYear = int256(usersSupplyRatePerYear) -
            int256(usersBorrowRatePerYear);

        if (usersFundingRatePerYear != 0) {
            return usersFundingRatePerYear;
        }

        (uint256 avgBorrowRatePerBlock, , ) = ILens(_morphoLensContract)
            .getAverageBorrowRatePerYear(_poolDebtTokenAddress);

        (uint256 avgSupplyRatePerBlock, , ) = ILens(_morphoLensContract)
            .getAverageSupplyRatePerYear(_poolCollateralTokenAddress);

        return int256(avgSupplyRatePerBlock) - int256(avgBorrowRatePerBlock);
    }

    function getHealthFactor(address _morphoLensContract)
        public
        returns (uint256)
    {
        return ILens(_morphoLensContract).getUserHealthFactor(address(this));
    }

    function loanToValueRatio(address _morphoLensContract)
        public
        returns (uint256)
    {
        (uint256 collateralValue, uint256 debtValue, ) = getUserBalanceStates(
            _morphoLensContract
        );

        return (debtValue * 100) / collateralValue;
    }

    function currentLiquidationThreshold(address _morphoLensContract)
        public
        returns (uint256 threshold)
    {
        (, , threshold) = getUserBalanceStates(_morphoLensContract);
    }
}
