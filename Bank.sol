// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Bank
 * @dev A contract for managing deposits and withdrawals of USDC tokens.
 */
contract Bank is Context, Ownable, Pausable, ReentrancyGuard {
    using Address for address payable;

    IERC20 public usdcToken;

    struct Deposit {
        /**
         * @dev The participant ID associated with the deposit.
         */
        string id;
        /**
         * @dev The amount of the deposit.
         */
        int256 amount;
    }

    /**
     * @dev Stores the deposits of each account. (id => amount)
     * @notice The key is the participant ID and the value is the deposit amount.
     */
    mapping(string => int256) public deposits;

    /**
     * @dev Stores the address of each id. (id => address)
     * @dev Value required by the transfer() method.
     * @notice The key is the participant ID and the value is the account address.
     */
    mapping(string => address) public accounts;

    /**
     * @dev Stores the id of each address. (address => id)
     * @dev Value required by the withdraw() method.
     * @notice The key is the account address and the value is the participant ID.
     */
    mapping(address => string) public ids;

    /**
     * @dev Emitted when an account is stored.
     * @param account The address of the account.
     * @param id The ID of the account.
     */
    event AccountStored(address indexed account, string indexed id);

    /**
     * @dev Emitted when a deposit is made.
     * @param account The address of the account that made the deposit.
     * @param amount The amount of the deposit.
     * @param deposits An array of Deposit structs containing the participant ID and deposit amount.
     */
    event DepositMade(
        address indexed account,
        uint256 amount,
        Deposit[] deposits
    );

    /**
     * @dev Emitted when a withdrawal is made from an account.
     * @param account The address of the account.
     * @param id The ID of the account.
     * @param amount The amount of the withdrawal.
     */
    event WithdrawalMade(
        address indexed account,
        string indexed id,
        uint256 amount
    );

    /**
     * @dev Emitted when a transfer is made to an account.
     * @param account The address of the account.
     * @param id The ID of the account.
     * @param amount The amount of the transfer.
     */
    event TransferMade(
        address indexed account,
        string indexed id,
        uint256 amount
    );

    /**
     * @dev Constructor function that sets the USDC token address.
     * @param usdcAddress The address of the USDC token contract.
     */
    constructor(address usdcAddress) {
        usdcToken = IERC20(usdcAddress);
    }

    /**
     * @dev Pauses the contract.
     * @notice Only the contract owner can call this function.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     * @notice Only the contract owner can call this function.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Deposits USDC into the contract.
     * @param depositor The address of the depositor.
     * @param deposits_ An array of Deposit structs containing the participant ID and deposit amount.
     * @notice This function will revert if the USDC transfer fails.
     * @notice This function will revert if the contract is paused.
     */
    function deposit(
        address depositor,
        Deposit[] calldata deposits_
    ) external whenNotPaused {
        uint256 depositsAmount = 0;

        for (uint256 i = 0; i < deposits_.length; i++) {
            depositsAmount += uint256(deposits_[i].amount);
            deposits[deposits_[i].id] += deposits_[i].amount;
        }

        require(
            usdcToken.transferFrom(
                depositor,
                address(this),
                uint256(depositsAmount)
            ),
            "USDC transfer failed"
        );

        emit DepositMade(depositor, depositsAmount, deposits_);
    }

    /**
     * @dev Sets the account ID for a given address.
     * @param address_ The address to set the account ID for.
     * @param id The account ID to set.
     * @notice This function will unset any previous account ID and address mappings.
     * @notice Only the contract owner can call this function.
     */
    function setAccount(address address_, string calldata id) public onlyOwner {
        delete accounts[ids[address_]];
        delete ids[accounts[id]];

        accounts[id] = address_;
        ids[address_] = id;

        emit AccountStored(address_, id);
    }

    /**
     * @dev Withdraws USDC from the contract.
     * @notice This function will revert if the account ID is not set or the USDC transfer fails.
     * @notice This function will revert if the contract is paused.
     */
    function withdraw() public whenNotPaused nonReentrant {
        address payable account = payable(_msgSender());
        string memory id = ids[account];

        require(bytes(id).length > 0, "Account not set");

        uint256 amount = uint256(deposits[id]);

        deposits[id] = 0;

        require(
            usdcToken.transfer(_msgSender(), amount),
            "USDC transfer failed"
        );

        emit WithdrawalMade(_msgSender(), id, amount);
    }

    /**
     * @dev Transfers USDC to a given account ID.
     * @param id The account ID to transfer USDC to.
     * @notice This function will revert if the account ID is not set or the USDC transfer fails.
     * @notice Only the contract owner can call this function.
     */
    function transfer(string calldata id) public onlyOwner nonReentrant {
        address payable account = payable(accounts[id]);

        require(account != address(0), "Account not set");

        uint256 amount = uint256(deposits[id]);

        deposits[id] = 0;

        require(usdcToken.transfer(account, amount), "USDC transfer failed");

        emit TransferMade(account, id, amount);
    }
}
