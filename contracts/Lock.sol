// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vesting {
    using SafeERC20 for IERC20;

    IERC20 private immutable token;

    enum DurationUints {
        Weeks,
        Months,
        Days
    }

    struct VestingSchedule {
        address beneficary;
        uint256 start_time;
        uint256 duration;
        DurationUints durationUint;
        uint256 totalamount;
        uint256 released;
    }

    mapping(address => VestingSchedule[]) public VestingSchedules;

    event VestingScheduleCreated(
        address beneficary,
        uint256,
        DurationUints,
        uint256
    );
    event tokenReleased(address indexed beneficary, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function createVestingSchedule(
        address _beneficary,
        uint256 _start_time,
        uint256 _duration,
        DurationUints _durationuint,
        uint256 _amount
    ) external payable {
        require(_beneficary != address(0), "no address passed");
        require(_amount > 0, "amount is zero");
        require(_start_time > block.timestamp, "not valid time ");

        token.safeTransferFrom(msg.sender, address(this), _amount);

        VestingSchedules[_beneficary].push(
            VestingSchedule({
                beneficary: _beneficary,
                start_time: _start_time,
                duration: _duration,
                durationUint: _durationuint,
                totalamount: _amount,
                released: 0
            })
        );

        emit VestingScheduleCreated(
            _beneficary,
            _start_time,
            _durationuint,
            _amount
        );
    }

    function release(address _beneficary) external {
        VestingSchedule[] storage schedules = VestingSchedules[_beneficary];
        require(schedules.length > 0, "no vesting found");
        uint256 totalRelease;

        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage vestingschedule = schedules[i];

            uint256 amountToSend = releasableAmount(vestingschedule);
            if(amountToSend > 0){
                vestingschedule.released += amountToSend;
                token.safeTransfer(_beneficary,amountToSend);
                totalRelease += amountToSend;
            }
        }

        emit tokenReleased(_beneficary, totalRelease);
    }

    function getReleasedAmounrt(address _beneficary)public view returns (uint256){
              VestingSchedule[] storage schedules = VestingSchedules[_beneficary];
              require(schedules.length > 0 , "No vesting");
              uint256 amountoSend;
              for (uint256 i = 0; i< schedules.length ; i++){
                   VestingSchedule memory schedule = schedules[i];
                    amountoSend += releasableAmount(schedule);
              }
              return amountoSend;
    }

    function releasableAmount(
        VestingSchedule memory _schedule
    ) public view  returns (uint256) {
        return vestedAmount(_schedule) - _schedule.released;
    }

    function vestedAmount(
        VestingSchedule memory _schedule
    ) public view returns (uint256) {
        if (_schedule.duration == 0) {
            if (block.timestamp >= _schedule.start_time) {
                return _schedule.totalamount;
            } else {
                return 0;
            }
        }

        uint256 sliceInsec;

        if (_schedule.durationUint == DurationUints.Days) {
            sliceInsec = 1;
        } else if (_schedule.durationUint == DurationUints.Weeks) {
            sliceInsec = 7;
        } else if (_schedule.durationUint == DurationUints.Months) {
            sliceInsec = 30;
        }

          if (block.timestamp < _schedule.start_time) {
            return 0;
        } else if (block.timestamp >= _schedule.start_time + _schedule.duration * sliceInsec) {
            return _schedule.totalamount;
        } else {
            uint256 monthsPassed = (block.timestamp - _schedule.start_time) / sliceInsec;
            return (_schedule.totalamount * monthsPassed) / _schedule.duration;
        }
    }
}
