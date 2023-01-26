Welcome to Zach's Bootcamp :)

Here are the rules:
- Solidity only until you feel comfortable with that (no testing, no front end, etc)
- Use Remix as the dev environment. You can deploy to "virtual JS" to play around with your functions and make sure they all work like you expect. 
- When you finish a challenge, just copy and paste the code into a .sol file on your computer and email it to me. 

If you get stuck on any of these:
- First step is to check [Ethereum By Example](https://solidity-by-example.org/). It's really hard to remember syntax early on, so no shame in checking that. 
- If you're getting an error you can't understand, Google & Stack Overflow are your friends.
- If neither of those works, ask me. Better to keep momentum than to get stuck.

CHALLENGES

You don't need to do these in order, but they are loosely ordered to build on each other, so I would try to unless you really get stuck.

1) Crypto Zombies
- get your hands on the keyboard actually writing Solidity code
- get comfortable with the different data types, etc.

2) Magic Number
- make a contract with two functions: 
- setMagicNumber lets a user set the contract's magic number,
- getMagicNumber returns the contract's magic number

3) Guarded Magic Number
- edit the last contract so that only the person who made the contract can set the number

4) User Account Magic Number
- anyone can set a magic number, and the contract saves a different number for each user
- make it so that every user can only set one. if they've set it before, the contract fails
- change the getMagicNumber function so you can input anyone's address to read their magic number

5) Ether Wallet
- this is similar to the last one, but with money
- anyone can deposit ether, and you track their account balances
- of course, in this case, you can add more and the balance increases
- anyone can withdraw their own ether

6) Ether Wallet With Approvals
- can you add the ability in the last contract for me to approve you to spend X amount of my ether?

7) Split Payments
- this contract takes in two addresses, the splitters
- every eth payment that comes in lets each of them withdraw 50%

8) Split Payments with Different Percentages
- same as above, but let them set the percentages up front

9) ERC20 (your first big aha moment)
- go through the [EIP 20 standard](https://eips.ethereum.org/EIPS/eip-20) (this defines how ERC20s should work)
- try to build this standard. think about: how can you track balances, allow approvals, etc? you've done a lot of this already.
- if you get stuck, feel free to check out [OpenZeppelin implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)

10) Escrow
- this contract represents a deal between two users
- i deposit funds once with a specific time you can withdraw them
- you aren't able to withdraw them until that time

11) Multisig
- this contract starts with 10 ether in it, and three specific signers
- if 2/3 of the signers call a function, they can approve the contract to send ether to another address

12) Customized Multisig
- make the above contract more flexible:
- $ can be deposited any time
- addresses can be added at any time (by "owner", person who deployed the contract)
- number needed to sign can change at any time (by "owner", person who deployed the contract)

13) NFT
- go through the [EIP721 standard](https://eips.ethereum.org/EIPS/eip-721)
- try to build an NFT to this standard
- if you get stuck, here's [OpenZeppelin implementation](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol)

AFTER

You can probably finish all of these in a few weeks if you take it seriously. You'll be functional at Solidity by that point. 

The next step is to understand how some real useful apps work, which will be much easier with Solidity feeling clearer:
- build a simple staking platform, where users can stake token for rewards in another token 
- build a simple nft with minting functionality and metadata and deploy it on polygon
- build a simple DEX (uniswap v2 style) and understand constant product formula, etc.
- build a lottery that uses chainlink vrf for randomness
- upgrade your nft contract to use a merkle proof for claiming minting
- read [Mastering Ethereum](https://www.amazon.com/Mastering-Ethereum-Building-Smart-Contracts/dp/1491971940) (it's not useful for actual Solidity code and most will go over your head but it helps the pieces really start to click)
- do [Ethernaut](https://ethernaut.openzeppelin.com/) or [Capture The Ether](https://capturetheether.com/) (at least the first ~8 challenges)
- learn foundry and get comfortable building locally

At that point, I'd recommend building something you take seriously with no roadmap. 

<3