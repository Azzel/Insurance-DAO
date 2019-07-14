# DSURE
## Insurance DAO prototype
This is the code for ethereum smart contract to realize Insurance DAO. Code accompanied by truffle test scripts.
DSURE DAO based on the p2p principle - all premiums are pooled together to cover claims declared by its member.
Also, profit share is implied but not realized yet - after the end of the contract premium left could be withdrawn.

File's list:
### ClaimManagersList.sol
This smart contract is designed to organize a group of people who can represent managers to review and make a decision to accept or reject a claim.
Contract initiated with 1 manager as owner. There is a public function to propose a new member to list. To prevent the spam the function is payable with a small fee.
Current managers can review the new proposed manager and vote to accept or reject him/her.
### ClaimManagersListTest.js
Java script for Truffle to TDD of contract
### SelfInsuranceDao.sol
Main smart contract of insurance DAO. The contract contains the next arrays:
- InsuranceContract - each represents the insurance contract itself;
- Member - policyholders;
- ClaimFolder - each represents is a claim declared

Also contract have some main parameters:
- claimdeposit - the amount of fee for all main activities;
- tariffNum and tariffCount - to save insurance tariff = (tariffNum / tariffCount);
- NTUtermInDays;
- numberOfClaimFolderManagers

The scenario of using DAO:
- buyContract - pay the premium and make a new insurance contract. To by contract, the parent member should be provided, but this is deprecated for now. In a more detailed realization, some ID should be provided. All premiums are collected on the contract's reserve pool;
- withdrawContractByNTU - function to cancel the contract and return full premium on NTU (not taken up - in cooling period);
- applyNewClaim - function to declare claim. Outer URL with full details on a claim should be provided. URL also used as a claim ID. Supposed that declarant uploads all data about a claim on this URL for claim managers.
During the creation of the folder function chooses by a random set of managers from ClaimManagersList assigns to claim. To prevent spam in applied claims function is payable with small fee accumulated in admin fee pool.
- returnFirstAppliedClaimFolderURL - claim manager could retrieve the URL of first assigned to him/her claim folder to operate with. 
- voteForClaimFolder - after consideration of claim applied claim manager should make a decision and accept or reject a claim. The total decision on claims made on 1/2 of claims managers. Supposed that some amount from the administration fee pool could be paid to managers who participated in the decision.
- withdrawClaimSettlement - in case of a positive decision on his/her claim the declarant could retrieve claim amount from the contract.

### SelfInsuranceDaoTest.js
Java script for Truffle to TDD of the contract with the realization of the main test scenario

## todo
- retrieve profit share function;
- remake collection of the claim amount from the reserve;
- make a variation for a more specific insurance product;
- optimize the function for gas consumption
