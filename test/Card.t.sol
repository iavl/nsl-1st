// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@std/Test.sol";
import "@std/console2.sol";
import "../contracts/Card.sol";
import "../contracts/Oracle.sol";
import "./EmitExpecter.sol";

contract CardTest is Test, EmitExpecter {
    Oracle oracle;
    Card card;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public dan = address(0x3);

    function setUp() public {
        oracle = new Oracle();
        card = new Card(address(oracle));
    }

    function testRun() public {
        // new game
        vm.prank(alice);
        card.newGame();
        // join
        vm.prank(bob);
        card.joinGame();
        // join
        vm.prank(dan);
        card.joinGame();
        // start game
        card.startGame();

        while (true) {
            uint256 deadCount = 0;

            if (address(0) != _getWinner()) {
                break;
            }

            /////////////////////// commit
            // alice
            uint256[] memory aliceCards = _getCandidates(alice);
            if (_getHealth(alice) > 0) {
                //        _logUints(aliceCards);
                bytes32 aliceHash = keccak256(abi.encodePacked(aliceCards));
                vm.prank(alice);
                card.commit(aliceCards, aliceHash);
            } else {
                deadCount++;
            }

            // bob
            uint256[] memory bobCards = _getCandidates(bob);
            if (_getHealth(bob) > 0) {
                //        _logUints(bobCards);
                bytes32 bobHash = keccak256(abi.encodePacked(bobCards));
                vm.prank(bob);
                card.commit(bobCards, bobHash);
            } else {
                deadCount++;
            }

            // dan
            uint256[] memory danCards = _getCandidates(dan);
            if (_getHealth(dan) > 0) {
                //        _logUints(danCards);
                bytes32 danHash = keccak256(abi.encodePacked(danCards));
                vm.prank(dan);
                card.commit(danCards, danHash);
            } else {
                deadCount++;
            }

            /////////////////////// reveal
            if (_getHealth(alice) > 0) {
                // alice
                vm.prank(alice);
                card.reveal(aliceCards);
            }
            if (_getHealth(bob) > 0) {
                // bob
                vm.prank(bob);
                card.reveal(bobCards);
            }
            if (_getHealth(dan) > 0) {
                // dan
                vm.prank(dan);
                card.reveal(danCards);
            }

            if (deadCount >= 2) {
                break;
            }

            _logReplayInfo();
        }

        // battle
        _logGameInfo();
    }

    function _getCandidates(address account) internal view returns (uint256[] memory cards) {
        Card.Player[] memory _playersInfo = new Card.Player[](3);
        (, , _playersInfo, ) = card.getGameInfo();

        for (uint256 i = 0; i < _playersInfo.length; i++) {
            if (account == _playersInfo[i].user) {
                cards = _playersInfo[i].candidateCards;
                break;
            }
        }
    }

    function _getHealth(address account) internal view returns (uint256 health) {
        Card.Player[] memory _playersInfo = new Card.Player[](3);

        (, , _playersInfo, ) = card.getGameInfo();

        for (uint256 i = 0; i < _playersInfo.length; i++) {
            if (account == _playersInfo[i].user) {
                health = _playersInfo[i].health;
                break;
            }
        }
    }

    function _getCurrentCards(address account) internal view returns (uint256[] memory cards) {
        Card.Player[] memory _playersInfo = new Card.Player[](3);

        (, , _playersInfo, ) = card.getGameInfo();

        for (uint256 i = 0; i < _playersInfo.length; i++) {
            if (account == _playersInfo[i].user) {
                cards = _playersInfo[i].currentCards;
                break;
            }
        }
    }

    function _getWinner() internal view returns (address winner) {
        (, winner, , ) = card.getGameInfo();
    }

    function _logUints(uint256[] memory arrays) internal {
        console.logBytes32(0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa);
        for (uint256 i = 0; i < arrays.length; i++) {
            console.logUint(arrays[i]);
        }
        console.logBytes32(0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa);
    }

    function _logReplayInfo() internal {
        Card.Replay[] memory _replayInfo = new Card.Replay[](3);

        (, , , _replayInfo) = card.getGameInfo();
        console.logBytes32(0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa);
        console.logUint(_replayInfo.length);
        for (uint256 i = 0; i < _replayInfo.length; i++) {
            Card.Replay memory replay = _replayInfo[i];
            console.logAddress(replay.user1);
            console.logAddress(replay.user2);
            console.logAddress(replay.winner);
        }
        console.logBytes32(0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa);
    }

    function _logGameInfo() internal {
        uint256 round;
        address winner;
        Card.Player[] memory _playersInfo = new Card.Player[](3);
        Card.Replay[] memory _replayInfo = new Card.Replay[](3);

        (round, winner, _playersInfo, _replayInfo) = card.getGameInfo();
        console.logUint(round);
        console.logAddress(winner);

        for (uint256 i = 0; i < _playersInfo.length; i++) {
            Card.Player memory player = _playersInfo[i];
            console.logAddress(player.user);
            console.logUint(player.round);
            //            console.logBytes32(player.commitmentHash);
            console.logUint(player.lastActiveTime);
            //            console.logUint(player.status);
            console.logUint(player.health);

            //            console.logUint(11111111111111111111111111111111111111111111111111111111111111111111);
            //            for (uint256 j = 0; j < player.candidateCards.length; j++) {
            //                console.logUint(player.candidateCards[j]);
            //            }
            //            console.logUint(11111111111111111111111111111111111111111111111111111111111111111111);

            console.logUint(222222222222222222222222222222222222222222222222222222222222222);
        }
    }
}
