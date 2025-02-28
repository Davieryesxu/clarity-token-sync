import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new token with metadata",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const metadata = "Test Token";
    
    let block = chain.mineBlock([
      Tx.contractCall("token-sync", "register-token", 
        [types.uint(1), types.some(types.ascii(metadata))], 
        deployer.address
      )
    ]);
    assertEquals(block.receipts[0].result.expectOk(), true);
  },
});

Clarinet.test({
  name: "Ensure contract pause prevents operations",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("token-sync", "set-contract-pause", [types.bool(true)], deployer.address),
      Tx.contractCall("token-sync", "register-token", [types.uint(1), types.none()], deployer.address)
    ]);
    
    block.receipts[1].result.expectErr(104); // contract-paused
  },
});
