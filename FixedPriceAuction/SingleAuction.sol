// contracts/contracts/SingleAuction.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title SingleAuction
 * @dev Represents an individual auction where a product can be bought at a fixed price.
 */
contract SingleAuction is ReentrancyGuard {
    // State variables
    address public seller;
    address public arbiter;
    address public buyer;
    uint256 public price;
    string public productName;
    string public description;
    string public imageUrl;
    bool public isActive;
    uint256 public deadline;
    bool public isCancelled;

    // Events
    event AuctionEnded(address indexed buyer, uint256 amount);
    event ItemBought(address indexed buyer, uint256 amount);
    event DescriptionUpdated(string newDescription);
    event ImageUrlUpdated(string newImageUrl);
    event AuctionCancelled();
    event DeadlineExtended(uint256 newDeadline);

    // Modifiers
    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can perform this action");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can perform this action");
        _;
    }

    modifier auctionActive() {
        require(isActive, "Auction is not active");
        _;
    }

    modifier onlySellerOrArbiter() {
        require(
            msg.sender == seller || msg.sender == arbiter,
            "Only seller or arbiter can perform this action"
        );
        _;
    }

    /**
     * @dev Initializes the auction with the provided parameters.
     * @param _price The fixed price of the product.
     * @param _productName The name of the product.
     * @param _duration The duration of the auction in seconds.
     * @param _arbiter The address of the arbiter responsible for resolving disputes.
     * @param _imageUrl The URL of the product image.
     * @param _description The description of the product.
     * @param _seller The address of the seller creating the auction.
     */
    constructor(
        uint256 _price,
        string memory _productName,
        uint256 _duration,
        address _arbiter,
        string memory _imageUrl,
        string memory _description,
        address _seller
    ) {
        require(_arbiter != address(0), "Arbiter cannot be the zero address");
        require(_seller != address(0), "Seller cannot be the zero address");

        seller = _seller;
        price = _price;
        productName = _productName;
        description = _description;
        imageUrl = _imageUrl;
        isActive = true;
        isCancelled = false;
        deadline = block.timestamp + _duration;
        arbiter = _arbiter;
    }

    /**
     * @dev Allows a user to buy the item by sending ETH.
     *      Refunds any excess ETH sent beyond the fixed price.
     *
     * Requirements:
     * - The auction must be active and not cancelled.
     * - The sent ETH must be equal to or exceed the fixed price.
     * - The auction deadline must not have passed.
     * - The item must not have been bought already.
     *
     * Emits an {ItemBought} and {AuctionEnded} event upon successful purchase.
     */
    function buy() external payable nonReentrant auctionActive {
        require(!isCancelled, "Auction has been cancelled");
        require(msg.value >= price, "Insufficient ETH sent");
        require(block.timestamp < deadline, "Auction deadline has passed");
        require(buyer == address(0), "Item already bought");

        buyer = msg.sender;
        isActive = false;

        uint256 excess = msg.value - price;

        // Transfer the fixed price to the seller
        (bool sent, ) = seller.call{value: price}("");
        require(sent, "Failed to send ETH to seller");

        // Refund any excess ETH to the buyer
        if (excess > 0) {
            (bool refundSent, ) = buyer.call{value: excess}("");
            require(refundSent, "Failed to refund excess ETH");
        }

        emit ItemBought(buyer, price);
        emit AuctionEnded(buyer, price);
    }

    /**
     * @dev Allows the arbiter to end the auction after the deadline if the item hasn't been bought.
     *
     * Requirements:
     * - The caller must be the arbiter.
     * - The auction must be active and not cancelled.
     * - The current time must be past the deadline.
     *
     * Emits an {AuctionEnded} event.
     */
    function endAuction() external onlyArbiter {
        require(isActive, "Auction is not active");
        require(!isCancelled, "Auction has been cancelled");
        require(block.timestamp >= deadline, "Auction deadline not reached");

        isActive = false;
        emit AuctionEnded(buyer, price);
    }

    /**
     * @dev Allows the seller to update the description of the product.
     *
     * Requirements:
     * - The caller must be the seller.
     * - The auction must be active and not cancelled.
     *
     * Emits a {DescriptionUpdated} event.
     */
    function updateDescription(string memory _description) external onlySeller auctionActive {
        description = _description;
        emit DescriptionUpdated(_description);
    }

    /**
     * @dev Allows the seller to update the image URL of the product.
     *
     * Requirements:
     * - The caller must be the seller.
     * - The auction must be active and not cancelled.
     *
     * Emits an {ImageUrlUpdated} event.
     */
    function updateImageUrl(string memory _imageUrl) external onlySeller auctionActive {
        imageUrl = _imageUrl;
        emit ImageUrlUpdated(_imageUrl);
    }

    /**
     * @dev Allows the seller to cancel the auction before it's sold.
     *
     * Requirements:
     * - The caller must be the seller.
     * - The auction must be active and not already cancelled.
     *
     * Emits an {AuctionCancelled} event.
     */
    function cancelAuction() external onlySeller auctionActive {
        isActive = false;
        isCancelled = true;
        emit AuctionCancelled();
    }

    /**
     * @dev Allows the seller or arbiter to extend the auction deadline.
     * @param _additionalTime The additional time in seconds to extend the auction.
     *
     * Requirements:
     * - The caller must be the seller or arbiter.
     * - The auction must be active and not cancelled.
     * - The additional time must be greater than zero.
     *
     * Emits a {DeadlineExtended} event.
     */
    function extendDeadline(uint256 _additionalTime) external onlySellerOrArbiter auctionActive {
        require(_additionalTime > 0, "Additional time must be greater than zero");
        deadline += _additionalTime;
        emit DeadlineExtended(deadline);
    }
}
