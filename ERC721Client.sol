/**
 *Submitted for verification at snowtrace.io on 2022-02-02
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties {
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");

        _royalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }
}

contract NodeBears is ERC721Enumerable,ERC721Burnable,Ownable, ERC2981PerTokenRoyalties
{
    using Strings for uint256;
  // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    struct Winner {
        uint256 date;
        address winner;
        uint256 tokenId;
    }

    mapping(uint256 => address) private winner;

    string baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    string public pollName;
    uint256 public lotteryIntervalDays = 7;
    uint256 private epochDay = 86400;
    uint256 public cost = 1 ether;       //1 avax 
    uint256 public oneAvaxCost = 1 ether;    //const price 
    uint256 public maxSupply = 6969;
    uint256 public maxMintForTx = 3;
    uint256 public maxMintsForAddress = 3;
    uint256 private noFreeAddresses = 0;
    uint256 public drawNumber = 0;
    uint256 private contractRoyalties = 1000; //10%
    
    //bool public revealed = false;
    bool public paused = true;
    bool public lotteryActive = false;
    bool public pollState = false;
    bool public live = false;

    uint256[] public lotteryDates;
    string[] public pollOptions;

    mapping(string => bool) pollOptionsMap;
    mapping(string => uint256) public votes;
    mapping(address => bool) public whiteListAddresses;
    mapping(address => uint256) private addressMints;
    mapping(uint256 => Winner[]) public winnerLog;
    mapping(address => string) private votedAddresses;
    mapping(string => bool) private defaultpollOptions;
    mapping(address => uint256) private _winners;
    mapping(uint256 => bool) public revealed;
    mapping(address => bool) public preSaleAddresses;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    /*
    @function _baseURI()
    @description - Gets the current base URI for nft metadata
    @returns <string>
  */
   
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
    @function mint(_mintAmount)
    @description - Mints _mintAmount of NFTs for sender address.
    @param <uint256> _mintAmount - The number of NFTs to mint.
  */
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerCanMintCount = maxMintsForAddress - addressMints[msg.sender];

        require(
            ownerCanMintCount >= _mintAmount,
            "ERROR: You cant mint that many bears"
        );
        require(!paused, "ERROR: Contract paused. Please check discord.");
        require(
            _mintAmount <= maxMintForTx,
            "ERROR: The max no mints per transaction exceeded"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "ERROR: Not enough bears left to mint!"
        );

        if (!live) {
            if (preSaleAddresses[msg.sender]) {
                require(
                    msg.value >= cost * _mintAmount,
                    "ERROR: Need More Avax PRESALE "
                );
            } else if (whiteListAddresses[msg.sender]) {
                if (ownerCanMintCount == maxMintsForAddress)
                {
                    require(
                        msg.value >= ((cost * _mintAmount) - oneAvaxCost),
                        "ERROR: Please send more AVAX - WL"
                    );
                } else {
                    require(
                        msg.value >= cost * _mintAmount,
                        "ERROR: Need More Avax PRESALE "
                );
                }
            } else {
                require(((preSaleAddresses[msg.sender])||(preSaleAddresses[msg.sender])), "ERROR: Only Whitelist and Presale addresses can mint!");        
            }           
        }

        if (live) {
            require(
                msg.value >= cost * _mintAmount,
                "ERROR: Need More Avax to mint!"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(msg.sender, tokenId);
            _setTokenRoyalty(tokenId, owner(), contractRoyalties);

            addressMints[msg.sender]++;

            // activate lottery once all minted using lotteryIntervalDays
            if (tokenId == maxSupply) {
                activateLottery();
            }


            // This will have changes after a mint, so re-asign it
            supply = totalSupply();
        }
    }

    /*
    @function activateLottery(_owner)
    @description - Activates the lottery
  */
    function activateLottery() private {
        lotteryActive = true;
        lotteryDates.push(block.timestamp + (epochDay * lotteryIntervalDays));
        drawNumber++;
    }

      /*
    @function activateLottery(_owner)
    @description - Activates the lottery
  */
    function ownerActivateLottery() public onlyOwner {
        lotteryActive = true;
        lotteryDates.push(block.timestamp + (epochDay * lotteryIntervalDays));
        drawNumber++;
    }

    /*
    @function walletOfOwner(_owner)
    @description - Gets the list ok NFT tokenIds that owner has.
  */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /*
    @function tokenURL(tokenId)
    @description - Gets the metadata URI for a NFT tokenId
    @param <uint256> tokenId - The id ok the NFT token
    @returns <string> - The URI for the NFT metadata file
  */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed[tokenId] == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /*
    @function setCost(_newCost)
    @description - Sets the cost of a single NFT
    @param <uint256> _newCost - The cost of a single nft
  */
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    /*
    @function setMaxMintForTx
    @description - Sets the maximum mintable amount in 1 tx
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForTx(uint256 amount) public onlyOwner {
        maxMintForTx = amount;
    }

    /*
    @function setMaxMintForAddress
    @description - Sets the maximum mintable amount for an address
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForAddress(uint256 amount) public onlyOwner {
        maxMintsForAddress = amount;
    }

    /*
    @function setBaseURI(_newBaseURI)
    @description - Sets the base URI for the meta data files
    @param <string> _newBaseURI - The new base URI for the metadata files
  */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /*
    @function setBaseExtension(_newBaseExtension)
    @description - Sets the extension for the meta data file (default .json)
    @param <string> _newBaseExtension - The new file extension to use.
  */
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /*
    @function setNotRevealedURI(_newBaseExtension)
    @description - sets the uri to hidden
    @param <string> _notRevealedURI - Hidden url.
  */
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /*
    @function pause(_state)
    @description - Pauses the contract.
    @param <bool> _state - true/false
  */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /*
    @function pause(_state)
    @description - Pauses the contract.
    @param <bool> _state - true/false
  */
    function publicLive(bool _state) public onlyOwner {
        live = _state;
    }

    /*
    @function selectWinner()
    @description - Selects a winner if the current date allows. Uses NFT id to select winner.
    @param <uint> no - The number of winners
    @returns <address> - The winner
    */
    function selectWinners(uint256 noOfWinners) public onlyOwner {
        require(!paused, "ERROR: Contract is paused");
        require(lotteryActive, "ERROR: Lottery not active yet");
        require(noOfWinners <= 50, "ERROR: Too many winners selected");

        uint256 epochNow = block.timestamp;
        uint256 nextLotteryDate = lotteryDates[lotteryDates.length - 1];

        require(
            epochNow >= nextLotteryDate,
            "ERROR: Cannot draw yet, too early"
        );

        for (uint256 i = 0; i < noOfWinners; i++) {
            selectAWinner(
                0,
                epochNow,
                msg.sender,
                nextLotteryDate,
                msg.sender,
                0
            );
        }

        lotteryDates.push(epochNow + (epochDay * lotteryIntervalDays));

        // increment draw
        drawNumber++;
    }

    /*
    @function selectAWinner()
    @description - Selects a winner and does not allow the same address to win more than once.
    @param <uint> no - The number of winners
    @returns <address> - The winner
    */
    function selectAWinner(
        uint256 it,
        uint256 epochNow,
        address sender,
        uint256 lotteryDate,
        address randomAddr,
        uint256 randomNo
    ) internal {
        // Generate random id between 1 - 5000 (corresponds to NFT id)

        uint256 winningToken = rand(randomAddr, randomNo);
        address winnerAddress = ERC721.ownerOf(winningToken);
        uint256 lastWon = _winners[winnerAddress];

        bool alreadyWon = (lastWon == lotteryDate);

        Winner memory win;

        if ((it < 5) && alreadyWon) {
            uint256 newIt = it + 1;
            return
                selectAWinner(
                    newIt,
                    epochNow,
                    sender,
                    lotteryDate,
                    winnerAddress,
                    winningToken
                );
        } else if ((it >= 5) && alreadyWon) {
            return;
        } else {
            win.date = lotteryDate;
            win.winner = winnerAddress;
            win.tokenId = winningToken;
            winnerLog[drawNumber].push(win);

            _winners[winnerAddress] = lotteryDate;
        }

        return;
    }

    function rand(address randomAddress, uint256 randomNo)
        internal
        view
        returns (uint256)
    {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp - randomNo) +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(randomAddress)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / maxSupply) * maxSupply)) + 1;
    }

    /*
    @function reveal()
    @description - reveal token uri
    @param
    */
    function reveal() public onlyOwner {
        uint256 supply = totalSupply();
        for (uint256 token_id = 1; token_id <= supply; token_id++) {
            setRevealed(token_id);
        }
    }

    function setRevealed(uint256 token_id) private onlyOwner {
        revealed[token_id] = true;
    }

    /*
    @function getRandomAddress()
    @description - Gets a random address
    @param <address> random address
    */
    function getRandomAddress() public view onlyOwner returns (address) {
        uint256 tokenId = rand(msg.sender, 0);
        return ownerOf(tokenId);
    }

    /*
    @function setLotteryState()
    @description - Sets the lottery state to active/not active (true/false)
    @param <address> state - The lottery state
    */
    function setLotteryState(bool state) public onlyOwner {
        lotteryActive = state;
    }

    /*
    @function setMaxSupply()
    @description - Sets the max supply that can be minted.
                   This will be useful if the project sells out super fast and
                   we want to add more mintable nfts.
    */
    function setMaxSupply(uint256 amount) public onlyOwner {
        require(
            amount > maxSupply,
            "ERROR: Max supply is currently smaller than new supply"
        );
        lotteryActive = false;
        maxSupply = amount;
    }

    /*
    @function addToWhiteListed(addr)
    @description - Add an address to the freebie list
    @param <address> addr - The array of addresses to whitelist
    */
    function addToWhiteListed(address[] memory addresses) public onlyOwner {
        require(!paused, "ERROR: Contract paused!");
        require(
            noFreeAddresses < 201,
            "ERROR: MAX number of free addresses added"
        );

        for (uint256 account = 0; account < addresses.length; account++) {
            addToWhiteList(addresses[account]);
        }
    }

    /*
    @function addToWhiteList(addr)
    @description - Add an address to the freebie list
    @param <address> addr - The address to whitelist
    */
    function addToWhiteList(address addr) public onlyOwner {
        require(!paused, "ERROR: Contract paused!");
        require(
            noFreeAddresses < 201,
            "ERROR: MAX number of free addresses added"
        );
        whiteListAddresses[addr] = true;
        noFreeAddresses++;
    }

    /*
    @function addToPreSaleList(address)
    @description - Add an address to presale List
    @param <address> addr - The array of addresses to presale
    */
    function addToPreSaleList(address[] memory addresses) public onlyOwner {
        require(!paused, "ERROR: Contract paused!");

        for (uint256 account = 0; account < addresses.length; account++) {
            addToPreSale(addresses[account]);
        }
    }

    /*
    @function addToPreSale(addr)
    @description - Add an address to the presale List
    @param <address> addr - add address to presale
    */
    function addToPreSale(address addr) public onlyOwner {
        require(!paused, "ERROR: Contract paused!");
        preSaleAddresses[addr] = true;
    }

    /*
    @function setLotteryIntervalDays(noDays)
    @description - Set the number of days between each lottery draw.
    @param <uint256> noDays - The number of days.
    */
    function setLotteryIntervalDays(uint256 noDays) public onlyOwner {
        lotteryIntervalDays = noDays;
    }

     
    ///////////////////////////////////
    //       AIRDROP CODE STARTS     //
    ///////////////////////////////////

    // Send NFTs to a list of addresses
    function giftNftToList(address[] calldata _sendNftsTo)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            {_safeMint(_sendNftsTo[i], totalSupply());
            addressMints[_sendNftsTo[i]]++;}
    }

    // Send NFTs to a single address
    function giftNftToAddress(address _sendNftsTo, uint256 _howMany)
        external
        onlyOwner
        tokensAvailable(_howMany)
    {
        for (uint256 i = 0; i < _howMany; i++)
           {_safeMint(_sendNftsTo, totalSupply());
             addressMints[_sendNftsTo]++;} 
    }

    
    ///////////////////
    // Query Method  //
    ///////////////////

    function tokensRemaining() public view returns (uint256) {
        return maxSupply - totalSupply() - 100; // reserve 100 mints for the team
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    ///////////////////
    //  Helper Code  //
    ///////////////////

    modifier tokensAvailable(uint256 _howMany) {
        require(_howMany <= tokensRemaining(), "Try minting less tokens");
        _;
    }
    /*
    @function setAirDropStatus(value)
    @description - Sets the status of airdrop to true/false
    @param <bool> value - true/false
    */

    /*
    @function castVote(value)
    @description - Casts a vote if you own a bear
    @param <string> memory - The option chosen
    */
    function castVote(string memory option) public {
        require(!paused, "ERROR: Contract paused");
        require(pollState, "ERROR: No poll to vote on right now");
        require(pollOptionsMap[option], "ERROR: Invalid voting option");
        require(
            keccak256(abi.encodePacked(votedAddresses[msg.sender])) !=
                keccak256(abi.encodePacked(pollName)),
            "ERROR: You have already voted in this poll!"
        );

        uint256 noVotes = balanceOf(msg.sender);

        require(
            noVotes > 0,
            "ERROR: You have no voting rights. Get yourself a bear my fren!"
        );
        votes[option] += noVotes;
        votedAddresses[msg.sender] = pollName;
    }

    /*
    @function addPollOption(option)
    @description - Adds an option for voting
    @param <string> memory - The option to add
    */
    function addPollOption(string memory option) public onlyOwner {
        pollOptionsMap[option] = true;
        pollOptions.push(option);
    }

    /*
    @function clearPollOptions()
    @description - Clears the current poll
    */
    function clearPollOptions() public onlyOwner {
        for (uint256 i = 0; i < pollOptions.length; i++) {
            votes[pollOptions[i]] = 0;
            pollOptionsMap[pollOptions[i]] = false;
            delete pollOptions[i];
        }
    }

    /*
    @function setPollName(name)
    @description - Sets the poll name/quesstion
    @param <string> memory - The name/question of the poll
    */
    function setPollName(string memory name) public onlyOwner {
        pollName = name;
    }

    /*
    @function getVoteCountForOption(option)
    @description - Gets the number of votes for a poll option
    @param <string> memory - The option to get the poll counts for
    */
    function getVoteCountForOption(string memory option)
        public
        view
        returns (uint256)
    {
        return votes[option];
    }

    /*
    @function togglePollVoting(state)
    @description - Turns the poll on/off
    @param <string> memory - The value true/false
    */
    function setPollState(bool state) public onlyOwner {
        pollState = state;
    }

    /*
    @function getPollOptions(state)
    @description - returns the array of poll options
    */
    function getPollOptions() public view returns (string[] memory) {
        return pollOptions;
    }

    /*
    @function clearPoll()
    @description - clears poll, options and votes
    */
    function clearPoll() public onlyOwner {
        clearPollOptions();
        pollState = false;
        pollName = "";
    }

    /*
    @function getWinnersForDraw(drawNo)
    @description - Gets all the winners for a given draw
    */
    function getWinnersForDraw(uint256 drawNo)
        public
        view
        returns (Winner[] memory)
    {
        return winnerLog[drawNo];
    }

    /*
    @function clearWinnersForDraw(drawNo)
    @description - clears out all the winner logs for that draw. This is for when the array gets large!
    */
    function clearWinnersForDraw(uint256 drawNo) public onlyOwner {
        for (uint256 i = 0; i < 50; i++) {
            delete winnerLog[drawNo][i];
        }
    }

    /*
    @function noPollOptions()
    @description - Gets the current number of options for the poll
    */
    function noPollOptions() public view returns (uint256) {
        return pollOptions.length;
    }

     function withdraw() public payable onlyOwner {
    
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }


}
