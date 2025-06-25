// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BallotValidation
 * @dev Smart contract for validating and recording ballot counting results
 * Enables multiple officials (Presiding Officer, Deputy Presiding Officer, Party Agents)
 * to validate the same ballot count, providing multiple layers of verification
 */
contract BallotValidation {
    address public admin;
    
    // Structure to store election result details
    struct ElectionResult {
        string candidateId;
        string pollingStation;
        uint256 votes;
        bool validatedByPO;
        bool validatedByDPO;
        address[] partyAgentValidations;
        uint256 timestamp;
        bool finalized;
    }
    
    // Mapping from result ID to election result
    mapping(string => ElectionResult) public electionResults;
    
    // Array of all result IDs for enumeration
    string[] public resultIds;
    
    // Role management
    mapping(address => bool) public presidingOfficers;
    mapping(address => bool) public deputyPresidingOfficers;
    mapping(address => string) public partyAgents; // Maps address to political party
    
    // Events
    event ResultSubmitted(string resultId, string candidateId, string pollingStation, uint256 votes);
    event ResultValidatedByPO(string resultId, address validator);
    event ResultValidatedByDPO(string resultId, address validator);
    event ResultValidatedByPartyAgent(string resultId, address validator, string politicalParty);
    event ResultFinalized(string resultId, uint256 validationCount);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyPO() {
        require(presidingOfficers[msg.sender], "Only Presiding Officers can perform this action");
        _;
    }
    
    modifier onlyDPO() {
        require(deputyPresidingOfficers[msg.sender], "Only Deputy Presiding Officers can perform this action");
        _;
    }
    
    modifier onlyPartyAgent() {
        require(bytes(partyAgents[msg.sender]).length > 0, "Only Party Agents can perform this action");
        _;
    }
    
    /**
     * @dev Constructor - set deployer as admin
     */
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Role management functions
     */
    function assignPresidingOfficer(address officer) public onlyAdmin {
        presidingOfficers[officer] = true;
    }
    
    function removePresidingOfficer(address officer) public onlyAdmin {
        presidingOfficers[officer] = false;
    }
    
    function assignDeputyPresidingOfficer(address officer) public onlyAdmin {
        deputyPresidingOfficers[officer] = true;
    }
    
    function removeDeputyPresidingOfficer(address officer) public onlyAdmin {
        deputyPresidingOfficers[officer] = false;
    }
    
    function assignPartyAgent(address agent, string memory politicalParty) public onlyAdmin {
        require(bytes(politicalParty).length > 0, "Political party cannot be empty");
        partyAgents[agent] = politicalParty;
    }
    
    function removePartyAgent(address agent) public onlyAdmin {
        delete partyAgents[agent];
    }
    
    /**
     * @dev Submit a new election result
     * @param resultId Unique identifier for the result
     * @param candidateId The candidate identifier
     * @param pollingStation The polling station identifier
     * @param votes The number of votes counted
     */
    function submitResult(
        string memory resultId,
        string memory candidateId,
        string memory pollingStation,
        uint256 votes
    ) public {
        require(
            presidingOfficers[msg.sender] || 
            deputyPresidingOfficers[msg.sender] || 
            bytes(partyAgents[msg.sender]).length > 0,
            "Unauthorized: Only election officials can submit results"
        );
        
        require(bytes(resultId).length > 0, "Result ID cannot be empty");
        require(bytes(candidateId).length > 0, "Candidate ID cannot be empty");
        require(bytes(pollingStation).length > 0, "Polling station cannot be empty");
        
        // Check if result already exists
        if (electionResults[resultId].timestamp == 0) {
            // New result
            electionResults[resultId] = ElectionResult({
                candidateId: candidateId,
                pollingStation: pollingStation,
                votes: votes,
                validatedByPO: false,
                validatedByDPO: false,
                partyAgentValidations: new address[](0),
                timestamp: block.timestamp,
                finalized: false
            });
            
            resultIds.push(resultId);
            
            emit ResultSubmitted(resultId, candidateId, pollingStation, votes);
        } else {
            // Result exists, just validate based on caller's role
            // Validation will be handled by specific validation functions
        }
        
        // Auto-validate based on submitter's role
        if (presidingOfficers[msg.sender]) {
            validateResultAsPO(resultId);
        } else if (deputyPresidingOfficers[msg.sender]) {
            validateResultAsDPO(resultId);
        } else if (bytes(partyAgents[msg.sender]).length > 0) {
            validateResultAsPartyAgent(resultId);
        }
    }
    
    /**
     * @dev Validate a result as Presiding Officer
     * @param resultId The result identifier
     */
    function validateResultAsPO(string memory resultId) public onlyPO {
        require(electionResults[resultId].timestamp > 0, "Result does not exist");
        require(!electionResults[resultId].validatedByPO, "Result already validated by a PO");
        
        electionResults[resultId].validatedByPO = true;
        emit ResultValidatedByPO(resultId, msg.sender);
        
        checkAndFinalizeResult(resultId);
    }
    
    /**
     * @dev Validate a result as Deputy Presiding Officer
     * @param resultId The result identifier
     */
    function validateResultAsDPO(string memory resultId) public onlyDPO {
        require(electionResults[resultId].timestamp > 0, "Result does not exist");
        require(!electionResults[resultId].validatedByDPO, "Result already validated by a DPO");
        
        electionResults[resultId].validatedByDPO = true;
        emit ResultValidatedByDPO(resultId, msg.sender);
        
        checkAndFinalizeResult(resultId);
    }
    
    /**
     * @dev Validate a result as Party Agent
     * @param resultId The result identifier
     */
    function validateResultAsPartyAgent(string memory resultId) public onlyPartyAgent {
        require(electionResults[resultId].timestamp > 0, "Result does not exist");
        
        // Check if this party agent has already validated
        address[] storage validations = electionResults[resultId].partyAgentValidations;
        for (uint256 i = 0; i < validations.length; i++) {
            if (validations[i] == msg.sender) {
                revert("Party agent has already validated this result");
            }
        }
        
        // Add validation
        electionResults[resultId].partyAgentValidations.push(msg.sender);
        emit ResultValidatedByPartyAgent(resultId, msg.sender, partyAgents[msg.sender]);
        
        checkAndFinalizeResult(resultId);
    }
    
    /**
     * @dev Check if a result can be finalized based on validation count
     * @param resultId The result identifier
     */
    function checkAndFinalizeResult(string memory resultId) internal {
        ElectionResult storage result = electionResults[resultId];
        
        // A result is finalized if it has both PO and DPO validation plus at least one party agent
        if (
            result.validatedByPO && 
            result.validatedByDPO && 
            result.partyAgentValidations.length > 0 &&
            !result.finalized
        ) {
            result.finalized = true;
            emit ResultFinalized(resultId, 2 + result.partyAgentValidations.length);
        }
    }
    
    /**
     * @dev Get a result by ID
     * @param resultId The result identifier
     * @return candidateId The candidate identifier
     * @return pollingStation The polling station identifier
     * @return votes The number of votes counted
     * @return validatedByPO Whether the result is validated by a Presiding Officer
     * @return validatedByDPO Whether the result is validated by a Deputy Presiding Officer
     * @return partyAgentCount The number of party agents who validated the result
     * @return isFinalized Whether the result is finalized
     */
    function getResult(string memory resultId) public view returns (
        string memory candidateId,
        string memory pollingStation,
        uint256 votes,
        bool validatedByPO,
        bool validatedByDPO,
        uint256 partyAgentCount,
        bool isFinalized
    ) {
        ElectionResult storage result = electionResults[resultId];
        require(result.timestamp > 0, "Result does not exist");
        
        return (
            result.candidateId,
            result.pollingStation,
            result.votes,
            result.validatedByPO,
            result.validatedByDPO,
            result.partyAgentValidations.length,
            result.finalized
        );
    }
    
    /**
     * @dev Get the total number of results
     * @return The total number of results
     */
    function getTotalResults() public view returns (uint256) {
        return resultIds.length;
    }
    
    /**
     * @dev Get a result ID by index
     * @param index The index of the result
     * @return The result ID
     */
    function getResultIdByIndex(uint256 index) public view returns (string memory) {
        require(index < resultIds.length, "Index out of bounds");
        return resultIds[index];
    }
    
    /**
     * @dev Transfer admin rights to a new address
     * @param newAdmin The address of the new admin
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        admin = newAdmin;
    }
}
