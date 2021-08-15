import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { fetchBookmarkedStatuses, expandBookmarkedStatuses } from '../../actions/bookmarks';
import Column from '../ui/components/column';
import ColumnHeader from '../../components/column_header';
import { addColumn, removeColumn, moveColumn } from '../../actions/columns';
import ScheduledStatusList from '../../components/scheduled_status_list';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { debounce } from 'lodash';

const messages = defineMessages({
  heading: { id: 'column.scheduled_status', defaultMessage: 'Scheduled Statuses' },
});

const mapStateToProps = state => ({
  statusIds: state.getIn(['status_lists', 'scheduled_status', 'items']),
  isLoading: state.getIn(['status_lists', 'scheduled_status', 'isLoading'], true),
  hasMore: !!state.getIn(['status_lists', 'scheduled_status', 'next']),
});

export default @connect(mapStateToProps)
@injectIntl
class ScheduledStatus extends ImmutablePureComponent {

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    statusIds: ImmutablePropTypes.list.isRequired,
    intl: PropTypes.object.isRequired,
    columnId: PropTypes.string,
    multiColumn: PropTypes.bool,
    hasMore: PropTypes.bool,
    isLoading: PropTypes.bool,
  };

  componentWillMount () {
    this.props.dispatch(fetchBookmarkedStatuses());
  }

  handlePin = () => {
    const { columnId, dispatch } = this.props;

    if (columnId) {
      dispatch(removeColumn(columnId));
    } else {
      dispatch(addColumn('SCHEDULED_STATUS', {}));
    }
  }

  handleMove = (dir) => {
    const { columnId, dispatch } = this.props;
    dispatch(moveColumn(columnId, dir));
  }

  handleHeaderClick = () => {
    this.column.scrollTop();
  }

  setRef = c => {
    this.column = c;
  }

  handleLoadMore = debounce(() => {
    this.props.dispatch(expandBookmarkedStatuses());
  }, 300, { leading: true })

  render () {
    const { intl, scheduledStatusIds, columnId, multiColumn, hasMore, isLoading } = this.props;
    const pinned = !!columnId;

    const emptyMessage = <FormattedMessage id='empty_column.scheduled_statuses' defaultMessage="You don't have any scheduled posts yet. When you schedule one, it will show up here." />;

    return (
      <Column bindToDocument={!multiColumn} ref={this.setRef} label={intl.formatMessage(messages.heading)}>
        <ColumnHeader
          icon='bookmark'
          title={intl.formatMessage(messages.heading)}
          onPin={this.handlePin}
          onMove={this.handleMove}
          onClick={this.handleHeaderClick}
          pinned={pinned}
          multiColumn={multiColumn}
          showBackButton
        />

        <ScheduluedStatusList
          trackScroll={!pinned}
          statusIds={scheduledStatusIds}
          scrollKey={`bookmarked_statuses-${columnId}`}
          hasMore={hasMore}
          isLoading={isLoading}
          onLoadMore={this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
        />
      </Column>
    );
  }

}
