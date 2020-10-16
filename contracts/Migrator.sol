// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";

contract Migrator {
    address public chef;
    address public oldFactory;
    IUniswapV2Factory public factory;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address _chef,
        address _oldFactory,
        IUniswapV2Factory _factory,
        uint256 _notBeforeBlock
    ) public {
        chef = _chef;
        oldFactory = _oldFactory;
        factory = _factory;
        notBeforeBlock = _notBeforeBlock;
    }

    // user stake pool tokens to get bos
    // migrate liquidity(pair of tokens) from uniswap pool to bos pool
    function migrate(IUniswapV2Pair orig) public returns (IUniswapV2Pair) {
        require(msg.sender == chef, "not from master chef");
        require(block.number >= notBeforeBlock, "too early to migrate");
        require(orig.factory() == oldFactory, "not from old factory");
        address token0 = orig.token0();
        address token1 = orig.token1();
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        if (pair == IUniswapV2Pair(address(0))) {
            pair = IUniswapV2Pair(factory.createPair(token0, token1));
        }
        // balance of liquidity in orig pool owned by MasterChef(MasterChef might have been deposit tokens to original pool)
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        // return liquidity owned by MasterChef to original pool, assuming liquidity balance of orig pool is zero, if someone transfer liquidity to
        // this pool, extra tokens will be withdrawn, it's a happy thing
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));       // transfer pair of tokens in original pool to new pool, orig.balanceOf(orig) >= liquidity
        pair.mint(msg.sender);          // mint liquidity in new pool to masterChef
        desiredLiquidity = uint256(-1);
        return pair;
    }
}