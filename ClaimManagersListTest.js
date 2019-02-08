const ClaimManagersList = artifacts.require("./ClaimManagersList.sol");

const FINNEY = 10**15;

contract("ClaimManagersList", accounts => {
    const [firstAccount, secondAccount, thirdAccount] = accounts;
    
    var manager1Url = "secondAccountUrl";
    var manager2Url = "thirdAccountUrl";
    
    var managersList;
    
    before(async () => {
        managersList = await ClaimManagersList.new(2);
    });
    
    describe("test straight cases", function() {
        
        //according to create list in before section
        it("new created list should consist of 1 manager", async () => {
            assert.equal(await managersList.returnLengthOfList(), 1, "after creation number of managers should be 1");
            assert.equal(await managersList.returnManagerAddress(0), firstAccount, "after creation 1st manager = firstAccount");
            assert.equal(await managersList.returnLengthOfProposedList(), 0, "after creation number of proposed managers should be 0");
        });
        
        it("propose 2nd manager", async () => {
            await managersList.proposeNewManager(manager1Url, secondAccount, { from: firstAccount, value: 2 * FINNEY });
            assert.equal(await managersList.returnLengthOfProposedList(), 1, "after proposion of 2nd manager number in proposed list should be 1");
        });
        
        it("promote 2nd manager", async () => {
            await managersList.voteForProposedManager(manager1Url, true, { from: firstAccount});
            assert.equal(await managersList.returnLengthOfProposedList(), 0, "after promotion of 2nd manager number of proposed list = 0");
            assert.equal(await managersList.returnLengthOfList(), 2, "after promotion number of claim managers should be 2");
            assert.equal(await managersList.returnManagerAddress(1), secondAccount, "the new manager should be last promoted manager");
        });
        
        it("propose 3rd manager", async () => {
            await managersList.proposeNewManager(manager2Url, thirdAccount, { from: firstAccount, value: 2 * FINNEY });
            assert.equal(await managersList.returnLengthOfProposedList(), 1, "after proposion of 3rd manager number in proposed list should be 1");
        });
        
        it("reject 3rd manager", async () => {
            await managersList.voteForProposedManager(manager2Url, false, { from: firstAccount});
            await managersList.voteForProposedManager(manager2Url, false, { from: secondAccount});
            assert.equal(await managersList.returnLengthOfProposedList(), 0, "after rejection number of proposed managers should be 0");
            assert.equal(await managersList.returnLengthOfList(), 2, "after rejection number of claim managers should stay 2");
        });
        
        it("propose 3rd manager (again)", async () => {
            await managersList.proposeNewManager(manager2Url, thirdAccount, { from: firstAccount, value: 2 * FINNEY });
            assert.equal(await managersList.returnLengthOfProposedList(), 1, "after proposion of 3rd manager number in proposed list should be 1");
        });
        
    
    });
    
    describe("test error cases (but not only)", function() {
    
        it("propose manager with fee less then deposit should fail", async () => {
            try {
                await managersList.proposeNewManager(manager2Url, thirdAccount, { from: firstAccount, value: 1 * FINNEY });
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
        
        it("propose manager already at active manager should fail", async () => {
            try {
                await managersList.proposeNewManager(manager1Url, secondAccount, { from: firstAccount, value: 2 * FINNEY });
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
    
        it("promote 3rd manager with wrong url should fail", async () => {
            try {
                await managersList.voteForProposedManager(manager1Url, true, { from: secondAccount});
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
        
        it("double proposion of 3rd manager should fail", async () => {
            try {
                await managersList.voteForProposedManager(manager1Url, true, { from: secondAccount});
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
        
        it("try to vote for proposed manager from non manager should fail", async () => {
            //await managersList.proposeNewManager(manager2Url, thirdAccount, { from: firstAccount, value: 1 * FINNEY });
            try {
                await managersList.voteForProposedManager(manager2Url, true, { from: thirdAccount});
                assert.fail();
            } catch (err) {
                assert.ok(/revert/.test(err.message));
            }
        });
        
        it("promote 3rd manager (at last)", async () => {
            assert.equal(await managersList.returnLengthOfProposedList(), 1, "before propose 3rd number in list = 1");
            await managersList.voteForProposedManager(manager2Url, true, { from: firstAccount});
            
            //second vote not neseccary - 1/2 enouth. is it ok?
            //await managersList.voteForProposedManager(manager2Url, true, { from: secondAccount});
            
            assert.equal(await managersList.returnLengthOfProposedList(), 0, "after promotion of 3rd number of proposed managers should be 0");
            assert.equal(await managersList.returnLengthOfList(), 3, "after promotion of 3rd  number of claim managers should be 3");
        });
    
    });
    
});