import React from 'react';
import styled from 'styled-components';
import {Card} from '../../views/Card.js';
import EditorQuerySection from './EditorQuerySection.js';
import Modal from '../../design-components/Modal.js';
import Article from '../../views/Article.js';
import GridSpinner from '../../views/spinners/GridSpinner.js';
import {assignForSubmissionProcess} from '../../../../smartcontracts/methods/web3-platform-contract-methods.mjs';
import {withRouter} from 'react-router-dom';
import {getEtherscanLink} from '../../../../helpers/getEtherscanLink.js';
import {isGanache} from '../../../../helpers/isGanache.mjs';
import Pagination from './Pagination.js';
import withWeb3 from '../../contexts/WithWeb3.js';
import connect from 'react-redux/es/connect/connect.js';
import {fetchUnassignedSubmissions} from '../../reducers/editor-methods.js';
import {TITLE_GENERAL_ERROR} from '../../constants/ModalErrors.js';
import {ToastContainer, toast} from 'react-toastify';
import '../../design-components/Notification.css';
import 'react-toastify/dist/ReactToastify.css';
import {ARTICLE_ASSIGNED_TX} from '../../constants/Messages.js';

const Container = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
`;

const Articles = styled.div`
  display: flex;
  flex-direction: column;
  width: 95%;
  margin-top: 1em;
`;

class EditorArticles extends React.Component {
  constructor() {
    super();
    this.state = {
      filtersActive: false,
      articleOnHover: null,
      tx: null,
      showTxModal: false
    };
  }

  handleQuery = (field, value) => {
    this.setState({[field]: value});
  };

  componentDidMount() {
    this.getSubmissions(1);
  }

  componentDidUpdate(prevProps) {
    if (
      this.props.errorMessage &&
      prevProps.errorMessage !== this.props.errorMessage
    ) {
      this.setState({showModal: true});
    }
  }

  getSubmissions(page) {
    this.setState({page});
    this.props.fetchUnassignedSubmissions(page);
  }

  async assignArticle(scSubmissionID) {
    let gasAmount;
    // gas estimation on ganache doesn't work properly
    if (!isGanache(this.props.context.web3))
      gasAmount = await assignForSubmissionProcess(
        this.props.context.platformContract,
        scSubmissionID
      ).estimateGas({
        from: this.props.selectedAccount.address
      });
    else gasAmount = 80000000;

    assignForSubmissionProcess(
      this.props.context.platformContract,
      scSubmissionID
    )
      .send({
        from: this.props.selectedAccount.address,
        gas: gasAmount
      })
      .on('transactionHash', tx => {
        console.log(tx);
        toast(ARTICLE_ASSIGNED_TX(tx), {
          position: toast.POSITION.TOP_CENTER,
          autoClose: 20000,
          className: '__ALERT_SUCCESS',
          progressClassName: '__BAR'
        });
        /* this.setState({
          tx,
          showTxModal: true
        });*/
      })
      .on('receipt', receipt => {
        console.log(
          'Assigning the editor to the submission exited with the TX status: ' +
            receipt.status
        );
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
          toggle={() => {
            this.setState({showModal: false});
          }}
          show={this.state.showModal}
          title={TITLE_GENERAL_ERROR}
        >
          {this.props.errorMessage}
        </Modal>

        <Modal
          action={'GOT IT'}
          callback={() => {
            this.setState({showTxModal: false});
            this.props.history.push(`/app/editor/signoff`);
          }}
          noClose
          show={this.state.showTxModal}
          title={'Your article has been successfully submitted!'}
        >
          Dear editor, your request for assigning yourself to this article
          submission process has successfully triggered our Smart Contract. If
          you are interested, you can track the Blockchain approval process at
          the following link: <br />
          <a href={+'tx/' + this.state.tx} target={'_blank'}>
            {this.state.tx}{' '}
          </a>
        </Modal>
      </div>
    );
  }

  render() {
    return (
      <Container>
        <ToastContainer />
        {this.renderModals()}
        <Card title={'Assign articles'}>
          <EditorQuerySection
            checked={this.state.filtersActive}
            handleFilters={filtersActive => {
              this.setState({filtersActive});
            }}
            handleQuery={(field, value) => {
              this.handleQuery(field, value);
            }}
          />

          <Pagination
            currentPage={this.state.page}
            totalPages={this.props.nrOfPages}
            goToPage={page => {
              this.getSubmissions(page);
            }}
          />

          {!this.props.articles ? (
            <GridSpinner />
          ) : (
            <Articles>
              {this.props.articles.map(article => {
                return (
                  <Article
                    buttonText={'Assign article to me'}
                    key={article._id}
                    onHover={this.state.articleOnHover === article._id}
                    article={article}
                    onMouseEnter={obj => {
                      this.setState({articleOnHover: obj._id});
                    }}
                    onMouseLeave={obj => {
                      this.setState({articleOnHover: null});
                    }}
                    action={async id => {
                      await this.assignArticle(id);
                    }}
                  />
                );
              })}
            </Articles>
          )}
        </Card>
      </Container>
    );
  }
}

export default withWeb3(
  withRouter(
    connect(
      state => ({
        articles: state.unassignedArticlesData.articles,
        nrOfPages: state.unassignedArticlesData.nrOfPages,
        loading: state.unassignedArticlesData.loading,
        errorMessage: state.unassignedArticlesData.error,
        selectedAccount: state.accountsData.selectedAccount
      }),
      dispatch => {
        return {
          fetchUnassignedSubmissions: page => {
            dispatch(fetchUnassignedSubmissions(page));
          }
        };
      }
    )(EditorArticles)
  )
);
