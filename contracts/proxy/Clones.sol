// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

pragma solidity ^0.8.20;

import {Errors} from "../utils/Errors.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[ERC-1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[ERC-1167] 是用于部署最小代理合约的标准，也称为“克隆”。
 *
 * > 为了以不可变的方式简单且便宜地克隆合约功能，该标准指定了一个最小的字节码实现，该实现将所有调用委托给一个已知的固定地址。
 *
 * 该库包括使用 `create`（传统部署）或 `create2`（加 salt 的确定性部署）来部署代理的函数。它包含了使用确定性方法预测克隆地址的函数。
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        return clone(implementation, 0);
    }

    /**
     * @dev Same as {xref-Clones-clone-address-}[clone], but with a `value` parameter to send native currency
     * to the new contract.
     *
     * NOTE: Using a non-zero value at creation will require the contract using this function (e.g. a factory)
     * to always have enough balance for new deployments. Consider exposing this function under a payable method.
     */
    /**
     * @dev 与 {xref-Clones-clone-address-}[clone] 相同，但添加了一个 `value` 参数，用于向新合约发送 native 货币。
     *
     * 注意：在创建时使用非零值将要求使用此函数的合约（例如工厂合约）始终具有足够的余额以进行新的部署。请考虑将此函数公开为一个可支付的方法。
     */
    function clone(address implementation, uint256 value) internal returns (address instance) {
        // 在部署新合约之前，确保当前合约的余额足以覆盖传递的value
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // 使用mstore在内存中存储最小代理合约的字节码
            // Stores the bytecode after address
            mstore(0x20, 0x5af43d82803e903d91602b57fd5bf3)
            // 组合字节码和实现合约地址，形成完整的最小代理合约的字节码
            // implementation address
            mstore(0x11, implementation)
            // Packs the first 3 bytes of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0x88, implementation), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // 使用create操作码部署合约，并传递value
            instance := create(value, 0x09, 0x37)
        }

        // 确保合约部署成功。如果部署失败，返回错误
        if (instance == address(0)) {
            revert Errors.FailedDeployment();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    /**
     * @dev 部署并返回一个克隆合约的地址，该克隆合约模仿 `implementation` 的行为。
     *
     * 该函数使用 create2 操作码和 `salt` 来确定性地部署克隆。多次使用相同的 `implementation` 和 `salt` 会导致回退，
     * 因为克隆合约不能在同一地址部署两次。
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        return cloneDeterministic(implementation, salt, 0);
    }

    /**
     * @dev Same as {xref-Clones-cloneDeterministic-address-bytes32-}[cloneDeterministic], but with
     * a `value` parameter to send native currency to the new contract.
     *
     * NOTE: Using a non-zero value at creation will require the contract using this function (e.g. a factory)
     * to always have enough balance for new deployments. Consider exposing this function under a payable method.
     */
    function cloneDeterministic(address implementation, bytes32 salt, uint256 value)
        internal
        returns (address instance)
    {
        if (address(this).balance < value) {
            revert Errors.InsufficientBalance(address(this).balance, value);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Stores the bytecode after address
            mstore(0x20, 0x5af43d82803e903d91602b57fd5bf3)
            // implementation address
            mstore(0x11, implementation)
            // Packs the first 3 bytes of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0x88, implementation), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            instance := create2(value, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert Errors.FailedDeployment();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := and(keccak256(add(ptr, 0x43), 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}
