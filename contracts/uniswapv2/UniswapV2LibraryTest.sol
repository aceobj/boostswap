// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./libraries/UniswapV2Library.sol";

contract  UniswapV2LibraryTest {
    function pairFor(address factory, address tokenA, address tokenB) public pure returns (address pair) {
        pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }
}