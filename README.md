# The BoostSwap
[BoostSwap](https://boostswap.org) is a fully decentralized protocol for automated liquidity provision based on Ethereum with Yield Farming.
Frequently called methods are optimized so as to spend less gas for usual transactions.


Design
---------------------------------------------
As one of the major DeFi platform, UniSwap has gained huge attention in the community. Different from traditional exchange, there is no order book for each trading pair(pool) in UniSwap. The running of platform is maintained by liquidity providers acting as AMMs(automated market makers) instead.

UniSwap liquidity providers earn 0.3% of trading fees if they stay in pool.
Once leaving the pool by withdrawing staked pair of tokens(their liquidity will be burnt in the meantime), they no longer receive any trading fees. 

Based on UniSwap, SushiSwap adds an incentive mechanism by distributing 10/11 of mined SUSHI tokens to liquidity providers. At early stage the token mined in each block is 10 times that distributed in later blocks. 100,000,000(1/10 of total supply) SUSHI tokens have been mined in the first two weeks for attracting early investors, which is not conductive to long-term development of the project.

We develop a more user-friendly exchange, in which both liquidity providers and general users will benefit from trading tokens.


Schedule
---------------------------------------------
To facilitate users receiving BOS tokens, we designed interface to help users migrating liquidity from UniSwap to BoostSwap.  Once users transferred UniSwap liquidity tokens to booster, they are qualified to receive BOS tokens starting from specified block.

The total supply of BOS tokens is 200,000,000. For the 1st 100000 blocks, 1000 BOS tokens will be minted per block. For the next 400,000 blocks, 100 BOS tokens will be minted per block. For the next 400,000 blocks, 50 BOS tokens will be minted per block, etc.  In a word, the BOS tokens minted per block will be halved the next stage.

| Blocks      |  ~Days      |  ~Acc Days  | Reward per Block |   Total Reward   |    Acc Reward    |
| ----------- | ----------- | ----------- | ---------------- | ---------------- | -----------------|
| 100,000     |    15       |   15        |    1000          |     100,000,000  |   100,000,000    |
| 400,000     |    60       |   75        |    100           |      40,000,000  |   140,000,000    |
| 400,000     |    60       |   135       |    50            |      20,000,000  |   160,000,000    |
| 400,000     |    60       |   195       |    25            |      10,000,000  |   170,000,000    |
| 400,000     |    60       |   255       |    12.5          |      5,000,000   |   175,000,000    |
| 400,000     |    60       |   315       |    6.25          |      2,500,000   |   190,000,000    |
| 400,000     |    60       |   375       |    3.125         |      1,250,000   |   191,250,000    |
| 400,000     |    60       |   435       |    1.5625        |      625,000     |   197,500,000    |
| ...         |    ...      |   ...       |    ...           |      ...         |   ...            |

To maintain the long-term development for BoostSwap, 10% of mined BOS tokens will be distributed to developers.


Bootstrap Pools
---------------------------------------------
Following are several pools available in the beginning for user to migrate their liquidity here for earning BOS rewards:

1. Stable Coins
    - [***0*** USDT - ETH](https://uniswap.info/pair/0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852)
    - [***1*** USDC - ETH](https://uniswap.info/pair/0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc)
    - [***2*** DAI  - ETH](https://uniswap.info/pair/0xa478c2975ab1ea89e8196811f51a7b7ade33eb11)
    - [***3*** sUSD - ETH](https://uniswap.info/pair/0xf80758ab42c3b07da84053fd88804bcb6baa4b5c)

2. Lending Protocols
    - [***4*** COMP - ETH](https://uniswap.info/pair/0xcffdded873554f362ac02f8fb1f02e5ada10516f)
    - [***5*** LEND - ETH](https://uniswap.info/pair/0xab3f9bf1d81ddb224a2014e98b238638824bcf20)

3. Synthetic
    - [***6*** UMA  - ETH](https://uniswap.info/pair/0x88d97d199b9ed37c29d846d00d443de980832a22)
    - [***7*** SNX  - ETH](https://uniswap.info/pair/0x43ae24960e5534731fc831386c07755a2dc33d47)

4. Ponzinomics
    - [***8*** AMPL - ETH](https://uniswap.info/pair/0xc5be99a02c6857f9eac67bbce58df5572498f40c)
    - [***9*** YFI  - ETH](https://uniswap.info/pair/0x2fdbadf3c4d5a8666bc06645b8358ab803996e28)

5. Oracles
    - [***10*** BAND - ETH](https://uniswap.info/pair/0xf421c3f2e695c2d4c0765379ccace8ade4a480d9)
    - [***11*** LINK - ETH](https://uniswap.info/pair/0xa2107fa5b38d9bbd2c461d6edf11b11a50f6b974)

6. cross-chain
    - [***12*** REN  - ETH](https://info.uniswap.org/pair/0x8bd1661da98ebdd3bd080f0be4e6d9be8ce9858c) <!-- - BASE - sUSD  - [SRM  - ETH](https://info.uniswap.org/pair/0xcc3d1ecef1f9fd25599dbea2755019dc09db3c54) - [CRV  - ETH](https://info.uniswap.org/pair/0x3da1313ae46132a397d90d95b1424a9a7e3e0fce) -->

7. Exchange
    - [***13*** UNI  - ETH](https://info.uniswap.org/pair/0xd3d2e2692501a5c9ca623199d38826e513033a17)   
    - [BOS  - ETH]() (**2X** BOS Reward)

The BOS tokens distributed to pool BOS-ETH is **2X** that of other pools listed above.

Staking
---------------------------------------------
As another kind of incentive, a special contract designed to encourage user staking their BOSs for more BOSs. The added value comes from 0.05% of trading fees(represented as mined liquidity).


Migration of liquidity from UniSwap
---------------------------------------------
The UniswapV2 liquidity pool tokens staking stage will last for about 15 days(on 100,000 blocks). During this stage users stake their liquidity tokens to BoostSwap witness in UniSwap.  After staking stage witness will migrate all staked liquidity to pool newly created in BoostSwap. 

After migration with enough liquidity users are able to trade for their favourite tokens in BoostSwap!!!
