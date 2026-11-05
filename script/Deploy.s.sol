// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console2 } from "forge-std/Script.sol";
import { UpstreamFunding } from "../contracts/UpstreamFunding.sol";

/**
 * @notice Deploys UpstreamFunding to Sepolia (chainId 11155111).
 *
 * The constructor is non-payable and requires no ETH (sponsorships arrive later).
 *
 * Environment variables / Forge flags:
 *   SEPOLIA_RPC_URL      - Sepolia RPC endpoint (--rpc-url)
 *   DEPLOYER_PRIVATE_KEY - funded deployer key (--private-key)
 *
 * Recipient configuration (9 recipients), one set per index 0..8:
 *   UPSTREAM_NAME_0..8      - human-readable name
 *   UPSTREAM_CAT_0..8       - category (0 maintainer, 1 contributor, 2 upstream dependency)
 *   UPSTREAM_ADDR_0..8      - recipient Ethereum address
 *   UPSTREAM_SHARE_0..8     - allocation share in basis points
 *
 * The shares must sum to exactly 10000 (BPS_DENOMINATOR), addresses must be
 * unique and non-zero, and shares must be non-zero.
 *
 * Illustrative allocation (the project's intended split):
 *   Index 0: maintainer        3000 bps (30%)
 *   Index 1-5: contributors    800 bps each (8% each)
 *   Index 6-8: upstream deps   1000 bps each (10% each)
 *
 * Example (forgescript):
 *   forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL \
 *     --private-key $DEPLOYER_PRIVATE_KEY --broadcast
 */
