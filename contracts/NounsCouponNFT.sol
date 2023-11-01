
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NounsCouponNFT is ERC721Enumerable {
    address private nounsCouponRedemption;
    address public pendingNounsCouponRedemption;
    uint256 public redemptionAddressChangeTimestamp;
    uint256 public constant ADDRESS_CHANGE_DELAY = 24 hours;  // 24 hour delay

    mapping(uint256 => uint256) public couponExpiry; // Coupon ID to Expiry Timestamp

    constructor(address _nounsCouponRedemption) ERC721("NounsCoupon", "NCP") {
        nounsCouponRedemption = _nounsCouponRedemption;
    }

    modifier onlyRedemptionContract() {
        require(msg.sender == nounsCouponRedemption, "Unauthorized");
        _;
    }

    function proposeRedemptionContract(address _nounsCouponRedemption) external onlyRedemptionContract {
        pendingNounsCouponRedemption = _nounsCouponRedemption;
        redemptionAddressChangeTimestamp = block.timestamp + ADDRESS_CHANGE_DELAY;
    }

    function confirmRedemptionContractChange() external {
        require(block.timestamp >= redemptionAddressChangeTimestamp, "Change not yet allowed");
        require(msg.sender == pendingNounsCouponRedemption, "Unauthorized");
        nounsCouponRedemption = pendingNounsCouponRedemption;
        pendingNounsCouponRedemption = address(0);
    }

    function issueCoupon(address recipient, uint256 expiry) external onlyRedemptionContract {
        uint256 newCouponId = totalSupply() + 1;
        _mint(recipient, newCouponId);
        couponExpiry[newCouponId] = expiry;
    }

    function burnCoupon(uint256 couponId) external onlyRedemptionContract {
        _burn(couponId);
    }
}
