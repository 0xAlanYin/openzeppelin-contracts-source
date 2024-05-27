// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC721Receiver} from "../IERC721Receiver.sol";
import {IERC721Errors} from "../../../interfaces/draft-IERC6093.sol";

/**
 * @dev Library that provide common ERC-721 utility functions.
 *
 * See https://eips.ethereum.org/EIPS/eip-721[ERC-721].
 */
library ERC721Utils {
    /**
     * @dev Performs an acceptance check for the provided `operator` by calling {IERC721-onERC721Received}
     * on the `to` address. The `operator` is generally the address that initiated the token transfer (i.e. `msg.sender`).
     *
     * The acceptance call is not executed and treated as a no-op if the target address doesn't contain code (i.e. an EOA).
     * Otherwise, the recipient must implement {IERC721Receiver-onERC721Received} and return the acceptance magic value to accept
     * the transfer.
     */
    /**
     * 通过在“to”地址上调用 {IERC721-onERC721Received} 对所提供的“operator”执行验收检查。 “operator”通常是发起令牌传输的地址（即“msg.sender”）。
     * 如果目标地址不包含代码（即 EOA），则不会执行接受调用，并将其视为无操作。
     * 否则，接收方必须实现 {IERC721Receiver-onERC721Received} 并返回接受魔法值以接受转账。Ï
     */
    function checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        internal
    {
        // to.code.length > 0 说明是合约，不是 EOA 账户
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    // Token rejected
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-IERC721Receiver implementer
                    revert IERC721Errors.ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}
