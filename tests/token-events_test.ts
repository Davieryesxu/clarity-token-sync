import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can log events",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;

    let block = chain.mineBlock([
      Tx.contractCall("token-sync", "register-token", [types.uint(1)], deployer.address),
      Tx.contractCall("token-events", "log-sync-event", 
        [types.uint(1), types.uint(0), types.uint(5)], 
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[1].result.expectOk(), types.uint(0));
  },
});
