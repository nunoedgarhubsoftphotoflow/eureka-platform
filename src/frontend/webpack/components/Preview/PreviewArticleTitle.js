import React, {Fragment} from 'react';
import styled from 'styled-components';
import {renderField} from '../TextEditor/DocumentRenderer.mjs';
import ReviewsWriterContainer from '../Reviews/ReviewsWriterContainer.js';
import {ReviewsWriterFieldContainer} from '../Reviews/ReviewsWriterField.js';
import PreviewStatus from '../../views/PreviewStatus.js';

const Container = styled.div``;
const Title = styled.h3`
  font-size: 26px;
  font-weight: bold;
  line-height: 1.3;
  font-family: 'Roboto', sans-serif;
  margin-bottom: 10px;
  flex: 3;
  margin-top: 0;
`;

const PreviewArticleTitle = ({document, isReview}) => {
  return (
    <Container id={'title'}>
      <ReviewsWriterFieldContainer>
        {isReview ? (
          <Fragment>
            <Title>{renderField(document, 'title')}</Title>
            <ReviewsWriterContainer
              onClick={() => {
                alert('sküüüü');
              }}
            />
          </Fragment>
        ) : null}
      </ReviewsWriterFieldContainer>
    </Container>
  );
};
export default PreviewArticleTitle;
