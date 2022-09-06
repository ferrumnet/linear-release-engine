# Problem and Solution

### The Problem with Current Vesting Solutions

There are a slew of vesting and linear release solutions in the market today. These solutions have brought innovative implementations to the market, but they lack the holistic architecture needed to solve the multifaceted problems of today's crypto industry.

When you review the currently available solutions, you find one or more of the following problems:

1. Charging too much 1% to 5% of the total supply
2. Not providing the option for linear release, only giving option for release date based vesting
3. Not providing the option for a cliff or lock period with the linear release option
4. Not providing the option for linear release of the cliff or locked period tokens
5. No ability to administer necessary updates on token categories such as team tokens

With our Linear Release Engine, Ferrum has set out to solve each one of these problems and bring more value to the space.

### Our Solution - Linear Release Engine

We built a modular Linear Release Engine to solve the issues identified above and to enable extensibility so the open source community and developers around the world can build their own implementations powered by Ferrum's Linear Release Engine.

Linear Release Engine makes it possible to build products like Iron Vest which can solve real-world problems with token release schedules and mitigate the sell pressure caused by staking, farming, and mining rewards or vesting token release dates.

#### What is the Linear Release Engine?

The Linear Release Engine is a modular implementation that allows you to configure the release of ERC20 assets with limitless built-in customizations. To explain the full power of the Linear Release Engine we have created the Iron Vest product powered by the Linear Release Engine. Let's go over all the features of the Iron Vest.

#### What is Iron Vest?

Iron Vest is the first implementation powered by the Linear Release Engine. Iron Vest allows you to launch a Vesting Contract and set up custom pools with our without a cliff. Here is a detailed list of features for Iron Vest:

1. Set a pool with traditional time-based vesting i.e. 1 month lock, 10% a month for 10 months
2. Set a pool with linear release with custom release rates per second. e.g.&#x20;
   1. Set Vesting Term (Length of Vesting in days) `vestingDays`
   2. Set Vesting Release Rate (Rate at which tokens are released to be claimed) `vestingReleaseRate`
   3. Upload Vesting Withdrawal Addresses and Amounts for each allocated address
3. Set a pool with linear release and a cliff or lock period
   1. This setup includes all options of linear release vesting with the addition of cliff or lock period
   2. Choose if the cliff period tokens will be released at once upon the arrival of the lock period end date or if they will be released linearly over a period of time by setting `clifVestingDays` and `cliffVestingReleaseRate`
4. Set team token vesting with special administrative controls
   1. With team tokens, the inability to stop vesting if a team member leaves the project before meeting their commitments is a serious problem. This causes projects to handle team token vesting manually or lose a significant chunk of the allocated tokens to individuals no longer contributing to the growth of the organization. With administrative controls for team token vesting, the authorized party can update the vesting period through a multi-sig process.
