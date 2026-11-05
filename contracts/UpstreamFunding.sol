// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ReentrancyGuard } from "./ReentrancyGuard.sol";

/**
 * @title UpstreamFunding
 * @notice Pay-it-upstream open-source funding protocol.
 *
 * Sponsors send ETH to a single contract address. The contract automatically
 * attributes incoming funds to nine registered recipients:
 *   1 project maintainer
 *   5 regular contributors
 *   3 upstream open-source dependencies
 *
 * Every recipient independently inspects their accrued balance and withdraws
 * their own funds via a pull-payment pattern. The maintainer never custodies,
 * controls, redirects, or withdraws money belonging to other recipients.
 *
 * The funding split is established at construction and is immutable thereafter.
 * There is no owner, no admin, no emergency sweep, and no function that can
 * move credited funds to any address other than the entitled recipient.
 *
 * Security model
 * --------------
 *   * All accounting is derived exclusively from msg.value. Caller-supplied
 *     amounts are never trusted.
 *   * checks-effects-interactions ordering: recipient balances are cleared
 *     before the external ETH transfer in withdraw().
 *   * withdraw() is protected by OpenZeppelin's ReentrancyGuard.
 *   * ETH transfers use address.call{ value: amount }("") with success
 *     checking; on failure, accounting is restored and the transaction
 *     reverts.
 *   * Solidity 0.8 built-in overflow/underflow checks protect all arithmetic.
 *   * Integer division is used for share calculation; the rounding remainder
 *     is explicitly allocated to a designated remainder recipient so that
 *     SUM(recipient allocations) == msg.value exactly. No dust is left
 *     unattributed.
 *   * No privileged role exists. No function can extract ETH owed to
 *     recipients.
 *
 * @dev Forced ETH (e.g. SELFDESTRUCT) increases the contract's native balance
 *      but is NOT recorded as sponsorship revenue and cannot be withdrawn by
 *      anyone. There is no administrative sweep for it.
 */
