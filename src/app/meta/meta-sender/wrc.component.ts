import {Component, OnInit} from '@angular/core';
import {Web3Service} from '../../util/web3.service';
import { MatSnackBar } from '@angular/material';

declare let require: any;
const wrc_artifacts = require('../../../../build/contracts/WasteWaterRecyclingCertificates.json');

@Component({
  selector: 'app-meta-sender',
  templateUrl: './wrc.component.html',
  styleUrls: ['./wrc.component.css']
})
export class SampleWrcComponent implements OnInit {
  accounts: string[];
  SampleWRC: any;

  model = {
    amount: 0,
    receiver: '',
    balance: 0,
    account: '',
    msgvalue: 0
  };

  status = '';

  constructor(private web3Service: Web3Service, private matSnackBar: MatSnackBar) {
    console.log('Constructor: ' + web3Service);
  }

  ngOnInit(): void {
    console.log('OnInit: ' + this.web3Service);
    console.log(this);
    this.watchAccount();
    this.web3Service.artifactsToContract(wrc_artifacts)
      .then((WRCAbstraction) => {
        this.SampleWRC = WRCAbstraction;
        this.SampleWRC.deployed().then(deployed => {
          console.log(deployed);
          deployed.Transfer({}, (err, ev) => {
            console.log('Transfer event came in, refreshing balance');
            this.refreshBalance();
          });
        });

      });
  }

  watchAccount() {
    this.web3Service.accountsObservable.subscribe((accounts) => {
      this.accounts = accounts;
      this.model.account = accounts[0];
      this.refreshBalance();
    });
  }

  setStatus(status) {
    this.matSnackBar.open(status, null, {duration: 3000});
  }

  async sendCoin() {
    if (!this.SampleWRC) {
      this.setStatus('Metacoin is not loaded, unable to send transaction');
      return;
    }

    const amount = this.model.amount;
    const receiver = this.model.receiver;

    console.log('Sending coins' + amount + ' to ' + receiver);

    this.setStatus('Initiating transaction... (please wait)');
    try {
      const deployedwrc = await this.SampleWRC.deployed();
      const transaction = await deployedwrc.transfer(receiver, amount, {from: this.model.account});

      if (!transaction) {
        this.setStatus('Transaction failed!');
      } else {
        this.setStatus('Transaction complete!');
      }
    } catch (e) {
      console.log(e);
      this.setStatus('Error sending coin; see log.');
    }
  }

  async refreshBalance() {
    console.log('Refreshing balance');

    try {
      const deployedwrc = await this.SampleWRC.deployed();
      console.log(deployedwrc);
      console.log('Account', this.model.account);
      const WRCBalance = await this.web3Service.getWeb3().then(web3 => {return web3.eth.getBalance(deployedwrc.address)});
    //   console.log('Found balance: ' + SimpleWalletBalance);
      this.model.balance = this.SampleWRC.web3.fromWei(WRCBalance,"ether");
    } catch (e) {
      console.log(e);
      this.setStatus('Error getting balance, see log.');
    }
  }

  setAmount(e) {
    console.log('Setting amount: ' + e.target.value);
    this.model.amount = e.target.value;
  }

  setReceiver(e) {
    console.log('Setting receiver: ' + e.target.value);
    this.model.receiver = e.target.value;
  }

}
async issueWrcfromEther() {
  if (!this.SampleWRC) {
    this.setStatus('Metacoin is not loaded, unable to send transaction');
    return;
  }
  const deployedwrc = await this.SampleWrc.deployed();
  console.log(deployedwrc);
  const transaction =await deployedwrc.IssueWRC({from:this.model.account,value:this.model.msgvalue });
  if (!transaction){
    this.setStatus('transaction failed!');
  }else {
    this.setStatus('transaction complete!');
  }  
}
// var number = web3.eth.getTransactionCount("0x407d73d8a49eeb85d32cf465507dd71d507100c1");
// console.log(number); // 1
setissuewrcvalue(e){
  this.model.msgvalue = e.target.value;
}
async withdrawtoEther() {
  if (!this.SampleWRC) {
    this.setStatus('Metacoin is not loaded, unable to send transaction');
    return;
  }
  const sender = this.model.account;
  const deployedwrc = await this.SampleWrc.deployed();
  console.log(deployedwrc);
  const transaction =await deployedwrc.withdraw(sender,this.model.msgvalue);
  if (!transaction){
    this.setStatus('transaction failed!');
  }else {
    this.setStatus('transaction complete!');
  }  
}
withdrawvalue(e){
  this.model.msgvalue = e.target.value;
}