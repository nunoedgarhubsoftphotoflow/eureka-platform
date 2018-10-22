import React from 'react';
import styled from 'styled-components';
import {NavLink} from 'react-router-dom';
import {__FIFTH} from '../../helpers/colors.js';
import {MAKE_MOBILE} from '../../helpers/mobile.js';
import {PANEL_LEFT_BREAK_POINT} from '../../helpers/layout.js';
import Icon from './icons/Icon.js';

export const MyNavPill = styled(NavLink)`
  &:hover {
    transform: translateY(2px);
  }
  transition: 0.25s all;
  text-decoration: none;
  font-size: 0.875rem;
  font-weight: 500;
  padding: 0.75rem 1rem;
  color: ${__FIFTH};
  background-color: #fff;
  box-shadow: 0 4px 6px rgba(50, 50, 93, 0.11), 0 1px 3px rgba(0, 0, 0, 0.08);
  margin: 0 10px;
  border-radius: 10px;
  cursor: pointer;

  &.${props => props.activeClassName} {
    background-color: ${__FIFTH};
    color: #fff;
  }
`;

MyNavPill.defaultProps = {
  activeClassName: 'active'
};
const IconContainer = styled.div`
  width: 125px;
  display: flex;
  justify-content: center;
  align-items: center;
  ${MAKE_MOBILE(PANEL_LEFT_BREAK_POINT)`
    width: auto;
  `};
`;

const Name = styled.div`
  white-space: nowrap;
  ${MAKE_MOBILE(PANEL_LEFT_BREAK_POINT)`
    display: none; 
  `};
`;

const NavPill = props => {
  return (
    <MyNavPill to={`${props.base}/${props.path}`}>
      <IconContainer {...props}>
        <Name>{props.name}</Name>
        <Icon
          noMove
          left={5}
          icon={props.icon}
          material={props.material}
          width={props.width}
          height={props.height}
        />
      </IconContainer>
    </MyNavPill>
  );
};

export default NavPill;
