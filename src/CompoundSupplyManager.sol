// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/interfaces/ICErc20.sol";
import "src/interfaces/IComptroller.sol";

/// @title CompoundSupplyManager Contract
/// @notice This contract allows users to supply ERC20 tokens to the Compound protocol, borrow against collateral, and manage their cToken balances.
/// @dev The contract interacts with a specific ERC20 token and its corresponding cToken on the Compound protocol.
contract CompoundSupplyManager {
    /// @notice The underlying ERC20 token that will be supplied to the Compound protocol
    ERC20 public token;

    /// @notice The cToken representing the supplied ERC20 token on the Compound protocol
    ICErc20 public cToken;

    /// @dev Error to indicate that minting cTokens failed
    error MintFailed();

    /// @dev Error to indicate that redeeming cTokens failed
    error RedeemFailed();

    /// @notice Constructor to initialize the contract with the ERC20 token and corresponding cToken addresses
    /// @param _token The address of the ERC20 token that will be supplied (e.g., DAI)
    /// @param _cToken The address of the corresponding cToken on the Compound protocol (e.g., cDAI)
    constructor(address _token, address _cToken) {
        token = ERC20(_token);
        cToken = ICErc20(_cToken);
    }

    /// @notice Supply a specified amount of the ERC20 token to the Compound protocol
    /// @dev Transfers the specified amount of tokens from the user, approves the cToken contract to spend the tokens, and mints cTokens
    /// @param _amount The amount of the ERC20 token to supply (in the smallest unit, considering decimals)
    /// @return The result of the mint operation (0 indicates success)
    /// @custom:error MintFailed Reverts if the minting of cTokens fails (i.e., if the result is not 0)
    /// @example supply(1000 * 10**18); // Supply 1000 DAI (DAI has 18 decimals)
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
    /// @example getCTokenBalance(); // Returns the balance of cTokens held by this contract
    function getCTokenBalance() external view returns (uint) {
        return cToken.balanceOf(address(this));
    }

    /// @notice Retrieve the current exchange rate and supply rate per block from the Compound protocol
    /// @dev This function calls the `exchangeRateCurrent` and `supplyRatePerBlock` functions on the cToken to get the latest values
    /// @return exchangeRate The current exchange rate between the cToken and the underlying asset, scaled by 1e18
    /// @return supplyRatePerBlock The current supply interest rate per block, scaled by 1e18
    /// @example (uint exchangeRate, uint supplyRate) = getInfo(); // Returns the current exchange rate and supply rate per block
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
    /// @example estimateBalanceOfUnderlying(); // Returns the estimated balance of the underlying asset
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

    /// @notice Redeem a specified amount of cTokens for the underlying asset
    /// @dev Burns the specified amount of cTokens and transfers the equivalent amount of the underlying asset to the caller
    /// @param _amount The amount of cTokens to redeem (in the smallest unit, considering decimals)
    /// @return The result of the redeem operation (0 indicates success)
    /// @custom:error RedeemFailed Reverts if the redemption of cTokens fails (i.e., if the result is not 0)
    /// @example redeem(100 * 10**8); // Redeem 100 cTokens (assuming cToken has 8 decimals)
    function redeem(uint _amount) external returns (uint) {
        uint256 redeemResult = cToken.redeem(_amount);

        // Revert the transaction if redeeming failed
        if (redeemResult != 0) {
            revert RedeemFailed();
        }

        // Return the result of the redeem operation (0 indicates success)
        return redeemResult;
    }

    /// @notice Get the collateral factor for the specified cToken
    /// @dev Retrieves the collateral factor for the cToken from the Comptroller
    /// @return The collateral factor, scaled by 1e18
    /// @example getCollateralFactor(); // Returns the collateral factor for the cToken
    function getCollateralFactor() external view returns (uint256) {
        (bool isListed, uint collateralFactor, bool isComped) = comptroller
            .markets(cToken);

        return collateralFactor;
    }

    /// @notice Get the account's liquidity and shortfall
    /// @dev Calculates the user's liquidity and shortfall in USD, scaled by 1e18
    /// @return liquidity The user's available liquidity
    /// @return shortfall The user's shortfall (if any)
    /// @example (uint liquidity, uint shortfall) = getAccountLiquidity(); // Returns the liquidity and shortfall for the account
    function getAccountLiquidity()
        external
        view
        returns (uint256 liquidity, uint256 shortfall)
    {
        (uint _error, uint _liquidity, uint _shortfall) = comptroller
            .getAccountLiquidity(address(this));

        require(_error == 0, "Comptroller: error");

        return (liquidity, shortfall);
    }

    /// @notice Get the current price of the underlying asset for the specified cToken
    /// @dev Uses the PriceFeed to fetch the price of the underlying asset in USD, scaled by 1e18
    /// @param _cToken The address of the cToken to fetch the price for
    /// @return The price of the underlying asset in USD, scaled by 1e18
    /// @example getPriceFeed(address cDAI); // Returns the price of the underlying asset for cDAI
    function getPriceFeed(address _cToken) external view returns (uint256) {
        return priceFeed.getUnderlyingPrice(_cToken);
    }

    /// @notice Enter a market and borrow a specified amount of the underlying asset
    /// @dev Enters the supply market for the specified cToken and borrows a percentage of the maximum available amount based on liquidity
    /// @param _cToken The address of the cToken to borrow
    /// @param _decimals The number of decimals of the token to borrow
    /// @example borrow(address cDAI, 18); // Borrow a portion of the maximum available DAI
    function borrow(address _cToken, uint256 _decimals) external {
        address[] memory cTokens = new address[](1);

        cTokens[0] = address(cTokens);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "comptroller.enterMarkets failed");

        (uint256 error, uint256 liquidity, uint256 shortfall) = comptroller
            .getAccountLiquidity(address(this));

        require(error == 0, "error");
        require(shortfall == 0, "shortfall > 0");
        require(liquidity > 0, "liquidity = 0");

        uint256 price = price.getUnderlyingPrice(_cToken);

        uint256 maxBorrow = (liquidity * (10 ** decimals)) / price;
        require(amount > 0, "max borrow = 0");

        uint256 amountToBorrow = (maxBorrow * 50) / 100;
        require(ICErc20(_cToken).borrow(amount) == 0, "borrow failed");
    }

    /// @notice Get the current borrowed balance (including interest) for the specified cToken
    /// @dev Retrieves the current borrow balance for the contract's address
    /// @param _cTokenBorrowed The address of the cToken to check the borrowed balance for
    /// @return The current borrow balance, including interest
    /// @example getBorrowBalance(address cDAI); // Returns the borrowed balance for cDAI
    function getBorrowBalance(
        address _cTokenBorrowed
    ) public returns (uint256) {
        return ICErc20(_cTokenBorrowed).borrowBalanceCurrent(address(this));
    }

    /// @notice Repay a specified amount of the borrowed asset
    /// @dev Approves the cToken contract to spend the specified amount of the underlying asset and repays the debt
    /// @param _tokenBorrowed The address of the underlying token borrowed
    /// @param _cTokenBorrowed The address of the cToken corresponding to the borrowed token
    /// @param _amount The amount of the underlying asset to repay (in the smallest unit, considering decimals)
    /// @example repay(address DAI, address cDAI, 1000 * 10**18); // Repay 1000 DAI (assuming 18 decimals)
    function repay(
        address _tokenBorrowed,
        address _cTokenBorrowed,
        uint256 amount
    ) external {
        ERC20(_tokenBorrowed).approve(_cTokenBorrowed, _amount);
        require(
            ICErc20(_cTokenBorrowed).repayBorrow(_amount) == 0,
            "repay failed"
        );
    }
}
