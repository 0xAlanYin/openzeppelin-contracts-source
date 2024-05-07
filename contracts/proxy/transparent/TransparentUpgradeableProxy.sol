// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.20;

import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "../ERC1967/ERC1967Proxy.sol";
import {IERC1967} from "../../interfaces/IERC1967.sol";
import {ProxyAdmin} from "./ProxyAdmin.sol";

/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and its upgradeability mechanism is implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface ITransparentUpgradeableProxy is IERC1967 {
    function upgradeToAndCall(address, bytes calldata) external payable;
}

/**
 * @dev This contract implements a proxy that is upgradeable through an associated {ProxyAdmin} instance.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches the {ITransparentUpgradeableProxy-upgradeToAndCall} function exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can call the `upgradeToAndCall` function but any other call won't be forwarded to
 * the implementation. If the admin tries to call a function on the implementation it will fail with an error indicating
 * the proxy admin cannot fallback to the target implementation.
 *
 * These properties mean that the admin account can only be used for upgrading the proxy, so it's best if it's a
 * dedicated account that is not used for anything else. This will avoid headaches due to sudden errors when trying to
 * call a function from the proxy implementation. For this reason, the proxy deploys an instance of {ProxyAdmin} and
 * allows upgrades only if they come through it. You should think of the `ProxyAdmin` instance as the administrative
 * interface of the proxy, including the ability to change who can trigger upgrades by transferring ownership.
 *
 * NOTE: The real interface of this proxy is that defined in `ITransparentUpgradeableProxy`. This contract does not
 * inherit from that interface, and instead `upgradeToAndCall` is implicitly implemented using a custom dispatch
 * mechanism in `_fallback`. Consequently, the compiler will not produce an ABI for this contract. This is necessary to
 * fully implement transparency without decoding reverts caused by selector clashes between the proxy and the
 * implementation.
 *
 * NOTE: This proxy does not inherit from {Context} deliberately. The {ProxyAdmin} of this contract won't send a
 * meta-transaction in any way, and any other meta-transaction setup should be made in the implementation contract.
 *
 * IMPORTANT: This contract avoids unnecessary storage reads by setting the admin only during construction as an
 * immutable variable, preventing any changes thereafter. However, the admin slot defined in ERC-1967 can still be
 * overwritten by the implementation logic pointed to by this proxy. In such cases, the contract may end up in an
 * undesirable state where the admin slot is different from the actual admin. Relying on the value of the admin slot
 * is generally fine if the implementation is trusted.
 *
 * WARNING: It is not recommended to extend this contract to add additional external functions. If you do so, the
 * compiler will not check that there are no selector conflicts, due to the note above. A selector clash between any new
 * function and the functions declared in {ITransparentUpgradeableProxy} will be resolved in favor of the new one. This
 * could render the `upgradeToAndCall` function inaccessible, preventing upgradeability and compromising transparency.
 */

//  TransparentUpgradeableProxy 继承自 ERC1967Proxy， ERC1967Proxy 继承自 Proxy
contract TransparentUpgradeableProxy is ERC1967Proxy {
    // An immutable address for the admin to avoid unnecessary SLOADs before each call
    // at the expense of removing the ability to change the admin once it's set.
    // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
    // with its own ability to transfer the permissions to another account.
    address private immutable _admin;

    /**
     * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
     */
    error ProxyDeniedAdminAccess();

    /**
     * @dev Initializes an upgradeable proxy managed by an instance of a {ProxyAdmin} with an `initialOwner`,
     * backed by the implementation at `_logic`, and optionally initialized with `_data` as explained in
     * {ERC1967Proxy-constructor}.
     */
    // 1.构造函数按继承顺序执行，从基类到派生类
    // 2.继承的合约构造函数会自动调用，但如果它们接受参数，必须显式调用它们，比如在“TransparentUpgradeableProxy”构造函数中有 ERC1967Proxy(_logic, _data)。
    //这是显式调用具有特定输入参数的构造函数的语法。
    constructor(address _logic, address initialOwner, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        // 将_admin 设置为 ProxyAdmin 合约地址。授权的是“ProxyAdmin”合约，而不是 ProxyAdmin 所有者 EOA。
        _admin = address(new ProxyAdmin(initialOwner));
        // Set the storage value and emit an event for ERC-1967 compatibility
        ERC1967Utils.changeAdmin(_proxyAdmin());
    }

    /**
     * @dev Returns the admin of this proxy.
     */
    function _proxyAdmin() internal view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
     */
    // 1.由于子合约重写 _fallback,优先执行子合约的 _fallback
    // 2.所有用户调用“TransparentUpgradeableProxy”的所有函数都会调用到这里
    function _fallback() internal virtual override {
        if (msg.sender == _proxyAdmin()) {
            // 管理员用户调用这里
            if (msg.sig != ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                revert ProxyDeniedAdminAccess();
            } else {
                _dispatchUpgradeToAndCall();
            }
        } else {
            // 普通用户调用到父合约
            super._fallback();
        }
    }

    /**
     * @dev Upgrade the implementation of the proxy. See {ERC1967Utils-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - If `data` is empty, `msg.value` must be zero.
     */
    function _dispatchUpgradeToAndCall() private {
        // 从 calldata 中获取新实现地址，然后使用 ERC1967Utils.UpgradeToAndCall，传入新实现地址和任何后续调用的数据。
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }
}
