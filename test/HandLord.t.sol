// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@std/Test.sol";
import "@std/console2.sol";
import "../contracts/HandLord.sol";
import "../contracts/Oracle.sol";
import "./EmitExpecter.sol";

contract HandLordTest is Test, EmitExpecter {
    Oracle oracle;
    HandLord card;

    address public alice = address(0x1);
    address public bob = address(0x2);
    address public dan = address(0x3);

    function setUp() public {
        oracle = new Oracle();
        card = new HandLord(address(oracle));
    }

    function testWith3Players() public {
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
            if (address(0) != _getWinner()) {
                break;
            }

            /////////////////////// commit
            _commit(alice);
            _commit(bob);
            _commit(dan);

            /////////////////////// reveal
            _reveal(alice);
            _reveal(bob);
            _reveal(dan);
        }

        _logGameInfo();
    }

    function test1V1() public {
        // new game
        vm.prank(alice);
        card.newGame();
        // join
        vm.prank(bob);
        card.joinGame();
        // start game
        card.startGame();

        while (true) {
            if (address(0) != _getWinner()) {
                break;
            }

            //            /////////////////////// commit
            //            _commit(alice);
            //            _commit(bob);
            //
            //            /////////////////////// reveal
            //            _reveal(alice);
            //            _reveal(bob);
            _autoRun(alice);
            _autoRun(bob);
        }

        _logGameInfo();
    }

    function testTimeout() public {
        // new game
        vm.prank(alice);
        card.newGame();
        // join
        vm.prank(bob);
        card.joinGame();
        // start game
        card.startGame();

        /////////////////////// commit
        // alice
        _commit(alice);
        _reveal(alice);

        // timeout
        skip(300);
        vm.prank(alice);
        card.settle();

        _logGameInfo();

        // round 2
        _commit(alice);
        _commit(bob);
        _reveal(alice);
        _reveal(bob);

        _logGameInfo();
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
            if (address(0) != _getWinner()) {
                break;
            }

            /////////////////////// commit
            _commit(alice);
            _commit(bob);
            _commit(dan);

            /////////////////////// reveal
            _reveal(alice);
            _reveal(bob);
            _reveal(dan);
        }

        // battle
        _logGameInfo();
    }

    function _commit(address account) internal {
        uint256[] memory candidatesCards = _getCandidates(account);

        if (_getHealth(account) > 0) {
            bytes32 hash = keccak256(abi.encodePacked(candidatesCards));
            vm.prank(account);
            card.commit(candidatesCards, hash);
        }
    }

    function _reveal(address account) internal {
        uint256[] memory candidatesCards = _getCandidates(account);
        if (_getHealth(account) > 0) {
            vm.prank(account);
            card.reveal(candidatesCards);
        }
    }

    function _autoRun(address account) internal {
        if (_getHealth(account) > 0) {
            uint256[] memory candidatesCards = _getCandidates(account);
            bytes32 hash = keccak256(abi.encodePacked(candidatesCards));

            vm.startPrank(account);
            card.commit(candidatesCards, hash);
            card.reveal(candidatesCards);
            vm.stopPrank();
        }
    }

    function _getCandidates(address account) internal view returns (uint256[] memory cards) {
        HandLord.Player[] memory _playersInfo = new HandLord.Player[](3);
        (, , _playersInfo, ) = card.getGameInfo();

        for (uint256 i = 0; i < _playersInfo.length; i++) {
            if (account == _playersInfo[i].user) {
                cards = _playersInfo[i].candidateCards;
                break;
            }
        }
    }

    function _getHealth(address account) internal view returns (uint256 health) {
        HandLord.Player[] memory _playersInfo = new HandLord.Player[](3);

        (, , _playersInfo, ) = card.getGameInfo();

        for (uint256 i = 0; i < _playersInfo.length; i++) {
            if (account == _playersInfo[i].user) {
                health = _playersInfo[i].health;
                break;
            }
        }
    }

    function _getCurrentCards(address account) internal view returns (uint256[] memory cards) {
        HandLord.Player[] memory _playersInfo = new HandLord.Player[](3);

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
        HandLord.Replay[] memory _replayInfo = new HandLord.Replay[](3);

        (, , , _replayInfo) = card.getGameInfo();
        console.logBytes32(0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa);
        console.logUint(_replayInfo.length);
        for (uint256 i = 0; i < _replayInfo.length; i++) {
            HandLord.Replay memory replay = _replayInfo[i];
            console.logAddress(replay.user1);
            console.logAddress(replay.user2);
            console.logAddress(replay.winner);
        }
        console.logBytes32(0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa);
    }

    function _logGameInfo() internal {
        uint256 round;
        address winner;
        HandLord.Player[] memory _playersInfo = new HandLord.Player[](3);
        HandLord.Replay[] memory _replayInfo = new HandLord.Replay[](3);

        (round, winner, _playersInfo, _replayInfo) = card.getGameInfo();
        console.logUint(round);
        console.logAddress(winner);

        /*
        for (uint256 i = 0; i < _playersInfo.length; i++) {
            HandLord.Player memory player = _playersInfo[i];
            console.logAddress(player.user);
            console.logUint(player.round);
            console.logBytes32(player.commitmentHash);
            console.logUint(player.lastActiveTime);
            console.logUint(player.status);
            console.logUint(player.health);
            console.logUint(11111111111111111111111111111111111111111111111111111111111111111111);
            for (uint256 j = 0; j < player.candidateCards.length; j++) {
                console.logUint(player.candidateCards[j]);
            }
            console.logUint(11111111111111111111111111111111111111111111111111111111111111111111);
        }
        */
    }
}
