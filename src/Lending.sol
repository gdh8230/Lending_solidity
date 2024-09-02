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

    //사용자 담보자산
    mapping(address => uint256) public collateralBalance;
    //사용자 대출잔액
    mapping(address => uint256) public borrowBalance;

    constructor(IPriceOracle _upsideOracle, address _reserveToken) {
        upsideOracle = _upsideOracle;
        reserveToken = IERC20(_reserveToken);
    }

    function initializeLendingProtocol(address _reserveToken) external payable {
        reserveToken = IERC20(_reserveToken);
        IERC20(_reserveToken).transferFrom(msg.sender, address(this), msg.value);
    }

    //담보금액을 입금
    function deposit(address token, uint256 amount) external payable {
        if (token == address(0x0)) {    // Ether deposit
            require(msg.value == amount, "Incorrect Ether amount sent");
            uint256 etherPrice = upsideOracle.getPrice(token);
            uint256 reserveTokenAmount = (amount * etherPrice);

            collateralBalance[msg.sender] += reserveTokenAmount;

        } else {    // ERC20 deposit
            uint256 tokenPrice = upsideOracle.getPrice(token);
            uint256 reserveTokenAmount = (amount * tokenPrice) / 1e18;

            require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

            collateralBalance[msg.sender] += reserveTokenAmount;
        }
    }
    
    function borrow(address token, uint256 amount) external {
        uint256 price = upsideOracle.getPrice(token);
        uint256 reserveTokenAmount = (amount * price) / 1e18;
        
        // 예를 들어, 담보 비율이 150%라면 필요한 담보 금액은 대출 금액의 1.5배
        uint256 requiredCollateral = reserveTokenAmount * 150 / 100;

        // 충분한 담보가 있는지 확인
        uint256 collateralValue = collateralBalance[msg.sender];
        require(collateralValue >= requiredCollateral, "Insufficient collateral");

        // 프로토콜에 충분한 자금이 있는지 확인
        uint256 availableLiquidity = reserveToken.balanceOf(address(this));
        require(availableLiquidity >= reserveTokenAmount, "Insufficient liquidity in the pool");

        // borrowBalance에 sender의 대출금액 추가
        borrowBalance[msg.sender] += reserveTokenAmount;

        // 대출 금액을 사용자에게 전송
        require(reserveToken.transfer(msg.sender, reserveTokenAmount), "Transfer failed");
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
