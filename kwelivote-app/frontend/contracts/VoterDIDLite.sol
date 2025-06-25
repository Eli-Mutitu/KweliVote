// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VoterDIDLite
 * @dev A lightweight version of the VoterDID contract that uses less gas
 * This optimized version removes storage of national IDs array to save gas
 */
contract VoterDIDLite {
    address public admin;
    
    // Mapping from nationalId to DID
    mapping(string => string) private voterDIDs;
    
    // Mapping to track registered voters
    mapping(string => bool) private registeredVoters;
    
    // Events with minimal parameters
    event DIDRegistered(string nationalId);
    event DIDUpdated(string nationalId);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    
    /**
     * @dev Constructor - set deployer as admin
     */
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Register a new voter with their DID (gas-optimized version)
     * @param did The W3C compliant DID
     * @param nationalId The voter's national ID
     */
    function registerDID(string memory nationalId, string memory did) public onlyAdmin {
        require(bytes(nationalId).length > 0, "Empty ID");
        require(bytes(did).length > 0, "Empty DID");
        
        bool isUpdate = registeredVoters[nationalId];
        
        // Store the DID
        voterDIDs[nationalId] = did;
        
        // Mark as registered if new
        if (!isUpdate) {
            registeredVoters[nationalId] = true;
            emit DIDRegistered(nationalId);
        } else {
            emit DIDUpdated(nationalId);
        }
    }
    
    /**
     * @dev Get a voter's DID by national ID
     * @param nationalId The voter's national ID
     * @return The voter's DID
     */
    function getDID(string memory nationalId) public view returns (string memory) {
        return voterDIDs[nationalId];
    }
    
    /**
     * @dev Check if a voter is registered
     * @param nationalId The voter's national ID
     * @return True if voter is registered
     */
    function isRegistered(string memory nationalId) public view returns (bool) {
        return registeredVoters[nationalId];
    }
    
    /**
     * @dev Transfer admin rights to a new address
     * @param newAdmin The address of the new admin
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "Zero address");
        admin = newAdmin;
    }
    
    /**
     * @dev Legacy function for backward compatibility
     */
    function registerVoter(string memory did, string memory nationalId) public onlyAdmin {
        registerDID(nationalId, did);
    }
}
