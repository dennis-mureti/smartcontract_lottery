from brownie import (
    accounts,
    network,
    config,
    MockV3Aggregator,
    Contract,
    VRFCoordinatorMock,
    LinkToken,
    interface
)

FORKED_LOCAL_ENVIRONEMNETS = ["mainnet-fork", "mainnet-fork-dev"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]


def get_account(index=None, id=None):
    # accounts[0]
    # accounts.add("env")
    # accounts.load("id")
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONEMNETS
    ):
        return accounts[0]

    return accounts.add(
        config["wallets"]["from_key"]
    )  # will now be our default making it more liberal


contract_to_mock = {  # mapping to map the contract names to their type
    "eth_usd_price_feed": MockV3Aggregator,
    "vrf_coordinator": VRFCoordinatorMock,
    "link_token": LinkToken,
}


def get_contract(contract_name):

    """This function (get_contract) will grab the contract address from brownie config if defined, otherwise it will deploy a mock version of that contract and return
    that mock contract.

        Args:
            contract_name(string)
        Returnd:
            brownie.network.contract.ProjectContract: The most recently deployed version of this cntract

    """
    contract_type = contract_to_mock[
        contract_name
    ]  # to get the type of contract that we have
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
    ):  # to check if we are on a local blockchain
        if len(contract_type) <= 0:
            # MockvVAggregator.length(
            deploy_mocks()
        contract = contract_type[
            -1
        ]  # to get the mocks. similar to doing (MockV3Aggregator.length)
    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        # address
        # ABI. which we get from our MockV3Aggregator
        contract = Contract.from_abi(
            contract_type._name, contract_address, contract_type.abi
        )  # allows us to get a contract from its abi and its address
    return contract


# deploy function
DECIMALS = 8
INITIAL_VALUE = 200000000000


def deploy_mocks(decimals=DECIMALS, initial_value=INITIAL_VALUE):
    account = get_account()
    mock_price_feed = MockV3Aggregator.deploy(
        decimals, initial_value, {"from": account}
    )
    link_token = LinkToken.deploy({"from":account})
    VRFCoordinatorMock.deploy(link_token.address, {"from": account})
    print("Deployed!!")

def fund_with_link(contract_address, account=None, link_token=None, amount=1000000000000000000): # 0.1 LINK
    account = account if account else get_account()
    link_token = link_token if link_token else get_contract("link_token")
    tx = link_token.transfer(contract_address, amount , {"from": amount})
    # link_token_contract = interface.LinkTokenInterface(link_token.address)
    # tx = link_token_contract.transfer(contract_address, amount, {"from":account}) # to interact with contract that already exists
    tx.wait(1)
    print("Fund contract!")
    return tx
