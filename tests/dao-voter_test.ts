import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensures that proposals can be created and retrieved",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        let block = chain.mineBlock([
            Tx.contractCall('dao-voter', 'create-proposal', [
                types.utf8("Test Proposal"),
                types.utf8("This is a test proposal"),
                types.uint(100)
            ], deployer.address)
        ]);
        block.receipts[0].result.expectOk().expectUint(0);
        
        let getProposal = chain.mineBlock([
            Tx.contractCall('dao-voter', 'get-proposal', [types.uint(0)], deployer.address)
        ]);
        getProposal.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Ensures voting works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Create proposal
        let block = chain.mineBlock([
            Tx.contractCall('dao-voter', 'create-proposal', [
                types.utf8("Test Proposal"),
                types.utf8("This is a test proposal"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Vote on proposal
        let voteBlock = chain.mineBlock([
            Tx.contractCall('dao-voter', 'cast-vote', [
                types.uint(0),
                types.bool(true)
            ], wallet1.address)
        ]);
        voteBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Check if voted
        let checkVote = chain.mineBlock([
            Tx.contractCall('dao-voter', 'has-voted', [
                types.uint(0),
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        checkVote.receipts[0].result.expectOk().expectBool(true);
    }
});
