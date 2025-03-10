/* eslint-disable */
import { Constants, TAG_TYPES } from 'utilities/constants';
import { CommonsPayload } from './interface';
import {
  AI_ANSWER_SEARCH_SUCCESS,
  AI_ANSWER_SEARCH,
  CALCULATE_MULTIPLIER_PTS_SUCCESS,
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
  GET_INVENTIONS_OPEN_TO_QUOTE_COUNT_SUCCESS,
  GET_INVENTIONS_OPEN_TO_QUOTE_COUNT,
  GET_INVENTIONS_OPEN_TO_QUOTE_SUCCESS,
  GET_OWNED_COMMUNITY,
  GET_PROBLEM_SUCCESS,
  GET_PRODUCT_SUCCESS,
  GET_RELATED_ITEMS_SUCCESS,
  GET_RELATED_ITEMS,
  GET_RELATION_PROMPT_SUCCESS,
  GET_RELATION_PROMPT,
  GET_TAG_SUCCESS,
  GET_TAG_USERS_SUCCESS,
  GET_TAG_USERS,
  GET_TAG,
  GET_TAGS_BY_USER_ID_SUCCESS,
  OPEN_AUTH_MODAL,
  RESET_MODAL_CLOSABLE,
  SET_MODAL_CLOSABLE,
  SET_RELATED_COMPANIES,
  TOGGLE_CREDITS_TOPUP_MODAL,
  TOGGLE_INVITE_USER_MODAL,
  TOGGLE_JOIN_MINDMINER_MODAL,
  TOGGLE_LEAD_COMM_MODAL,
  TOGGLE_SUBSCRIPTION_MODAL,
  UPDATE_ERROR_STATUS,
  GET_LISTED_NFTS,
  GET_LISTED_NFTS_SUCCESS,
  TOGGLE_GET_LISTED_NFTS_LOADING,
  GET_NFT,
  GET_NFT_SUCCESS
} from './types';

const INITIAL_STATE = {
  activity: [],
  activityCount: 0,
  activityLoading: false,
  aiAnswer: { answer: '', type: '' },
  aiImage: {},
  aiTitle: { text: '', origin: null },
  aiTitleLoader: false,
  commonsErrorMessage: '',
  createEmployeeLoading: false,
  downloadPatentLoader: false,
  editTagLoading: false,
  employees: [],
  employeesCount: 0,
  getAiImageloading: false,
  getFollowingTagsCount: 0,
  getFollowingTagsCountLoader: false,
  getInventionsAcceptedByManufacturerCount: 0,
  getInventionsOpenToQuoteCount: 0,
  getOwnedCommunityLoader: false,
  getProblem: {},
  getProduct: {},
  getTagUsersLoader: false,
  inventions: [],
  inventionsAcceptedByManufacturer: [],
  inventionsCount: 0,
  inventionsOpenToQuote: [],
  itemsCount: 0,
  loading: false,
  multiplierIdeaPoints: 0,
  ownedCommunity: null,
  problems: [],
  problemsCount: 0,
  products: [],
  productsCount: 0,
  relatedCompanies: {},
  relationPrompt: '',
  relationPromptLoader: false,
  solutions: [],
  solutionsCount: 0,
  statusCode: null,
  tag: {},
  tagActivity: [],
  tagActivityCount: 0,
  tagActivityLoading: false,
  tagFollowersCount: 0,
  tagUserCount: 0,
  tagUsers: [],
  toggleAuthModal: false,
  toggleCreditsTopUpModal: false,
  toggleInviteUserModal: false,
  toggleLeadCommModal: false,
  toggleSubscriptionModal: false,
  togglJoinMindminerModal: false,
  getListedNftsLoader: false,
  listedNfts: [],
  isModalClosable: true,
  getNftLoader: false,
  nft: null
};

