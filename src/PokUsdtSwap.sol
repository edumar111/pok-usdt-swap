// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title POK↔USDT 1:1 Swap (Ambos con 6 decimales)
/// @notice Permite comprar/vender POK con USDT al tipo 1:1 (6 decimales)
/// @dev Usa OpenZeppelin y está protegido contra reentradas. Fee opcional en basis points.

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

    // fee en basis points (100 bps = 1%). Por defecto 0.
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

    // ------- Admin -------
    function setFee(uint16 _feeBps, address _receiver) external onlyOwner {
        if (_feeBps > 10_000) revert InvalidFee(); // máx 100%
        if (_receiver == address(0)) revert ZeroAddress();
        feeBps = _feeBps;
        feeReceiver = _receiver;
        emit FeeUpdated(_feeBps, _receiver);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /// @notice Rescata tokens atascados o excedentes del contrato.
    function rescue(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit Rescue(token, amount, to);
    }

    
    // ------- User flows -------
    /// @notice Comprar POK entregando USDT (1:1)
    function buyPok(uint256 usdtAmount, address to) external nonReentrant whenNotPaused {
        if (usdtAmount == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();
        // validar que haya fondos suficientes de ether del _msgSender();
        require(USDT_TOKEN.balanceOf(address(msg.sender) ) >= usdtAmount, "Fondos ETH insuficientes");
        
        USDT_TOKEN.safeTransferFrom(msg.sender, address(this), usdtAmount);

        (uint256 fee, uint256 pokNet) = _takeFee(usdtAmount);

        if (POK_TOKEN.balanceOf(address(this)) < pokNet) revert InsufficientLiquidity();

        if (fee > 0) POK_TOKEN.safeTransfer(feeReceiver, fee);
        POK_TOKEN.safeTransfer(to, pokNet);

        emit BoughtPOK(msg.sender, to, usdtAmount, pokNet, fee);
    }

    /// @notice Vender POK para recibir USDT (1:1)
    function sellPok(uint256 pokAmount, address to) external nonReentrant whenNotPaused {
        if (pokAmount == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();

        POK_TOKEN.safeTransferFrom(msg.sender, address(this), pokAmount);

        (uint256 fee, uint256 usdtNet) = _takeFee(pokAmount);

        if (USDT_TOKEN.balanceOf(address(this)) < usdtNet) revert InsufficientLiquidity();

        if (fee > 0) USDT_TOKEN.safeTransfer(feeReceiver, fee);
        USDT_TOKEN.safeTransfer(to, usdtNet);

        emit SoldPOK(msg.sender, to, pokAmount, usdtNet, fee);
    }

    // ------- Views -------
    function previewBuyPok(uint256 usdtAmount) external view returns (uint256 pokNet, uint256 feePok) {
        (feePok, pokNet) = _takeFee(usdtAmount);
    }

    function previewSellPok(uint256 pokAmount) external view returns (uint256 usdtNet, uint256 feeUsdt) {
        (feeUsdt, usdtNet) = _takeFee(pokAmount);
    }

    // ------- Fee utils -------
    function _takeFee(uint256 amount) internal view returns (uint256 fee, uint256 net) {
        if (feeBps == 0) return (0, amount);
        fee = (amount * feeBps) / 10_000;
        net = amount - fee;
    }

}
