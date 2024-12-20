// contracts/contracts/AuctionFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SingleAuction.sol";

/**
 * @title AuctionFactory
 * @dev Factory contract to create and manage multiple SingleAuction instances.
 */
contract AuctionFactory is Ownable {
    // Array to store all deployed SingleAuction contracts
    SingleAuction[] public auctions;
    
    // Counter to keep track of the number of auctions created
    uint256 public auctionCount;

    // Event emitted when a new auction is created
    event AuctionCreated(address indexed auctionAddress, uint256 indexed auctionId);

    /**
     * @dev Creates a new SingleAuction contract.
     * @param _price The fixed price of the product.
     * @param _productName The name of the product.
     * @param _duration The duration of the auction in seconds.
     * @param _arbiter The address of the arbiter responsible for resolving disputes.
     * @param _imageUrl The URL of the product image.
     * @param _description The description of the product.
     */
    function createAuction(
        uint256 _price,
        string memory _productName,
        uint256 _duration,
        address _arbiter,
        string memory _imageUrl,
        string memory _description
    ) external onlyOwner {
        // Deploy a new SingleAuction contract with the provided parameters
        SingleAuction newAuction = new SingleAuction(
            _price,
            _productName,
            _duration,
            _arbiter,
            _imageUrl,
            _description,
            msg.sender
        );
        
        // Add the new auction to the auctions array
        auctions.push(newAuction);
        auctionCount += 1;
        
        // Emit the AuctionCreated event with the auction address and its ID
        emit AuctionCreated(address(newAuction), auctionCount);
    }

    /**
     * @dev Retrieves a subset of auctions for pagination purposes.
     * @param _start The starting index from which to retrieve auctions.
     * @param _limit The maximum number of auctions to retrieve.
     * @return A dynamic array of SingleAuction contracts.
     *
     * @notice This function helps in fetching auctions in batches to avoid gas-intensive operations
     * when the auctions array grows large.
     */
    function getAuctions(uint256 _start, uint256 _limit) external view returns (SingleAuction[] memory) {
        require(_start < auctionCount, "Start index out of bounds");
        
        // Calculate the end index ensuring it does not exceed the total count
        uint256 end = _start + _limit;
        if (end > auctionCount) {
            end = auctionCount;
        }
        
        uint256 size = end - _start;
        SingleAuction[] memory batch = new SingleAuction[](size);
        
        // Populate the batch array with the specified range of auctions
        for (uint256 i = 0; i < size; i++) {
            batch[i] = auctions[_start + i];
        }
        
        return batch;
    }

    /**
     * @dev Retrieves the address of a specific auction by its ID.
     * @param _id The ID of the auction to retrieve.
     * @return The address of the SingleAuction contract.
     */
    function getAuctionAddress(uint256 _id) external view returns (address) {
        require(_id < auctionCount, "Auction does not exist");
        return address(auctions[_id]);
    }
}
