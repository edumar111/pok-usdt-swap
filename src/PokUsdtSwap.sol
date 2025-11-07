// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title POK↔USDT 1:1 Swap (Both with 6 decimals)
/// @notice Allows buying/selling POK with USDT at a 1:1 rate (6 decimals)
/// @dev Uses OpenZeppelin and is protected against reentrancy. Optional fee in basis points.

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol"; 
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Pausable} from "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract PokUsdtSwap is Ownable2Step, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDT_TOKEN;
    IERC20 public immutable POK_TOKEN;

    // fee en basis points (100 bps = 1%). default 0.
    uint16 public feeBps;
    address public feeReceiver;

    event BoughtPOK(address indexed buyer, address indexed to, uint256 usdtIn, uint256 pokOut, uint256 feePok);
    event SoldPOK(address indexed seller, address indexed to, uint256 pokIn, uint256 usdtOut, uint256 feeUsdt);
    event FeeUpdated(uint16 feeBps, address feeReceiver);
    event Rescue(address token, uint256 amount, address to);

    error ZeroAddress();
    error InsufficientLiquidity();
    error InvalidFee();
    error ZeroAmount();

    constructor(address _usdt, address _pok, address _owner)  Ownable(_owner) {
        if (_usdt == address(0) || _pok == address(0) || _owner == address(0)) revert ZeroAddress();
        USDT_TOKEN = IERC20(_usdt);
        POK_TOKEN = IERC20(_pok);
        feeReceiver = _owner;
       
    }

    /**
    * @dev Sets the fee and fee receiver address.
    * @param _feeBps The fee in basis points (max 10,000).
    * @param _receiver The address that will receive the fees.
    */
    function setFee(uint16 _feeBps, address _receiver) external onlyOwner {
        if (_feeBps > 10_000) revert InvalidFee(); // máx 100%
        if (_receiver == address(0)) revert ZeroAddress();
        feeBps = _feeBps;
        feeReceiver = _receiver;
        emit FeeUpdated(_feeBps, _receiver);
    }

    /// @notice Pauses or unpauses the buy/sell functions.
    function pause() external onlyOwner { _pause(); }

    /// @notice Unpauses the buy/sell functions.
    function unpause() external onlyOwner { _unpause(); }

    /** 
    * @notice Rescues stuck or excess tokens from the contract.
    * @param token The address of the token to rescue.
    * @param amount The amount of tokens to rescue.
    * @param to The address to send the rescued tokens to.
    */
    function rescue(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit Rescue(token, amount, to);
    }



    /** 
    * @notice buy POK with USDT (1:1) 
    * @param usdtAmount The amount of USDT to spend.
    * @param to The address to receive the POK tokens.  
    */
    function buyPok(uint256 usdtAmount, address to) external nonReentrant whenNotPaused {
        if (usdtAmount == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();
        // validate that the msg.sender has enough USDT balance
        require(USDT_TOKEN.balanceOf(address(msg.sender) ) >= usdtAmount, "Fondos USDT insuficientes");

        USDT_TOKEN.safeTransferFrom(msg.sender, address(this), usdtAmount);

        (uint256 fee, uint256 pokNet) = _takeFee(usdtAmount);

        if (POK_TOKEN.balanceOf(address(this)) < pokNet) revert InsufficientLiquidity();

        if (fee > 0) POK_TOKEN.safeTransfer(feeReceiver, fee);
        POK_TOKEN.safeTransfer(to, pokNet);

        emit BoughtPOK(msg.sender, to, usdtAmount, pokNet, fee);
    }

    /**
    * @notice sell POK to receive USDT (1:1)
    * @param pokAmount The amount of POK to sell.
    * @param to The address to receive the USDT tokens.
    */
    function sellPok(uint256 pokAmount, address to) external nonReentrant whenNotPaused {
        if (pokAmount == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();
        
        require(POK_TOKEN.balanceOf(address(msg.sender) ) >= pokAmount, "Fondos POK insuficientes");

        POK_TOKEN.safeTransferFrom(msg.sender, address(this), pokAmount);

        (uint256 fee, uint256 usdtNet) = _takeFee(pokAmount);

        if (USDT_TOKEN.balanceOf(address(this)) < usdtNet) revert InsufficientLiquidity();

        if (fee > 0) USDT_TOKEN.safeTransfer(feeReceiver, fee);
        USDT_TOKEN.safeTransfer(to, usdtNet);

        emit SoldPOK(msg.sender, to, pokAmount, usdtNet, fee);
    }

    // ------- Views -------
    /** 
    * @notice Preview the amount of POK received when buying with USDT.
    * @param usdtAmount The amount of USDT to spend.
    * @return pokNet The amount of POK received.
    * @return feePok The fee applied to the transaction.
    */
    function previewBuyPok(uint256 usdtAmount) external view returns (uint256 pokNet, uint256 feePok) {
        (feePok, pokNet) = _takeFee(usdtAmount);
    }

    /** 
    * @notice Preview the amount of USDT received when selling POK.
    * @param pokAmount The amount of POK to sell.
    * @return usdtNet The amount of USDT received.
    * @return feeUsdt The fee applied to the transaction.
    */
    function previewSellPok(uint256 pokAmount) external view returns (uint256 usdtNet, uint256 feeUsdt) {
        (feeUsdt, usdtNet) = _takeFee(pokAmount);
    }

    // ------- Fee utils -------
    /**
    * @notice Calculates the fee and neto amount after applying the fee.
    * @param amount The total amount before fee.
    * @return fee The calculated fee.
    * @return net The neto amount after fee.
    */
    function _takeFee(uint256 amount) internal view returns (uint256 fee, uint256 net) {
        if (feeBps == 0) return (0, amount);
        fee = (amount * feeBps) / 10_000;
        net = amount - fee;
    }

}
