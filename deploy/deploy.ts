import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const deployedRealEstateNFT = await deploy("RealEstateNFT", {
    from: deployer,
    log: true,
  });

  console.log(`RealEstateNFT contract: `, deployedRealEstateNFT.address);
};
export default func;
func.id = "deploy_RealEstateNFT"; // id required to prevent reexecution
func.tags = ["RealEstateNFT"];