const reducer = (
  state = INITIAL_STATE,
  action: { type: string; payload: CommonsPayload; feedType?: string | null }
) => {
  switch (action.type) {
    case AI_ANSWER_SEARCH:
      return { ...state, loading: true };
    case AI_ANSWER_SEARCH_SUCCESS:
      return { ...state, aiAnswer: action.payload, loading: false };
    case DOWNLOAD_PATENT_APP:
      return { ...state, downloadPatentLoader: true };
    case DOWNLOAD_PATENT_APP_SUCCESS:
      return { ...state, downloadPatentLoader: false };
    case EDIT_TAG:
      return { ...state, editTagLoading: true };
    case TOGGLE_GET_LISTED_NFTS_LOADING:
      return { ...state, getListedNftsLoader: action.payload };
    case GET_NFT:
      return { ...state, getNftLoader: true };
    case GET_NFT_SUCCESS:
      return { ...state, getNftLoader: false, nft: action.payload };
    case GET_LISTED_NFTS:
      return { ...state, getListedNftsLoader: true };
    case GET_LISTED_NFTS_SUCCESS:
      return {
        ...state,
        getListedNftsLoader: false,
        listedNfts: action.payload
      };
    case SET_MODAL_CLOSABLE:
      return { ...state, isModalClosable: action.payload };
    case RESET_MODAL_CLOSABLE:
      return { ...state, isModalClosable: true };  
    case GET_AI_TITLE:
      return { ...state, aiTitleLoader: true };
    case GET_AI_TITLE_SUCCESS:
      return {
        ...state,
        aiTitle: {
          text: action.payload.title,
          origin: action.payload.origin
        },
        aiTitleLoader: false
      };
    case GET_AI_IMAGE:
      return { ...state, getAiImageloading: true };
    case TOGGLE_SUBSCRIPTION_MODAL:
      return { ...state, toggleSubscriptionModal: action.payload.state };
    case TOGGLE_INVITE_USER_MODAL:
      return { ...state, toggleInviteUserModal: action.payload.state };
    case TOGGLE_LEAD_COMM_MODAL:
      return { ...state, toggleLeadCommModal: action.payload.state };
    case TOGGLE_JOIN_MINDMINER_MODAL:
      return { ...state, togglJoinMindminerModal: action.payload.state };
    case TOGGLE_CREDITS_TOPUP_MODAL:
      return { ...state, toggleCreditsTopUpModal: action.payload.state };
    case GET_AI_IMAGE_SUCCESS:
      return { ...state, aiImage: action.payload, getAiImageloading: false };
    case GET_EMPLOYEES:
      return { ...state, loading: true };
    case SET_RELATED_COMPANIES:
      return { ...state, relatedCompanies: action.payload };
    case GET_EMPLOYEES_SUCCESS:
      return {
        ...state,
        employees: action.payload.data,
        employeesCount: action.payload.total,
        loading: false
      };
    case GET_RELATED_ITEMS:
      return { ...state, loading: true };
    case GET_RELATED_ITEMS_SUCCESS:
      switch (action.payload.item) {
        case Constants.PROBLEMS:
          return {
            ...state,
            problems: action.payload.items,
            problemsCount: action.payload.count,
            loading: false
          };
        case Constants.SOLUTIONS:
          return {
            ...state,
            solutions: action.payload.items,
            solutionsCount: action.payload.count,
            loading: false
          };
        case Constants.APPLICATIONS:
          return {
            ...state,
            inventions: action.payload.items,
            inventionsCount: action.payload.count,
            loading: false
          };
        case Constants.COMPANY_PRODUCTS:
          return {
            ...state,
            products: action.payload.items,
            productsCount: action.payload.count,
            loading: false
          };
        default:
          return {
            ...state
          };
      }
    case GET_FEED:
      if (action.payload.feedType == TAG_TYPES.TAG_FEED) {
        return { ...state, tagActivityLoading: true };
      } else {
        return { ...state, activityLoading: true };
      }
    case GET_FEED_SUCCESS:
      if (action.feedType == TAG_TYPES.TAG_FEED) {
        return {
          ...state,
          tagActivity: action.payload.data,
          tagActivityCount: action.payload.totalActivities,
          tagActivityloading: false
        };
      } else {
        return {
          ...state,
          activity: action.payload.data,
          activityCount: action.payload.totalActivities,
          activityLoading: false
        };
      }
    case GET_TAG:
      return { ...state, loading: true };
    case GET_OWNED_COMMUNITY:
      return { ...state, getOwnedCommunityLoader: true };
    case GET_TAGS_BY_USER_ID_SUCCESS:
      return {
        ...state,
        ownedCommunity: action.payload,
        getOwnedCommunityLoader: false
      };
    case GET_TAG_SUCCESS:
      return {
        ...state,
        tag: action.payload,
        loading: false,
        editTagLoading: false
      };
    case GET_FOLLOWING_TAGS_COUNT:
      return {
        ...state,
        getFollowingTagsCountLoader: true
      };
    case GET_FOLLOWING_TAGS_COUNT_SUCCESS:
      return {
        ...state,
        getFollowingTagsCount: action.payload.count,
        getFollowingTagsCountLoader: false
      };
    case GET_TAG_USERS:
      return { ...state, getTagUsersLoader: true };
    case GET_TAG_USERS_SUCCESS:
      return {
        ...state,
        getTagUsersLoader: false,
        tagUsers: action.payload.data,
        tagUserCount: action.payload.total
      };
    case CREATE_EMPLOYEE_PROFILE:
      return { ...state, createEmployeeLoading: true };
    case CREATE_EMPLOYEE_PROFILE_SUCCESS:
      return { ...state, createEmployeeLoading: false };
    case GET_RELATION_PROMPT:
      return { ...state, relationPromptLoader: true };
    case GET_RELATION_PROMPT_SUCCESS:
      return {
        ...state,
        relationPromptLoader: false,
        relationPrompt: action.payload.relationPrompt
      };
    case UPDATE_ERROR_STATUS:
      return {
        ...state,
        statusCode: action.payload.statusCode,
        commonsErrorMessage: action.payload.errorMessage,
        createEmployeeLoading: false,
        loading: false
      };
    case OPEN_AUTH_MODAL:
      return { ...state, toggleAuthModal: action.payload.toggleAuthModal };
    case GET_PRODUCT_SUCCESS:
      return { ...state, getProduct: action.payload };
    case GET_PROBLEM_SUCCESS:
      return { ...state, getProblem: action.payload };
    case CALCULATE_MULTIPLIER_PTS_SUCCESS:
      return {
        ...state,
        multiplierIdeaPoints: action.payload.ideaPoints
      };
    case GET_INVENTIONS_OPEN_TO_QUOTE_SUCCESS:
      return {
        ...state,
        inventionsOpenToQuote: action.payload
      };
    case GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_SUCCESS:
      return {
        ...state,
        inventionsAcceptedByManufacturer: action.payload
      };
    case GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_COUNT:
      return {
        ...state
      };
    case GET_INVENTIONS_ACCEPTED_BY_MANUFACTURER_COUNT_SUCCESS:
      return {
        ...state,
        getInventionsAcceptedByManufacturerCount:
          action.payload.getInventionsAcceptedByManufacturerCount
      };
    case GET_INVENTIONS_OPEN_TO_QUOTE_COUNT:
      return {
        ...state
      };
    case GET_INVENTIONS_OPEN_TO_QUOTE_COUNT_SUCCESS:
      return {
        ...state,
        getInventionsOpenToQuoteCount:
          action.payload.getInventionsOpenToQuoteCount
      };
    default:
      return state;
  }
};

export default reducer;
