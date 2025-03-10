import { Problem } from 'components/CardProblem';
import { Solution } from 'components/CardSolution';
import { Tag } from 'components/CardTag';
import {
  AI_ANSWER_SEARCH_SUCCESS,
  AI_ANSWER_SEARCH,
  CALCULATE_MULTIPLIER_PTS_FAILURE,
  CALCULATE_MULTIPLIER_PTS_SUCCESS,
  CALCULATE_MULTIPLIER_PTS,
  CREATE_EMPLOYEE_PROFILE_SUCCESS,
  CREATE_EMPLOYEE_PROFILE,
  DOWNLOAD_PATENT_APP_SUCCESS,
  DOWNLOAD_PATENT_APP,
  EDIT_TAG,
  GET_AI_IMAGE_SUCCESS,
  GET_AI_IMAGE,
  GET_AI_TITLE_SUCCESS,
  GET_AI_TITLE,
  GET_EMPLOYEES_SUCCESS,
  GET_EMPLOYEES,
  GET_FEED_SUCCESS,
  GET_FEED,
  GET_FOLLOWING_TAGS_COUNT_SUCCESS,
  GET_FOLLOWING_TAGS_COUNT,
  GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_COUNT_SUCCESS,
  GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_COUNT,
  GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_SUCCESS,
  GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER,
  GET_INVENTIONS_OPEN_TO_QUOTE_COUNT_SUCCESS,
  GET_INVENTIONS_OPEN_TO_QUOTE_COUNT,
  GET_INVENTIONS_OPEN_TO_QUOTE_SUCCESS,
  GET_INVENTIONS_OPEN_TO_QUOTE,
  GET_OWNED_COMMUNITY,
  GET_PROBLEM_FAILURE,
  GET_PROBLEM_SUCCESS,
  GET_PROBLEM,
  GET_PRODUCT_FAILURE,
  GET_PRODUCT_SUCCESS,
  GET_PRODUCT,
  GET_RELATED_COMPANIES_SUCCESS,
  GET_RELATED_COMPANIES,
  GET_RELATED_ITEMS_SUCCESS,
  GET_RELATED_ITEMS,
  GET_RELATION_PROMPT_SUCCESS,
  GET_RELATION_PROMPT,
  GET_TAG_FOLLOWERS,
  GET_TAG_SUCCESS,
  GET_TAG_USERS_SUCCESS,
  GET_TAG_USERS,
  GET_TAG,
  GET_TAGS_BY_USER_ID_SUCCESS,
  OPEN_AUTH_MODAL,
  SET_MODAL_CLOSABLE,
  SET_RELATED_COMPANIES,
  TOGGLE_CREDITS_TOPUP_MODAL,
  TOGGLE_INVITE_USER_MODAL,
  TOGGLE_JOIN_MINDMINER_MODAL,
  TOGGLE_LEAD_COMM_MODAL,
  TOGGLE_SUBSCRIPTION_MODAL,
  UNLINK_TAG,
  UPDATE_ERROR_STATUS,
  VOTE_ITEM,
  RESET_MODAL_CLOSABLE,
  REQUEST_SUBSCRIPTION,
  GET_LISTED_NFTS,
  GET_LISTED_NFTS_SUCCESS,
  TOGGLE_GET_LISTED_NFTS_LOADING,
  UPDATE_LISTED_NFTS,
  GET_NFT,
  GET_NFT_SUCCESS
} from './types';
import {
  AiAnswerSearchPayload,
  CreateProfilePayload,
  DownloadPatentAppPayload,
  editTagPayload,
  getEmployeesSuccessPayload,
  GetNftsPayload,
  getRelatedItemsPayload,
  getRelatedItemsSuccessPayload,
  getTagUsersSuccessPayload
} from './interface';
import { Application } from 'components/CardApplication';
import { Token } from 'interface/common';

export const aiAnswerSearch = (payload: AiAnswerSearchPayload) => ({
  type: AI_ANSWER_SEARCH,
  payload
});

export const getNft = (payload) => ({
  type: GET_NFT,
  payload
});

export const getNftSuccess = (payload) => ({
  type: GET_NFT_SUCCESS,
  payload
});

export const getListedNfts = (payload: GetNftsPayload) => ({
  type: GET_LISTED_NFTS,
  payload
});

export const getListedNftsSuccess = (payload) => ({
  type: GET_LISTED_NFTS_SUCCESS,
  payload
});

export const setModalClosable = (isClosable: boolean) => ({
  type: SET_MODAL_CLOSABLE,
  payload: isClosable,
});

export const resetModalClosable = () => ({
  type: RESET_MODAL_CLOSABLE,
});

export const updateListedNfts = (payload) => ({
  type: UPDATE_LISTED_NFTS,
  payload
});

