const { increaseTime } = require("./utils");
const ClaimManagersList = artifacts.require("./ClaimManagersList.sol");
const SelfInsuranceDao = artifacts.require("./SelfInsuranceDao.sol");

const FINNEY = 10**15;
const DAY = 3600 * 24;

contract("InsuranceDAO", accounts => {
    const [firstAccount, secondAccount, thirdAccount] = accounts;
    
    var managersList;
    var manager1Url = "secondAccountUrl";
    var manager2Url = "thirdAccountUrl";
    
    var claimUrl1 = "claimOneUrl";
    var claimUrl2 = "claimTwoUrl";
    
    var insuranceDao;
    var minSumAssured = 1;
    var maxSumAssured = 100;
    var claimDeposit = 1;
    //uint256 NTUTermInDays = 14;
    var tariffNum = 1;
    var tariffCount = 100; //insurance tariff = (tariffNum / tariffCount) - so we set it = 1%
    
    before(async () => {
        managersList = await ClaimManagersList.new(claimDeposit);
        insuranceDao = await SelfInsuranceDao.new(minSumAssured, maxSumAssured,
            claimDeposit, tariffNum, tariffCount, managersList.address);
    });
    
    describe("create new Insurance DAO", function() {
        
        it("create inicial list of 3 managers (detailes tests are in ClaimManagersListTest.js)", async () => {
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
            await managersList.proposeNewManager(manager1Url, secondAccount, { from: firstAccount, value: claimDeposit * FINNEY });
            await managersList.voteForProposedManager(manager1Url, true, { from: firstAccount});
            await managersList.proposeNewManager(manager2Url, thirdAccount, { from: firstAccount, value: claimDeposit * FINNEY });
            await managersList.voteForProposedManager(manager2Url, true, { from: firstAccount});
            //await managersList.voteForProposedManager(manager2Url, true, { from: secondAccount});
            
            assert.equal(await managersList.returnLengthOfList(), 3, "after (2) promotion the number of claim managers should be 3");
            assert.equal(await managersList.returnManagerAddress(0), firstAccount, "the manager (0) should be firstAccount");
            assert.equal(await managersList.returnManagerAddress(1), secondAccount, "the manager (1) should be secondAccount");
            assert.equal(await managersList.returnManagerAddress(2), thirdAccount, "the manager (2) should be thirdAccount");
        });
        
        it("create new InsuranceDAO", async () => {
            assert.equal(await insuranceDao.returnNumberOfContracts(), 0, "new DAO should have 0 contracts");
        });
    
    });
    
    describe("'new business' process", function() {
    
        it("buy new contract", async () => {
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
            await insuranceDao.buyContract(secondAccount, { from: firstAccount, value: claimDeposit * FINNEY });
            assert.equal(await insuranceDao.returnNumberOfContracts(), 1, "after buy 1 contract count should = 1");
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
        });
    
        it("NTU contract", async () => {
            
            const initBalance = await web3.eth.getBalance(firstAccount);
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
            
            await insuranceDao.withdrawContractByNTU({ from: firstAccount });
            
            const finalBalance = await web3.eth.getBalance(firstAccount);
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
            
            assert.ok(web3.utils.fromWei(finalBalance, "ether") > web3.utils.fromWei(initBalance, "ether"), "after NTU-refund balance should be greater");
        });
        
        it("buy new contract again", async () => {
            await insuranceDao.buyContract(secondAccount, { from: firstAccount, value: claimDeposit * FINNEY});
            assert.equal(await insuranceDao.returnNumberOfContracts(), 2, "after buy 2nd contract again count should = 2");
        });
        
        it("try to buy second contract should fail", async () => {
            try {
                await insuranceDao.buyContract(secondAccount, { from: firstAccount, value: claimDeposit * FINNEY });
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
        
        it("try to NTU contract after NTU date should fail", async () => {
            await increaseTime(15*DAY);
            try {
                await insuranceDao.withdrawContractByNTU({ from: firstAccount });
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
        
        it("renewal of the contract (after first ended)", async () => {
            await increaseTime(351*DAY);
            await insuranceDao.buyContract(secondAccount, { from: firstAccount, value: claimDeposit * FINNEY });
            assert.equal(await insuranceDao.returnNumberOfContracts(), 3, "after renewal contract count should = 3");
        });
    
    });
    
    describe("apply new claim process", function() {
    
        it("apply new claim", async () => {
            await increaseTime(20 * DAY);
            //const startDate = await insuranceDao.returnStartDateOfCurrentContract({ from: firstAccount });
            //console.log(startDate);
            //console.log(startDate + 20 * DAY);
            await insuranceDao.applyNewClaim(10 * claimDeposit, claimUrl1, /*20 * DAY,*/ { from: firstAccount, value: claimDeposit * FINNEY });
            assert.equal(await insuranceDao.returnFirstAppliedClaimFolderURL({ from: firstAccount }), claimUrl1, "after apply first usettled claim url firstAccount ok");
            assert.equal(await insuranceDao.returnFirstAppliedClaimFolderURL({ from: secondAccount }), claimUrl1, "after apply first usettled claim url secondAccount ok");
            assert.equal(await insuranceDao.returnStatusOfClaimNum(0), 2, "after apply #0 claim its status = 2 (InProgress)");
        });
    
        it("reject claim", async () => {
            await insuranceDao.voteForClaimFolder(claimUrl1, false, { from: firstAccount});
            await insuranceDao.voteForClaimFolder(claimUrl1, false, { from: secondAccount});
            assert.equal(await insuranceDao.returnStatusOfClaimNum(0), 1, "after reject #0 claim its status = Rejected (1)");
        });
        
        it("apply new claim (again)", async () => {
            //await increaseTime(20 * DAY);
            await insuranceDao.applyNewClaim(10 * claimDeposit, claimUrl2, /*20 * DAY,*/ { from: firstAccount, value: claimDeposit * FINNEY });
            assert.equal(await insuranceDao.returnFirstAppliedClaimFolderURL({ from: firstAccount }), claimUrl2, "after apply first usettled claim url firstAccount ok");
            assert.equal(await insuranceDao.returnFirstAppliedClaimFolderURL({ from: secondAccount }), claimUrl2, "after apply first usettled claim url secondAccount ok");
            assert.equal(await insuranceDao.returnStatusOfClaimNum(1), 2, "after apply #1 claim its status = 2 (InProgress)");
        });
        
        it("approve the claim", async () => {
            await insuranceDao.voteForClaimFolder(claimUrl2, true, { from: firstAccount});
            await insuranceDao.voteForClaimFolder(claimUrl2, true, { from: secondAccount});
            assert.equal(await insuranceDao.returnStatusOfClaimNum(0), 1, "after accept #1 claim its status = 0 (Accepted)");
        });
        
        it("get refund for claim", async () => {
            const initBalance = await web3.eth.getBalance(firstAccount);
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
            
            await insuranceDao.withdrawClaimSettlement({ from: firstAccount });
            
            const finalBalance = await web3.eth.getBalance(firstAccount);
            console.log(web3.utils.fromWei(await web3.eth.getBalance(firstAccount), "finney"));
            
            assert.ok(web3.utils.fromWei(finalBalance, "ether") > web3.utils.fromWei(initBalance, "ether"), "after claim refund balance should be greater");
        });
    
    });
    
    describe("post pool process", function() {
    
        it("get profit share");
    
    });
    
});
