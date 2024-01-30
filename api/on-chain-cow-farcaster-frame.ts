// Two very important environment variables to set that you MUST set in Vercel:
// - SYNDICATE_API_KEY: The API key for your Syndicate project. If you're on the
// demo plan, DM @Will on Farcaster/@WillPapper on Twitter to get upgraded.
// - NEYNAR_API_KEY: The API key for your Neynar project. Without this,
// addresses won't be able to be extracted from FIDs for minting
import { VercelRequest, VercelResponse } from "@vercel/node";
import { SyndicateClient } from "@syndicateio/syndicate-node";
import { createPublicClient, http } from "viem";
import { baseSepolia, mainnet } from "viem/chains";

const erc721Address = "0xBeFD018F3864F5BBdE665D6dc553e012076A5d44";
const erc721Abi = [
  {
    inputs: [{ name: "owner", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];

const syndicate = new SyndicateClient({
  token: () => {
    const apiKey = process.env.SYNDICATE_API_KEY;
    if (typeof apiKey === "undefined") {
      // If you receive this error, you need to define the SYNDICATE_API_KEY in
      // your Vercel environment variables. You can find the API key in your
      // Syndicate project settings under the "API Keys" tab.
      throw new Error(
        "SYNDICATE_API_KEY is not defined in environment variables."
      );
    }
    return apiKey;
  },
});

const client = createPublicClient({
  chain: baseSepolia,
  transport: http(process.env.ALCHEMY_BASE_SEPOLIA_API_KEY),
});

export default async function (req: VercelRequest, res: VercelResponse) {
  const balanceTest = await getBalance(
    "0x3Cbd57dA2F08b3268da07E5C9038C11861828637"
  );
  console.log("Balance test: ", balanceTest);
  // Farcaster Frames will send a POST request to this endpoint when the user
  // clicks the button. If we receive a POST request, we can assume that we're
  // responding to a Farcaster Frame button click.
  if (req.method == "POST") {
    try {
      console.log("req.body", req.body);
      // A full version of this would have auth, but we're not dealing with any
      // sensitive data or funds here. If you'd like, you could validate the
      // Farcaster signature here
      const fid = req.body.untrustedData.fid;
      const addressFromFid = await getAddrByFid(fid);
      console.log(
        "Extracted address from FID passed to Syndicate: ",
        addressFromFid
      );
      // Mint the On-Chain Cow NFT. We're not passing in any arguments, since the
      // amount will always be 1
      const mintTx = await syndicate.transact.sendTransaction({
        projectId: "abcab73a-55d2-4441-a93e-edf95d183b34",
        contractAddress: "0xBeFD018F3864F5BBdE665D6dc553e012076A5d44",
        chainId: 84532,
        functionSignature: "mint(address to)",
        args: {
          // TODO: Change to the user's connected Farcaster address. This is going
          // to WillPapper.eth for now
          to: addressFromFid,
        },
      });
      console.log("Syndicate Transaction ID: ", mintTx.transactionId);

      // Get the current count of On-Chain Cows minted
      let balance = await getBalance(addressFromFid);

      if (balance == "0" || balance == undefined) {
        res.status(200).setHeader("Content-Type", "text/html").send(`
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width" />
            <meta property="og:title" content="On-Chain Cow!" />
            <meta
              property="og:image"
              content="https://on-chain-cow-farcaster-frame.vercel.app/img/on-chain-cow-happy-cow.png"
            />
            <meta property="fc:frame" content="vNext" />
            <meta
              property="fc:frame:image"
              content="https://on-chain-cow-farcaster-frame.vercel.app/img/on-chain-cow-happy-cow.png"
            />
            <meta
              property="fc:frame:button:1"
              content="Grow your on-chain pasture! Mint MORE COWS!"
            />
            <meta
              name="fc:frame:post_url"
              content="https://on-chain-cow-farcaster-frame.vercel.app/api/on-chain-cow-farcaster-frame"
            />
          </head>
        </html>
    `);
      } else {
        res.status(200).setHeader("Content-Type", "text/html").send(`
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width" />
            <meta property="og:title" content="On-Chain Cow!" />
            <meta
              property="og:image"
              content="https://on-chain-cow-farcaster-frame.vercel.app/img/on-chain-cow-happy-cow.png"
            />
            <meta property="fc:frame" content="vNext" />
            <meta
              property="fc:frame:image"
              content="https://on-chain-cow-farcaster-frame.vercel.app/img/on-chain-cow-happy-cow.png"
            />
            <meta
              property="fc:frame:button:1"
              content="${balance} cows in your pasture with more on the way! Mint MORE COWS!"
            />
            <meta
              name="fc:frame:post_url"
              content="https://on-chain-cow-farcaster-frame.vercel.app/api/on-chain-cow-farcaster-frame"
            />
          </head>
        </html>
      `);
      }
    } catch (error) {
      res.status(500).send(`Error: ${error.message}`);
    }
  } else {
    // If the request is not a POST, we know that we're not dealing with a
    // Farcaster Frame button click. Therefore, we should send the Farcaster Frame
    // content
    res.status(200).setHeader("Content-Type", "text/html").send(`
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width" />
        <meta property="og:title" content="On-Chain Cow!" />
        <meta
          property="og:image"
          content="https://on-chain-cow-farcaster-frame.vercel.app/img/on-chain-cow-neutral-cow.png"
        />
        <meta property="fc:frame" content="vNext" />
        <meta
          property="fc:frame:image"
          content="https://on-chain-cow-farcaster-frame.vercel.app/img/on-chain-cow-neutral-cow.png"
        />
        <meta property="fc:frame:button:1" content="How many On-Chain Cows can you mint?" />
        <meta
          name="fc:frame:post_url"
          content="https://on-chain-cow-farcaster-frame.vercel.app/api/on-chain-cow-farcaster-frame"
        />
      </head>
    </html>
    `);
  }
}

// Based on https://github.com/coinbase/build-onchain-apps/blob/b0afac264799caa2f64d437125940aa674bf20a2/template/app/api/frame/route.ts#L13
async function getAddrByFid(fid: number) {
  console.log("Extracting address for FID: ", fid);
  const options = {
    method: "GET",
    url: `https://api.neynar.com/v2/farcaster/user/bulk?fids=${fid}`,
    headers: {
      accept: "application/json",
      api_key: process.env.NEYNAR_API_KEY || "",
    },
  };
  console.log("Fetching user address from Neynar API");
  const resp = await fetch(options.url, { headers: options.headers });
  console.log("Response: ", resp);
  const responseBody = await resp.json(); // Parse the response body as JSON
  if (responseBody.users) {
    const userVerifications = responseBody.users[0];
    if (userVerifications.verifications) {
      console.log(
        "User address from Neynar API: ",
        userVerifications.verifications[0]
      );
      return userVerifications.verifications[0].toString();
    }
  }
  console.log("Could not fetch user address from Neynar API for FID: ", fid);
  return "0x0000000000000000000000000000000000000000";
}

async function getBalance(address: string) {
  let balance;
  try {
    balance = await client.readContract({
      address: erc721Address,
      abi: erc721Abi,
      functionName: "balanceOf",
      args: [address],
    });
  } catch {
    console.log("Could not get balance for address: ", address);
  }
  // Convert from bigint to a Number and then to a string to avoid "178n" with n
  // being appended to balances
  // This is safe given that the balance will not exceed the max size of a
  // Javascript number
  return Number(balance).toString();
}
