// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title CompleteToken
 * @dev Full ERC-20 implementation dengan approval system
 */
contract CompleteToken {

    // ============ METADATA ============

    string public name;
    string public symbol;
    uint8 public decimals;

    // ============ STATE ============

    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    /**
     * @dev Nested mapping untuk allowances
     * allowances[owner][spender] = amount
     *
     * Contoh:
     * allowances[Alice][Uniswap] = 1000
     * → Uniswap boleh spend 1000 token dari Alice
     */
    mapping(address => mapping(address => uint256)) public allowances;

    // ============ EVENTS ============

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ============ CONSTRUCTOR ============

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // ============ VIEW FUNCTIONS ============

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    // ============ TRANSFER FUNCTIONS ============

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Cannot transfer to zero address");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ============ APPROVAL FUNCTIONS ============

    /**
     * @dev Approve spender untuk spend token caller
     * @param _spender Address yang di-approve
     * @param _value Jumlah yang di-approve
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Cannot approve zero address");

        // Set allowance
        allowances[msg.sender][_spender] = _value;

        // Emit event
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev Transfer dari address lain menggunakan allowance
     * @param _from Owner yang token-nya akan di-transfer
     * @param _to Recipient
     * @param _value Jumlah token
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // 1. Validasi: from punya cukup balance?
        require(balances[_from] >= _value, "Insufficient balance");

        // 2. Validasi: caller punya allowance cukup?
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");

        // 3. Validasi: recipient valid?
        require(_to != address(0), "Cannot transfer to zero address");

        // 4. Update balances
        balances[_from] -= _value;
        balances[_to] += _value;

        // 5. Update allowance (kurangi yang sudah dipakai)
        allowances[_from][msg.sender] -= _value;

        // 6. Emit Transfer event
        emit Transfer(_from, _to, _value);

        return true;
    }
}