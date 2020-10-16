// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./uniswapv2/libraries/SafeMath.sol";
import "./uniswapv2/interfaces/IERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";
import "./uniswapv2/interfaces/IWETH.sol";

//
contract BosMaker {
    using SafeMath for uint256;

    IUniswapV2Factory public factory;
    address public bar;
    address public bos;
    address public weth;

    constructor(IUniswapV2Factory _factory, address _bar, address _bos, address _weth) public {
        factory = _factory;
        bos = _bos;
        bar = _bar;
        weth = _weth;
    }

    // anyone can call this function?
    // 1) withdraw liquidity provision from [token0, token1] pool to BosMaker
    // 2) exchange token0 for eth from [token0, eth] pool, eth is deposited into [eth,bos] pool
    //    exchange token1 for eth from [token1, eht] pool, eth is deposited into [eth, bos] pool
    // 3) bos swapped out by depositing eth into [eth, bos] pool at step 2) is sent to BosBar
    function convert(address token0, address token1) public {
        // At least we try to make front-running harder to do.
        require(msg.sender == tx.origin, "do not convert from contract"); // make sure this function is not called from other contract
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        pair.transfer(address(pair), pair.balanceOf(address(this))); // transfer LP tokens from this contract(BosMaker) to the pool itself
        pair.burn(address(this)); // withdraw tokens from pool to this contract(BosMaker)
        uint256 wethAmount = _toWETH(token0) + _toWETH(token1);
        _toBOS(wethAmount); // swap ETH for Bos from [eth, bos] pool, swapped bos is transferred to BosBar
    }

    // convert token to ETH, and put into [bos, eth] pool
    function _toWETH(address token) internal returns (uint256) {
        if (token == bos) {
            uint256 amount = IERC20(token).balanceOf(address(this)); // amount of bos owned by this contract
            // _safeTransfer(token, bar, amount); // transfer amount BOSs to BosBar
            IERC20(token).transfer(bar, amount);
            return 0;
        }
        if (token == weth) {
            uint256 amount = IERC20(token).balanceOf(address(this)); // amount of WETHs owned by this contract
            // _safeTransfer(token, factory.getPair(weth, bos), amount); // transfer amount ETHs to [bos, weth] pool
            IERC20(token).transfer(factory.getPair(weth, bos), amount);
            return amount;
        }
        // token is neither bos nor eth
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, weth)); // get [token, eth] pool
        if (address(pair) == address(0)) {
            return 0;
        }
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint256 reserveIn, uint256 reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        // reserveIn:  reserve0 if token == token0 else reserve1, balance of token in [token, eth] pool
        // reserveOut: reserve1 if token == token0 else reserve0, balance of ETH in [token, eth] pool

        uint256 amountIn = IERC20(token).balanceOf(address(this)); // amount of tokens owned by this contract
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint256 amountOut = numerator / denominator; // amount of ETH obtained
        (uint256 amount0Out, uint256 amount1Out) = token0 == token ? (uint256(0), amountOut) : (amountOut, uint256(0));
        // amount0Out: 0              if token == token0 else amountOut(ETH)
        // amount1Out: amountOut(ETH) if token == token0 else 0

        // _safeTransfer(token, address(pair), amountIn); // transfer amountIn tokens to [token, eth] pool
        IERC20(token).transfer(address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, factory.getPair(weth, bos), new bytes(0)); // withdraw ETH from [token, eth] pool to [bos, eth] pool
        return amountOut;
    }

    // amountIn: amount of ETHs
    function _toBOS(uint256 amountIn) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(weth, bos));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint256 reserveIn, uint256 reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint256 amountOut = numerator / denominator; // amount of BOSs
        (uint256 amount0Out, uint256 amount1Out) = token0 == weth ? (uint256(0), amountOut) : (amountOut, uint256(0));

        pair.swap(amount0Out, amount1Out, bar, new bytes(0)); // deposit ETH, withdraw BOS, and transfer BOS to BosBar
    }

    /*function _safeTransfer(address token, address to, uint256 amount) internal {
        IERC20(token).transfer(to, amount);
    }*/
}
