// contract to insure additional civil laybility for car owners
// in order to cover exeed of limit og obligatory laybility insurance
pragma solidity ^0.5.0;

import './ClaimManagersList.sol';

contract SelfInsuranceDao {
    
    enum InsuranceContractStatus {InForce, NTU, Ended} //+Lapsed?
    enum ClaimStatus {Accepted, Rejected, InProgress}
    
    struct InsuranceContract {
        //uint256 contractId;
        InsuranceContractStatus status;
        uint startDate;
        //uint256 contractTerm; //always 360 days
        uint sumAssured;
        uint premium;
        //uint256 reserve;
        uint profitShareSum;
        address owner;
        
        //product specific attributes:
        //bytes32 VINhash;
    }
    
    struct Member {
        address memberAddress;
        address parentAddress;
        uint reserve;
    }
    
    struct ClaimFolder {
        ClaimStatus status;
        string claimURL;
        uint claimAmount;
        uint amountToSettle;
        address[numberOfClaimFolderManagers] managers;
        uint claimDate;
        //uint256 claimApplicationDate;
        uint256 votesPro;
        uint256 votesContra;
        //address beneficiary;
        
        uint256 contractNum;
    }
    
    /*
    event NewClaimApplied();
    event ClaimPassed(uint256 _claimAmount, ClaimStatus _cstatus);
    event NewContractBought(address _add, uint256 _premiumAmount);
    */
    
    //***some Contract constant and variables***
    uint minSumAssured;
    uint maxSumAssured;
    uint claimDeposit; //sum of deposit to start process claim - in order avoid claims spam
    //uint256 contractTermInDays;
    uint256 NTUTermInDays = 15 days;
    uint256 tariffNum;
    uint256 tariffCount; //insurance tariff = (tariffNum / tariffCount) - we split to 2 figures cause we use integers only
    
    //lists of contracts managers and etc
    ClaimManagersList claimManagersList;
    
    InsuranceContract[] insuranceContracts; //list of contracts
    ClaimFolder[] claimFolders; //list of claim folders
    Member[] members; //list of members
    
    uint constant numberOfClaimFolderManagers = 3; //constant number of managers to reconcile the applied claim
    
    uint256 reserve;
    uint256 adminFee;
    
    constructor (uint _minsum, uint _maxsum, uint _deposit, uint256 _tariffNum, uint256 _tariffCount, address _cmlist) public {
        require(_minsum > 0);
        require(_maxsum >= _minsum);
        //require(_deposit >= _minsum * _tariffNum / _tariffCount);
        //require(_deposit <= _maxsum * _tariffNum / _tariffCount);
        require(_tariffNum > 0);
        require(_tariffCount > 0);
        
        //simple check if claimmanagerslist exists as contract. should change by calling some spesific function
        uint size;
        assembly { size := extcodesize(_cmlist) }
        require(size > 0);
        
        minSumAssured = _minsum * 1 finney;
        maxSumAssured = _maxsum * 1 finney;
        claimDeposit = _deposit * (1 finney); //temp nominated in finney
        tariffNum = _tariffNum;
        tariffCount = _tariffCount;
        
        claimManagersList = ClaimManagersList(_cmlist);
        
    }
    
    //***
    
    /*
    //*** group of product specific functions
    function checkIfVinInsured(string _vin) private constant returns (bool _vinf) {
        _vinf = false;
        for (uint256 i = 0; i < insuranceContracts.length; i++) {
            if (insuranceContracts[i].VINhash == keccak256(_vin) 
                && insuranceContracts[i].status == InsuranceContractStatus.InForce) {
                _vinf = true;
                break;
            }
        }
    }
    
    function returnInsuranceContractByVinNum (string _vin) private constant returns (uint _insContractNum) {
        _insContractNum = 0; //zero means no contract have been found
        for (uint256 i = 0; i < insuranceContracts.length; i ++) {
            if (insuranceContracts[i].status == InsuranceContractStatus.InForce
                && insuranceContracts[i].VINhash == keccak256(_vin)) {
                _insContractNum = i + 1; //add 1 to distinct from zero
                break;
            }
        }
    }
    
    function returnInsuranceContractByOwnerNVinNum (address _add, string _vin) private constant returns (uint _insContractNum) {
        _insContractNum = 0; //zero means no contract have been found
        for (uint256 i = 0; i < insuranceContracts.length; i ++) {
            if (insuranceContracts[i].owner == _add 
                && insuranceContracts[i].status == InsuranceContractStatus.InForce
                && insuranceContracts[i].VINhash == keccak256(_vin)) {
                _insContractNum = i + 1; //add 1 to distinct from zero
                break;
            }
        }
    }
    
    ///***
    */
    
    //*** group of function to make and process claim
    
    function applyNewClaim (/*string _vin,*/ uint _claimAmount, string memory _claimURL /*,  uint _claimDate*/) public payable {
        
        uint256 _contractNum = returnActiveContractByAddressNum(msg.sender, now); //_claimDate //returnInsuranceContractByVinNum(_vin);
        require(_contractNum > 0);
        _contractNum--;
        require(msg.sender == insuranceContracts[_contractNum].owner);
        require(msg.value >= claimDeposit);
        uint256 l = claimManagersList.returnLengthOfList();
        
        //comment for immidiate test
        require(insuranceContracts[_contractNum].startDate + NTUTermInDays <= now); //accept claims only after NTUTermInDays
        
        //populate list of claimFolderManagers
        address[numberOfClaimFolderManagers] memory _managers;
        uint256 i = 0; //some variables for circles
        uint256 j;
        uint256 h; 
        bool alreadyIn = false; //if choosen manager already selected
        address _add;
        
        
        //make simple select if managers count == numberOfClaimFolderManagers?
        if (l <= numberOfClaimFolderManagers) {//if number of active managers less then nominal number for settlement
            for (i = 0; i < l; i++) {
                _managers[i] = claimManagersList.returnManagerAddress(i);
            }  
        }
        else
            while (_managers.length < numberOfClaimFolderManagers) {
                j = uint(blockhash(block.number-1-i))%l + 1;
                _add = claimManagersList.returnManagerAddress(j);
                for (h = 0; h < _managers.length; h++) {
                    if (_add == _managers[h]) {
                        alreadyIn = true;
                        break;
                    }
                }
                if (!alreadyIn) _managers[i] = _add;
                alreadyIn = false;
                i++;
            }
        
        
        adminFee += msg.value;
        
        claimFolders.push(ClaimFolder ({
            status: ClaimStatus.InProgress,
            claimURL: _claimURL,
            claimAmount: _claimAmount * 1 finney, //temp nominated in finney
            managers: _managers,
            //claimApplicationDate: now,
            claimDate: now, //_claimDate,
            votesPro: 0,
            votesContra: 0,
            amountToSettle: 0,
            //beneficiary: msg.sender,
            contractNum: _contractNum
        }));
        
    }
    
    function returnFirstUnsettledClaimFolderForManagerNum (address _add) private view returns (uint _firstClaimFolder) {
        _firstClaimFolder = 0; //zero means no folder have been found
        for (uint256 i = 0; i < claimFolders.length; i ++) {
            if (claimFolders[i].status == ClaimStatus.InProgress) {
                for (uint j = 0; j < claimFolders[i].managers.length; j++) {
                    if (claimFolders[i].managers[j] == _add) {
                        _firstClaimFolder = i + 1; //add 1 to distinct from zero
                        break;
                    }
                }
            }
            if (_firstClaimFolder > 0) break;
        }
    }
    
    function returnFirstAppliedClaimFolderURL () public view returns (string memory _url) {
        require(claimFolders.length > 0);
        uint256 _numClaimFolder = returnFirstUnsettledClaimFolderForManagerNum(msg.sender);
        require( _numClaimFolder > 0);
        _url = claimFolders[_numClaimFolder-1].claimURL; //minus 1 cause function returns number + 1 
    }
    
    function voteForClaimFolder (string memory _url, bool _vote) public {
        uint256 _numClaimFolder = returnFirstUnsettledClaimFolderForManagerNum(msg.sender);
        require(_numClaimFolder > 0); //non zero folder
        _numClaimFolder--; //reduce by 1 to return to "array" numeration
        require(keccak256(bytes(_url)) == keccak256(bytes(claimFolders[_numClaimFolder].claimURL))); //the same claimURL
        //require(claimFolders[_numClaimFolder].status == ClaimStatus.InProgress); //ClaimFolder not closed - alredy checked in return url function
        
        if (_vote) claimFolders[_numClaimFolder].votesPro++;
        else claimFolders[_numClaimFolder].votesContra++;
        
        /*
        for (uint i = 0; i < claimFolders[i].managers.length; i++) {
            if (claimFolders[_numClaimFolder].managers[i] == msg.sender) 
                delete claimFolders[_numClaimFolder].managers[i]; //delete manager after vote. but length remain the same? not working
        }
        */
        
        
        //check if 1/2 of total votes already pro or contra this claim and update status
        if (claimFolders[_numClaimFolder].votesPro * 2 >= claimFolders[_numClaimFolder].managers.length) {
            claimFolders[_numClaimFolder].status = ClaimStatus.Accepted;
            uint _claimAmount = claimFolders[_numClaimFolder].claimAmount;
            address _add = insuranceContracts[claimFolders[_numClaimFolder].contractNum].owner;
            claimFolders[_numClaimFolder].amountToSettle = collectSumFromReserves(_claimAmount, _add);
            //claimManagersList.updateCountOfPassedClaimsByManager(keccak256(msg.sender), uint(ClaimStatus.Accepted));
        }
        if (claimFolders[_numClaimFolder].votesContra * 2 > claimFolders[_numClaimFolder].managers.length) {
            claimFolders[_numClaimFolder].status = ClaimStatus.Rejected;
            //claimManagersList.updateCountOfPassedClaimsByManager(keccak256(msg.sender), uint(ClaimStatus.Rejected));
        }
    }
    
    function collectSumFromReserves(uint _claimAmount, address _add) private returns (uint256 _amountToTransfer) {
        _amountToTransfer = 0;
        
        uint256 _amount;
        uint fineX = 4; //aditional multiplyer for claimant and it's parent
        uint _tmpFineX = 1;
        uint256 i = members.length; //for circle
        uint256 j; //for circle 2
        uint256 l = members.length; // fixed uint256 for faster calculation (?)
        while (_amountToTransfer < _claimAmount || i > 0) {//from last member to first
            j = i - 1; //convert to array numeration
            if (members[j].memberAddress == _add ) { //claimant or parent
                _tmpFineX = fineX;
                fineX--; //fine for parent
                if(fineX == 0) fineX = 1; //no less then 1
                _add = members[j].parentAddress;
            }
            else _tmpFineX = 1; //standart multiplyer
            if (members[j].reserve > 0) {
                //from every member we take 1 of (members.length * (tariffNum / tariffCount)) part from reserve
                if (members[j].reserve * _tmpFineX / l / tariffNum * tariffCount > (_claimAmount - _amountToTransfer))
                    _amount = _claimAmount - _amountToTransfer;
                else _amount = members[j].reserve * _tmpFineX / l / tariffNum * tariffCount;
                members[j].reserve -= _amount;
                _amountToTransfer += _amount;
            }
            i--; //next member
        }   
        
        return _amountToTransfer;
    }
    
    function returnFirstSettledNUnpaidClaimFolderNum (address _add) private view returns (uint _firstClaimFolder) {
        _firstClaimFolder = 0; //zero means no folder have been found
        for (uint256 i = 0; i < claimFolders.length; i ++) {
            if (claimFolders[i].status == ClaimStatus.Accepted && claimFolders[i].amountToSettle > 0
                && insuranceContracts[claimFolders[i].contractNum].owner == _add) {
                _firstClaimFolder = i + 1; //add 1 to distinct from zero
                break;
            }    
        }
    }
    
    function withdrawClaimSettlement() public {
        uint256 _numClaimFolder = returnFirstSettledNUnpaidClaimFolderNum(msg.sender);
        require( _numClaimFolder > 0); //non zero folder
        _numClaimFolder--; //reduce by 1 to return to "array" numeration
        uint _amountToTransfer = claimFolders[_numClaimFolder].amountToSettle;
        claimFolders[_numClaimFolder].amountToSettle = 0;
        makeWithdrawFromReserve(msg.sender, _amountToTransfer);
    }
    
    //***
    
    //*** group of function to conclude InsuranceContract
    function makeWithdrawFromReserve(address payable _add, uint _amountToTransfer) private {
        if (_amountToTransfer > reserve) _amountToTransfer = reserve;
        reserve -= _amountToTransfer;
        _add.transfer(_amountToTransfer); //_amountToTransfer
    }
    
    function withdrawContractByNTU () public {
        uint256 _contractNum = returnActiveContractByAddressNum(msg.sender, now);
        require( _contractNum > 0); //non zero folder
        _contractNum--; //reduce by 1 to return to "array" numeration
        
        require(insuranceContracts[_contractNum].startDate + NTUTermInDays > now);
        uint _amountToTransfer = insuranceContracts[_contractNum].premium;
        
        uint256 _memberNum = returnMemberByAddressNum(msg.sender);
        require( _memberNum > 0); //non zero folder
        _memberNum--; //reduce by 1 to return to "array" numeration
        if (_amountToTransfer > members[_memberNum].reserve) _amountToTransfer = members[_memberNum].reserve;
        members[_memberNum].reserve -= _amountToTransfer;
        insuranceContracts[_contractNum].status = InsuranceContractStatus.NTU;
        
        makeWithdrawFromReserve(msg.sender, _amountToTransfer);
        
        //return true;
    }
    
    function returnMemberByAddressNum (address _add) private view returns (uint256 _num) {
        _num = 0; //zero means no member have been found
        for (uint256 i = 0; i < members.length; i++)
            if (members[i].memberAddress == _add) {
                _num = i + 1;
                break;
            }
    }
    
    function returnActiveContractByAddressNum (address _add, uint _date) private view returns (uint256 _num) {
        _num = 0; //zero means no member have been found
        for (uint256 i = 0; i < insuranceContracts.length; i++)
            if (insuranceContracts[i].owner == _add 
                && insuranceContracts[i].status == InsuranceContractStatus.InForce
                && insuranceContracts[i].startDate <= _date
                && insuranceContracts[i].startDate + 365 days > _date
                ) {
                _num = i + 1;
                break;
            }
    }
    
    function buyContract (/*string _vin,*/ address _parentadd) public payable {
        uint _sumAssured = msg.value * tariffCount / tariffNum; //back calculating the sumAssured
        require(_sumAssured <= maxSumAssured);
        require(_sumAssured >= minSumAssured);
        
        //require(!checkIfVinInsured(_vin)); //only 1 contract for 1 member
        uint256 _contractNum = returnActiveContractByAddressNum(msg.sender, now);
        require(_contractNum == 0);
        
        //create member if needed
        uint256 _memberNum =  returnMemberByAddressNum(msg.sender);
        if (_memberNum > 0) {
            members[_memberNum-1].reserve += msg.value; //minus 1 cause function returns number + 1 
        }
        else { //create new member
            //require(returnMemberByAddressNum(_parentadd) > 0); //parentAddress should be a member
            members.push(Member({
                memberAddress: msg.sender,
                parentAddress: _parentadd,
                reserve: msg.value
            }));
        }
        
        insuranceContracts.push(InsuranceContract ({
            //VINhash: keccak256(_vin),
            
            status: InsuranceContractStatus.InForce,
            startDate: now,
            sumAssured: _sumAssured,
            premium: msg.value,
            //reserve: msg.value,
            profitShareSum: 0,
            owner: msg.sender
        }));
        
        reserve += msg.value; //increase total reserve
    }
    
    function returnNumberOfContracts() public view returns (uint256) {
        return insuranceContracts.length;
    }
    
    function returnNumberOfClaims() public view returns (uint256) {
        return insuranceContracts.length;
    }
    
    function returnStatusOfClaimNum(uint _numClaimFolder) public view returns (uint) {
        return uint(claimFolders[_numClaimFolder].status);
    }
    
    function returnStartDateOfCurrentContract () public view returns (uint256) {
        uint256 _contractNum = returnActiveContractByAddressNum(msg.sender, now);
        require(_contractNum > 0);
        _contractNum--; //reduce by 1 to return to "array" numeration
        
        return insuranceContracts[_contractNum].startDate;
    }
    
    //***
}
