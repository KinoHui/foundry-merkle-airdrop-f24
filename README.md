## 📚 Table of Contents

- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Pre-deploy: Generate merkle proofs](#pre-deploy-generate-merkle-proofs)
- [Deploy](#deploy)
  - [Deploy to Anvil](#deploy-to-anvil)
  - [Deploy to a zkSync local node](#deploy-to-a-zksync-local-node)
    - [zkSync prerequisites](#zksync-prerequisites)
    - [Setup local zkSync node](#setup-local-zksync-node)
    - [Deploy to a local zkSync network](#deploy-to-a-local-zksync-network)
    - [Deploy to zkSync Sepolia](#deploy-to-zksync-sepolia)
  - [Interacting - zkSync local network](#interacting---zksync-local-network)
    - [Setup local zkSync node, deploy contracts, and run airdrop claim](#setup-local-zksync-node-deploy-contracts-and-run-airdrop-claim)
  - [Interacting - Local Anvil network](#interacting---local-anvil-network)
    - [Setup Anvil and deploy contracts](#setup-anvil-and-deploy-contracts)
    - [Sign your airdrop claim](#sign-your-airdrop-claim)
    - [Claim your airdrop](#claim-your-airdrop)
    - [Check claim amount](#check-claim-amount)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)
- [Thank you!](#thank-you)

## 🚀 Getting Started

### Requirements

Before we dive in, let’s make sure you have everything you need to get started:

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) 
  - You’ll know you did it right if you can run `git --version` and see something like `git version x.x.x`.
- [foundry](https://getfoundry.sh/) 
  - You’ll know it’s working if you can run `forge --version` and it responds with `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`.

For our adventure, we’ll be using **vanilla Foundry** and not **foundry-zksync** to start.

### Quickstart

Ready to get going? Just follow these simple steps:

```bash
git clone https://github.com/ciara/merkle-airdrop
cd merkle-airdrop
make # or run forge install && forge build if you don't have make
```

## 🛠️ Usage

### Pre-deploy: Generate Merkle Proofs

We’ll be generating Merkle proofs for a list of addresses to airdrop funds to. If you’d like to stick with the default addresses already set up in this repo, feel free to jump ahead to [deploy](#deploy)!

If you want to work with your own addresses (check out the `whitelist` list in `GenerateInput.s.sol`), here’s how to do that:

First, update the array of addresses in `GenerateInput.s.sol`. Next, generate the input file, the Merkle root, and the proofs by running:

Using make:

```bash
make merkle
```

Or if you prefer running commands directly:

```bash
forge script script/GenerateInput.s.sol:GenerateInput && forge script script/MakeMerkle.s.sol:MakeMerkle
```

After that, grab the `root` from `script/target/output.json` (you might see more than one, but they’ll all be the same) and paste it into the `Makefile` as `ROOT` for zkSync deployments. Also, update `s_merkleRoot` in `DeployMerkleAirdrop.s.sol` for Ethereum/Anvil deployments.

## 🚀 Deploy

### Deploy to Anvil

Let’s get your smart contracts deployed to Anvil! Just follow these steps:

```bash
# Optional: Ensure you're on vanilla Foundry
foundryup
# Run a local Anvil node
make anvil
# Then, in a second terminal
make deploy
```

### Deploy to a zkSync Local Node

If you're interested in deploying to a zkSync local node, here’s how to set it up:

#### zkSync Prerequisites

Before we proceed, make sure you have everything set up:

- [foundry-zksync](https://github.com/matter-labs/foundry-zksync)
  - You’ll know it’s installed correctly if you can run `forge --version` and see something like `forge 0.0.2 (816e00b 2023-03-16T00:05:26.396218Z)`.
- [npx & npm](https://docs.npmjs.com/cli/v10/commands/npm-install)
  - You’ll know it’s ready if you can run `npm --version` and `npx --version` and see versions like `7.24.0` and `8.1.0`.
- [docker](https://docs.docker.com/engine/install/)
  - You’ll know Docker is up and running if you can run `docker --version` and see something like `Docker version 20.10.7, build f0df350`. Check that the daemon is running with:
  
```bash
docker --info
```

You should see an output that confirms the client is working.

#### Setup Local zkSync Node

Now, let’s set up your local zkSync node:

Run the following command:

```bash
npx zksync-cli dev config
```

Select: `In memory node` and don’t choose any additional modules.

Next, start the node with:

```bash
npx zksync-cli dev start
```

You should see an output like this:

```
In memory node started v0.1.0-alpha.22:
 - zkSync Node (L2):
  - Chain ID: 260
  - RPC URL: http://127.0.0.1:8011
```

This setup will save your zkSync configuration for future use. After this, you can simply run:

```bash
make zk-anvil
```

If you ever need to stop the zkSync node (but let it run for now), just run:

```bash
docker ps
```

Grab the container ID, and if you see it running, you can stop it with:

```bash
docker kill ${CONTAINER_ID}
```

#### Deploy to a Local zkSync Network

Ready to deploy? Here’s how:

```bash
# Optional: Ensure you're on foundry-zksync
foundryup-zksync
# (If you haven't already) Set up a docker container for zkSync
# make zk-anvil
# Deploy your contracts
make deploy-zk
```

#### Deploy to zkSync Sepolia

To deploy to zkSync Sepolia, ensure your environment is set up correctly:

- Make sure you have `ZKSYNC_SEPOLIA_RPC_URL` set in your `.env` file.
- An account named `default` must be set up in your `cast`. [Check this guide for help](https://www.youtube.com/watch?v=VQe7cIpaE54).

Now, you’re ready to deploy to Sepolia:

```bash
# Optional: Ensure you're on foundry-zksync
foundryup-zksync
# Deploy to zkSync Sepolia
make deploy-zk-sepolia
# You'll be prompted to enter your password
```

## 🤝 Interacting with Your Contracts

Now that your contracts are deployed, let’s interact with them!

### Interacting - zkSync Local Network

In this section, we’ll allow the second default Anvil address (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`) to call the claim function and pay for the gas on behalf of the first default Anvil address (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`), which will receive the airdrop.

#### Setup Local zkSync Node, Deploy Contracts, and Run Airdrop Claim

Make sure you have the prerequisites set up (check [zkSync prerequisites](#zksync-prerequisites)).

To set up a local node and deploy the zkSync contracts, run:

```bash
foundryup-zksync
chmod +x interactZk.sh && ./interactZk.sh
```

You’ll see output indicating:

1. Deploying zkSync smart contracts
2. Signing your airdrop claim
3. Claiming the airdrop

All of this will happen automatically through the `./interactZk.sh` script. How awesome is that?

### Interacting - Local Anvil Network

Now, if you want to switch back to the Local Anvil network, here’s what you need to do:

#### Setup Anvil and Deploy Contracts

First, let’s get your Anvil node running:

```bash
foundryup
make anvil
# Now deploy the contracts
make deploy
# Copy the BagelToken address & Airdrop contract address
```

Once your contracts are deployed, make sure to copy the **Bagel Token** and **Airdrop contract addresses**. You’ll need to paste them into the `AIRDROP_ADDRESS` and `TOKEN_ADDRESS` variables in the `Makefile`. 

The following steps will let the second default Anvil address (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`) call claim and pay for the gas on behalf of the first default Anvil address (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`), which will receive the airdrop. 

#### Sign Your Airdrop Claim

In another terminal window, run:

```bash
make sign
```

This command will retrieve the signature bytes outputted to the terminal. Make sure to copy those and add them to `Interact.s.sol`, remembering to remove the `0x` prefix! 

If you’ve modified the claiming addresses in the Merkle tree, don’t forget to update the proofs in this file as well (you can get those from `output.json`).

#### Claim Your Airdrop

Now, let’s claim those tokens! Simply run:

```bash
make claim
```

#### Check Claim Amount

To verify that the claiming address has received the airdropped tokens, check the balance by running:

```bash
make balance
```

**Note:** The default Anvil address (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`) should now show an increased balance!

## 🧪 Testing

Want to ensure everything is working smoothly? Let’s run some tests!

For a standard test, just run:

```bash
foundryup
forge test
```

For zkSync testing, you can run:

```bash
# This will run `foundryup-zksync && forge test --zksync && foundryup`
make zktest
```

### Test Coverage

To see how much of your code is covered by tests, run:

```bash
forge coverage
```

## ⛽ Estimate Gas

To estimate gas costs for your transactions, you can run:

```bash
forge snapshot
```

You’ll see an output file called `.gas-snapshot` which provides insights into the gas usage.

## ✨ Formatting

To keep your code clean and tidy, you can format it with:

```bash
forge fmt
```

## 🙏 Thank You!

Thank you for taking the time to explore the **Merkle Airdrop**!

Feel free to reach out if you have any questions or suggestions. Happy coding! 🚀
