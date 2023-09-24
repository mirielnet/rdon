import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { expandPublicTimeline } from 'mastodon/actions/timelines';
import Masonry from 'react-masonry-infinite';
import { List as ImmutableList, Map as ImmutableMap } from 'immutable';
import DetailedStatusContainer from 'mastodon/features/status/containers/detailed_status_container';
import { debounce } from 'lodash';
import LoadingIndicator from 'mastodon/components/loading_indicator';

const mapStateToProps = (state) => {
  const timeline = state.getIn(['timelines', 'public'], ImmutableMap());

  return {
    statusIds: timeline.get('items', ImmutableList()),
    isLoading: timeline.get('isLoading', false),
    hasMore: timeline.get('hasMore', false),
  };
};

export default @connect(mapStateToProps)
class PublicTimeline extends React.PureComponent {

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    statusIds: ImmutablePropTypes.list.isRequired,
    isLoading: PropTypes.bool.isRequired,
    hasMore: PropTypes.bool.isRequired,
  };

  componentDidMount () {
    this._connect();
  }

  componentDidUpdate (prevProps) {
  }

  _connect () {
    const { dispatch } = this.props;

    dispatch(expandPublicTimeline());
  }

  handleLoadMore = () => {
    const { dispatch, statusIds } = this.props;
    const maxId = statusIds.last();

    if (maxId) {
      dispatch(expandPublicTimeline({ maxId }));
    }
  }

  setRef = c => {
    this.masonry = c;
  }

  handleHeightChange = debounce(() => {
    if (!this.masonry) {
      return;
    }

    this.masonry.forcePack();
  }, 50)

  render () {
    const { statusIds, hasMore, isLoading } = this.props;

    const sizes = [
      { columns: 1, gutter: 0 },
      { mq: '415px', columns: 1, gutter: 10 },
      { mq: '640px', columns: 2, gutter: 10 },
      { mq: '960px', columns: 3, gutter: 10 },
      { mq: '1255px', columns: 3, gutter: 10 },
    ];

    const loader = (isLoading && statusIds.isEmpty()) ? <LoadingIndicator key={0} /> : undefined;

    return (
      <Masonry ref={this.setRef} className='statuses-grid' hasMore={hasMore} loadMore={this.handleLoadMore} sizes={sizes} loader={loader}>
        {statusIds.map(statusId => (
          <div className='statuses-grid__item' key={statusId}>
            <DetailedStatusContainer
              id={statusId}
              compact
              measureHeight
              onHeightChange={this.handleHeightChange}
            />
          </div>
        )).toArray()}
      </Masonry>
    );
  }

}