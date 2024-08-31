pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
    function setPrice(address token, uint256 price) external;
}

contract UpsideLending {
    IPriceOracle upsideOracle;
    IERC20 public reserveToken;

    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public borrowBalance;

    constructor(IPriceOracle _upsideOracle, address _reserveToken) {
        upsideOracle = _upsideOracle;
        reserveToken = IERC20(_reserveToken);
    }

    function initializeLendingProtocol(address _reserveToken) external payable {
        reserveToken = IERC20(_reserveToken);
        IERC20(_reserveToken).transferFrom(msg.sender, address(this), msg.value);
    }

    function deposit(address token, uint256 amount) external payable {
        if (token == address(0x0)) {    // Ether
            require(msg.value == amount, "Incorrect Ether amount sent");
            uint256 price = upsideOracle.getPrice(token);
            uint256 reserveTokenAmount = amount * price;
            require(reserveToken.transferFrom(msg.sender, address(this), reserveTokenAmount), "Transfer failed");
        } else {    // ERC20
            uint256 price = upsideOracle.getPrice(token);
            uint256 reserveTokenAmount = (amount * price) / 1e18;
            require(reserveToken.transferFrom(msg.sender, address(this), reserveTokenAmount), "Transfer failed");
        }
    }
    
    function borrow(address token, uint256 amount) external {
    }

    function repay(address token, uint256 amount) external {
    }

    function withdraw(address token, uint256 amount) external {
    }

    function getAccruedSupplyAmount(address token) external view returns (uint256) {
    }

    function liquidate(address borrower, address token, uint256 amount) external {
    }

}
