import React from 'react';
import styled from 'styled-components';

const getTextColor = props => {
  if (props.status === 'primary') {
    return '#2643e9';
  }
};

const getBackColor = props => {
  if (props.status === 'primary') {
    return 'rgba(203, 210, 246, 0.5)';
  }
};
const LabelContainer = styled.div`
  padding-right: 0.875em;
  padding-left: 0.875em;
  padding-top: 0.5em;
  padding-bottom: 0.5em;
  text-transform: uppercase !important;
  color: ${props => getTextColor(props)};
  background-color: ${props => getBackColor(props)};
  border-radius: 10rem;
  font-weight: 600;
  line-height: 1;
  display: inline-block;
  text-align: center;
  vertical-align: baseline;
  white-space: nowrap;
  margin-bottom: ${props => (props.bottom ? props.bottom + 'px' : null)};
  margin-left: ${props => (props.left ? props.left + 'px' : null)};
  margin-right: ${props => (props.right ? props.right + 'px' : null)};
  margin-top: ${props => (props.top ? props.top + 'px' : null)};
`;

export const Label = props => {
  return <LabelContainer {...props}>{props.children}</LabelContainer>;
};
