// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC-721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC-721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    // safeTransferFrom 方法：如果_to 是一个合约应该调用其onERC721Received方法, 并且检查其返回值，如果返回值不为bytes4(keccak256("onERC721Received(address,uint256,bytes)"))抛出异常
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
