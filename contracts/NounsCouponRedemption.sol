
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INounsDAOExecutor {
    function safeTransferFrom(address recipient, uint256 nounId) external;
    function withdrawDAONounsFromEscrowIncreasingTotalSupply(address recipient, uint256 nounId) external;
}

contract NounsCouponRedemption {
    address public nounsCouponNFT;
    address public pendingNounsCouponNFT;
    address public nounsDAOExecutor;
    address public pendingNounsDAOExecutor;
    address public escrow;
    address public pendingEscrow;
    uint256 public addressChangeTimestamp;
    uint256 public constant ADDRESS_CHANGE_DELAY = 24 hours;  // 24 hour delay

    enum Source { Treasury, Escrow }

    constructor(address _nounsCouponNFT, address _nounsDAOExecutor, address _escrow) {
        nounsCouponNFT = _nounsCouponNFT;
        nounsDAOExecutor = _nounsDAOExecutor;
        escrow = _escrow;
    }

    modifier onlyDAOExecutor() {
        require(msg.sender == nounsDAOExecutor, "Unauthorized");
        _;
    }

    function proposeAddresses(address _nounsCouponNFT, address _nounsDAOExecutor, address _escrow) external onlyDAOExecutor {
        pendingNounsCouponNFT = _nounsCouponNFT;
        pendingNounsDAOExecutor = _nounsDAOExecutor;
        pendingEscrow = _escrow;
        addressChangeTimestamp = block.timestamp + ADDRESS_CHANGE_DELAY;
    }

    function confirmAddressChange() external onlyDAOExecutor {
        require(block.timestamp >= addressChangeTimestamp, "Change not yet allowed");
        nounsCouponNFT = pendingNounsCouponNFT;
        nounsDAOExecutor = pendingNounsDAOExecutor;
        escrow = pendingEscrow;
        pendingNounsCouponNFT = address(0);
        pendingNounsDAOExecutor = address(0);
        pendingEscrow = address(0);
    }

    function issueCouponToRecipient(address recipient, uint256 expiryTimestamp) external onlyDAOExecutor {
        // Assuming a max expiry of 1 year for a coupon. This can be adjusted based on requirements.
        require(expiryTimestamp == 0 || (expiryTimestamp >= block.timestamp && expiryTimestamp <= block.timestamp + 365 days), "Invalid expiryTimestamp");
        NounsCouponNFT(nounsCouponNFT).issueCoupon(recipient, expiryTimestamp);
    }

    function redeemNoun(uint256 couponId, uint256 nounId, Source source) external {
        require(NounsCouponNFT(nounsCouponNFT).ownerOf(couponId) == msg.sender, "Not the coupon owner");
        uint256 expiry = NounsCouponNFT(nounsCouponNFT).couponExpiry(couponId);
        require(expiry == 0 || expiry > block.timestamp, "Coupon has expired");
        NounsCouponNFT(nounsCouponNFT).burnCoupon(couponId);
        if (source == Source.Treasury) {
            INounsDAOExecutor(nounsDAOExecutor).safeTransferFrom(msg.sender, nounId);
        } else if (source == Source.Escrow) {
            INounsDAOExecutor(nounsDAOExecutor).withdrawDAONounsFromEscrowIncreasingTotalSupply(msg.sender, nounId);
        }
    }

    function burnByDAO(uint256 couponId) external onlyDAOExecutor {
        require(NounsCouponNFT(nounsCouponNFT).ownerOf(couponId) != address(0), "Coupon does not exist");
        NounsCouponNFT(nounsCouponNFT).burnCoupon(couponId);
    }
}
