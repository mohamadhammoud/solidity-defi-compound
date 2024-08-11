// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title PriceFeed Interface for Compound Protocol
/// @notice This interface defines the function required to fetch the price of the underlying asset for a given cToken within the Compound protocol
/// @dev The PriceFeed contract is a crucial component that provides up-to-date pricing information for the assets being used as collateral or borrowed within the Compound protocol
interface PriceFeed {
    /// @notice Get the price of the underlying asset for a specific cToken
    /// @param cToken The address of the cToken whose underlying asset price is being queried
    /// @return The price of the underlying asset, typically scaled by 1e18
    function getUnderlyingPrice(address cToken) external view returns (uint);
}
