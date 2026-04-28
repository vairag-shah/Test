// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Tokenized real estate property with fractional ownership and rental income distribution
contract PropertyToken {
    
    string public propertyName;
    string public propertyLocation;
    uint256 public propertyValue;
    
    string public name = "Property Token";
    string public symbol = "PROP";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 * 10**18;
    
    uint256 public tokenPrice;
    bool public investmentOpen = true;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public totalRentalIncomeDeposited;
    uint256 public totalRentalIncomeClaimed;
    mapping(address => uint256) public rentalIncomeClaimed;
    
    address public owner;
    
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);
    event RentalIncomeDeposited(address indexed depositor, uint256 amount);
    event IncomeClaimed(address indexed claimer, uint256 amount);
    event PropertyInitialized(string name, string location, uint256 value, uint256 pricePerToken);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier investmentActive() {
        require(investmentOpen, "Investment closed");
        _;
    }
    
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
        balanceOf[owner] = totalSupply;
        emit PropertyInitialized(_propertyName, _propertyLocation, _propertyValue, _tokenPrice);
    }
    
    // Users invest ETH to receive tokens
    function invest(uint256 numTokens) external payable investmentActive {
        require(numTokens > 0, "Invalid amount");
        require(numTokens <= balanceOf[owner], "Insufficient tokens");
        
        uint256 requiredPayment = (numTokens * tokenPrice) / 10**18;
        require(msg.value >= requiredPayment, "Insufficient payment");
        
        balanceOf[owner] -= numTokens;
        balanceOf[msg.sender] += numTokens;
        
        if (msg.value > requiredPayment) {
            payable(msg.sender).transfer(msg.value - requiredPayment);
        }
        
        emit TokensPurchased(msg.sender, numTokens, requiredPayment);
    }
    
    // Deposit rental income for distribution
    function depositRentalIncome() external payable {
        require(msg.value > 0, "Invalid amount");
        totalRentalIncomeDeposited += msg.value;
        emit RentalIncomeDeposited(msg.sender, msg.value);
    }
    
    // Calculate claimable income: (user tokens / total tokens) * total income - already claimed
    function getClaimableIncome(address holder) public view returns (uint256) {
        if (totalSupply == 0) return 0;
        
        uint256 userTokens = balanceOf[holder];
        uint256 proportionalShare = (userTokens * totalRentalIncomeDeposited) / totalSupply;
        uint256 alreadyClaimed = rentalIncomeClaimed[holder];
        
        return proportionalShare > alreadyClaimed ? proportionalShare - alreadyClaimed : 0;
    }
    
    // Claim proportional rental income
    function claimRentalIncome() external {
        uint256 claimableAmount = getClaimableIncome(msg.sender);
        require(claimableAmount > 0, "Nothing to claim");
        require(claimableAmount <= address(this).balance, "Insufficient balance");
        
        rentalIncomeClaimed[msg.sender] += claimableAmount;
        totalRentalIncomeClaimed += claimableAmount;
        
        payable(msg.sender).transfer(claimableAmount);
        emit IncomeClaimed(msg.sender, claimableAmount);
    }
    
    function setInvestmentStatus(bool _isOpen) external onlyOwner {
        investmentOpen = _isOpen;
    }
    
    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getStats() external view returns (
        uint256 totalTokens,
        uint256 totalIncomeDeposited,
        uint256 totalIncomeClaimed,
        uint256 currentBalance
    ) {
        return (totalSupply, totalRentalIncomeDeposited, totalRentalIncomeClaimed, address(this).balance);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0) && to != address(0), "Invalid address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }
    
    receive() external payable {
        totalRentalIncomeDeposited += msg.value;
        emit RentalIncomeDeposited(msg.sender, msg.value);
    }
}
