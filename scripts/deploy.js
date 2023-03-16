/*For Pancake contract*/

async function main() {
  // We get the contract to deploy

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:                    ", await deployer.address);
  const construct = await deployer.address;

  const core = await ethers.getContractFactory("PancakeFactory");
  const periphery = await ethers.getContractFactory("PancakeRouter");
  const cake = await ethers.getContractFactory("PancakeERC20");
  const WBNB = await ethers.getContractFactory("WBNB");

  const factory = await core.deploy(construct);
  const wbnb = await WBNB.deploy();
  const peripheryContracts = await periphery.deploy(factory.address, wbnb.address);
  const cakeToken = await cake.deploy();


  console.log("Factory deployed to:         ", factory.address);
  console.log("Router contract deployed to: ", peripheryContracts.address);
  console.log("Cake token deployed to:      ", cakeToken.address);

  const hash = await factory.INIT_CODE_HASH();
  console.log("INIT_CODE_HASH:              ", hash);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });