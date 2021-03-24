import React from 'react';
import Column from '../ui/components/column';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import PropTypes from 'prop-types';
import ImmutablePureComponent from 'react-immutable-pure-component';
import Icon from 'mastodon/components/icon';
import TrendsContainer from './containers/trends_container';

const messages = defineMessages({
  menu: { id: 'trends.heading', defaultMessage: 'Trends' },
});

export default
@injectIntl
class Trends extends ImmutablePureComponent {

  static propTypes = {
    intl: PropTypes.object.isRequired,
    multiColumn: PropTypes.bool,
  };

  render () {
    const { intl, multiColumn } = this.props;

    return (
      <Column bindToDocument={!multiColumn} label={intl.formatMessage(messages.menu)}>
        {multiColumn && <div className='column-header__wrapper'>
          <h1 className='column-header'>
            <button>
              <Icon id='bars' className='column-header__icon' fixedWidth />
              <FormattedMessage id='trends.heading' defaultMessage='Trends' />
            </button>
          </h1>
        </div>}

        <TrendsContainer multiColumn={multiColumn} />
      </Column>
    );
  }

}