export const toggleGetListedNftsLoader = (payload) => ({
  type: TOGGLE_GET_LISTED_NFTS_LOADING,
  payload
});

export const aiAnswerSearchSuccess = (payload: {
  answer: string;
  type: string;
}) => ({
  type: AI_ANSWER_SEARCH_SUCCESS,
  payload
});

export const getAiTitle = (payload) => ({
  type: GET_AI_TITLE,
  payload
});

export const getAiTitleSuccess = (payload: {
  title: string;
  origin: string | null;
}) => ({
  type: GET_AI_TITLE_SUCCESS,
  payload
});

export const getAiImage = (payload) => ({
  type: GET_AI_IMAGE,
  payload
});

export const getAiImageSuccess = (payload) => ({
  type: GET_AI_IMAGE_SUCCESS,
  payload
});

export const createEmployeeProfile = (payload: CreateProfilePayload) => ({
  type: CREATE_EMPLOYEE_PROFILE,
  payload
});

export const createEmployeeProfileSuccess = () => ({
  type: CREATE_EMPLOYEE_PROFILE_SUCCESS,
  payload: {}
});

export const downloadPatentApp = (payload: DownloadPatentAppPayload) => ({
  type: DOWNLOAD_PATENT_APP,
  payload
});

export const downloadPatentAppSuccess = () => ({
  type: DOWNLOAD_PATENT_APP_SUCCESS,
  payload: {}
});

export const editTag = (payload: editTagPayload) => ({
  type: EDIT_TAG,
  payload
});

export const getEmployees = (payload: { tagId: string | number }) => ({
  type: GET_EMPLOYEES,
  payload
});

export const getEmployeesSuccess = (payload: getEmployeesSuccessPayload) => ({
  type: GET_EMPLOYEES_SUCCESS,
  payload
});

export const setRelatedCompanies = (payload) => ({
  type: SET_RELATED_COMPANIES,
  payload
});
export const getRelatedCompanies = (payload) => {
  return {
    type: GET_RELATED_COMPANIES,
    payload
  };
};

export const getRelatedCompaniesSuccess = (payload) => ({
  type: GET_RELATED_COMPANIES_SUCCESS,
  payload
});

export const getRelatedItems = (payload: getRelatedItemsPayload) => ({
  type: GET_RELATED_ITEMS,
  payload
});

export const getRelatedItemsSuccess = (
  payload: getRelatedItemsSuccessPayload
) => ({
  type: GET_RELATED_ITEMS_SUCCESS,
  payload
});

export const getOwnedCommunity = (payload) => ({
  type: GET_OWNED_COMMUNITY,
  payload
});

export const getTagsByUserIdSuccess = (payload) => ({
  type: GET_TAGS_BY_USER_ID_SUCCESS,
  payload
});

export const getTag = (
  key: string | number,
  pagination?: { page: number; perPage: number }
) => ({
  type: GET_TAG,
  payload: { key, pagination }
});

export const openAuthModal = (toggleAuthModal) => ({
  type: OPEN_AUTH_MODAL,
  payload: { toggleAuthModal }
});

export const toggleInviteUserModal = (state) => ({
  type: TOGGLE_INVITE_USER_MODAL,
  payload: { state }
});

export const toggleLeadCommunityModal = (state) => ({
  type: TOGGLE_LEAD_COMM_MODAL,
  payload: { state }
});

export const togglJoinMindminerModal = (state) => ({
  type: TOGGLE_JOIN_MINDMINER_MODAL,
  payload: { state }
});

export const toggleSubscriptionModal = (state) => ({
  type: TOGGLE_SUBSCRIPTION_MODAL,
  payload: { state }
});

export const toggleCreditsTopUpModal = (state) => ({
  type: TOGGLE_CREDITS_TOPUP_MODAL,
  payload: { state }
});

export const getTagSuccess = (payload: Tag) => ({
  type: GET_TAG_SUCCESS,
  payload
});

export const requestSubscription = (payload) => ({
  type: REQUEST_SUBSCRIPTION,
  payload
});

export const getTagFollowers = (
  tagId: string | number,
  followers?: string | number,
  actionType?: string,
  key?: string | string[],
  itemType?: string,
  pagination?: { page: number; perPage: number },
  filterType?: string,
  searchFilter?: string,
  sort?: { field: string; order: string },
  userKey?: string | null
) => ({
  type: GET_TAG_FOLLOWERS,
  actionType,
  filterType,
  followers,
  itemType,
  key,
  pagination,
  searchFilter,
  tagId,
  sort,
  userKey
});

export const getFollowingTagsCount = (
  userKey: string | number,
  onlyCount = true
) => ({
  type: GET_FOLLOWING_TAGS_COUNT,
  payload: { userKey, onlyCount }
});

