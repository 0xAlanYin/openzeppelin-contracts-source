// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
// 重入保护
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.
    // - 布尔变量比 uint256 更昂贵：在 Solidity 中，布尔变量（boolean）在写操作时比 uint256 等类型更昂贵。
    //这是因为每次写入操作需要先执行一次 SLOAD 操作读取槽的内容，然后替换布尔变量所占的位，再写回。这导致额外的存储操作开销。
    // - 编译器防御措施：这种操作是编译器用来防止合约升级和指针别名的问题，无法被禁用。

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    // - 非零值：将值设为非零（例如，NOT_ENTERED 设置为 1，ENTERED 设置为 2）会使部署合约时的费用稍高，因为初始化非零值比初始化零值成本更高。
    // - 降低退款：但是，这样做的好处是在每次调用 nonReentrant 函数时，退款金额会更低。
    //由于每次交易的退款金额上限是总交易 gas 的一个百分比，因此在这种情况下，保持退款金额较低可以增加获得全额退款的可能性。
    //简言之，使用 uint256 变量比布尔变量更节省 gas 费用，因为 uint256 变量操作不会产生额外的 SLOAD 和 SSTORE 操作，减少了每次调用 nonReentrant 函数的总 gas 消耗。这使得交易的总 gas 消耗较低，提高了获得全额退款(没用完的 gas 会被退还)的可能。
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    // 整个过程相当于上了锁：业务执行前加锁==>执行业务==>业务执行后解锁（与 Java 中的 ）
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    // 如果重入保护当前设置为“entered”，则返回 true，这表示调用堆栈中有一个“nonReentrant”函数。
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}
