import React, { useState, useEffect } from "react";
import abi from "./abi.json";
import Web3 from "web3";
import detectEthereumProvider from '@metamask/detect-provider';
import { useMoralis } from "react-moralis";
import { toast } from 'react-toastify';
require("dotenv").config();

const { REACT_APP_CONTRACT_ADDRESS, REACT_APP_MINT_PRICE, REACT_APP_MINT_PRICE_AFTER_2K } = process.env;
const SELECTEDNETWORK = "4";
const SELECTEDNETWORKNAME = "Rinkeby TESTNET";
const nftquantity = 9999;

function Mintbtn() {
  const [loading, setLoading] = useState(false);
  const [isWalletConnected, setIsWalletConnected] = useState(false);
  const [errormsg, setErrorMsg] = useState(false);
  const [hideMinting, setHideMinting] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const [totalSupply, settotalSupply] = useState(0);

  const { authenticate, isAuthenticated, isAuthenticating, user, account, logout } = useMoralis();

  const login = async () => {
    console.log("isAuthenticated :: ", isAuthenticated);
    if (!isAuthenticated) {

      await authenticate({ signingMessage: "Log-in Lazy LeoPard" })
        .then(function (user) {
          if (user) {
            toast.success("Wallet connected successfully");
          }
          console.log("logged in user:", user);
          console.log(user.get("ethAddress"));
        })
        .catch(function (error) {
          console.log(error);
        });
    }
  }

  const logOut = async () => {

    await logout();
    toast.success("Logout successfully")
    console.log("logged out");
  }

  const getProvider = () => {
    //  const { provider } = store.getState();
    let newProvider = null;
    try {
      if (!window.ethereum) throw new Error("Wallet not found");
      //   if (window.ethereum?.providers) {
      //     newProvider =
      //       window.ethereum.providers &&
      //       window.ethereum.providers.find((provider) => provider.isMetaMask);
      //   }
      if (
        window.ethereum?.isCoinbaseWallet ||
        window.ethereum?.overrideIsMetaMask
      )
        newProvider = window.ethereum.providers.find(
          (provider) => provider.isMetaMask
        );
      else newProvider = window.ethereum;
      return newProvider;
    } catch (err) {
      console.log(err, "ERROR_Wallet");
      //   store.dispatch(
      //     alert({
      //       title: "",
      //       message: err.message || "Window.ethereum not found or provider missed",
      //       severity: "error",
      //       show: true,
      //     })
      //   );
    }
  }

  useEffect(() => {
    async function walletProvider() {
      // await login();

      try {
        if (await detectEthereumProvider()) {
          // setProvider(true);
          // window.web3 = new Web3(window.ethereum);
          const web3 = new Web3(getProvider() || Web3.givenProvider);

          // const web3 = window.web3;
          if (await web3.eth.net.getId() == SELECTEDNETWORK) {

            const contractaddress = REACT_APP_CONTRACT_ADDRESS;
            const ct = new web3.eth.Contract(abi, contractaddress);
            settotalSupply(await ct.methods.totalSupply().call());


            if (nftquantity - await ct.methods.totalSupply().call() == 0) {
              setErrorMsg("All NFTs minted, Sale has ended");
            }


            const prevMetaMaskAccount = await web3.eth.getAccounts();
            // console.log("prevMetaMaskAccount ==> ", prevMetaMaskAccount);
            const provider = getProvider();

            if (prevMetaMaskAccount.length === 0) {
              const accountsList = await provider.request({
                method: "eth_requestAccounts",
              });
              // console.log(provider, "accountsList ==> ", accountsList.length);
              if (accountsList && accountsList.length > 0) {
                toast.success("Metamask wallet connected successfully");
              }
            }

          }
          else {
            // setProvider(false);
            setErrorMsg("Select \"" + SELECTEDNETWORKNAME + "\" network in your wallet to mint the NFT");
          }
        }
        else {
          setErrorMsg("Non-Ethereum browser detected. You should consider trying MetaMask!");
          // setProvider(false);
        }
        if (window.ethereum) {
          handleEthereum();
        }
        else {
          window.addEventListener('ethereum#initialized', handleEthereum, { once: true, });
          setTimeout(handleEthereum, 10000);
        }

        function handleEthereum() {
          const { ethereum } = window;
          if (ethereum && ethereum.isMetaMask) {
            console.log('Ethereum successfully detected!');
            // setProvider(true);
          } else {
            setErrorMsg('Please install MetaMask!');
            // setProvider(false);
          }
        }
      } catch (error) {
        console.log("Error :: ", error);
        if (error && error.code && error.message) {
          toast.error(error.message);
        }
      }

    }
    walletProvider();

  }, []);

  async function resetMinting(ct) {
    settotalSupply(await ct.methods.totalSupply().call());
    setQuantity(1);
    setHideMinting(false);
  }

  async function loadWeb3() {
    setHideMinting(true);
    // await login();

    try {

      if (await detectEthereumProvider()) {
        const web3 = new Web3(getProvider() || Web3.givenProvider);

        if (await web3.eth.net.getId() == SELECTEDNETWORK) {

          // creating contract instance
          const contractaddress = REACT_APP_CONTRACT_ADDRESS;
          const ct = new web3.eth.Contract(abi, contractaddress);
          let current = await ct.methods.totalSupply().call();
          console.log(nftquantity, "======= current ========", current)
          if (Number(current) === nftquantity) {
            console.log("======= total equal ========")
            toast.warn("No NFT Found")
            console.log("Sold out");
            await resetMinting(ct);
            return;
          }
          const baseURIis = await ct.methods.baseURI().call();
          console.log("get baseURIis ==> ", baseURIis)

          const provider = getProvider();
          const prevMetaMaskAccount = await web3.eth.getAccounts();
          // console.log("prevMetaMaskAccount ==> ", prevMetaMaskAccount);

          if (prevMetaMaskAccount.length === 0) {
            const accountsList = await provider.request({
              method: "eth_requestAccounts",
            });
            // console.log("accountsList ==> ", accountsList.length);

            if (accountsList && accountsList.length > 0) {
              toast.success("Metamask wallet connected successfully");
            }
          }

          // const web3 = window.web3;

          // Meta Mask Connected Account Address
          let metaMaskAccount = await web3.eth.getAccounts();
          metaMaskAccount = metaMaskAccount[0];

          const requiredBalance = Number(current) < 2000 ? `${REACT_APP_MINT_PRICE * quantity}` : `${REACT_APP_MINT_PRICE_AFTER_2K * quantity}`;

          await web3.eth.getBalance(metaMaskAccount, async (err, result) => {
            if (err) {
              console.log(err)
              await resetMinting(ct);
              return;
            } else {
              const walletBalance = web3.utils.fromWei(result, "ether");
              console.log("walletBalance ", walletBalance + " ETH");
              console.log("Compare Balance: ", walletBalance, requiredBalance);
              if (walletBalance < requiredBalance) {
                toast.error("Insufficient balance");
                await resetMinting(ct);
                return;
              } else {

                try {
                  await ct.methods
                    .mint(metaMaskAccount, quantity)
                    .send({
                      from: metaMaskAccount,
                      value: web3.utils.toBN(web3.utils.toWei(requiredBalance, "ether"))
                    })
                    .on('transactionHash', async function (hash) {
                      console.log("transactionHash :: ", hash);
                      toast.success("Please wait minting is in progress");
                      setLoading(true);
                    })
                    .on('receipt', async function (receipt) {
                      console.log("receipt :: ", receipt);
                      toast.success(`You have minted ${quantity} NFT successfully.`);
                      setLoading(false);

                      await resetMinting(ct);
                    });

                } catch (error) {
                  await resetMinting(ct);
                  console.log("Error :: ", error);
                  if (error && error.code && error.message) {
                    toast.error(error.message);
                  }
                }
              }
            }

          });

        } else {
          setHideMinting(false);
          toast.warn("Please Connect to Rinkeby  network");
          console.log("===== SELECTEDNETWORK failed ==========");
          setErrorMsg("Select \"" + SELECTEDNETWORKNAME + "\" network in your wallet to mint the NFT");
        };
      } else if (window.web3) {
        console.log("===== detectEthereumProvider failed ==========")
        window.web3 = new Web3(window.web3.currentProvider);
      } else {
        setHideMinting(false);
        console.log("===== detectEthereumProvider not found ==========")
        // window.alert(
        //   "Non-Ethereum browser detected. You should consider trying MetaMask!"
        // );
        { setErrorMsg("Non-Ethereum browser detected. You should consider trying MetaMask!") }
      }

    } catch (error) {
      setHideMinting(false);
      console.log("Error :: ", error);
      if (error && error.code && error.message) {
        toast.error(error.message);
      }
    }
  }

  return (
    <div>
      {!errormsg ? (
        <div className="row mintingsection py-5">
          <div className="col-sm-12">
            <div className="yellow">
              <div style={{ display: "flex", flexDirection: "row", alignItems: "center", margin: "auto", width: "320px" }} className="mt-2">
                <h3 className="text-white">Quantity</h3>
                <div style={{ marginLeft: "10px" }}>
                  <button className="minus back-button px-3 mx-1"
                    disabled={hideMinting}
                    onClick={() => {
                      if (quantity > 1) {
                        setQuantity(quantity - 1);
                      }
                    }}
                  >-</button>
                  <span style={{ fontSize: 30, margin: "0 15px", color: '#fff' }}>
                    {quantity}
                  </span>
                  <button
                    className="plus back-button px-3 mx-1"
                    disabled={hideMinting}
                    onClick={() => {
                      if (quantity < 2) {
                        setQuantity(quantity + 1);
                      }
                    }}
                  >+</button>
                </div>
              </div>
            </div>
            <button
              className="mt-3 mint-btn mx-auto d-block"
              disabled={hideMinting}
              onClick={() => {
                loadWeb3();
              }}
            >{loading ? "Loading..." : "Mint a Lazy Leopard!"}</button>
            {/* <button
              className="mt-3 mint-btn mx-auto d-block"
            >Minting <i class="fa fa-spinner fa-spin"></i></button> */}

            <h5 className="mt-2 supplytext">{nftquantity - totalSupply}/{nftquantity} Available</h5>
          </div>
        </div>) : <h5 className="mt-2 supplytext"><b>{errormsg}</b></h5>}
    </div>
  );
}

export default Mintbtn;