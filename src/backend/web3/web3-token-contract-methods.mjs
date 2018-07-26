export const mintEurekaTokens = async (
  eurekaTokenContract,
  accounts,
  amounts,
  owner
) => {

  let gasEstimated = await getGasEstimation(
    eurekaTokenContract.methods.mint(accounts, amounts)
  );

  //Minting
  return eurekaTokenContract.methods
    .mint(accounts, amounts)
    .send({
      from: owner,
      gas: gasEstimated
    })
    .then(receipt => {
      return receipt;
    });
};

export const finishMinting = (contract, owner) => {
  return contract.methods
    .finishMinting()
    .send({
      from: owner
    })
    .then(receipt => {
      console.log('The EKA token minting has been finished.');
      return receipt;
    });
};

export const submitArticle = (_contract, _from, _to, _amount, _data) => {
  return _contract.methods
    .transferAndCall(_to, _amount, _data)
    .send({
      from: _from
    })
    .then(receipt => {
      console.log(
        'The article submission exited with the TX status: ' + receipt.status
      );
      return receipt;
    })
    .catch(err => {
      console.error(err);
    });
};

/*
  Getters
 */

export const getBalanceOf = (contract, account) => {
  return contract.methods
    .balanceOf(account)
    .call({from: account})
    .then(bal => {
      return bal;
    })
    .catch(err => {
      console.error(err);
    });
};

export const getTotalSupplyOf = (contract, fromAccount) => {
  return contract.methods
    .totalSupply()
    .call({from: fromAccount})
    .then(supply => {
      return supply;
    })
    .catch(err => {
      console.error(err);
    });
};

export const getGasEstimation = (func, fromAccount) => {
  return func.estimateGas({
    from: fromAccount
  });
};
