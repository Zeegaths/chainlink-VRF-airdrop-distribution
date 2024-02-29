// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;


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


contract randomAirdrops {

    address owner;
    uint userCount;

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

    constructor() {
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
            prizeDistribution();        
        }          
    }

    function prizeDistribution() public  {
        // require();
    }
}