export const getFollowingTagsCountSuccess = (count: number) => ({
  type: GET_FOLLOWING_TAGS_COUNT_SUCCESS,
  payload: { count }
});

export const getTagUsers = (payload: {
  tagId: string | number;
  filterType?: string | null;
  pagination?: { page: number; perPage: number };
}) => ({
  type: GET_TAG_USERS,
  payload
});

export const getTagUsersSuccess = (payload: getTagUsersSuccessPayload) => ({
  type: GET_TAG_USERS_SUCCESS,
  payload
});

export const unlinkTag = (
  type: string,
  itemId: string | number,
  tagKey: string,
  pagination: { page: number; perPage: number }
) => ({
  type: UNLINK_TAG,
  payload: { type, itemId, tagKey, pagination }
});

export const updateErrorStatus = (
  statusCode: number,
  errorMessage: string
) => ({
  type: UPDATE_ERROR_STATUS,
  payload: { statusCode, errorMessage }
});

export const getFeed = (
  pagination?: { page: number; perPage: number },
  key?: string | null,
  feedType?: string | null,
  filters?: Array<string> | null,
  sortType?: string | null
) => ({
  type: GET_FEED,
  payload: { pagination, key, feedType, filters, sortType }
});

export const getFeedSuccess = (payload, feedType?: string | null) => ({
  type: GET_FEED_SUCCESS,
  payload,
  feedType
});

export const voteItem = (itemType, itemId, voteType, voteCriteria, data) => ({
  type: VOTE_ITEM,
  payload: { itemType, itemId, voteType, voteCriteria, data }
});

export const getProduct = (payload) => ({
  type: GET_PRODUCT,
  payload
});

export const getProductSuccess = (payload) => ({
  type: GET_PRODUCT_SUCCESS,
  payload
});

export const getProductFailure = () => ({
  type: GET_PRODUCT_FAILURE
});

export const getProblem = (payload) => ({
  type: GET_PROBLEM,
  payload
});

export const getProblemSuccess = (payload) => ({
  type: GET_PROBLEM_SUCCESS,
  payload
});

export const getProblemFailure = () => ({
  type: GET_PROBLEM_FAILURE
});

export const getRelationPrompt = (payload: {
  conceptTitle: string;
  productTitle: string;
  firstSolutionTitle: string;
  secondSolutionTitle: string;
  remainingSolutions: Array<Solution>;
  problemSolvedBySolution: Array<Problem>;
}) => ({
  type: GET_RELATION_PROMPT,
  payload
});

export const getRelationPromptSuccess = (relationPrompt: string) => ({
  type: GET_RELATION_PROMPT_SUCCESS,
  payload: { relationPrompt }
});

export const calculateMultiplierIdeaPoints = (payload) => ({
  type: CALCULATE_MULTIPLIER_PTS,
  payload
});

export const calculateMultiplierIdeaPointsSuccess = (payload) => ({
  type: CALCULATE_MULTIPLIER_PTS_SUCCESS,
  payload
});

export const calculateMultiplierIdeaPointsFailure = () => ({
  type: CALCULATE_MULTIPLIER_PTS_FAILURE
});

export const getInventionsOpenToQuote = (
  id: string,
  pagination: { page: number; perPage: number }
) => ({
  type: GET_INVENTIONS_OPEN_TO_QUOTE,
  payload: { id, pagination }
});

export const getInventionsOpenToQuoteSuccess = (
  payload: Array<Application>
) => ({
  type: GET_INVENTIONS_OPEN_TO_QUOTE_SUCCESS,
  payload
});

export const getInventionsOpenToQuoteCount = (id: string) => ({
  type: GET_INVENTIONS_OPEN_TO_QUOTE_COUNT,
  payload: { id }
});

export const getInventionsOpenToQuoteCountSuccess = (
  getInventionsOpenToQuoteCount: number
) => ({
  type: GET_INVENTIONS_OPEN_TO_QUOTE_COUNT_SUCCESS,
  payload: { getInventionsOpenToQuoteCount }
});

export const getInventionsAcceptedByManufacturer = (
  id: string,
  pagination: { page: number; perPage: number }
) => ({
  type: GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER,
  payload: { id, pagination }
});

export const getInventionsAcceptedByManufacturerSuccess = (
  payload: Array<Application>
) => ({
  type: GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_SUCCESS,
  payload
});

export const getInventionsAcceptedByManufacturerCount = (id: string) => ({
  type: GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_COUNT,
  payload: { id }
});

export const getInventionsAcceptedByManufacturerCountSuccess = (
  getInventionsAcceptedByManufacturerCount: number
) => ({
  type: GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_COUNT_SUCCESS,
  payload: { getInventionsAcceptedByManufacturerCount }
});
