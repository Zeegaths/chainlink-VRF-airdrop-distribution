// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts@0.8.0/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts@0.8.0/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {ConfirmedOwner} from "@chainlink/contracts@0.8.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//participant registration
//activity
//entries for prize pool participation
//prize distribution
//random winner selection-adjustable
//airdrop reward calculation-prize pool, entries earned
//gas effient ERC-20 token reward distribution
//log events

//VRF
//error-handling
//gas-efficient

//comments on functions

contract RandomAirdrops is VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 2;

    uint64 s_subscriptionId;
    address owner;
    uint256 userCount;
    address tokenAddress;
    uint256 totalPrizePool;
    uint256[] public randomResult;

    struct Player {
        uint256 id;
        string username;
        uint256 entries;
    }

    Player[] userArray;
    address[] public players;

    uint256 totalEntries;
    mapping(address => Player) user;
    mapping(address => bool) hasRegistered;
    mapping(address => uint256) userEntries;
    mapping(uint256 => string) public question;
    mapping(uint256 => uint256) public answer;
    mapping(address => mapping(uint256 => bool)) public hasAnswered; // New mapping to track whether a user has answered a question

    event TotalEntries(address indexed _player, uint256 _userEntries);

    modifier onlyOwner() {
        require(msg.sender == owner, "chill");
        _;
    }

    constructor(address _tokenAddress, uint64 subscriptionId)
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;

        question[1] = "How many countries are in Africa?";
        answer[1] = 54;

        question[2] = "How many continents are in the world?";
        answer[2] = 7;

        question[
            3
        ] = "How many presidents have been assassinated in US history?";
        answer[3] = 4;

        question[4] = "How many oceans are in the world?";
        answer[4] = 5;

        question[5] = "How many planets are there?";
        answer[5] = 8;

        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];

        return (request.fulfilled, request.randomWords);
    }

    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");

        require(msg.sender != address(0), "Address zero detected");

        require(!hasRegistered[msg.sender], "Have already registered");

        uint256 _id = userCount + 1;

        hasRegistered[msg.sender] = true;

        Player storage newUser = user[msg.sender];

        newUser.id = _id;
        newUser.username = _username;
        newUser.entries = 0;
        userCount++;

        userArray.push(newUser);
    }

    function answerQuestions(uint256 _questionId, uint256 _userAnswer)
        external
    {
        require(hasRegistered[msg.sender], "You need to register first");
        require(_questionId >= 1 && _questionId <= 5, "Invalid question ID");
        require(
            !hasAnswered[msg.sender][_questionId],
            "You have already answered this question"
        );

        // Check if the user's answer is correct
        if (_userAnswer == answer[_questionId]) {
            // Assign different prizes for each question
            uint256 prize;
            if (_questionId == 1) {
                prize = 10; // Prize for Question 1
            } else if (_questionId == 2) {
                prize = 20; // Prize for Question 2
            } else if (_questionId == 3) {
                prize = 15; // Prize for Question 3
            } else if (_questionId == 4) {
                prize = 25; // Prize for Question 4
            } else if (_questionId == 5) {
                prize = 30; // Prize for Question 5
            }

            // Award entries based on the prize
            userEntries[msg.sender] += prize;
            totalEntries += prize;

            // Mark the question as answered by the user
            hasAnswered[msg.sender][_questionId] = true;

            emit TotalEntries(msg.sender, userEntries[msg.sender]);
        }
        if (userEntries[msg.sender] >= 50) {
            players.push(msg.sender);
        }

        if (totalEntries >= 50) {
            payWinner();
        }
    }



    function payWinner() public {
        require(msg.sender == owner, "only owner can pick a winner");

        if (players.length == 0) {
            // No players to pay
            return;
        }

        RequestStatus memory request = s_requests[lastRequestId];

        uint256 index = request.randomWords[0] % players.length;
        address winnerAddress = players[index];
     

        uint256 winnerAmount = (userEntries[winnerAddress] * totalPrizePool) / totalEntries; // Access entries from userEntries mapping

        IERC20(tokenAddress).transfer(winnerAddress, winnerAmount);

        // Clear the players array and reset totalEntries
        delete players;
        totalEntries = 0;
    }
}
