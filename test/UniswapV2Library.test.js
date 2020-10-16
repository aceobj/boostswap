const { expectRevert, time } = require('@openzeppelin/test-helpers');
const MockERC20 = artifacts.require('MockERC20');
const UniswapV2Pair = artifacts.require('UniswapV2Pair');
const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const UniswapV2LibraryTest = artifacts.require('UniswapV2LibraryTest');

contract('UniswapV2LibraryTest', ([alice, minter]) => {
    beforeEach(async () => {
        this.factory = await UniswapV2Factory.new(alice, { from: alice });
        this.factory2 = await UniswapV2Factory.new(minter, { from: minter });
        this.libraryTest = await UniswapV2LibraryTest.new({ from: alice });
        this.token1 = await MockERC20.new('TOKEN1', 'TOKEN', '100000000', { from: minter });
        this.token2 = await MockERC20.new('TOKEN2', 'TOKEN2', '100000000', { from: minter });
        // this.token1Token2 = await UniswapV2Pair.at((await this.factory.createPair(this.token1.address, this.token2.address)).logs[0].args.pair);
    });

    it('should return correct UniswapV2Pair address', async () => {
        // const pair = await this.libraryTest.pairFor(this.factory.address, this.token1.address, this.token2.address);
        const pair = await this.factory.createPair(this.token1.address, this.token2.address);
        // console.log(pair);
        const token1Token2 = await UniswapV2Pair.at(pair.logs[0].args.pair);
        console.log('pair address:', token1Token2.address);
        const p2 = await this.libraryTest.pairFor(this.factory.address, this.token1.address, this.token2.address);
        assert.equal(token1Token2.address, p2);
        console.log('factory  addr:', this.factory.address);
        console.log('factory2 addr:', this.factory2.address);
    });
});
