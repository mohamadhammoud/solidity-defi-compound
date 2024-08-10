// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CErc20 Interface for Compound Protocol
/// @dev This interface provides the main functions for interacting with Compound's CErc20 tokens.

interface CErc20 {
    /// @notice Get the current balance of a specified address's CErc20 tokens
    /// @param account The address to get the balance of
    /// @return The number of CErc20 tokens held by the address
    function balanceOf(address account) external view returns (uint);

    /// @notice Mint new CErc20 tokens by supplying underlying tokens to the protocol
    /// @param amount The amount of underlying tokens to supply
    /// @return The result of the mint operation (0 for success, error code otherwise)
    function mint(uint amount) external returns (uint);

    /// @notice Get the current exchange rate between CErc20 tokens and underlying tokens
    /// @return The current exchange rate scaled by 1e18
    function exchangeRateCurrent() external returns (uint);

    /// @notice Get the current supply interest rate per block
    /// @return The current supply interest rate per block, scaled by 1e18
    function supplyRatePerBlock() external returns (uint);

    /// @notice Get the underlying balance of an address, considering the current exchange rate
    /// @param account The address to get the underlying balance of
    /// @return The underlying balance of the address
    function balanceOfUnderlying(address account) external returns (uint);

    /// @notice Redeem a specified amount of CErc20 tokens in exchange for the underlying asset
    /// @param amount The amount of CErc20 tokens to redeem
    /// @return The result of the redeem operation (0 for success, error code otherwise)
    function redeem(uint amount) external returns (uint);

    /// @notice Redeem a specified amount of underlying tokens by burning CErc20 tokens
    /// @param amount The amount of underlying tokens to redeem
    /// @return The result of the redeem operation (0 for success, error code otherwise)
    function redeemUnderlying(uint amount) external returns (uint);

    /// @notice Borrow a specified amount of underlying tokens from the protocol
    /// @param amount The amount of underlying tokens to borrow
    /// @return The result of the borrow operation (0 for success, error code otherwise)
    function borrow(uint amount) external returns (uint);

    /// @notice Get the current borrow balance of an address, including interest
    /// @param account The address to get the borrow balance of
    /// @return The current borrow balance of the address
    function borrowBalanceCurrent(address account) external returns (uint);

    /// @notice Get the current borrow interest rate per block
    /// @return The current borrow interest rate per block, scaled by 1e18
    function borrowRatePerBlock() external view returns (uint);

    /// @notice Repay a specified amount of the borrowed underlying tokens
    /// @param amount The amount of underlying tokens to repay
    /// @return The result of the repay operation (0 for success, error code otherwise)
    function repayBorrow(uint amount) external returns (uint);

    /// @notice Liquidate a borrower's collateral when they are undercollateralized
    /// @param borrower The address of the borrower to liquidate
    /// @param amount The amount of the borrower's debt to repay
    /// @param collateral The address of the asset to seize as collateral
    /// @return The result of the liquidation operation (0 for success, error code otherwise)
    function liquidateBorrow(
        address borrower,
        uint amount,
        address collateral
    ) external returns (uint);
}
