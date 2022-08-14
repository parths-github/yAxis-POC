const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

// Fork at 11160218


async function main() {

    let abi = [
        "function balanceOf(address _user) view returns (uint256)",
        "function approve(address spender, uint256 amount) external returns (bool)",
        "function transfer(address recipient, uint256 amount) external returns (bool)"
    ];


    const yAxisMetaVault= await ethers.getContractAt('yAxisMetaVault', "0xBFbEC72F2450eF9Ab742e4A27441Fa06Ca79eA6a");
    const curve = new ethers.Contract('0x6c3f90f043a72fa612cbac8115ee7e52bde6e490', abi, ethers.getDefaultProvider());

    // Impersonating account which has some 3crv tokens
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: ["0x5661bF295f48F499A70857E8A6450066a8D16400"],
      });

    const signer = await ethers.getSigner("0x5661bF295f48F499A70857E8A6450066a8D16400");

    // Getting some eth
    await ethers.provider.send("hardhat_setBalance", [
        signer.address,
        "0x1158e460913d00000", // 20 ETH
    ]);

    // Approving
    await curve.connect(signer).approve(yAxisMetaVault.address, BigNumber.from('10000000000000000000'));

    // Depositing 1 wei of 3crv to mint 1 wei of MVLT
    await yAxisMetaVault.connect(signer).deposit(1, '0x6c3f90f043a72fa612cbac8115ee7e52bde6e490', 0, false, {gasLimit: 23000000});

    // Transferring 3crv directly to yAxisMetaVault
    await curve.connect(signer).transfer(yAxisMetaVault.address, ethers.utils.parseEther('3'), {gasLimit: 23000000});

    const beforeBalance = await yAxisMetaVault.balanceOf(signer.address);
    // Depositing with lesser amount
    await yAxisMetaVault.connect(signer).deposit(ethers.utils.parseEther('2'), '0x6c3f90f043a72fa612cbac8115ee7e52bde6e490', 0, false, {gasLimit: 23000000});
    const totalSupply = await yAxisMetaVault.totalSupply();
    const afterBalance = await yAxisMetaVault.balanceOf(signer.address);

    // No MVLT should be minted. So before and after should be equal
    console.log(beforeBalance, afterBalance, totalSupply);



}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })
