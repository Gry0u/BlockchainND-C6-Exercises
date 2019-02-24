pragma solidity ^0.4.25;

/* It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info:
https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/
*/
import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract ExerciseC6D {
    // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    using SafeMath for uint256;


    address private contractOwner;   // Account used to deploy contract


    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    // Status codes returned by oracles
    uint8 private constant ON_TIME = 10;
    uint8 private constant NOT_ON_TIME = 99;

    // Track all registered oracles
    mapping(address => uint8[3]) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;   // Account that requested status
        bool isOpen;        // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;  // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
                                                        // submit
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;


    // Event fired each time an oracle submits a response
    event FlightStatusInfo(string flight, uint256 timestamp, uint8 status, bool verified);

    // Flight data persisted forever
    struct FlightStatus {
        bool hasStatus;
        uint8 status;
    }

    mapping(bytes32 => FlightStatus) flights;

    constructor() public {
        contractOwner = msg.sender;
    }
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier paidRegistrationFee() {
        require(msg.value >= REGISTRATION_FEE, "Each Oracle must pay a registration to get registered");
        _;
    }

    modifier oracleHasRightIndex(uint8 index) {
        require(
            (oracles[msg.sender][0] == index) || (oracles[msg.sender][1] == index) || (oracles[msg.sender][2] == index),
            "Index does not match oracle request"
        );
        _;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/
    /*********************************** BEGIN: Oracle Registration ***********************************/
    // STAGE ONE: ORACLES REGISTER WITH THE SMART CONTRACT
    // Register an oracle with the contract
    function registerOracle()
    external
    paidRegistrationFee
    payable
    {
        uint8[3] memory indexes = generateIndexes(msg.sender);
        oracles[msg.sender] = indexes;
    }

    function getOracle(address account)
    external
    view
    requireContractOwner
    returns(uint8[3])
    {
        return oracles[account];
    }

    /************************************ END: Oracle Registration ************************************/
    /************************************ BEGIN: Oracle Data Request ************************************/
    // STAGE TWO: ORACLES ARE RANDOMLY CHOSEN TO FETCH INFORMATION
    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, string flight, uint256 timestamp);

    // Generate a request
    function fetchFlightStatus(string flight, uint256 timestamp) external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, flight, timestamp));
        oracleResponses[key] = ResponseInfo({ requester: msg.sender, isOpen: true });

        emit OracleRequest(index, flight, timestamp);

    }

    /************************************ END: Oracle Data Request ************************************/
    /*********************************** BEGIN: Oracle Callback ***********************************/
    // STAGE THREE: ORACLES SUBMIT INFORMATION
    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
    (
        uint8 index,
        string flight,
        uint256 timestamp,
        uint8 statusId
    )
    external
    oracleHasRightIndex(index)
    {
        // Generate key
        bytes32 key = keccak256(abi.encodePacked(index, flight, timestamp));
        // check if request valid
        require(oracleResponses[key].isOpen == true, "This request is not open or invalid");
        // Add response
        oracleResponses[key].responses[statusId].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        if (oracleResponses[key].responses[statusId].length >= MIN_RESPONSES) {

            // Prevent any more responses since MIN_RESPONSE threshold has been reached
            oracleResponses[key].isOpen = false;

            // Announce to the world that verified flight status information is available
            emit FlightStatusInfo(flight, timestamp, statusId, true);
            // Save the flight information for posterity
            bytes32 flightKey = keccak256(abi.encodePacked(flight, timestamp));
            flights[flightKey] = FlightStatus(true, statusId);
        } else {
            // Oracle submitting response but MIN_RESPONSES threshold not yet reached

            // Announce to the world that verified flight status information is available
            emit FlightStatusInfo(flight, timestamp, statusId, false);
        }
    }

    /************************************ END: Oracle Callback ************************************/
    /************************************ BEGIN: Utility Functions ************************************/
    // Query the status of any flight
    function viewFlightStatus(string flight, uint256 timestamp)
    external
    view
    returns(uint8)
    {
        require(flights[flightKey].hasStatus, "Flight status not available");

        bytes32 flightKey = keccak256(abi.encodePacked(flight, timestamp));
        return flights[flightKey].status;
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    /************************************ END: Utility Functions ************************************/


}
