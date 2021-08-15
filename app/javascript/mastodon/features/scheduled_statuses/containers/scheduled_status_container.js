import React from 'react';
import { connect } from 'react-redux';
import ScheduledStatus from '../components/scheduled_status';
import { makeGetStatus, makeGetPictureInPicture } from '../selectors';
import {
  muteStatus,
  unmuteStatus,
  deleteStatus,
  hideStatus,
  revealStatus,
  toggleStatusCollapse,
  hideQuote,
  revealQuote,
} from '../actions/statuses';

import { openModal } from '../actions/modal';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import { boostModal, deleteModal, unfollowModal, unsubscribeModal } from '../initial_state';
import { showAlertForError } from '../actions/alerts';

import { createSelector } from 'reselect';
import { Map as ImmutableMap } from 'immutable';

const messages = defineMessages({
  deleteConfirm: { id: 'confirmations.delete.confirm', defaultMessage: 'Delete' },
  deleteMessage: { id: 'confirmations.delete.message', defaultMessage: 'Are you sure you want to delete this status?' },
  redraftConfirm: { id: 'confirmations.redraft.confirm', defaultMessage: 'Delete & redraft' },
  redraftMessage: { id: 'confirmations.redraft.message', defaultMessage: 'Are you sure you want to delete this status and re-draft it? Favourites and boosts will be lost, and replies to the original post will be orphaned.' },
});

const makeMapStateToProps = () => {
  const getStatus = makeGetStatus();
  const getPictureInPicture = makeGetPictureInPicture();
  const customEmojiMap = createSelector([state => state.get('custom_emojis')], items => items.reduce((map, emoji) => map.set(emoji.get('shortcode'), emoji), ImmutableMap()));

  const mapStateToProps = (state, props) => ({
    scheduled_status: getStatus(state, props),
    pictureInPicture: getPictureInPicture(state, props),
    emojiMap: customEmojiMap(state),
  });

  return mapStateToProps;
};

const mapDispatchToProps = (dispatch, { intl }) => ({

  onEditSchedule (scheduled_status) {
    dispatch(openModal('EMBED', {
      url: scheduled_status.get('url'),
      onError: error => dispatch(showAlertForError(error)),
    }));
  },

  onDelete (scheduled_status, history, withRedraft = false) {
    if (!deleteModal) {
      dispatch(deleteStatus(scheduled_status.get('id'), history, withRedraft));
    } else {
      dispatch(openModal('CONFIRM', {
        message: intl.formatMessage(withRedraft ? messages.redraftMessage : messages.deleteMessage),
        confirm: intl.formatMessage(withRedraft ? messages.redraftConfirm : messages.deleteConfirm),
        onConfirm: () => dispatch(deleteStatus(scheduled_status.get('id'), history, withRedraft)),
      }));
    }
  },

});

export default injectIntl(connect(makeMapStateToProps, mapDispatchToProps)(ScheduledStatus));
