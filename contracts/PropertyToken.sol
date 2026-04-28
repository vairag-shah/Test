// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PropertyToken
 * @dev A tokenized real estate investment contract representing fractional ownership
 *      of a single property with rental income distribution capabilities.
 * 
 * This contract implements:
 * - ERC20-like token functionality for property ownership
 * - Investment mechanism to purchase fractional tokens
 * - Proportional rental income distribution
 * - Claim function for token holders to withdraw their accumulated income
 */

contract PropertyToken {
    
    // ==================== STATE VARIABLES ====================
    
    /// @dev Property details
    string public propertyName;
    string public propertyLocation;
    uint256 public propertyValue; // Value in wei
    
    /// @dev Token details
    string public name = "Property Token";
    string public symbol = "PROP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 * 10**18; // 100 tokens representing 100% ownership
    
    /// @dev Investment parameters
    uint256 public tokenPrice; // Price per token in wei
    bool public investmentOpen = true;
    
    /// @dev Balances and allowances (ERC20-like)
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    /// @dev Rental income distribution
    uint256 public totalRentalIncomeDeposited; // Total income ever deposited
    uint256 public totalRentalIncomeClaimed; // Total income claimed by users
    
    // Maps user address => total rental income claimed by that user
    mapping(address => uint256) public rentalIncomeClaimed;
    
    /// @dev Ownership and access control
    address public owner;
    
    // ==================== EVENTS ====================
    
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event RentalIncomeDeposited(address indexed depositor, uint256 amount);
    event IncomeClaimed(address indexed claimer, uint256 amount);
    event PropertyInitialized(string name, string location, uint256 value, uint256 pricePerToken);
    
    // ==================== MODIFIERS ====================
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }
    
    modifier investmentActive() {
        require(investmentOpen, "Investment period is closed");
        _;
    }
    
    // ==================== CONSTRUCTOR ====================
    
    /**
     * @dev Initialize the property token contract
     * @param _propertyName Name of the property
     * @param _propertyLocation Location of the property
     * @param _propertyValue Total value of the property in wei
     * @param _tokenPrice Price per token in wei
     */
    constructor(
        string memory _propertyName,
        string memory _propertyLocation,
        uint256 _propertyValue,
        uint256 _tokenPrice
    ) {
        owner = msg.sender;
        propertyName = _propertyName;
        propertyLocation = _propertyLocation;
        propertyValue = _propertyValue;
        tokenPrice = _tokenPrice;
        
        // Owner starts with all tokens (100% ownership)
        balanceOf[owner] = totalSupply;
        
        emit PropertyInitialized(_propertyName, _propertyLocation, _propertyValue, _tokenPrice);
    }
    
    // ==================== INVESTMENT FUNCTIONS ====================
    
    /**
     * @dev Allow users to invest and receive tokens
     *      User must send ETH equal to: numTokens * tokenPrice
     * @param numTokens Number of tokens to purchase (in smallest unit with decimals)
     */
    function invest(uint256 numTokens) external payable investmentActive {
        require(numTokens > 0, "Must purchase at least 1 token");
        require(numTokens <= balanceOf[owner], "Not enough tokens available for sale");
        
        uint256 requiredPayment = (numTokens * tokenPrice) / 10**18;
        require(msg.value >= requiredPayment, "Insufficient payment. Check token price.");
        
        // Transfer tokens from owner to investor
        balanceOf[owner] -= numTokens;
        balanceOf[msg.sender] += numTokens;
        
        // Refund excess ETH
        if (msg.value > requiredPayment) {
            payable(msg.sender).transfer(msg.value - requiredPayment);
        }
        
        emit TokensPurchased(msg.sender, numTokens, requiredPayment);
    }
    
    // ==================== RENTAL INCOME FUNCTIONS ====================
    
    /**
     * @dev Owner deposits rental income to be distributed among token holders
     *      Anyone can call this but it will use the caller's funds
     */
    function depositRentalIncome() external payable {
        require(msg.value > 0, "Must deposit some income");
        
        totalRentalIncomeDeposited += msg.value;
        
        emit RentalIncomeDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Calculate the claimable income for a token holder
     * @param holder Address of the token holder
     * @return Amount of income available to claim
     */
    function getClaimableIncome(address holder) public view returns (uint256) {
        if (totalSupply == 0) return 0;
        
        // Proportional share = (user tokens / total tokens) * total income
        uint256 userTokens = balanceOf[holder];
        uint256 proportionalShare = (userTokens * totalRentalIncomeDeposited) / totalSupply;
        
        // Already claimed amount
        uint256 alreadyClaimed = rentalIncomeClaimed[holder];
        
        // Claimable = proportional share - already claimed
        if (proportionalShare > alreadyClaimed) {
            return proportionalShare - alreadyClaimed;
        }
        return 0;
    }
    
    /**
     * @dev Allow token holders to claim their share of rental income
     */
    function claimRentalIncome() external {
        uint256 claimableAmount = getClaimableIncome(msg.sender);
        require(claimableAmount > 0, "No income available to claim");
        require(claimableAmount <= address(this).balance, "Insufficient contract balance");
        
        // Update the amount claimed by this user
        rentalIncomeClaimed[msg.sender] += claimableAmount;
        totalRentalIncomeClaimed += claimableAmount;
        
        // Transfer the income to the user
        payable(msg.sender).transfer(claimableAmount);
        
        emit IncomeClaimed(msg.sender, claimableAmount);
    }
    
    // ==================== UTILITY FUNCTIONS ====================
    
    /**
     * @dev Close or open investment period (owner only)
     */
    function setInvestmentStatus(bool _isOpen) external onlyOwner {
        investmentOpen = _isOpen;
    }
    
    /**
     * @dev Update token price (owner only)
     */
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get total stats
     */
    function getStats() external view returns (
        uint256 totalTokens,
        uint256 totalIncomeDeposited,
        uint256 totalIncomeClaimed,
        uint256 currentBalance
    ) {
        return (
            totalSupply,
            totalRentalIncomeDeposited,
            totalRentalIncomeClaimed,
            address(this).balance
        );
    }
    
    // ==================== ERC20-LIKE TRANSFER FUNCTIONS ====================
    
    /**
     * @dev Transfer tokens to another address
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     * @return success Whether the transfer was successful
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        return true;
    }
    
    /**
     * @dev Approve another address to spend tokens on behalf of caller
     * @param spender Address to allow spending
     * @param amount Amount to approve
     * @return success Whether approval was successful
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    /**
     * @dev Transfer tokens from one address to another (requires approval)
     * @param from Source address
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     * @return success Whether the transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        return true;
    }
    
    // ==================== FALLBACK ====================
    
    /**
     * @dev Allow contract to receive ETH
     */
    receive() external payable {
        totalRentalIncomeDeposited += msg.value;
        emit RentalIncomeDeposited(msg.sender, msg.value);
    }
}
