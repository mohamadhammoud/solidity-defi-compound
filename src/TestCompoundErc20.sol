// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ICompound.sol";

/// @title CompoundSupplyManager Contract
/// @notice This contract allows users to supply ERC20 tokens to the Compound protocol and receive cTokens in return.
/// @dev The contract interacts with a specific ERC20 token and its corresponding cToken on the Compound protocol.
contract CompoundSupplyManager {
    /// @notice The underlying ERC20 token that will be supplied to the Compound protocol
    ERC20 public token;

    /// @notice The cToken representing the supplied ERC20 token on the Compound protocol
    CErc20 public cToken;

    /// @dev Error to indicate that minting cTokens failed
    error MintFailed();

    /// @dev Error to indicate that redeeming cTokens failed
    error RedeemFailed();

    /// @notice Constructor to initialize the contract with the ERC20 token and corresponding cToken addresses
    /// @param _token The address of the ERC20 token that will be supplied (e.g., DAI)
    /// @param _cToken The address of the corresponding cToken on the Compound protocol (e.g., cDAI)
    constructor(address _token, address _cToken) {
        token = ERC20(_token);
        cToken = CErc20(_cToken);
    }

    /// @notice Supply a specified amount of the ERC20 token to the Compound protocol
    /// @dev Transfers the specified amount of tokens from the user, approves the cToken contract to spend the tokens, and mints cTokens
    /// @param _amount The amount of the ERC20 token to supply (in the smallest unit, considering decimals)
    /// @return The result of the mint operation (0 indicates success)
    /// @custom:error MintFailed Reverts if the minting of cTokens fails (i.e., if the result is not 0)
    function supply(uint256 _amount) external returns (uint256) {
        // Transfer the specified amount of tokens from the user to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        // Approve the cToken contract to spend the tokens
        token.approve(address(cToken), _amount);

        // Mint cTokens by supplying the ERC20 token to the Compound protocol
        uint256 mintResult = cToken.mint(_amount);

        // Revert the transaction if minting failed
        if (mintResult != 0) {
            revert MintFailed();
        }

        // Return the result of the mint operation (0 indicates success)
        return mintResult;
    }

    /// @notice Get the current balance of cTokens held by this contract
    /// @dev This function returns the cToken balance for the contract's address
    /// @return The number of cTokens held by this contract
    function getCTokenBalance() external view returns (uint) {
        return cToken.balanceOf(address(this));
    }

    /// @notice Retrieve the current exchange rate and supply rate per block from the Compound protocol
    /// @dev This function calls the `exchangeRateCurrent` and `supplyRatePerBlock` functions on the cToken to get the latest values
    /// @return exchangeRate The current exchange rate between the cToken and the underlying asset, scaled by 1e18
    /// @return supplyRatePerBlock The current supply interest rate per block, scaled by 1e18
    function getInfo()
        external
        returns (uint256 exchangeRate, uint256 supplyRatePerBlock)
    {
        // Get the latest exchange rate from the cToken
        exchangeRate = cToken.exchangeRateCurrent();

        // Get the current supply rate per block from the cToken
        supplyRatePerBlock = cToken.supplyRatePerBlock();
    }

    /// @notice Estimate the current balance of the underlying asset held by this contract in terms of the ERC20 token
    /// @dev This function calculates the underlying asset balance by multiplying the cToken balance by the current exchange rate and adjusting for token decimals
    /// @return The estimated balance of the underlying asset in the smallest unit of the ERC20 token (e.g., if the token is DAI, this would be in wei)
    function estimateBalanceOfUnderlying() external returns (uint256) {
        // Get the cToken balance of this contract
        uint256 cTokenbalance = cToken.balanceOf(address(this));

        // Get the current exchange rate from cToken to the underlying asset
        uint256 exchangeRate = cToken.exchangeRateCurrent();

        // cToken typically has 8 decimals
        uint256 cTokenDecimals = 8;

        // Calculate and return the balance of the underlying asset, adjusting for decimals
        return
            (cTokenbalance * exchangeRate) /
            10 ** (18 + token.decimals() - cTokenDecimals);
    }

    function redeem(uint _amount) external returns (uint) {
        uint256 redeemResult = cToken.redeem(_amount);

        // Revert the transaction if redeeming failed
        if (redeemResult != 0) {
            revert RedeemFailed();
        }

        // Return the result of the mint operation (0 indicates success)
        return redeemResult;
    }
}
