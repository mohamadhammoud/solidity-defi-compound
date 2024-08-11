// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IComptroller Interface for Compound Protocol
/// @notice This interface defines the key functions for interacting with the Comptroller contract in the Compound protocol
/// @dev The Comptroller is the central contract in the Compound protocol responsible for managing market operations, including entering markets, managing liquidity, and handling liquidations
interface IComptroller {
    /// @notice Get information about a specific market within the Compound protocol
    /// @param cTokenAddress The address of the cToken market to query
    /// @return isListed Whether the market is listed in the Compound protocol
    /// @return collateralFactorMantissa The collateral factor for this market, scaled by 1e18
    /// @return isComped Whether the market is included in COMP distribution
    function markets(
        address cTokenAddress
    )
        external
        view
        returns (bool isListed, uint collateralFactorMantissa, bool isComped);

    /// @notice Enter one or more markets to enable the use of the corresponding assets as collateral
    /// @param cTokens An array of cToken addresses to enter into as collateral markets
    /// @return An array of results indicating success (0) or failure (non-zero error codes) for each market entered
    function enterMarkets(
        address[] calldata cTokens
    ) external returns (uint[] memory);

    /// @notice Get the current liquidity status of an account
    /// @param account The address of the account to query
    /// @return err An error code (0 indicates success)
    /// @return liquidity The excess liquidity of the account, scaled by 1e18
    /// @return shortfall The shortfall of the account (if any), scaled by 1e18
    function getAccountLiquidity(
        address account
    ) external view returns (uint err, uint liquidity, uint shortfall);

    /// @notice Get the current close factor used in liquidation calculations
    /// @return The close factor, scaled by 1e18, representing the maximum portion of a borrow that can be repaid in a single liquidation
    function closeFactorMantissa() external view returns (uint);

    /// @notice Get the current liquidation incentive used in liquidation calculations
    /// @return The liquidation incentive, scaled by 1e18, which represents the additional collateral that liquidators receive as a bonus
    function liquidationIncentiveMantissa() external view returns (uint);

    /// @notice Calculate the number of cTokens to seize in the event of a liquidation
    /// @param cTokenBorrowed The address of the borrowed cToken
    /// @param cTokenCollateral The address of the collateral cToken
    /// @param actualRepayAmount The actual amount of the underlying borrowed asset being repaid
    /// @return seizeTokens The number of cTokens that can be seized as collateral
    /// @return err An error code (0 indicates success)
    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint actualRepayAmount
    ) external view returns (uint seizeTokens, uint err);
}