contract UpstreamFunding is ReentrancyGuard {
    // -----------------------------------------------------------------------
    // Constants
    // -----------------------------------------------------------------------
    uint16 public constant BPS_DENOMINATOR = 10000;

    /// @notice Recipient categories.
    uint8 public constant CATEGORY_MAINTAINER = 0;
    uint8 public constant CATEGORY_CONTRIBUTOR = 1;
    uint8 public constant CATEGORY_UPSTREAM_DEPENDENCY = 2;

    /// @notice Index of the recipient designated to receive any rounding
    ///         remainder (index 0 = project maintainer).
    uint256 public constant REMAINDER_RECIPIENT_INDEX = 0;

    // -----------------------------------------------------------------------
    // Structs
    // -----------------------------------------------------------------------
    struct Recipient {
        address addr; // recipient wallet address
        string name; // human-readable name
        uint8 category; // CATEGORY_* constant
        uint16 shareBps; // allocation share in basis points
        uint256 credited; // lifetime ETH credited (wei)
        uint256 withdrawn; // lifetime ETH withdrawn (wei)
    }

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    bool public initialized;

    Recipient[] public recipients;
    mapping(address => uint256) public recipientIndex; // index + 1; 0 = not registered

    uint256 public recipientCount;

    /// @notice Total ETH received via sponsorship (wei). Excludes forced ETH.
    uint256 public totalReceived;

    /// @notice Total ETH credited to recipients (wei).
    uint256 public totalCredited;

    /// @notice Total ETH withdrawn by recipients (wei).
    uint256 public totalWithdrawn;

    /// @notice Monotonically increasing distribution identifier.
    uint256 public distributionId;

    // -----------------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------------
    error NotInitialized();
    error AlreadyInitialized();
    error InvalidConfiguration();
    error ZeroAddress();
    error DuplicateAddress();
    error ZeroShare();
    error InvalidTotalShares();
    error NotARecipient();
    error ZeroBalance();
    error ZeroSponsorship();
    error TransferFailed();

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    /// @notice Emitted when sponsorship funds are received and allocated.
    event FundingReceived(address indexed sponsor, uint256 amount, uint256 timestamp, uint256 indexed distributionId);

    /// @notice Emitted per recipient when a share is credited.
    event AllocationCredited(address indexed recipient, uint256 amount, uint256 indexed distributionId, uint8 category);

    /// @notice Emitted when a recipient withdraws their accrued ETH.
    event WithdrawalCompleted(address indexed recipient, uint256 amount, uint256 timestamp);

    // -----------------------------------------------------------------------
    // Constructor / initialization
    // -----------------------------------------------------------------------
    /**
     * @dev Initializes the immutable funding configuration.
     *
     * Called exactly once at deployment. After this, the allocation cannot be
     * changed and there is no administrative function to modify it.
     *
     * @param _names      Human-readable names for each recipient.
     * @param _categories Recipient category for each recipient (CATEGORY_*).
     * @param _addresses  Unique, non-zero Ethereum address for each recipient.
     * @param _shares     Allocation share in basis points for each recipient.
     */
    constructor(
        string[] memory _names,
        uint8[] memory _categories,
        address[] memory _addresses,
        uint16[] memory _shares
    ) {
        _initialize(_names, _categories, _addresses, _shares);
    }

    function _initialize(
        string[] memory _names,
        uint8[] memory _categories,
        address[] memory _addresses,
        uint16[] memory _shares
    ) internal {
        uint256 n = _addresses.length;
        if (n == 0 || n != _names.length || n != _categories.length || n != _shares.length) {
            revert InvalidConfiguration();
        }

        uint256 totalShares = 0;
        for (uint256 i = 0; i < n; i++) {
            if (_addresses[i] == address(0)) {
                revert ZeroAddress();
            }
            if (_shares[i] == 0) {
                revert ZeroShare();
            }
            // Duplicate-address check (O(n^2), n is small).
            for (uint256 j = i + 1; j < n; j++) {
                if (_addresses[i] == _addresses[j]) {
                    revert DuplicateAddress();
                }
            }
            totalShares += uint256(_shares[i]);
        }

        if (totalShares != BPS_DENOMINATOR) {
            revert InvalidTotalShares();
        }

        for (uint256 i = 0; i < n; i++) {
            recipients.push(
                Recipient({
                    addr: _addresses[i],
                    name: _names[i],
                    category: _categories[i],
                    shareBps: _shares[i],
                    credited: 0,
                    withdrawn: 0
                })
            );
            recipientIndex[_addresses[i]] = i + 1; // +1 so 0 means unregistered
        }

        recipientCount = n;
        initialized = true;
    }

    // -----------------------------------------------------------------------
    // Sponsorship (single-address funding)
    // -----------------------------------------------------------------------
    /**
     * @dev Sponsor the protocol with ETH. The accounting amount is derived
     *      exclusively from msg.value; no caller-supplied amount is trusted.
     *
     * Funds are automatically allocated to the registered recipients in
     * proportion to their immutable shares. Any integer-division remainder is
     * credited to the designated remainder recipient.
     */
    function sponsor() external payable {
        if (msg.value == 0) {
            revert ZeroSponsorship();
        }
        _allocate(msg.value);
    }

    /**
     * @dev Accepts direct ETH transfers to the contract address and allocates
     *      them identically to sponsor().
     */
    receive() external payable {
        _allocate(msg.value);
    }

    fallback() external payable {
        _allocate(msg.value);
    }

    // -----------------------------------------------------------------------
    // Internal allocation
    // -----------------------------------------------------------------------
    /**
     * @dev Allocates `value` wei across the registered recipients.
     *
     * Mathematical invariant: SUM(recipient allocations) == value.
     * Integer division is used throughout (no floating point). The rounding
     * remainder is credited to the designated remainder recipient so no dust
     * remains unattributed.
     */
    function _allocate(uint256 value) internal {
        if (!initialized) {
            revert NotInitialized();
        }

        uint256 id = ++distributionId;

        uint256 sumAllocations = 0;
        uint256[] memory allocations = new uint256[](recipientCount);
        for (uint256 i = 0; i < recipientCount; i++) {
            allocations[i] = (value * uint256(recipients[i].shareBps)) / BPS_DENOMINATOR;
            sumAllocations += allocations[i];
        }

        uint256 remainder = value - sumAllocations;
        allocations[REMAINDER_RECIPIENT_INDEX] += remainder;

        totalReceived += value;

        for (uint256 i = 0; i < recipientCount; i++) {
            recipients[i].credited += allocations[i];
            totalCredited += allocations[i];
            emit AllocationCredited(recipients[i].addr, allocations[i], id, recipients[i].category);
        }

        emit FundingReceived(msg.sender, value, block.timestamp, id);
    }

    // -----------------------------------------------------------------------
    // Pull-based withdrawal
    // -----------------------------------------------------------------------
    /**
     * @dev Lets a registered recipient withdraw their complete pending balance
     *      (credited but not yet withdrawn). Only the entitled recipient can
     *      withdraw, and only to their own address (msg.sender).
     *
     *      CEI ordering: the pending balance is cleared before the external
     *      ETH transfer, and the call is protected by nonReentrant. A failed
     *      transfer restores accounting and reverts.
     */
    function withdraw() external nonReentrant {
        if (!initialized) {
            revert NotInitialized();
        }

        uint256 indexPlusOne = recipientIndex[msg.sender];
        if (indexPlusOne == 0) {
            revert NotARecipient();
        }
        uint256 i = indexPlusOne - 1;

        uint256 pending = recipients[i].credited - recipients[i].withdrawn;
        if (pending == 0) {
            revert ZeroBalance();
        }

        // Clear accounting BEFORE the external transfer (CEI).
        recipients[i].withdrawn += pending;
        totalWithdrawn += pending;

        (bool success,) = payable(msg.sender).call{ value: pending }("");
        if (!success) {
            // Restore accounting so the recipient can retry once their
            // address is able to receive ETH.
            recipients[i].withdrawn -= pending;
            totalWithdrawn -= pending;
            revert TransferFailed();
        }

        emit WithdrawalCompleted(msg.sender, pending, block.timestamp);
    }

    // -----------------------------------------------------------------------
    // View / transparency functions
    // -----------------------------------------------------------------------
    /**
     * @dev Returns whether `account` is a registered recipient.
     */
    function isRecipient(address account) external view returns (bool) {
        return recipientIndex[account] != 0;
    }

    /**
     * @dev Returns the registered recipient at position `index`.
     */
    function getRecipient(uint256 index)
        external
        view
        returns (address addr, string memory name, uint8 category, uint16 shareBps, uint256 credited, uint256 withdrawn)
    {
        if (index >= recipientCount) {
            revert InvalidConfiguration();
        }
        Recipient storage r = recipients[index];
        return (r.addr, r.name, r.category, r.shareBps, r.credited, r.withdrawn);
    }

    function getRecipientAddress(uint256 index) external view returns (address) {
        if (index >= recipientCount) {
            revert InvalidConfiguration();
        }
        return recipients[index].addr;
    }

    function getRecipientName(uint256 index) external view returns (string memory) {
        if (index >= recipientCount) {
            revert InvalidConfiguration();
        }
        return recipients[index].name;
    }

    function getRecipientCategory(uint256 index) external view returns (uint8) {
        if (index >= recipientCount) {
            revert InvalidConfiguration();
        }
        return recipients[index].category;
    }

    function getRecipientShare(uint256 index) external view returns (uint16) {
        if (index >= recipientCount) {
            revert InvalidConfiguration();
        }
        return recipients[index].shareBps;
    }

    /**
     * @dev Returns the lifetime ETH credited to `account`.
     */
    function creditedBalance(address account) external view returns (uint256) {
        uint256 indexPlusOne = recipientIndex[account];
        if (indexPlusOne == 0) {
            return 0;
        }
        return recipients[indexPlusOne - 1].credited;
    }

    /**
     * @dev Returns the lifetime ETH withdrawn by `account`.
     */
    function withdrawnBalance(address account) external view returns (uint256) {
        uint256 indexPlusOne = recipientIndex[account];
        if (indexPlusOne == 0) {
            return 0;
        }
        return recipients[indexPlusOne - 1].withdrawn;
    }

    /**
     * @dev Returns the pending (withdrawable) balance of `account`
     *      (credited - withdrawn).
     */
    function pendingBalance(address account) external view returns (uint256) {
        uint256 indexPlusOne = recipientIndex[account];
        if (indexPlusOne == 0) {
            return 0;
        }
        Recipient storage r = recipients[indexPlusOne - 1];
        return r.credited - r.withdrawn;
    }

    /**
     * @dev Returns total outstanding liabilities (credited - withdrawn across
     *      all recipients). Equivalent to the sum of pending balances.
     */
    function outstandingLiabilities() external view returns (uint256) {
        return totalCredited - totalWithdrawn;
    }

    /**
     * @dev Returns the total ETH received via sponsorship.
     */
    function totalSponsorshipReceived() external view returns (uint256) {
        return totalReceived;
    }
}
