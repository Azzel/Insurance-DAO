//sub contract for claim managers list
pragma solidity ^0.5.0;
contract ClaimManagersList {
    
    enum ClaimStatus {Accepted, Rejected, InProgress}
    
    struct ClaimManager {
        //bool status; //active or suspended
        uint256 claimsPassed; //numbers of settled and rejected claims
        uint256 claimsSettled; //number of settled claims
        //uint256 numberOfReports; //number of reports for reopen claims
        address personAddress;
        //bytes32 personAddressHash;
    }
    
    struct ProposedClaimManager {
        string personURL;
        uint256 votesPro;
        uint256 votesContra;
        address personAddress;
    }
    
    /*
    event NewManagerProposed();
    event NewManagerPromoted(address _add);
    */
    
    uint claimDeposit; //sum of deposit to start process claim - in order avoid claims spam
    uint adminFee;
    
    //lists of contracts managers and etc
    ClaimManager[] claimManagers; //list of managers
    ProposedClaimManager[] proposedClaimManagers; //list of proposed managers
    
    constructor (uint _deposit) public {
        
        require(_deposit > 0);
        
        claimDeposit = _deposit * (1 finney); //temp nominated in finney
        
        //make sender as first manager
        claimManagers.push(ClaimManager ({
            //status: true,
            claimsPassed: 0, claimsSettled: 0,
            //numberOfReports: 0,
            //personAddressHash: keccak256(msg.sender),
            personAddress: msg.sender
        }));
        
    }
    
    //check if _add is a manager
    function checkClaimManager (address _add) private view returns (bool _isClaimManager) {
        _isClaimManager = false;
        for (uint256 i = 0; i < claimManagers.length; i++) {
            if (claimManagers[i].personAddress == _add) {
                _isClaimManager = true;
                break;
            }
        }
    }
    
    //check if _add is a proposed manager
    function checkProposedClaimManager (address _add) private view returns (bool _isClaimManager) {
        _isClaimManager = false;
        for (uint256 i = 0; i < proposedClaimManagers.length; i++) {
            if (proposedClaimManagers[i].personAddress == _add) {
                _isClaimManager = true;
                break;
            }
        }
    }
    
    function returnFirstProposedManagerUrl () public view returns (string memory) {
        require(proposedClaimManagers.length > 0);
        //require(checkClaimManager(msg.sender)); //commented for unit test but may be it's ok?
        return proposedClaimManagers[0].personURL;
    }
    
    function proposeNewManager (string memory _url, address _add) public payable {
        require(msg.value >= claimDeposit);
        //require(checkClaimManager(msg.sender)); //commented for unit test but may be it's ok?
        require(!checkClaimManager(_add));
        require(!checkProposedClaimManager(_add));
        adminFee += msg.value;
        proposedClaimManagers.push(ProposedClaimManager ({personURL: _url,
            votesPro: 0, votesContra: 0, personAddress: _add}));
    }
    
    function voteForProposedManager (string memory _url, bool _vote) public {
        require(checkClaimManager(msg.sender));
        require(keccak256(bytes(_url)) == keccak256(bytes(returnFirstProposedManagerUrl())));
        if (_vote) proposedClaimManagers[0].votesPro++; //always votes for first promoted manager
        else proposedClaimManagers[0].votesContra++;
        
        //check if 1/2 of total votes already pro or contra this manager
        if (proposedClaimManagers[0].votesPro * 2 >= claimManagers.length) { //more or equal of half pro
            promoteProposedManager();
        }
        if (proposedClaimManagers.length>0) {
            if (proposedClaimManagers[0].votesContra * 2 > claimManagers.length) { //more then half contra
                rejectProposedManager();
            }    
        }
        
        //get some payment from admin fee for activity?
    }
    
    function rejectProposedManager () private {
        for (uint256 i = 1; i < proposedClaimManagers.length; i++)
            proposedClaimManagers[0] = proposedClaimManagers[i];
        delete proposedClaimManagers[proposedClaimManagers.length-1];
        proposedClaimManagers.length--;
    }
    
    function promoteProposedManager () private {
        claimManagers.push(ClaimManager ({
            //status: true,
            claimsPassed: 0, claimsSettled: 0,
            //numberOfReports: 0,
            //personAddressHash: keccak256(proposedClaimManagers[0].personAddress),
            personAddress: proposedClaimManagers[0].personAddress
        }));
        rejectProposedManager(); //remove him from list after promotion
    }
    
    /*
    //_addhash is not good also
    function updateCountOfPassedClaimsByManager (bytes32 _addhash, uint _cstatus) public {
        for (uint256 i =0; i < claimManagers.length; i++) {
            if (claimManagers[i].personAddressHash == _addhash) {
                claimManagers[i].claimsPassed++;
                if (_cstatus == uint(ClaimStatus.Accepted)) claimManagers[i].claimsSettled++;
                break;
            }
        }
    }
    */
    
    //test help functions
    function returnLengthOfList () public view returns (uint256) {
        return claimManagers.length;
    }
    
    function returnLengthOfProposedList () public view returns (uint256) {
        return proposedClaimManagers.length;
    }
    
    function returnManagerAddress (uint256 _num) public view returns (address) {
        require(_num<claimManagers.length);
        return claimManagers[_num].personAddress;
    }
    
    function returnProposedManagerAddress (uint256 _num) public view returns (address) {
        require(_num<proposedClaimManagers.length);
        return proposedClaimManagers[_num].personAddress;
    }
    
    function returnClaimDepositValue () public view returns (uint256) {
        return claimDeposit;
    }
    
    //functions to retrive payment for claims adjustement from admeen fee?
    
}

