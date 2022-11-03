pragma solidity ^0.8.0;
import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MorphoAavePosition} from "../integrations/MorphoAavePosition.sol";

contract MorphoAaveKnockout is ERC721, Ownable {
    uint256 internal count = 0;
    address internal morphoContract;
    address internal morphoLensContract;

    mapping(uint256 => MorphoAavePosition) internal positions;

    constructor(address _morphoContract, address _morphoLensContract)
        ERC721("Photon - Morpho Aave Knockout", "pMAK")
    {
        morphoContract = _morphoContract;
        morphoLensContract = _morphoLensContract;
    }

    function create(
        address _collateralAddress,
        address _poolCollateralTokenAddress,
        address _debtTokenAddress,
        address _poolDebtTokenAddress,
        uint256 _amountDebt,
        uint256 _leverage
    ) public returns (uint256 tokenId) {
        IERC20(_debtTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amountDebt
        );
        positions[count] = new MorphoAavePosition(
            morphoContract,
            morphoLensContract
        );
        IERC20(_debtTokenAddress).approve(
            address(positions[count]),
            _amountDebt
        );
        positions[count].createPosition(
            _collateralAddress,
            _poolCollateralTokenAddress,
            _debtTokenAddress,
            _poolDebtTokenAddress,
            _amountDebt,
            _leverage
        );

        tokenId = count;
        _mint(msg.sender, count++);
    }

    function exercise(uint256 tokenId) public {
        require(ownerOf[tokenId] == msg.sender);

        positions[tokenId].closePosition();

        IERC20 collateral = IERC20(positions[tokenId].getCollateralAddress());

        collateral.transfer(msg.sender, collateral.balanceOf(address(this)));

        _burn(tokenId);
    }

    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {}

    function setMorphoContract(address _morphoContract) public onlyOwner {
        morphoContract = _morphoContract;
    }

    function setMorphoLensContract(address _morphoLensContract)
        public
        onlyOwner
    {
        morphoLensContract = _morphoLensContract;
    }
}
