// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BosBar is ERC20("BosBar", "vBOS"){
    using SafeMath for uint256;
    IERC20 public bos;

    constructor(IERC20 _bos) public {
        bos = _bos;
    }

    // Enter the bar. Pay some BOSs. Earn some shares.
    // _amount: BOSs to stake
    function enter(uint256 _amount) public {
        uint256 totalBos = bos.balanceOf(address(this)); // BOSs owned by Bar
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalBos == 0) {
            _mint(msg.sender, _amount); // mint equal amount of xBOS to sender
        } else {
            // what = _amount * totalShares / totalBos
            uint256 what = _amount.mul(totalShares) / totalBos;
            _mint(msg.sender, what);
        }
        // transfer BOSs from sender to Bar
        bos.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your BOSs.
    // _share: xBars to reclaim
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        // what = _share * totalBos / totalShares, bos to reclaim(withdraw)
        uint256 what = _share.mul(bos.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share); // burn xBOS
        bos.transfer(msg.sender, what); // transfer what bos to sender
    }
}