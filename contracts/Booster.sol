// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./uniswapv2/libraries/SafeMath.sol";
import "./uniswapv2/access/Ownable.sol";
import "./uniswapv2/interfaces/IERC20.sol";

interface IMigrator {
    function migrate(IERC20 token) external returns (IERC20);
}

contract Booster is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accBosPerShare;
    }

    address public bos;
    address public devaddr;
    uint256 public bonusEndBlock;
    uint256 public rewardPerBlock;
    uint256 public constant BONUS_MULTIPLIER = 10;
    uint256 public constant HALF_BLOCKS = 400000;
    IMigrator public migrator;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _bos,
        address _devaddr,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        bos = _bos;
        devaddr = _devaddr;
        rewardPerBlock = _rewardPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBosPerShare: 0
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setMigrator(IMigrator _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        IERC20(bos).setMaxSupply(_maxSupply);
    }

    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.approve(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    function computeRewards(uint256 _from, uint256 _to, uint256 _points) internal view returns (uint256) {
        uint256 afterFrom = bonusEndBlock + (_from + HALF_BLOCKS - bonusEndBlock) / HALF_BLOCKS * HALF_BLOCKS;
        uint256 beforeTo = bonusEndBlock + (_to - bonusEndBlock) / HALF_BLOCKS * HALF_BLOCKS;
        uint256 common = rewardPerBlock * _points / totalAllocPoint;
        uint256 x = (afterFrom - bonusEndBlock) / HALF_BLOCKS;
        uint256 rewards = 0;
        uint256 one = 1;

        if (afterFrom > beforeTo) {
            rewards = (_to - _from) * common / (one << (x-1));
        } else {
            uint256 y = (beforeTo - bonusEndBlock) / HALF_BLOCKS;
            rewards = (afterFrom - _from) * common / (one << (x-1));
            rewards += HALF_BLOCKS * common * ((one << (y-x)) - 1) / (one << (y-1));
            rewards += (_to - beforeTo) * common / (one << y);
        }

        return rewards;
    }

    function getReward(uint256 _from, uint256 _to, uint256 _points) public view returns (uint256) {
        uint256 bonusReward = BONUS_MULTIPLIER * rewardPerBlock;
        if (_to <= bonusEndBlock) {
            return (_to - _from) * bonusReward * _points / totalAllocPoint;
        } else if (_from >= bonusEndBlock) { // bonus has ended
            return computeRewards(_from, _to, _points);
        } else {
            return ((bonusEndBlock - _from) * bonusReward * _points / totalAllocPoint).add(
                computeRewards(bonusEndBlock, _to, _points)
            );
        }
    }

    function pendingBosReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBosPerShare = pool.accBosPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)); // balance of LP tokens owned by Booster
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 bosReward = getReward(pool.lastRewardBlock, block.number, pool.allocPoint);
            accBosPerShare = accBosPerShare.add((bosReward - bosReward / 10).mul(1e12) / lpSupply);
        }
        return (user.amount.mul(accBosPerShare) / 1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 bosReward = getReward(pool.lastRewardBlock, block.number, pool.allocPoint);
        uint256 poolReward = bosReward - (bosReward / 10);
        IERC20(bos).mint(devaddr, bosReward - poolReward);
        IERC20(bos).mint(address(this), poolReward);
        // accBosPerShare = accBosPerShare + bosReward * 10^12 / lpSupply
        pool.accBosPerShare = pool.accBosPerShare.add(poolReward.mul(1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBosPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeBosTransfer(msg.sender, pending);
            }
        }

        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBosPerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (user.amount.mul(pool.accBosPerShare) / 1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeBosTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBosPerShare) / 1e12;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeBosTransfer(address _to, uint256 _amount) internal {
        uint256 bosBalance = IERC20(bos).balanceOf(address(this));
        if (_amount > bosBalance) {
            IERC20(bos).transfer(_to, bosBalance);
        } else {
            IERC20(bos).transfer(_to, _amount);
        }
    }

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
