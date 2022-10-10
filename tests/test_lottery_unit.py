# on testing this function we expect to get 0.019
# or in nwei 190000000000000000
from brownie import Lottery, accounts, config, network,exceptions
from web3 import Web3
from scripts.deploy_lottery import deploy_lottery
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest


def test_get_entrance_fee():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip()
    #Arrange 
    lottery = deploy_lottery() #this will give us our lottery contract
    # act
    expected_entrance_fee = Web3.toWei (0.025, "ether")
    entrance_fee = lottery.getEntranceFee()
    # assert
    assert expected_entrance_fee == entrance_fee

def test_cant_enter_unless_started():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip()
    lottery = deploy_lottery()
    # act/assert
    with pytest.raises(exceptions.VirtualmachineError):
        lottery.enter({"from": get_account(), "value": lottery.getEntranceFee()})