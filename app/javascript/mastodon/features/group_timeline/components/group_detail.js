import React from 'react';
import ImmutablePureComponent from 'react-immutable-pure-component';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { counterRenderer } from 'mastodon/components/common_counter';
import { makeGetAccount } from 'mastodon/selectors';
import Avatar from 'mastodon/components/avatar';
import DisplayName from 'mastodon/components/display_name';
import IconButton from 'mastodon/components/icon_button';
import { FormattedMessage, injectIntl, defineMessages } from 'react-intl';
import { autoPlayGif, me, unfollowModal } from 'mastodon/initial_state';
import ShortNumber from 'mastodon/components/short_number';
import {
  followAccount,
  unfollowAccount,
  blockAccount,
  unblockAccount,
  unmuteAccount,
} from 'mastodon/actions/accounts';
import { openModal } from 'mastodon/actions/modal';
import { initMuteModal } from 'mastodon/actions/mutes';

const messages = defineMessages({
  follow: { id: 'account.follow', defaultMessage: 'Follow' },
  unfollow: { id: 'account.unfollow', defaultMessage: 'Unfollow' },
  requested: { id: 'account.requested', defaultMessage: 'Awaiting approval' },
  unblock: { id: 'account.unblock', defaultMessage: 'Unblock @{name}' },
  unmute: { id: 'account.unmute', defaultMessage: 'Unmute @{name}' },
  unfollowConfirm: {
    id: 'confirmations.unfollow.confirm',
    defaultMessage: 'Unfollow',
  },
});

const makeMapStateToProps = () => {
  const getAccount = makeGetAccount();

  const mapStateToProps = (state, { id }) => ({
    account: getAccount(state, id),
  });

  return mapStateToProps;
};

const mapDispatchToProps = (dispatch, { intl }) => ({
  onFollow(account) {
    if (
      account.getIn(['relationship', 'following']) ||
      account.getIn(['relationship', 'requested'])
    ) {
      if (unfollowModal) {
        dispatch(
          openModal('CONFIRM', {
            message: (
              <FormattedMessage
                id='confirmations.unfollow.message'
                defaultMessage='Are you sure you want to unfollow {name}?'
                values={{ name: <strong>@{account.get('acct')}</strong> }}
              />
            ),
            confirm: intl.formatMessage(messages.unfollowConfirm),
            onConfirm: () => dispatch(unfollowAccount(account.get('id'))),
          }),
        );
      } else {
        dispatch(unfollowAccount(account.get('id')));
      }
    } else {
      dispatch(followAccount(account.get('id')));
    }
  },

  onBlock(account) {
    if (account.getIn(['relationship', 'blocking'])) {
      dispatch(unblockAccount(account.get('id')));
    } else {
      dispatch(blockAccount(account.get('id')));
    }
  },

  onMute(account) {
    if (account.getIn(['relationship', 'muting'])) {
      dispatch(unmuteAccount(account.get('id')));
    } else {
      dispatch(initMuteModal(account));
    }
  },
});

export default
@injectIntl
@connect(makeMapStateToProps, mapDispatchToProps)
class GroupDetail extends ImmutablePureComponent {

  static propTypes = {
    account: ImmutablePropTypes.map.isRequired,
    intl: PropTypes.object.isRequired,
    onFollow: PropTypes.func.isRequired,
    onBlock: PropTypes.func.isRequired,
    onMute: PropTypes.func.isRequired,
  };

  _updateEmojis() {
    const node = this.node;

    if (!node || autoPlayGif) {
      return;
    }

    const emojis = node.querySelectorAll('.custom-emoji');

    for (var i = 0; i < emojis.length; i++) {
      let emoji = emojis[i];
      if (emoji.classList.contains('status-emoji')) {
        continue;
      }
      emoji.classList.add('status-emoji');

      emoji.addEventListener('mouseenter', this.handleEmojiMouseEnter, false);
      emoji.addEventListener('mouseleave', this.handleEmojiMouseLeave, false);
    }
  }

  componentDidMount() {
    this._updateEmojis();
  }

  componentDidUpdate() {
    this._updateEmojis();
  }

  handleEmojiMouseEnter = ({ target }) => {
    target.src = target.getAttribute('data-original');
  };

  handleEmojiMouseLeave = ({ target }) => {
    target.src = target.getAttribute('data-static');
  };

  handleFollow = () => {
    this.props.onFollow(this.props.account);
  };

  handleBlock = () => {
    this.props.onBlock(this.props.account);
  };

  handleMute = () => {
    this.props.onMute(this.props.account);
  };

  setRef = (c) => {
    this.node = c;
  };

  render() {
    const { account, intl } = this.props;

    let buttons;

    if (
      account.get('id') !== me &&
      account.get('relationship', null) !== null
    ) {
      const following = account.getIn(['relationship', 'following']);
      const requested = account.getIn(['relationship', 'requested']);
      const blocking = account.getIn(['relationship', 'blocking']);
      const muting = account.getIn(['relationship', 'muting']);

      if (requested) {
        buttons = (
          <IconButton
            disabled
            icon='hourglass'
            title={intl.formatMessage(messages.requested)}
          />
        );
      } else if (blocking) {
        buttons = (
          <IconButton
            active
            icon='unlock'
            title={intl.formatMessage(messages.unblock, {
              name: account.get('username'),
            })}
            onClick={this.handleBlock}
          />
        );
      } else if (muting) {
        buttons = (
          <IconButton
            active
            icon='volume-up'
            title={intl.formatMessage(messages.unmute, {
              name: account.get('username'),
            })}
            onClick={this.handleMute}
          />
        );
      } else if (!account.get('moved') || following) {
        buttons = (
          <IconButton
            icon={following ? 'user-times' : 'user-plus'}
            title={intl.formatMessage(
              following ? messages.unfollow : messages.follow,
            )}
            onClick={this.handleFollow}
            active={following}
          />
        );
      }
    }

    return (
      <div className='group__detail'>
        <div className='group__detail__img'>
          <img
            src={
              autoPlayGif ? account.get('header') : account.get('header_static')
            }
            alt=''
          />
        </div>

        <div className='group__detail__bar'>
          <a target='_blank' href={account.get('url')} className={'group__detail__bar__name'}>
            <Avatar account={account} size={48} />
            <DisplayName account={account} />
          </a>

          <div className='group__detail__bar__relationship account__relationship'>
            {buttons}
          </div>
        </div>

        <div className='group__detail__extra' ref={this.setRef}>
          <div
            className='group__header__content'
            dangerouslySetInnerHTML={{ __html: account.get('note_emojified') }}
          />
        </div>

        <div className='group__detail__extra'>
          <div className='group__header__links'>
            <a title={intl.formatNumber(account.get('statuses_count'))}>
              <ShortNumber
                value={account.get('statuses_count')}
                renderer={counterRenderer('statuses')}
              />
            </a>
            <a title={intl.formatNumber(account.get('followers_count'))}>
              <ShortNumber
                value={account.get('followers_count')}
                renderer={counterRenderer('members')}
              />
            </a>
          </div>
        </div>
      </div>
    );
  }

}
