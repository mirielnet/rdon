import { parseISO } from 'date-fns';

import {
  HASHTAG_FAVOURITE_FETCH_SUCCESS,
} from '../actions/favourite_tags';
import {
  HASHTAG_FAVOURITE_SUCCESS,
  HASHTAG_UNFAVOURITE_SUCCESS,
} from 'mastodon/actions/tags';
import { Map as ImmutableMap, fromJS } from 'immutable';

const initialState = ImmutableMap();

const normalizeFavouriteTag = (state, favourite_tag) => state.set(favourite_tag.name, fromJS({ name: favourite_tag.name, update_at: parseISO(favourite_tag.update_at) }));

const normalizeFavouriteTags = (state, favourite_tags) => {
  favourite_tags.forEach(favourite_tag => {
    state = normalizeFavouriteTag(state, favourite_tag);
  });

  return state;
};

export default function favourite_tags(state = initialState, action) {
  switch(action.type) {
  case HASHTAG_FAVOURITE_FETCH_SUCCESS:
    return normalizeFavouriteTags(state, action.favourite_tags);
  case HASHTAG_FAVOURITE_SUCCESS:
    return state.set(action.name, fromJS({ name: action.name, update_at: Date.now() }));
  case HASHTAG_UNFAVOURITE_SUCCESS:
    return state.delete(action.name);
  default:
    return state;
  }
};
