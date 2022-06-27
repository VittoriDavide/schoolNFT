pragma solidity >=0.6.0 <0.7.0;

import "./KickstarterNFT.sol";

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum, bytes32[] memory assets) public {

        Campaign newCampaign = new Campaign(minimum, msg.sender);
        new KickstarterNFT(assets, address(newCampaign));
        newCampaign.initialize(address(newCampaign));

        deployedCampaigns.push(address(newCampaign));
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    address public nftPOAP;
    address public CAMPAIGN_FACTORY;



    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
        CAMPAIGN_FACTORY = msg.sender;
    }

    function initialize(address _nftPOAP) public {
        require(msg.sender == CAMPAIGN_FACTORY);

        nftPOAP = _nftPOAP;
    }

    function contribute(string memory tokenURI) public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
        KickstarterNFT(nftPOAP).mintItem(tokenURI);
    }

    function createRequest(string memory description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
        description: description,
        value: value,
        recipient: recipient,
        complete: false,
        approvalCount: 0
        });

        requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender]);
        require(!request.approvals[msg.sender]);

        request.approvals[msg.sender] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        payable(request.recipient).transfer(request.value);
        request.complete = true;
    }
}
