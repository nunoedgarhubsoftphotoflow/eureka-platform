import React from 'react';
import styled from 'styled-components';
import GridSpinner from '../../views/spinners/GridSpinner.js';
import Article from '../../views/Article.js';
import {Card} from '../../views/Card.js';
import {__THIRD} from '../../../helpers/colors.js';
import {Link, withRouter} from 'react-router-dom';
import {setSanityToOk} from '../../../../smartcontracts/methods/web3-platform-contract-methods.mjs';
import Modal from '../../design-components/Modal.js';
import TxHash from '../../views/TxHash.js';
import withWeb3 from '../../contexts/WithWeb3.js';
import connect from 'react-redux/es/connect/connect.js';
import {fetchArticlesToSignOff} from '../../reducers/editor-methods.js';

const Container = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
`;

const NoArtDiv = styled.div`
  display: flex;
  font-style: italic;
  margin-top: 25px;
  color: ${__THIRD};
  font-size: 16px;
`;
const NoArticles = () => {
  return (
    <NoArtDiv>
      You don't have any articles to sign off. If you want to assign yourself to
      an article{' '}
      <Link to={'/app/editor/articles'} style={{marginLeft: 2.5}}>
        {' '}
        <strong>click here.</strong>
      </Link>
    </NoArtDiv>
  );
};
class EditorSignOff extends React.Component {
  constructor() {
    super();
    this.state = {
      articleOnHover: null
    };
  }

  async componentDidMount() {
    this.props.fetchArticlesToSignOff();
  }

  signOffArticle(articleHash) {
    setSanityToOk(this.props.context.platformContract, articleHash)
      .send({
        from: this.props.selectedAccount.address
      })
      .on('transactionHash', tx => {
        this.setState({
          tx,
          showTxModal: true
        });
      })
      .on('receipt', async receipt => {
        console.log('Sanity check:  ' + receipt.status);
        this.props.fetchArticlesToSignOff();
        return receipt;
      })
      .catch(err => {
        console.error(err);
        this.setState({
          errorMessage:
            'Ouh. Something went wrong with the Smart Contract call: ' +
            err.toString()
        });
      });
  }

  renderModals() {
    return (
      <div>
        <Modal
          type={'notification'}
          toggle={isErrorMessage => {
            this.setState({errorMessage: null});
          }}
          show={this.state.errorMessage || this.props.errorMessage}
          title={'You got the following error'}
        >
          {this.state.errorMessage || this.props.errorMessage}
        </Modal>

        <Modal
          toggle={isTx => {
            this.setState({tx: null});
          }}
          action={'GOT IT'}
          callback={() => {
            this.props.history.push('/app/editor/invite');
          }}
          show={this.state.tx}
          title={'We got your request!'}
        >
          This article successfully passed the sanity check! You can find its tx
          hash here: <TxHash txHash={this.state.tx}>Transaction Hash</TxHash>.{' '}
          <br />
        </Modal>
      </div>
    );
  }

  render() {
    return (
      <Container>
        {this.renderModals()}
        {this.props.loading ? (
          <GridSpinner />
        ) : (
          <Card title={'Sign Off Articles'}>
            {this.props.articles ? (
              this.props.articles.length > 0 ? (
                this.props.articles.map(article => {
                  return (
                    <Article
                      buttonText={'Sign off'}
                      key={article._id}
                      article={article}
                      onHover={this.state.articleOnHover === article._id}
                      onMouseEnter={obj => {
                        this.setState({articleOnHover: obj._id});
                      }}
                      onMouseLeave={obj => {
                        this.setState({articleOnHover: null});
                      }}
                      action={(_, article) => {
                        this.signOffArticle(article.articleHash);
                      }}
                    />
                  );
                })
              ) : (
                <NoArticles />
              )
            ) : (
              <NoArticles />
            )}
          </Card>
        )}
      </Container>
    );
  }
}

export default withWeb3(
  withRouter(
    connect(
      state => ({
        selectedAccount: state.accountsData.selectedAccount,
        articles: state.editorsData.articlesToSignOff,
        loading: state.editorsData.loadingSignOff,
        errorMessage: state.editorsData.errorSignOff
      }),
      dispatch => ({
        fetchArticlesToSignOff: () => {
          dispatch(fetchArticlesToSignOff());
        }
      })
    )(EditorSignOff)
  )
);
