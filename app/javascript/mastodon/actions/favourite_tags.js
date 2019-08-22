import api from '../api';

export const HASHTAG_FAVOURITE_FETCH_REQUEST = 'HASHTAG_FAVOURITE_FETCH_REQUEST';
export const HASHTAG_FAVOURITE_FETCH_SUCCESS = 'HASHTAG_FAVOURITE_FETCH_SUCCESS';
export const HASHTAG_FAVOURITE_FETCH_FAIL    = 'HASHTAG_FAVOURITE_FETCH_FAIL';

export const fetchFavouriteTags = () => (dispatch, getState) => {
  dispatch(fetchFavouriteTagsRequest());

  api(getState).get('/api/v1/favourite_tags')
    .then(({ data }) => dispatch(fetchFavouriteTagsSuccess(data)))
    .catch(err => dispatch(fetchFavouriteTagsFail(err)));
};

export const fetchFavouriteTagsRequest = () => ({
  type: HASHTAG_FAVOURITE_FETCH_REQUEST,
});

export const fetchFavouriteTagsSuccess = favourite_tags => ({
  type: HASHTAG_FAVOURITE_FETCH_SUCCESS,
  favourite_tags,
});

export const fetchFavouriteTagsFail = error => ({
  type: HASHTAG_FAVOURITE_FETCH_FAIL,
  error,
});
