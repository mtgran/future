pragma solidity ^0.4.4;

contract Vault {
    function preparePayment(string description, address _recipient, uint _value, bytes _data, uint _minPayTime);
}

contract Milestones {
    modifier onlyRecipient { if (msg.sender !=  recipient) throw; _; }
    modifier onlyDonor { if (msg.sender != donor) throw; _; }
    modifier onlyArbitrator { if (msg.sender != arbitrator) throw; _; }
    modifier onlyArbitratorOrDonorOrRecipient {
        if ((msg.sender != recipient) &&
            (msg.sender != donor) &&
            (msg.sender != arbitrator))
            throw;
        _;
    }
    modifier onlyArbitratorOrDonor {
        if ((msg.sender != recipient) &&
            (msg.sender != donor) &&
            (msg.sender != arbitrator))
            throw;
        _;
    }
    modifier onlyArbitratorOrRecipient {
        if ((msg.sender != recipient) &&
            (msg.sender != donor) &&
            (msg.sender != arbitrator))
            throw;
        _;
    }
    modifier campaigNotCancelled {
        if (campaigCancelled) throw;
        _;
    }

    address public recipient;
    address public donor;
    address public arbitrator;
    Vault public vault;

    enum MilestoneStatus { PendingApproval, NotDone, Done, Paid, Cancelled }

    struct Milestone {
        string description;
        string url;
        uint amount;
        uint minDoneDate;
        uint maxDoneDate;
        uint reviewTime;
        address payDestination;
        bytes payData;

        MilestoneStatus status;
        uint doneTime;
        uint approveTime;
    }

    Milestone[] public milestones;
    function getNumberMilestones() constant returns (uint) {
        return milestones.length;
    }

    bool campaigCancelled;

///////////
// Constuctor
///////////

    function Milestones(address _arbitrator, address _donor, address _recipient, address _vaultAddress ) {
        arbitrator = _arbitrator;
        donor = _donor;
        recipient = _recipient;
        vault = Vault(_vaultAddress);
    }

////////
// Change players
////////

    function changeArbitrator(address _newArbitrator) onlyArbitrator {
        arbitrator = _newArbitrator;
    }

    function changeDonor(address _newDonor) onlyArbitratorOrDonor {
        donor = _newDonor;
    }

    function changeRecipient(address _newRecipient) onlyArbitratorOrRecipient {
        recipient = _newRecipient;
    }

    function changeVault(address _newVaultAddr) onlyArbitrator {
        vault = Vault(_newVaultAddr);
    }


////////////
// Creation and modification of Milestones
////////////


    function proposeMilestonAddition(
        string _description,
        string _url,
        uint _amount,
        address _payDestination,
        bytes _payData,
        uint _minDoneDate,
        uint _maxDoneDate,
        uint _reviewTime
    ) onlyRecipient {
        Milestone milestone = milestones[milestones.length ++];
        milestone.description = _description;
        milestone.url = _url;
        milestone.amount = _amount;
        milestone.minDoneDate = _minDoneDate;
        milestone.maxDoneDate = _maxDoneDate;
        milestone.reviewTime = _reviewTime;
        milestone.payDestination = _payDestination;
        milestone.payData = _payData;

        milestone.status = MilestoneStatus.PendingApproval;
    }

    function cancelProposaMilestoneAddition(uint _idMilestone) onlyRecipient campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        milestone.status = MilestoneStatus.Cancelled;
    }

    function approveMilestoneAddition(uint _idMilestone) onlyDonor campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        milestone.status = MilestoneStatus.NotDone;
    }

    function cancelMilestone(uint _idMilestone) onlyArbitratorOrDonorOrRecipient campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        if  ((milestone.status != MilestoneStatus.PendingApproval) &&
             (milestone.status != MilestoneStatus.NotDone) &&
             (milestone.status != MilestoneStatus.Done))
            throw;

        milestone.status = MilestoneStatus.Cancelled;
    }

    function milestoneCompleted(uint _idMilestone) onlyRecipient campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        milestone.status = MilestoneStatus.Done;
    }


    function collectMilestone(uint _idMilestone) onlyRecipient campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        if  ((milestone.status != MilestoneStatus.Done) ||
             (now < milestone.doneTime + milestone.reviewTime))
            throw;

        doPayment(_idMilestone);
    }


    function approveMilestone(uint _idMilestone) onlyDonor campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        if (milestone.status != MilestoneStatus.Done) throw;

        doPayment(_idMilestone);
    }

    function rejectMilestone(uint _idMilestone) onlyDonor campaigNotCancelled {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        if (milestone.status != MilestoneStatus.Done) throw;

        milestone.status = MilestoneStatus.NotDone;
    }


    function forceApproveMileston(uint _idMilestone) onlyArbitrator campaigNotCancelled {
        doPayment(_idMilestone);
    }

    function doPayment(uint _idMilestone) internal {
        if (_idMilestone <= milestones.length) throw;
        Milestone milestone = milestones[_idMilestone];
        milestone.status = MilestoneStatus.Paid;
        milestone.approveTime = now;
        vault.preparePayment(milestone.description, milestone.payDestination, milestone.amount, milestone.payData, 0);
    }

    function cancelCampaign() onlyArbitrator campaigNotCancelled {
        campaigCancelled = true;
    }
}
