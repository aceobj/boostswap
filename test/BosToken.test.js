const { expectRevert } = require('@openzeppelin/test-helpers');
const BosToken = artifacts.require('BosToken');

contract('BosToken', ([alice, bob, carol, account, minter]) => {
    beforeEach(async () => {
        this.bos = await BosToken.new(/*account, 1917820800, */{ from: alice });
    });

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.bos.name();
        const symbol = await this.bos.symbol();
        const decimals = await this.bos.decimals();
        const maxSupply = await this.bos.maxSupply();
        assert.equal(name.valueOf(), 'BoostSwap');
        assert.equal(symbol.valueOf(), 'BOS');
        assert.equal(decimals.valueOf(), '18');
        assert.equal(maxSupply.valueOf(), '200000000000000000000000000')
    });

    it('should only allow owner to mint token', async () => {
        await this.bos.mint(alice, '100', { from: alice });
        await this.bos.mint(bob, '1000', { from: alice });
        await expectRevert(
            this.bos.mint(carol, '1000', { from: bob }),
            'Ownable: caller is not the owner',
        );
        const totalSupply = await this.bos.totalSupply();
        const aliceBal = await this.bos.balanceOf(alice);
        const bobBal = await this.bos.balanceOf(bob);
        const carolBal = await this.bos.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '100');
        assert.equal(bobBal.valueOf(), '1000');
        assert.equal(carolBal.valueOf(), '0');
    });

    it('should supply token transfers properly', async () => {
        await this.bos.mint(alice, '100', { from: alice });
        await this.bos.mint(bob, '1000', { from: alice });
        await this.bos.transfer(carol, '10', { from: alice });
        await this.bos.transfer(carol, '100', { from: bob });
        const totalSupply = await this.bos.totalSupply();
        const aliceBal = await this.bos.balanceOf(alice);
        const bobBal = await this.bos.balanceOf(bob);
        const carolBal = await this.bos.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '90');
        assert.equal(bobBal.valueOf(), '900');
        assert.equal(carolBal.valueOf(), '110');
    });

    it('should fail if you try to do bad transfers', async () => {
        await this.bos.mint(alice, '100', { from: alice });
        const aliceBal = await this.bos.balanceOf(alice);
        assert.equal(aliceBal.valueOf(), '100');
        await expectRevert(
            this.bos.transfer(carol, '110', { from: alice }),
            'Bos::_transferTokens: transfer amount exceeds balance',
        );
        await expectRevert(
            this.bos.transfer(carol, '1', { from: bob }),
            'Bos::_transferTokens: transfer amount exceeds balance',
        );
    });
  });
