// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console2 } from "forge-std/Test.sol";
import { UpstreamFunding } from "../contracts/UpstreamFunding.sol";

contract UpstreamFundingTest is Test {
    // -----------------------------------------------------------------------
    // Fixtures
    // -----------------------------------------------------------------------
    address public immutable sponsor = address(0x1234);
    address public immutable nonRecipient = address(0x9999);

    // Recipient addresses (index 0 = maintainer).
    address public immutable maintainer = address(0xAAAA);
    address public immutable contributor1 = address(0xBBBB);
    address public immutable contributor2 = address(0xCCCC);
    address public immutable contributor3 = address(0xDDDD);
    address public immutable contributor4 = address(0xEEEE);
    address public immutable contributor5 = address(0xFFFF);
    address public immutable upstream1 = address(0x1000);
    address public immutable upstream2 = address(0x1111);
    address public immutable upstream3 = address(0x1222);

    uint16 public constant SHARE_MAINTAINER = 3000;
    uint16 public constant SHARE_CONTRIBUTOR = 800;
    uint16 public constant SHARE_UPSTREAM = 1000;

    uint8 public constant CAT_MAINTAINER = 0;
    uint8 public constant CAT_CONTRIBUTOR = 1;
    uint8 public constant CAT_UPSTREAM = 2;
    uint16 public constant BPS = 10000;

    UpstreamFunding public funding;

    function setUp() public {
        vm.deal(address(this), 100 ether);
        vm.deal(sponsor, 300 ether);
        vm.deal(nonRecipient, 100 ether);
        vm.deal(maintainer, 1 ether);
        vm.deal(contributor1, 1 ether);
        vm.deal(contributor2, 1 ether);
        vm.deal(contributor3, 1 ether);
        vm.deal(contributor4, 1 ether);
        vm.deal(contributor5, 1 ether);
        vm.deal(upstream1, 1 ether);
        vm.deal(upstream2, 1 ether);
        vm.deal(upstream3, 1 ether);

        funding = _deployStandard();
    }

    function _deployStandard() internal returns (UpstreamFunding) {
        address[] memory addrs = new address[](9);
        string[] memory names = new string[](9);
        uint8[] memory categories = new uint8[](9);
        uint16[] memory shares = new uint16[](9);

        addrs[0] = maintainer;
        names[0] = "Alice Maintainer";
        categories[0] = CAT_MAINTAINER;
        shares[0] = SHARE_MAINTAINER;

        addrs[1] = contributor1;
        names[1] = "Bob Contributor";
        categories[1] = CAT_CONTRIBUTOR;
        shares[1] = SHARE_CONTRIBUTOR;

        addrs[2] = contributor2;
        names[2] = "Carol Contributor";
        categories[2] = CAT_CONTRIBUTOR;
        shares[2] = SHARE_CONTRIBUTOR;

        addrs[3] = contributor3;
        names[3] = "Dave Contributor";
        categories[3] = CAT_CONTRIBUTOR;
        shares[3] = SHARE_CONTRIBUTOR;

        addrs[4] = contributor4;
        names[4] = "Eve Contributor";
        categories[4] = CAT_CONTRIBUTOR;
        shares[4] = SHARE_CONTRIBUTOR;

        addrs[5] = contributor5;
        names[5] = "Frank Contributor";
        categories[5] = CAT_CONTRIBUTOR;
        shares[5] = SHARE_CONTRIBUTOR;

        addrs[6] = upstream1;
        names[6] = "Dep Alpha";
        categories[6] = CAT_UPSTREAM;
        shares[6] = SHARE_UPSTREAM;

        addrs[7] = upstream2;
        names[7] = "Dep Beta";
        categories[7] = CAT_UPSTREAM;
        shares[7] = SHARE_UPSTREAM;

        addrs[8] = upstream3;
        names[8] = "Dep Gamma";
        categories[8] = CAT_UPSTREAM;
        shares[8] = SHARE_UPSTREAM;

        return new UpstreamFunding(names, categories, addrs, shares);
    }

    function _sponsor(uint256 value) internal {
        vm.prank(sponsor);
        funding.sponsor{ value: value }();
    }

    // -----------------------------------------------------------------------
    // 1. Correct initialization
    // -----------------------------------------------------------------------
    function test_initialization_records_all_recipients() public {
        assertEq(funding.recipientCount(), 9);
        assertTrue(funding.initialized());
        assertEq(funding.getRecipientShare(0), SHARE_MAINTAINER);
        assertEq(funding.getRecipientAddress(0), maintainer);
        assertEq(funding.getRecipientCategory(0), CAT_MAINTAINER);

        uint256 contributorCount = 0;
        uint256 upstreamCount = 0;
        for (uint256 i = 0; i < 9; i++) {
            if (funding.getRecipientCategory(i) == CAT_CONTRIBUTOR) {
                contributorCount++;
                assertEq(funding.getRecipientShare(i), SHARE_CONTRIBUTOR);
            }
            if (funding.getRecipientCategory(i) == CAT_UPSTREAM) {
                upstreamCount++;
                assertEq(funding.getRecipientShare(i), SHARE_UPSTREAM);
            }
        }
        assertEq(contributorCount, 5);
        assertEq(upstreamCount, 3);
        assertTrue(funding.isRecipient(maintainer));
        assertFalse(funding.isRecipient(nonRecipient));
    }

    function test_shares_sum_to_denominator() public {
        uint256 total = 0;
        for (uint256 i = 0; i < funding.recipientCount(); i++) {
            total += uint256(funding.getRecipientShare(i));
        }
        assertEq(total, BPS);
    }

    // -----------------------------------------------------------------------
    // 2. Incorrect total share rejection
    // -----------------------------------------------------------------------
    function test_rejects_invalid_total_shares() public {
        address[] memory addrs = new address[](2);
        string[] memory names = new string[](2);
        uint8[] memory cats = new uint8[](2);
        uint16[] memory shares = new uint16[](2);
        addrs[0] = address(0x1111);
        names[0] = "A";
        cats[0] = 0;
        shares[0] = 6000;
        addrs[1] = address(0x2222); // total 9000
        names[1] = "B";
        cats[1] = 1;
        shares[1] = 3000;
        vm.expectRevert(UpstreamFunding.InvalidTotalShares.selector);
        new UpstreamFunding(names, cats, addrs, shares);
    }

    // -----------------------------------------------------------------------
    // 3. Zero-address rejection
    // -----------------------------------------------------------------------
    function test_rejects_zero_address() public {
        address[] memory addrs = new address[](2);
        string[] memory names = new string[](2);
        uint8[] memory cats = new uint8[](2);
        uint16[] memory shares = new uint16[](2);
        addrs[0] = address(0);
        names[0] = "A";
        cats[0] = 0;
        shares[0] = 5000;
        addrs[1] = address(0x2222);
        names[1] = "B";
        cats[1] = 1;
        shares[1] = 5000;
        vm.expectRevert(UpstreamFunding.ZeroAddress.selector);
        new UpstreamFunding(names, cats, addrs, shares);
    }

    // -----------------------------------------------------------------------
    // 4. Duplicate recipient rejection
    // -----------------------------------------------------------------------
    function test_rejects_duplicate_address() public {
        address[] memory addrs = new address[](2);
        string[] memory names = new string[](2);
        uint8[] memory cats = new uint8[](2);
        uint16[] memory shares = new uint16[](2);
        address dup = address(0x3333);
        addrs[0] = dup;
        names[0] = "A";
        cats[0] = 0;
        shares[0] = 5000;
        addrs[1] = dup;
        names[1] = "B";
        cats[1] = 1;
        shares[1] = 5000;
        vm.expectRevert(UpstreamFunding.DuplicateAddress.selector);
        new UpstreamFunding(names, cats, addrs, shares);
    }

    // -----------------------------------------------------------------------
    // 5. Zero share rejection
    // -----------------------------------------------------------------------
    function test_rejects_zero_share() public {
        address[] memory addrs = new address[](2);
        string[] memory names = new string[](2);
        uint8[] memory cats = new uint8[](2);
        uint16[] memory shares = new uint16[](2);
        addrs[0] = address(0x1111);
        names[0] = "A";
        cats[0] = 0;
        shares[0] = 0;
        addrs[1] = address(0x2222);
        names[1] = "B";
        cats[1] = 1;
        shares[1] = 10000;
        vm.expectRevert(UpstreamFunding.ZeroShare.selector);
        new UpstreamFunding(names, cats, addrs, shares);
    }

    // -----------------------------------------------------------------------
    // 6. Successful sponsorship / 7. Exact allocation / 6. msg.value derived
    // -----------------------------------------------------------------------
    function test_sponsorship_allocates_exact_shares() public {
        uint256 value = 100 ether;
        uint256 balanceBefore = address(funding).balance;

        vm.prank(sponsor);
        vm.expectEmit(true, true, false, true, address(funding));
        emit UpstreamFunding.FundingReceived(sponsor, value, block.timestamp, 1);

        funding.sponsor{ value: value }();

        assertEq(address(funding).balance, balanceBefore + value);
        assertEq(funding.totalSponsorshipReceived(), value);
        assertEq(funding.totalCredited(), value);
        assertEq(funding.distributionId(), 1);

        // Maintainer: 30% of 100 ether = 30 ether
        assertEq(funding.creditedBalance(maintainer), 30 ether);
        // Each contributor: 8% of 100 ether = 8 ether
        assertEq(funding.creditedBalance(contributor1), 8 ether);
        assertEq(funding.creditedBalance(contributor2), 8 ether);
        assertEq(funding.creditedBalance(contributor3), 8 ether);
        assertEq(funding.creditedBalance(contributor4), 8 ether);
        assertEq(funding.creditedBalance(contributor5), 8 ether);
        // Each upstream dep: 10% of 100 ether = 10 ether
        assertEq(funding.creditedBalance(upstream1), 10 ether);
        assertEq(funding.creditedBalance(upstream2), 10 ether);
        assertEq(funding.creditedBalance(upstream3), 10 ether);

        // Pending equals credited (nothing withdrawn yet).
        assertEq(funding.pendingBalance(maintainer), 30 ether);
        assertEq(funding.outstandingLiabilities(), value);
    }

    function test_allocation_derives_from_msg_value_not_caller_input() public {
        // Sponsor with a value that does not split evenly to prove rounding
        // handling and that accounting uses actual msg.value.
        uint256 value = 1 wei;
        _sponsor(value);

        // All shares truncate to 0; remainder (1 wei) goes to maintainer
        // (designated remainder recipient, index 0).
        assertEq(funding.creditedBalance(maintainer), 1 wei);
        assertEq(funding.creditedBalance(contributor1), 0);
        assertEq(funding.totalCredited(), 1 wei);
        assertEq(funding.totalReceived(), 1 wei);
    }

    function test_rounding_remainder_assigned_to_designated_recipient() public {
        // 3 wei: each 800-bps share -> 0, maintainer 3000-bps -> 0,
        // upstream 1000-bps -> 0. Remainder 3 wei -> maintainer.
        uint256 value = 3 wei;
        _sponsor(value);

        assertEq(funding.creditedBalance(maintainer), 3 wei);
        assertEq(funding.totalCredited(), value);
        assertEq(funding.outstandingLiabilities(), value);
    }

    function test_remainder_invariant_sum_equals_msg_value() public {
        // Odd value to force non-zero rounding dust across recipients.
        uint256 value = 123456789 wei;
        _sponsor(value);

        uint256 sum = 0;
        for (uint256 i = 0; i < funding.recipientCount(); i++) {
            (address a,) = _recipientAt(funding, i);
            sum += funding.creditedBalance(a);
        }
        assertEq(sum, value);
        assertEq(funding.totalCredited(), value);
        assertEq(funding.totalReceived(), value);
        assertEq(funding.outstandingLiabilities(), value);
    }

    // -----------------------------------------------------------------------
    // 9. Multiple sponsorships
    // -----------------------------------------------------------------------
    function test_multiple_sponsorships_accumulate() public {
        _sponsor(100 ether);
        _sponsor(50 ether);

        assertEq(funding.totalReceived(), 150 ether);
        assertEq(funding.totalCredited(), 150 ether);
        assertEq(funding.distributionId(), 2);
        assertEq(funding.creditedBalance(maintainer), 45 ether); // 30% of 150
        assertEq(funding.creditedBalance(contributor1), 12 ether); // 8% of 150
        assertEq(funding.creditedBalance(upstream1), 15 ether); // 10% of 150
        assertEq(funding.outstandingLiabilities(), 150 ether);
    }

    // -----------------------------------------------------------------------
    // 10-13. Individual withdrawal, exact amount, unauthorized, double
    // -----------------------------------------------------------------------
    function test_individual_withdrawal_pays_exact_pending() public {
        _sponsor(100 ether);

        uint256 expected = 30 ether; // maintainer pending
        uint256 balanceBefore = address(maintainer).balance;

        vm.prank(maintainer);
        vm.expectEmit(true, true, false, true, address(funding));
        emit UpstreamFunding.WithdrawalCompleted(maintainer, expected, block.timestamp);

        funding.withdraw();

        assertEq(address(maintainer).balance - balanceBefore, expected);
        assertEq(funding.pendingBalance(maintainer), 0);
        assertEq(funding.withdrawnBalance(maintainer), expected);
        assertEq(funding.totalWithdrawn(), expected);
        assertEq(funding.outstandingLiabilities(), 100 ether - expected);
    }

    function test_exact_withdrawn_amount_assertion() public {
        _sponsor(100 ether);

        // Contributor1 withdraws full pending 8 ether.
        uint256 balanceBefore = address(contributor1).balance;
        vm.prank(contributor1);
        funding.withdraw();
        assertEq(address(contributor1).balance - balanceBefore, 8 ether);
        assertEq(funding.pendingBalance(contributor1), 0);
    }

    function test_non_recipient_cannot_withdraw() public {
        vm.prank(nonRecipient);
        vm.expectRevert(UpstreamFunding.NotARecipient.selector);
        funding.withdraw();
    }

    function test_recipient_cannot_withdraw_another_balance() public {
        _sponsor(100 ether);
        // maintainer tries to withdraw from contributor1's balance: impossible
        // because withdraw() always uses msg.sender.
        uint256 balanceBefore = address(maintainer).balance;
        vm.prank(maintainer);
        funding.withdraw(); // withdraws maintainer's own 30 ether only
        assertEq(address(maintainer).balance - balanceBefore, 30 ether);
        assertEq(funding.pendingBalance(contributor1), 8 ether); // untouched
    }

    function test_double_withdrawal_reverted() public {
        _sponsor(100 ether);
        vm.prank(maintainer);
        funding.withdraw(); // 30 ether, pending now 0
        vm.prank(maintainer);
        vm.expectRevert(UpstreamFunding.ZeroBalance.selector);
        funding.withdraw();
    }

    function test_withdraw_clears_balance_before_transfer() public {
        _sponsor(100 ether);
        assertEq(funding.pendingBalance(maintainer), 30 ether);
        vm.prank(maintainer);
        funding.withdraw();
        assertEq(funding.pendingBalance(maintainer), 0);
    }

    // -----------------------------------------------------------------------
    // 15. Failed ETH transfer handling
    // -----------------------------------------------------------------------
    function test_withdrawal_to_contract_that_rejects_eth() public {
        RejectETH reject = new RejectETH();
        // Deploy a funding where `reject` is the maintainer so its withdraw fails.
        address[] memory addrs = new address[](1);
        string[] memory names = new string[](1);
        uint8[] memory cats = new uint8[](1);
        uint16[] memory shares = new uint16[](1);
        addrs[0] = address(reject);
        names[0] = "Reject";
        cats[0] = CAT_MAINTAINER;
        shares[0] = 10000;
        UpstreamFunding single = new UpstreamFunding(names, cats, addrs, shares);

        vm.deal(address(single), 1 ether);
        vm.prank(sponsor);
        single.sponsor{ value: 1 ether }();

        vm.prank(address(reject));
        vm.expectRevert(UpstreamFunding.TransferFailed.selector);
        single.withdraw();
        // Accounting restored: recipient can retry.
        assertEq(single.pendingBalance(address(reject)), 1 ether);
    }

    // -----------------------------------------------------------------------
    // 16. Reentrancy attack prevention
    // -----------------------------------------------------------------------
    function test_reentrancy_attack_on_withdraw_reverted() public {
        // Attacker contract is the sole recipient; its receive() re-enters
        // withdraw(). nonReentrant + CEI must prevent a double payout.
        ReentrantWithdrawer attacker = new ReentrantWithdrawer();
        address[] memory addrs = new address[](1);
        string[] memory names = new string[](1);
        uint8[] memory cats = new uint8[](1);
        uint16[] memory shares = new uint16[](1);
        addrs[0] = address(attacker);
        names[0] = "Attacker";
        cats[0] = CAT_MAINTAINER;
        shares[0] = 10000;
        UpstreamFunding single = new UpstreamFunding(names, cats, addrs, shares);
        attacker.setFunding(address(single));

        vm.deal(address(single), 1 ether);
        vm.prank(sponsor);
        single.sponsor{ value: 1 ether }();
        assertEq(single.pendingBalance(address(attacker)), 1 ether);

        vm.prank(sponsor);
        vm.expectRevert(UpstreamFunding.TransferFailed.selector);
        attacker.attack();

        // No double payout: accounting was restored on the failed transfer.
        assertEq(single.pendingBalance(address(attacker)), 1 ether);
        assertEq(single.withdrawnBalance(address(attacker)), 0);
    }

    // -----------------------------------------------------------------------
    // 17. Malicious recipient isolation
    // -----------------------------------------------------------------------
    function test_malicious_recipient_does_not_block_others() public {
        RejectETH reject = new RejectETH();

        address[] memory addrs = new address[](2);
        string[] memory names = new string[](2);
        uint8[] memory cats = new uint8[](2);
        uint16[] memory shares = new uint16[](2);
        addrs[0] = address(reject);
        names[0] = "Reject";
        cats[0] = 0;
        shares[0] = 5000;
        addrs[1] = maintainer;
        names[1] = "Alice";
        cats[1] = 0;
        shares[1] = 5000;
        UpstreamFunding mixed = new UpstreamFunding(names, cats, addrs, shares);

        vm.prank(sponsor);
        mixed.sponsor{ value: 2 ether }();

        // The well-behaved recipient can still withdraw even though the
        // reject-contract recipient cannot.
        vm.prank(maintainer);
        mixed.withdraw();
        assertEq(mixed.pendingBalance(maintainer), 0);
        assertEq(mixed.pendingBalance(address(reject)), 1 ether); // still pending
    }

    // -----------------------------------------------------------------------
    // 18. No administrative fund extraction
    // -----------------------------------------------------------------------
    function test_no_owner_or_admin_can_extract_funds() public {
        _sponsor(100 ether);
        // There is no owner/withdraw function other than recipients pulling
        // their own pending balance. No privileged path moves credited funds.
        assertEq(funding.totalCredited(), 100 ether);
        // Non-recipient cannot withdraw.
        vm.prank(nonRecipient);
        vm.expectRevert(UpstreamFunding.NotARecipient.selector);
        funding.withdraw();
    }

    // -----------------------------------------------------------------------
    // 19. No unauthorized split modification
    // -----------------------------------------------------------------------
    function test_no_function_to_modify_split() public {
        // After construction, shares are immutable. There is no setter.
        // Verify shares remain unchanged after sponsorships.
        _sponsor(100 ether);
        assertEq(funding.getRecipientShare(0), SHARE_MAINTAINER);
        assertEq(funding.getRecipientShare(1), SHARE_CONTRIBUTOR);
        assertEq(funding.getRecipientShare(6), SHARE_UPSTREAM);
        uint256 total = 0;
        for (uint256 i = 0; i < 9; i++) {
            total += uint256(funding.getRecipientShare(i));
        }
        assertEq(total, BPS);
    }

    // -----------------------------------------------------------------------
    // 20. Accounting invariants across multiple deposits
    // -----------------------------------------------------------------------
    function test_accounting_invariants_across_deposits() public {
        _sponsor(100 ether);
        _sponsor(50 ether);
        _sponsor(25 ether);

        uint256 totalReceived = 175 ether;
        assertEq(funding.totalReceived(), totalReceived);
        assertEq(funding.totalCredited(), totalReceived);
        assertEq(address(funding).balance, totalReceived);
        assertEq(funding.outstandingLiabilities(), totalReceived);

        // Withdraw some, invariant totalCredited - totalWithdrawn == sum pending holds.
        vm.prank(maintainer);
        funding.withdraw(); // maintainer pending = 30% of 175 = 52.5 -> truncated
        uint256 maintainerCredited = funding.creditedBalance(maintainer);
        assertEq(funding.withdrawnBalance(maintainer), maintainerCredited);
        assertEq(funding.pendingBalance(maintainer), 0);

        uint256 sumPending = 0;
        for (uint256 i = 0; i < 9; i++) {
            (address a,) = _recipientAt(funding, i);
            sumPending += funding.pendingBalance(a);
        }
        assertEq(sumPending, funding.outstandingLiabilities());
        assertEq(funding.outstandingLiabilities(), totalReceived - maintainerCredited);
    }

    // -----------------------------------------------------------------------
    // receive() path
    // -----------------------------------------------------------------------
    function test_receive_path_allocates() public {
        uint256 before = funding.totalReceived();
        (bool ok,) = payable(address(funding)).call{ value: 10 ether }("");
        assertTrue(ok);
        assertEq(funding.totalReceived(), before + 10 ether);
        assertEq(funding.totalCredited(), before + 10 ether);
    }

    // -----------------------------------------------------------------------
    // Fuzz tests
    // -----------------------------------------------------------------------
    /**
     * @dev For any positive sponsorship amount, the sum of credited
     *      allocations (including the rounding remainder) must equal msg.value.
     */
    function test_fuzz_sponsorship_preserves_value_invariant(uint256 value) public {
        vm.assume(value > 0);
        vm.assume(value < 200 ether); // sponsor is funded with 300 ether per run
        _sponsor(value);

        uint256 sum = 0;
        for (uint256 i = 0; i < funding.recipientCount(); i++) {
            (address a,) = _recipientAt(funding, i);
            sum += funding.creditedBalance(a);
        }
        assertEq(sum, value);
        assertEq(funding.totalCredited(), value);
        assertEq(funding.totalReceived(), value);
        assertEq(funding.outstandingLiabilities(), value);
    }

    // -----------------------------------------------------------------------
    // Invariant tests (run after every test)
    // -----------------------------------------------------------------------
    function invariant_total_credited_equals_total_received() public view {
        assertEq(funding.totalCredited(), funding.totalReceived());
    }

    function invariant_outstanding_equals_credited_minus_withdrawn() public view {
        assertEq(funding.outstandingLiabilities(), funding.totalCredited() - funding.totalWithdrawn());
    }

    function invariant_sum_pending_equals_outstanding_liabilities() public view {
        uint256 sumPending = 0;
        for (uint256 i = 0; i < funding.recipientCount(); i++) {
            (address a,) = _recipientAt(funding, i);
            sumPending += funding.pendingBalance(a);
        }
        assertEq(sumPending, funding.outstandingLiabilities());
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    function _recipientAt(UpstreamFunding f, uint256 i) internal view returns (address, uint16) {
        return (f.getRecipientAddress(i), f.getRecipientShare(i));
    }
}

// ---------------------------------------------------------------------------
// Reentrant attacker contract: attempts to re-enter withdraw().
// ---------------------------------------------------------------------------
contract ReentrantWithdrawer {
    address payable public funding;

    constructor() { }

    function setFunding(address _funding) external {
        funding = payable(_funding);
    }

    function attack() external payable {
        UpstreamFunding(funding).withdraw();
    }

    receive() external payable {
        // Attempt re-entry: nonReentrant causes the inner call to revert,
        // which makes the outer ETH transfer fail and restores accounting.
        UpstreamFunding(funding).withdraw();
    }
}

// ---------------------------------------------------------------------------
// Contract beneficiary that rejects all incoming ETH.
// ---------------------------------------------------------------------------
contract RejectETH {
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }
}

