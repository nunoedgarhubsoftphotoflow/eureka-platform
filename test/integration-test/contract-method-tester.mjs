import web3 from '../../src/backend/web3/web3Instance.mjs';
import {mintEurekaTokens, finishMinting, submitArticle, getBalanceOf} from "../../src/backend/web3/web3-token-contract-methods.mjs";
import {getAuthors, getLinkedArticles, getUrl} from "../../src/backend/web3/web3-platform-contract-methods.mjs";
import getArticleHex from '../../src/backend/web3/get-articleHex';
import getAccounts from "../../src/backend/web3/get-accounts.mjs";

let EurekaPlatformContract = undefined;
let EurekaTokenContract = undefined;
let account = undefined;

export default {
  setup: async (eurekaTokenContract, eurekaPlatformContract) => {
    let accounts = await getAccounts();
    account = accounts[0];
    EurekaPlatformContract = eurekaPlatformContract;
    EurekaTokenContract = eurekaTokenContract;

    let tokenAmounts = [];
    accounts.forEach(() => {
      tokenAmounts.push(20000);
    });
    await mintEurekaTokens(EurekaTokenContract, accounts, tokenAmounts, account);
    await finishMinting(EurekaTokenContract, account);
  },

  // signUpEditor() on SC
  testSignUpEditor: () => {
    if (EurekaPlatformContract) {
      //TODO implement web3Method function as soon as there is one
      EurekaPlatformContract.methods
        .signUpEditor(account)
        .send({
          from: account,
          gas: 4678127
        })
        .on('transactionHash', () => {
          //this.addNewTx(tx, game.id, Status.GAME_JOINED);
          // this.setLoadingToTrue(game);
        })
        .on('receipt', () => {
          //console.log(res);
          console.log('Successful Editor Sign up for address ' + account);
        })
        .on('confirmation', () => {
          // is returned for the first 24 block confirmations
        });
    } else {
      throw new Error(
        'No setup Contract Method Tester - set it up with an adress'
      );
    }
  },

  testSubmitArticle: async () => {
    let article = {
      articleHash:
        '449ee57a8c6519e1592af5f292212c620bbf25df787d25b55e47348a54d0f9c7',
      url: 'hoihoi',
      authors: [
        '0x655aA73E526cdf45c2E8906Aafbf37d838c2Ba88',
        '0x655aA73E526cdf45c2E8906Aafbf37d838c2Ba77'
      ],
      linkedArticles: [
        '5f37e6ef7ee3f86aaa592bce4b142ef345c42317d6a905b0218c7241c8e30015',
        '45bc397f0d43806675ab72cc08ba6399d679c90b4baed1cbe36908cdba09986a',
        'd0d1d5e3e1d46e87e736eb85e79c905986ec77285cd415bbb213f0c24d8bcffb'
      ]
    };

    let dataInHex = getArticleHex(article);
    let articleHashHex = '0x' + article.articleHash;

    await submitArticle(
      EurekaTokenContract,
      account,
      EurekaPlatformContract.options.address,
      5000,
      dataInHex
    );

    console.log('The balance of the service contract is ' + await getBalanceOf(EurekaTokenContract, EurekaPlatformContract.options.address));
    console.log('URL of the article: ' + await getUrl(EurekaPlatformContract, articleHashHex, account));
    console.log('Authors: ' + await getAuthors(EurekaPlatformContract, articleHashHex, account));
    console.log('Linked articles: ' + await getLinkedArticles(EurekaPlatformContract, articleHashHex, account));
  }
};
