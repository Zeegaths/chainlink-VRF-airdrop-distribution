// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
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


contract randomAirdrops is VRFConsumerBase {

    address owner;
    uint userCount;
    address tokenAddress;
    uint256 totalPrizePool;

    struct Player {
        uint256 id;
        string username;
        uint256 entries;
    }
   
   

    Player[] userArray;
    address [] public players;

    uint256 totalEntries;
    mapping(address => Player) user;
    mapping(address => bool) hasRegistered;
    mapping(address => uint256) userEntries;
    mapping(uint256 => string) public question;
    mapping(uint256 => uint256) public answer;
    mapping(address => mapping(uint256 => bool)) public hasAnswered; // New mapping to track whether a user has answered a question

    
    event TotalEntries(address indexed _player , uint256 _userEntries);

    bytes32 internal keyHash; // identifies which Chainlink oracle to use
    uint internal fee;        // fee to get random number
    uint public randomResult;

    constructor(address _tokenAddress) 
        VRFConsumerBase(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // VRF coordinator
            0x779877A7B0D9E8603169DdbD7836e478b4624789  // LINK token address
        )
        {
        keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
            fee = 0.25 * 10 ** 18;    // 0.1 LINK

        
        question[1] = "How many countries are in Africa?";
        answer[1] = 54;

        question[2] = "How many continents are in the world?";
        answer[2] = 7;

        question[3] = "How many presidents have been assassinated in US history?";
        answer[3] = 4;

        question[4] = "How many oceans are in the world?";
        answer[4] = 5;

        question[5] = "How many planets are there?";
        answer[5] = 8;
        
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint randomness) internal override {
        randomResult = randomness;
        payWinner();
    }


    function registerUser(string memory _username) public {
        require(bytes(_username).length > 0, "Username cannot be empty");

        require(msg.sender != address(0), "Address zero detected");

        require(!hasRegistered[msg.sender], "Have already registered");

        uint _id = userCount + 1;

        hasRegistered[msg.sender] = true;

        Player storage newUser = user[msg.sender];

        newUser.id = _id;
        newUser.username = _username;
        newUser.entries = 0;
        userCount++;

        userArray.push(newUser);
       
        
    }
    function answerQuestions(uint256 _questionId, uint256 _userAnswer) external {
        require(hasRegistered[msg.sender], "You need to register first");
        require(_questionId >= 1 && _questionId <= 5, "Invalid question ID");
        require(!hasAnswered[msg.sender][_questionId], "You have already answered this question");
        
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

            emit TotalEntries(msg.sender , userEntries[msg.sender]);
        }
        if(userEntries[msg.sender] >= 50) {
            players.push(msg.sender);
        }

        if (totalEntries >= 500) {
            pickWinner();        
        }          
    }

//prize distribution
    function pickWinner() public {
        require(msg.sender == owner, "only owner can pick a winner");
        getRandomNumber();
    }

    
    function payWinner() public {
        require(msg.sender == owner, "only owner can pick a winner");

        if (players.length == 0) {
        // No players to pay
            return;
        }

        uint index = randomResult % players.length;
        address winnerAddress = players[index];

        uint256 winnerAmount = userEntries[winnerAddress]; // Access entries from userEntries mapping

        IERC20(tokenAddress).transfer(winnerAddress, winnerAmount);

        // Clear the players array and reset totalEntries
        delete players;
        totalEntries = 0;
    }

}