contract Deploy is Script {
    // -----------------------------------------------------------------------
    // Pre-deployment validation errors
    // -----------------------------------------------------------------------
    /// @notice Emitted when a required environment variable is not set.
    error MissingEnvVariable(string varName);

    /// @notice Emitted when an environment variable value is invalid.
    ///         The value itself is never disclosed.
    error InvalidEnvValue(string varName, string reason);

    /// @notice Emitted when a recipient category is not 0, 1, or 2.
    error InvalidCategory(uint8 category, string varName);

    /// @notice Emitted when the same address is configured for two recipients.
    error DuplicateAddressConfig(address addr);

    /// @notice Emitted when the sum of all shares is not exactly 10000 BPS.
    error InvalidTotalSharesConfig(uint256 totalShares);

    /// @notice Emitted when a recipient index does not match the required
    ///         role and share for the intended allocation mapping.
    error InvalidAllocationMapping(
        uint256 index, uint8 expectedCategory, uint16 expectedShare, uint8 actualCategory, uint16 actualShare
    );

    // -----------------------------------------------------------------------
    // Entry point
    // -----------------------------------------------------------------------
    function run() external {
        // -------------------------------------------------------------------
        // 1. Network guard: Sepolia only (chainId 11155111).
        // -------------------------------------------------------------------
        require(block.chainid == 11155111, "Deploy: network must be Sepolia (chainId 11155111)");

        address deployer = msg.sender;
        console2.log("Deployer", deployer);
        console2.log("Chain ID", block.chainid);

        // -------------------------------------------------------------------
        // 2. Recipient environment variable keys.
        // -------------------------------------------------------------------
        string[] memory nameKeys = new string[](9);
        string[] memory catKeys = new string[](9);
        string[] memory addrKeys = new string[](9);
        string[] memory shareKeys = new string[](9);

        nameKeys[0] = "UPSTREAM_NAME_0";
        catKeys[0] = "UPSTREAM_CAT_0";
        addrKeys[0] = "UPSTREAM_ADDR_0";
        shareKeys[0] = "UPSTREAM_SHARE_0";

        nameKeys[1] = "UPSTREAM_NAME_1";
        catKeys[1] = "UPSTREAM_CAT_1";
        addrKeys[1] = "UPSTREAM_ADDR_1";
        shareKeys[1] = "UPSTREAM_SHARE_1";

        nameKeys[2] = "UPSTREAM_NAME_2";
        catKeys[2] = "UPSTREAM_CAT_2";
        addrKeys[2] = "UPSTREAM_ADDR_2";
        shareKeys[2] = "UPSTREAM_SHARE_2";

        nameKeys[3] = "UPSTREAM_NAME_3";
        catKeys[3] = "UPSTREAM_CAT_3";
        addrKeys[3] = "UPSTREAM_ADDR_3";
        shareKeys[3] = "UPSTREAM_SHARE_3";

        nameKeys[4] = "UPSTREAM_NAME_4";
        catKeys[4] = "UPSTREAM_CAT_4";
        addrKeys[4] = "UPSTREAM_ADDR_4";
        shareKeys[4] = "UPSTREAM_SHARE_4";

        nameKeys[5] = "UPSTREAM_NAME_5";
        catKeys[5] = "UPSTREAM_CAT_5";
        addrKeys[5] = "UPSTREAM_ADDR_5";
        shareKeys[5] = "UPSTREAM_SHARE_5";

        nameKeys[6] = "UPSTREAM_NAME_6";
        catKeys[6] = "UPSTREAM_CAT_6";
        addrKeys[6] = "UPSTREAM_ADDR_6";
        shareKeys[6] = "UPSTREAM_SHARE_6";

        nameKeys[7] = "UPSTREAM_NAME_7";
        catKeys[7] = "UPSTREAM_CAT_7";
        addrKeys[7] = "UPSTREAM_ADDR_7";
        shareKeys[7] = "UPSTREAM_SHARE_7";

        nameKeys[8] = "UPSTREAM_NAME_8";
        catKeys[8] = "UPSTREAM_CAT_8";
        addrKeys[8] = "UPSTREAM_ADDR_8";
        shareKeys[8] = "UPSTREAM_SHARE_8";

        // -------------------------------------------------------------------
        // 3. Read and validate all 9 recipients before any broadcast.
        //    Local configuration validation happens here, before the
        //    constructor (and therefore before any on-chain transaction).
        // -------------------------------------------------------------------
        string[] memory names = new string[](9);
        uint8[] memory categories = new uint8[](9);
        address[] memory addrs = new address[](9);
        uint16[] memory shares = new uint16[](9);

        for (uint256 i = 0; i < 9; i++) {
            names[i] = _readEnvString(nameKeys[i]);
            categories[i] = _readEnvUint8(catKeys[i]);
            addrs[i] = _readEnvAddress(addrKeys[i]);
            shares[i] = _readEnvUint16(shareKeys[i]);
        }

        // -------------------------------------------------------------------
        // 4. Validate categories: only 0 (maintainer), 1 (contributor),
        //    or 2 (upstream dependency) are permitted.
        // -------------------------------------------------------------------
        for (uint256 i = 0; i < 9; i++) {
            if (categories[i] > 2) {
                revert InvalidCategory(categories[i], catKeys[i]);
            }
        }

        // -------------------------------------------------------------------
        // 5. Validate addresses: non-zero and unique.
        // -------------------------------------------------------------------
        for (uint256 i = 0; i < 9; i++) {
            if (addrs[i] == address(0)) {
                revert InvalidEnvValue(addrKeys[i], "zero address");
            }
            for (uint256 j = i + 1; j < 9; j++) {
                if (addrs[i] == addrs[j]) {
                    revert DuplicateAddressConfig(addrs[i]);
                }
            }
        }

        // -------------------------------------------------------------------
        // 6. Validate shares: non-zero.
        // -------------------------------------------------------------------
        for (uint256 i = 0; i < 9; i++) {
            if (shares[i] == 0) {
                revert InvalidEnvValue(shareKeys[i], "zero share");
            }
        }

        // -------------------------------------------------------------------
        // 7. Validate total shares: must equal exactly 10000 BPS.
        // -------------------------------------------------------------------
        uint256 totalShares = 0;
        for (uint256 i = 0; i < 9; i++) {
            totalShares += uint256(shares[i]);
        }
        if (totalShares != 10000) {
            revert InvalidTotalSharesConfig(totalShares);
        }

        // -------------------------------------------------------------------
        // 8. Enforce exact index-to-role allocation mapping before any
        //    broadcast. Index 0 is the maintainer and also the designated
        //    remainder recipient (REMAINDER_RECIPIENT_INDEX = 0 in the
        //    contract). Placing the wrong recipient at index 0 would divert
        //    all rounding dust to the wrong party.
        // -------------------------------------------------------------------
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

        // -------------------------------------------------------------------
        // 9. All local configuration validation passed. Proceed to broadcast
        //    the deployment transaction. The constructor performs a second,
        //    independent round of validation (ZeroAddress, ZeroShare,
        //    DuplicateAddress, InvalidTotalShares) before any state change.
        //    If the constructor reverts, the broadcast transaction consumes
        //    gas but makes no state change and deploys no contract.
        // -------------------------------------------------------------------
        vm.startBroadcast();
        UpstreamFunding funding = new UpstreamFunding(names, categories, addrs, shares);
        vm.stopBroadcast();

        console2.log("UpstreamFunding", address(funding));
        console2.log("Recipient count", funding.recipientCount());
        console2.log("Total shares", totalShares);

        string memory key = "deployment";
        vm.serializeAddress(key, "deployer", deployer);
        vm.serializeUint(key, "chainId", block.chainid);
        vm.serializeAddress(key, "contractAddress", address(funding));
        vm.serializeUint(key, "recipientCount", funding.recipientCount());
        vm.serializeUint(key, "totalShares", totalShares);
    }

    // -----------------------------------------------------------------------
    // Environment variable readers with readable missing-variable errors
    // -----------------------------------------------------------------------

    /**
     * @dev Reads a string environment variable.
     *      Reverts MissingEnvVariable if the variable is not set.
     *      Reverts InvalidEnvValue if the value is an empty string.
     *      The variable value is never disclosed in error messages.
     */
    function _readEnvString(string memory key) internal returns (string memory) {
        try vm.envString(key) returns (string memory value) {
            if (bytes(value).length == 0) {
                revert InvalidEnvValue(key, "empty string");
            }
            return value;
        } catch {
            revert MissingEnvVariable(key);
        }
    }

    /**
     * @dev Reads a uint environment variable and truncates to uint8.
     *      Reverts MissingEnvVariable if the variable is not set.
     */
    function _readEnvUint8(string memory key) internal returns (uint8) {
        try vm.envUint(key) returns (uint256 value) {
            return uint8(value);
        } catch {
            revert MissingEnvVariable(key);
        }
    }

    /**
     * @dev Reads an address environment variable.
     *      Reverts MissingEnvVariable if the variable is not set.
     *      The address value is validated for zero separately.
     */
    function _readEnvAddress(string memory key) internal returns (address) {
        try vm.envAddress(key) returns (address value) {
            return value;
        } catch {
            revert MissingEnvVariable(key);
        }
    }

    /**
     * @dev Reads a uint environment variable and truncates to uint16.
     *      Reverts MissingEnvVariable if the variable is not set.
     */
    function _readEnvUint16(string memory key) internal returns (uint16) {
        try vm.envUint(key) returns (uint256 value) {
            return uint16(value);
        } catch {
            revert MissingEnvVariable(key);
        }
    }
}