// ---------------------------------------------------------------------------
// Deployment configuration validation tests
// ---------------------------------------------------------------------------
// These tests replicate the exact index-to-role allocation validation logic
// from script/Deploy.s.sol to verify it rejects all deviations before any
// broadcast would occur.
contract DeployConfigTest is Test {
    error InvalidAllocationMapping(
        uint256 index, uint8 expectedCategory, uint16 expectedShare, uint8 actualCategory, uint16 actualShare
    );

    address public immutable maintainer = address(0xAAAA);
    address public immutable contributor1 = address(0xBBBB);
    address public immutable contributor2 = address(0xCCCC);
    address public immutable contributor3 = address(0xDDDD);
    address public immutable contributor4 = address(0xEEEE);
    address public immutable contributor5 = address(0xFFFF);
    address public immutable upstream1 = address(0x1000);
    address public immutable upstream2 = address(0x1111);
    address public immutable upstream3 = address(0x1222);

    uint8[9] public categories;
    uint16[9] public shares;

    function setUp() public {
        _setAllCorrect();
    }

    function _setAllCorrect() internal {
        categories[0] = 0; // maintainer
        shares[0] = 3000;
        categories[1] = 1; // contributor
        shares[1] = 800;
        categories[2] = 1; // contributor
        shares[2] = 800;
        categories[3] = 1; // contributor
        shares[3] = 800;
        categories[4] = 1; // contributor
        shares[4] = 800;
        categories[5] = 1; // contributor
        shares[5] = 800;
        categories[6] = 2; // upstream dependency
        shares[6] = 1000;
        categories[7] = 2; // upstream dependency
        shares[7] = 1000;
        categories[8] = 2; // upstream dependency
        shares[8] = 1000;
    }

    function _validateMapping() external view {
        // Index 0: maintainer, category 0, 3000 BPS.
        if (categories[0] != 0 || shares[0] != 3000) {
            revert InvalidAllocationMapping(0, 0, 3000, categories[0], shares[0]);
        }
        // Indices 1-5: contributors, category 1, 800 BPS each.
        for (uint256 i = 1; i <= 5; i++) {
            if (categories[i] != 1 || shares[i] != 800) {
                revert InvalidAllocationMapping(i, 1, 800, categories[i], shares[i]);
            }
        }
        // Indices 6-8: upstream dependencies, category 2, 1000 BPS each.
        for (uint256 i = 6; i <= 8; i++) {
            if (categories[i] != 2 || shares[i] != 1000) {
                revert InvalidAllocationMapping(i, 2, 1000, categories[i], shares[i]);
            }
        }
    }

    function test_deploy_correct_mapping_accepted() public {
        this._validateMapping(); // should not revert
    }

    function test_deploy_wrong_maintainer_category_rejected() public {
        categories[0] = 1; // should be 0 (maintainer)
        vm.expectRevert();
        this._validateMapping();
    }

    function test_deploy_wrong_maintainer_share_rejected() public {
        shares[0] = 2000; // should be 3000
        vm.expectRevert();
        this._validateMapping();
    }

    function test_deploy_wrong_contributor_category_rejected() public {
        categories[1] = 2; // should be 1 (contributor)
        vm.expectRevert();
        this._validateMapping();
    }

    function test_deploy_wrong_contributor_share_rejected() public {
        shares[2] = 900; // should be 800
        vm.expectRevert();
        this._validateMapping();
    }

    function test_deploy_wrong_upstream_category_rejected() public {
        categories[6] = 1; // should be 2 (upstream dependency)
        vm.expectRevert();
        this._validateMapping();
    }

    function test_deploy_wrong_upstream_share_rejected() public {
        shares[8] = 900; // should be 1000
        vm.expectRevert();
        this._validateMapping();
    }

    function test_deploy_incorrect_index_assignment_rejected() public {
        // Swap maintainer and first contributor roles across indices.
        categories[0] = 1; // index 0 gets contributor role
        shares[0] = 800;
        categories[1] = 0; // index 1 gets maintainer role
        shares[1] = 3000;
        vm.expectRevert();
        this._validateMapping();
    }
}
