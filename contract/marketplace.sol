 //SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BlockOverFlow {

//The data type of the doubt the user will ask to the community
  struct Doubt {
    address payable posterAddress;
    uint quesId;
    string heading;
    string description;
    uint bounty;
    uint timeOfPosting;
    uint dueDate;
    int maxUpvote;
    int mostUpvoteAnsIndex;
    address current_winner;
  }

  struct Answer {
    string ans;
    address answerer;
    uint upvotes;
    uint ansId;
  }

  address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
//Index for the doubts
  uint256 doubtIndex = 0;

  Doubt[] internal doubts; // to store all of the doubts

  mapping (uint => Answer[]) quesToAnsS;// stored all the answer in a array so its easy to iterate, and mapped it to its qId below

  mapping (uint => mapping (uint => mapping(address =>bool))) questionToAnsToupvoter;

//Useful Events
  event NewDoubt(address indexed from, uint256 quesId, string heading, string description);
  event NewUpdateAnswer(address indexed from, uint256 answerid, uint256 quesid, string ans, uint256 upvotes);

//Function to add a doubt 
  function writeDoubt(
    string memory _heading,
    string memory _description,
    uint _dueDate, 
    uint _bounty) public payable{
      //User needs to transfer money to the contract when he posts a doubt
      require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _bounty
        ),
        "Transaction could not be performed"
        );

      doubts.push(
        Doubt(
          payable (msg.sender),
          doubtIndex,
          _heading,
          _description,
          _bounty, // enter this amount in cUSD
          block.timestamp,
          block.timestamp + (_dueDate * 60),
          -1, // initialzed maxUpvote to -1, to will change to zero when first answer is upvoted
          -1,//same reason as above.
          msg.sender
      ));
      emit NewDoubt(msg.sender, doubtIndex, _heading, _description);
      doubtIndex++;
  }

  function readDoubts() public view returns(Doubt[] memory) {
    return doubts;
  }
   


  function answerDoubt(string memory answer, uint qId) public {
    Answer memory ans = Answer(answer, msg.sender, 0, quesToAnsS[qId].length);
    quesToAnsS[qId].push(ans);//pushing answer to AnsS array
    questionToAnsToupvoter[qId][quesToAnsS[qId].length-1]; //initializing IDK its needed or not if not required, will remove it
    emit NewUpdateAnswer(msg.sender, quesToAnsS[qId].length, qId, ans.ans, ans.upvotes);
  }


  function upVote(uint _doubtIndex, uint _ansIndex) public {

    //Checks if the user has already upvoted for the particular answer
    require (questionToAnsToupvoter[_doubtIndex][_ansIndex][msg.sender] == false, "Cannot upvote the answer twice!");
    
    questionToAnsToupvoter[_doubtIndex][_ansIndex][msg.sender] = true;// marking the upvoter

    quesToAnsS[_doubtIndex][_ansIndex].upvotes++; // inc. the upvote for the answer by accessing
    
    //logic for updating winner in maxUpvotedAnsId
    if(int(quesToAnsS[_doubtIndex][_ansIndex].upvotes) > doubts[_doubtIndex].maxUpvote){ //checking maxupvote for that question to the latest upvoted ans vote
      doubts[_doubtIndex].maxUpvote = int(quesToAnsS[_doubtIndex][_ansIndex].upvotes); // reassigning maxupvote if needer
      doubts[_doubtIndex].mostUpvoteAnsIndex = int(_ansIndex); // and mostupvoteAnsIndex
      // address previousWinner = doubts[_doubtIndex].current_winner; // storing the previous winner
      if(doubts[_doubtIndex].maxUpvote > 2){
      doubts[_doubtIndex].current_winner = quesToAnsS[_doubtIndex][_ansIndex].answerer; // updates the address of current winner
      }
      // uint bountyamount = doubts[_doubtIndex].bounty; // changing the winner stream // leep in mind about the bounty
    }
  }

  function reward(uint _doubtIndex) public payable{
    require(block.timestamp > doubts[_doubtIndex].dueDate, "The due must end before the worthy can be rewarded");

  //This will transfer the money to the worthy person -> if the upvotes are less than 2, then the owner would get his money back
    require(
      IERC20Token(cUsdTokenAddress).transferFrom(
        address(this),
        doubts[_doubtIndex].current_winner,
        doubts[_doubtIndex].bounty
      ),
      "Transaction could not be performed"
    );
  }

  // function to read values from the contract just for testing
  function readAnsS(uint _index) public view returns(Answer[] memory) {
    return quesToAnsS[_index];
  }
}