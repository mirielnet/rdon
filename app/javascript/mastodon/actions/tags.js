import api from '../api';

export const HASHTAG_FETCH_REQUEST = 'HASHTAG_FETCH_REQUEST';
export const HASHTAG_FETCH_SUCCESS = 'HASHTAG_FETCH_SUCCESS';
export const HASHTAG_FETCH_FAIL    = 'HASHTAG_FETCH_FAIL';

export const HASHTAG_FOLLOW_REQUEST = 'HASHTAG_FOLLOW_REQUEST';
export const HASHTAG_FOLLOW_SUCCESS = 'HASHTAG_FOLLOW_SUCCESS';
export const HASHTAG_FOLLOW_FAIL    = 'HASHTAG_FOLLOW_FAIL';

export const HASHTAG_UNFOLLOW_REQUEST = 'HASHTAG_UNFOLLOW_REQUEST';
export const HASHTAG_UNFOLLOW_SUCCESS = 'HASHTAG_UNFOLLOW_SUCCESS';
export const HASHTAG_UNFOLLOW_FAIL    = 'HASHTAG_UNFOLLOW_FAIL';

export const HASHTAG_FAVOURITE_REQUEST = 'HASHTAG_FAVOURITE_REQUEST';
export const HASHTAG_FAVOURITE_SUCCESS = 'HASHTAG_FAVOURITE_SUCCESS';
export const HASHTAG_FAVOURITE_FAIL    = 'HASHTAG_FAVOURITE_FAIL';

export const HASHTAG_UNFAVOURITE_REQUEST = 'HASHTAG_UNFAVOURITE_REQUEST';
export const HASHTAG_UNFAVOURITE_SUCCESS = 'HASHTAG_UNFAVOURITE_SUCCESS';
export const HASHTAG_UNFAVOURITE_FAIL    = 'HASHTAG_UNFAVOURITE_FAIL';

export const fetchHashtag = name => (dispatch, getState) => {
  dispatch(fetchHashtagRequest());

  api(getState).get(`/api/v1/tags/${name}`).then(({ data }) => {
    dispatch(fetchHashtagSuccess(name, data));
  }).catch(err => {
    dispatch(fetchHashtagFail(err));
  });
};

export const fetchHashtagRequest = () => ({
  type: HASHTAG_FETCH_REQUEST,
});

export const fetchHashtagSuccess = (name, tag) => ({
  type: HASHTAG_FETCH_SUCCESS,
  name,
  tag,
});

export const fetchHashtagFail = error => ({
  type: HASHTAG_FETCH_FAIL,
  error,
});

export const followHashtag = name => (dispatch, getState) => {
  dispatch(followHashtagRequest(name));

  api(getState).post(`/api/v1/tags/${name}/follow`).then(({ data }) => {
    dispatch(followHashtagSuccess(name, data));
  }).catch(err => {
    dispatch(followHashtagFail(name, err));
  });
};

export const followHashtagRequest = name => ({
  type: HASHTAG_FOLLOW_REQUEST,
  name,
});

export const followHashtagSuccess = (name, tag) => ({
  type: HASHTAG_FOLLOW_SUCCESS,
  name,
  tag,
});

export const followHashtagFail = (name, error) => ({
  type: HASHTAG_FOLLOW_FAIL,
  name,
  error,
});

export const unfollowHashtag = name => (dispatch, getState) => {
  dispatch(unfollowHashtagRequest(name));

  api(getState).post(`/api/v1/tags/${name}/unfollow`).then(({ data }) => {
    dispatch(unfollowHashtagSuccess(name, data));
  }).catch(err => {
    dispatch(unfollowHashtagFail(name, err));
  });
};

export const unfollowHashtagRequest = name => ({
  type: HASHTAG_UNFOLLOW_REQUEST,
  name,
});

export const unfollowHashtagSuccess = (name, tag) => ({
  type: HASHTAG_UNFOLLOW_SUCCESS,
  name,
  tag,
});

export const unfollowHashtagFail = (name, error) => ({
  type: HASHTAG_UNFOLLOW_FAIL,
  name,
  error,
});

export const favouriteHashtag = name => (dispatch, getState) => {
  dispatch(favouriteHashtagRequest(name));

  api(getState).post(`/api/v1/tags/${name}/favourite`).then(({ data }) => {
    dispatch(favouriteHashtagSuccess(name, data));
  }).catch(err => {
    dispatch(favouriteHashtagFail(name, err));
  });
};

export const favouriteHashtagRequest = name => ({
  type: HASHTAG_FAVOURITE_REQUEST,
  name,
});

export const favouriteHashtagSuccess = (name, tag) => ({
  type: HASHTAG_FAVOURITE_SUCCESS,
  name,
  tag,
});

export const favouriteHashtagFail = (name, error) => ({
  type: HASHTAG_FAVOURITE_FAIL,
  name,
  error,
});

export const unfavouriteHashtag = name => (dispatch, getState) => {
  dispatch(unfavouriteHashtagRequest(name));

  api(getState).post(`/api/v1/tags/${name}/unfavourite`).then(({ data }) => {
    dispatch(unfavouriteHashtagSuccess(name, data));
  }).catch(err => {
    dispatch(unfavouriteHashtagFail(name, err));
  });
};

export const unfavouriteHashtagRequest = name => ({
  type: HASHTAG_UNFAVOURITE_REQUEST,
  name,
});

export const unfavouriteHashtagSuccess = (name, tag) => ({
  type: HASHTAG_UNFAVOURITE_SUCCESS,
  name,
  tag,
});

export const unfavouriteHashtagFail = (name, error) => ({
  type: HASHTAG_UNFAVOURITE_FAIL,
  name,
  error,
});
