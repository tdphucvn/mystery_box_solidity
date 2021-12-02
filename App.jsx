import React, { useEffect, useState } from "react";
import Web3 from "web3";

const App = () => {
  const [web3, setWeb3] = useState();
  const [account, setAccount] = useState();
  const [amount, setAmount] = useState();
  const [balance, setBalance] = useState();
  const [contract, setContract] = useState();
  const [event, setEvent] = useState();
  const [loading, setLoading] = useState();
  const [network, setNetwork] = useState();
  const [wrongNetwork, setwrongNetwork] = useState(false);
  const [contractAddress, setContractAddress] = useState();

  useEffect(async () => {
    if (typeof window.ethereum !== "undefined" && !this.state.wrongNetwork) {
      let accounts,
        network,
        balance,
        web3,
        maxBet,
        minBet,
        contract,
        contract_abi,
        contract_address;

      //don't refresh DApp when user change the network
      window.ethereum.autoRefreshOnNetworkChange = false;
      web3 = new Web3(window.ethereum);
      setState(web3);
      contract_abi = "";
      contract_address = "0x2FeF79F6b8777D4C13E2D7be422628A5B458b7ad"; //rinkeby
      contract = new web3.eth.Contract(contract_abi, contract_address);
      accounts = await web3.eth.getAccounts();

      //Update the data when user initially connect
      if (typeof accounts[0] !== "undefined" && accounts[0] !== null) {
        balance = await web3.eth.getBalance(accounts[0]);
        setAccount(accounts[0]);
        setBalance(balance);
      }

      setContract(contract);
      setContractAddress(contract_address);

      //Update account&balance when user change the account
      window.ethereum.on("accountsChanged", async (accounts) => {
        if (typeof accounts[0] !== "undefined" && accounts[0] !== null) {
          balance = await web3.eth.getBalance(accounts[0]);
          setBalance(balance);
          setAccount(account[0]);
        } else {
          setBalance(0);
          setAccount(null);
        }
      });

      //Update data when user switch the network
      window.ethereum.on("chainChanged", async (chainId) => {
        network = parseInt(chainId, 16);
        if (network !== 97) {
          setwrongNetwork(true);
        } else {
          if (account) {
            balance = await web3.eth.getBalance(account);
            setBalance(balance);
          }
          setNetwork(network);
          setLoading(false);
          setwrongNetwork(false);
        }
      });
    }
  }, []);

  const openMysteryBox = async (cost) => {
    const networkId = await web3.eth.net.getId();
    if (networkId !== 97) {
      setwrongNetwork(true);
    } else if (typeof account !== "undefined" && account !== null) {
      const randomSeed = Math.floor(Math.random() * Math.floor(1e9));

      //Send bet to the contract and wait for the verdict
      contract.methods
        .openMysteryBox(randomSeed)
        .send({ from: account, value: cost })
        .on("transactionHash", (hash) => {
          setLoading(true);
          contract.events.Result({}, async (error, event) => {
            const verdict = event.returnValues.randomReward;
            if (verdict === "0") {
              window.alert("You win COMMON icon");
            } else if (verdict === "1") {
              window.alert("You win RARE icon");
            } else if (verdict === "2") {
              window.alert("You win EXCLUSIVE icon");
            } else {
              window.alert("You win ADEN tokens");
            }

            //Prevent error when user logout, while waiting for the verdict
            if (account !== null && typeof account !== "undefined") {
              const balance = await web3.eth.getBalance(account);
              setBalance(balance);
            }
            setLoading(false);
          });
        })
        .on("error", (error) => {
          window.alert("Error");
        });
    } else {
      window.alert("Problem with account or network");
    }
  };

  return <div></div>;
};

export default App;
