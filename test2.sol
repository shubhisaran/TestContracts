// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol@4.7.3";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol@4.7.3";

interface PayableProxyInterface {
    fallback() external payable;
}

interface IUpgradeBeacon {
    function implementation() external view returns (address);
}


contract PayableProxy is PayableProxyInterface {
    // Address of the beacon.
    address private immutable _beacon;

    constructor(address beacon) payable {
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Deployment must originate from an approved deployer."
        );
        _beacon = beacon;
    }

    function initialize(address ownerToSet) external {
        require(
            (tx.origin == address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) ||
                tx.origin ==
                address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) ||
                tx.origin ==
                address(0x86D26897267711ea4b173C8C124a0A73612001da) ||
                tx.origin ==
                address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)),
            "Initialize must originate from an approved deployer."
        );
        // Get the implementation address from the provided beacon.
        address implementation = IUpgradeBeacon(_beacon).implementation();

        // Create the initializationCalldata from the provided parameters.
        bytes memory initializationCalldata = abi.encodeWithSignature(
            "initialize(address)",
            ownerToSet
        );

        (bool ok, ) = implementation.delegatecall(initializationCalldata);

        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    fallback() external payable override {
        _fallback();
    }


    function _fallback() internal {
        // Delegate if call value is zero.
        if (msg.value == 0) {
            _delegate(_implementation());
        }
    }

    function _delegate(address implementation) internal virtual {
        assembly { calldatacopy(0, 0, calldatasize())

            let result := delegatecall(
                gas(),
                implementation,
                0, 
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    function _implementation() internal view returns (address) {
        return IUpgradeBeacon(_beacon).implementation();
    }
}