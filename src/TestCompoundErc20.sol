// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICompound.sol";

/// @title TestCompoundErc20 Contract
/// @notice This contract allows users to supply ERC20 tokens to the Compound protocol and receive cTokens in return.
/// @dev The contract interacts with a specific ERC20 token and its corresponding cToken on the Compound protocol.
contract TestCompoundErc20 {
    /// @notice The underlying ERC20 token that will be supplied to the Compound protocol
    IERC20 public token;

    /// @notice The cToken representing the supplied ERC20 token on the Compound protocol
    CErc20 public cToken;

    /// @dev Error to indicate that minting cTokens failed
    error MintFailed();

    /// @notice Constructor to initialize the contract with the ERC20 token and corresponding cToken addresses
    /// @param _token The address of the ERC20 token that will be supplied (e.g., DAI)
    /// @param _cToken The address of the corresponding cToken on the Compound protocol (e.g., cDAI)
    constructor(address _token, address _cToken) {
        token = IERC20(_token);
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
}
