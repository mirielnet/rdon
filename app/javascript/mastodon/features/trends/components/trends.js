import React from 'react';
import ImmutablePureComponent from 'react-immutable-pure-component';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import LoadingIndicator from 'mastodon/components/loading_indicator';
import Hashtag from 'mastodon/components/hashtag';
import Column from 'mastodon/features/ui/components/column';
import ColumnSubheading from 'mastodon/features/ui/components/column_subheading';
import ScrollableList from 'mastodon/components/scrollable_list';

const messages = defineMessages({
  subheading: { id: 'trends.trending_now', defaultMessage: 'Trending now' },
});

export default
@injectIntl
class Trends extends ImmutablePureComponent {

  static propTypes = {
    trends: ImmutablePropTypes.list,
    fetchTrends: PropTypes.func.isRequired,
    multiColumn: PropTypes.bool,
    intl: PropTypes.object.isRequired,
  };

  componentDidMount () {
    this.props.fetchTrends();
    this.refreshInterval = setInterval(() => this.props.fetchTrends(), 900 * 1000);
  }

  componentWillUnmount () {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
  }

  render () {
    const { trends, multiColumn, shouldUpdateScroll, intl } = this.props;

    const emptyMessage = <FormattedMessage id='empty_column.trends' defaultMessage='No one has trends yet.' />;

    if (!trends) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    return (
      <ScrollableList
        scrollKey='trends'
        shouldUpdateScroll={shouldUpdateScroll}
        emptyMessage={emptyMessage}
        prepend={<ColumnSubheading text={intl.formatMessage(messages.subheading)} />}
        bindToDocument={!multiColumn}
      >
        {trends.map(hashtag =>
          <Hashtag key={hashtag.get('name')} hashtag={hashtag} />,
        )}
      </ScrollableList>
    );
  }

}
