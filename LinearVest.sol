// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IERC20.sol";
import "./SafeMath.sol";


contract LinearVest {
    using SafeMath for uint256;

    address public beneficiary;
    IERC20 public immutable YETI;

    uint public immutable vestStart; // time when vest starts
    uint public immutable vestLength; // time period over which the Yeti tokens linearly vest
    uint public immutable totalVestAmount; // amount of Yeti tokens that will vest in this contract
    uint public claimed; // amount of vested Yeti claimed so far


    modifier onlyBeneficiary {
        require(
            msg.sender == beneficiary,
            "Only the beneficiary can call this function."
        );
        _;
    }

    constructor(IERC20 _yetiToken, address _beneficiary, uint _start, uint _length, uint _total) public {
        YETI = _yetiToken;
        beneficiary = _beneficiary;

        vestStart = _start;
        vestLength = _length;
        totalVestAmount = _total;
    }


    // claim vested Yeti tokens
    function claimYeti(address _to, uint _amount) external onlyBeneficiary {
        require(block.timestamp > vestStart, "Vesting hasn't started yet");
        require(claimed < totalVestAmount, "All vested YETI has been claimed");

        uint timePastVestStart = block.timestamp.sub(vestStart);
        uint pctVested = _min(1e18, timePastVestStart.mul(1e18).div(vestLength));
        uint currentlyVested = pctVested.mul(totalVestAmount).div(1e18);

        require(currentlyVested >= claimed.add(_amount), "Insufficient vested Yeti");
        claimed = claimed.add(_amount);
        require(YETI.transfer(_to, _amount));
    }


    // update address that can claim Yeti tokens
    function updateBeneficiary(address _newBeneficiary) external onlyBeneficiary {
        beneficiary = _newBeneficiary;
    }


    // returns amount of Yeti tokens that have
    // vested to this contract but haven't been claimed
    function amountClaimable() external view returns (uint claimable) {
        if (block.timestamp >= vestStart) {
            uint timePastVestStart = block.timestamp.sub(vestStart);
            uint pctVested = _min(1e18, timePastVestStart.mul(1e18).div(vestLength));
            uint currentlyVested = pctVested.mul(totalVestAmount).div(1e18);

            return currentlyVested.sub(claimed);
        } else {
            return 0;
        }
    }


    // returns minimum of a, b
    function _min(uint a, uint b) internal pure returns (uint) {
        if (a < b) {
            return a;
        }
        return b;
    }

}
