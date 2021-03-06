pragma solidity ^0.4.24;

import {SimpleDecode} from "../lib/SimpleDecode.sol";
import {RequestableI} from "../lib/RequestableI.sol";
import {BaseCounter} from "./BaseCounter.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";


/// @notice A request can decrease `n`. Is it right to decrease the count?
contract FreezableCounter is BaseCounter, RequestableI {
  // SimpleDecode library to decode trieValue.
  using SimpleDecode for bytes;
  using SafeMath for *;

  // trie key for state variable `n`.
  bytes32 constant public TRIE_KEY_N = 0x00;

  // address of RootChain contract.
  address public rootchain;

  mapping (uint => bool) appliedRequests;

  // freeze counter before make request.
  bool public freezed;

  constructor(address _rootchain) {
    rootchain = _rootchain;

    // Counter in child chain is freezed at first.
    if (_rootchain == address(0)) {
      freezed = true;
    }
  }

  function freeze() external returns (bool success) {
    freezed = true;
    return true;
  }

  function applyRequestInRootChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes trieValue
  ) external returns (bool success) {
    require(!appliedRequests[requestId]);
    require(msg.sender == rootchain);
    require(freezed);

    // only accept request for `n`.
    require(trieKey == TRIE_KEY_N);

    if (isExit) {
      freezed = false;
      n = trieValue.toUint();
    } else {
      require(n == trieValue.toUint());
    }

    appliedRequests[requestId] = true;
  }

  function applyRequestInChildChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes trieValue
  ) external returns (bool success) {
    require(!appliedRequests[requestId]);
    require(msg.sender == address(0));
    require(freezed);

    // only accept request for `n`.
    require(trieKey == TRIE_KEY_N);

    if (isExit) {
      require(n == trieValue.toUint());
    } else {
      n = trieValue.toUint();
      freezed = false;
    }

    appliedRequests[requestId] = true;
  }
}