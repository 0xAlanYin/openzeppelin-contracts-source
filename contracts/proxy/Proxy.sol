// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Proxy.sol)

pragma solidity ^0.8.20;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            // 将 calldata 从偏移量 0 开始，长度为 calldatasize() 复制到内存中的偏移量 0，以便在委托调用中使用
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            // -gas() = 随调用一起发送的 Gas 数量
            // -implementation = 委托调用的合约地址，比如实现合约
            // -in = 输入(input)的起始内存位置 - 这标记着将发送到目标合约的输入数据在内存中的起始位置，记住 calldatacopy 复制到内存位置 0。
            // -insize = 输入大小 - 输入数据的大小（以字节为单位），在我们的情况下是 calldatasize()
            // -out = 输出的起始内存位置 - 标记着委托调用的输出数据将存储在内存中的起始位置，选择位置 0
            // -outsize = 输出大小 - 内存中输出区域的大小（以字节为单位），在我们的情况下为 0，这意味着不会将任何内容存储在内存中
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            // 注意，委托调用的输出值（而不是结果）将存储在返回数据缓冲区中。
            // 这可以使用 returnDataCopy 来访问。这意味着即使我们没有将其保存到内存中，返回值仍然可用
            // returndatacopy(destOffset = 0, srcOffset = 0, length = returndatasize())
            returndatacopy(0, 0, returndatasize())

            // 变量“result”捕获了委托调用是否成功执行的信息。0 表示执行失败。
            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }
}
