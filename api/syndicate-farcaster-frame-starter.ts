// Two very important environment variables to set that you MUST set in Vercel:
// - SYNDICATE_FRAME_API_KEY: The API key that you received for frame.syndicate.io.
// DM @Will on Farcaster/@WillPapper on Twitter to get an API key.
import { VercelRequest, VercelResponse } from "@vercel/node";
import { SyndicateClient } from "@syndicateio/syndicate-node";
import { createPublicClient, http } from "viem";
import { baseSepolia, mainnet } from "viem/chains";

export default async function (req: VercelRequest, res: VercelResponse) {
  // Farcaster Frames will send a POST request to this endpoint when the user
  // clicks the button. If we receive a POST request, we can assume that we're
  // responding to a Farcaster Frame button click.
  if (req.method == "POST") {
    try {
      // Once your contract is registered, you can mint an NFT using the following code
      const res = await fetch('https://frame.syndicate.io/api/mint', {
        method: "POST",
        headers: {
          "content-type": "application/json",
          Authorization: "Bearer <your-api-key>"
        }
        body: JSON.stringify({
          frameTrustedData: "req.body.frameTrustedData.messageBytes",
        })
      });

      res.status(200).setHeader("Content-Type", "text/html").send(`
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width" />
            <meta property="og:title" content="You've minted your commemorative NFT for Syndicate's Frame API!" />
            <meta
              property="og:image"
              content="https://syndicate-farcaster-frame-starter.vercel.app/img/example-frame-farcaster-cropped.png"
            />
            <meta property="fc:frame" content="vNext" />
            <meta
              property="fc:frame:image"
              content="https://syndicate-farcaster-frame-starter.vercel.app/img/example-frame-farcaster-cropped.png"
            />
            <meta
              property="fc:frame:button:1"
              content="You've minted your frame.syndicate.io commemorative NFT!"
            />
          </head>
        </html>
      `);
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
        <meta property="og:title" content="Mint your commemorative NFT for Syndicate's Frame API!" />
        <meta
          property="og:image"
          content="https://syndicate-farcaster-frame-starter.vercel.app/img/example-frame-farcaster-cropped.png"
        />
        <meta property="fc:frame" content="vNext" />
        <meta
          property="fc:frame:image"
          content="https://syndicate-farcaster-frame-starter.vercel.app/img/example-frame-farcaster-cropped.png"
        />
        <meta property="fc:frame:button:1" content="Mint your commemorative NFT for the launch of frame.syndicate.io!" />
        <meta
          name="fc:frame:post_url"
          content="https://syndicate-farcaster-frame-starter.vercel.app/api/syndicate-farcaster-frame-starter"
        />
      </head>
    </html>
    `);
  }
}