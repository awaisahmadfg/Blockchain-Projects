import { Application } from 'components/CardApplication';
import { Problem } from 'components/CardProblem';
import { Product } from 'components/CardProduct';
import { Profile } from 'components/CardProfile';
import { Solution } from 'components/CardSolution';
import { Tag } from 'components/CardTag';
import { Identifier, PsRecord } from 'dataPrvider';
import { Token } from 'interface/common';

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface CommonsPayload extends Tag {
  data?: Array<Profile>;
  employee: Array<Profile>;
  employeesCount: number;
  errorMessage?: string;
  followersCount?: number;
  relationPrompt: string;
  statusCode?: number;
  tag?: Tag;
  tagFollowersCount: number;
  total?: number;
  getProduct: Product;
  getProblem: Problem;
  multiplierIdeaPoints: number;
  listedNfts: Token[];
  getListedNftsLoader: boolean;
}

export interface AiAnswerSearchPayload {
  prompt: string;
  purpose: string;
  type: string;
}

export interface CreateProfilePayload {
  email: string;
  isCommunityEmployee?: boolean;
  name?: string;
  password?: string;
  tagId?: string | number;
  username?: string;
}

export interface DownloadPatentAppPayload {
  appId: string | number;
  pagination?: { page: number; perPage: number };
  profileId?: Identifier;
  title: string;
}

export interface editTagPayload {
  data: any;
  id: string | number;
  pagination?: {
    page: number;
    perPage: number;
  };
  userId?: string | number;
  type: string;
}

export interface unlinkTagPayload {
  type: string;
  itemId: string | number;
  tagKey: string;
  pagination?: { page: number; perPage: number };
}

export interface getEmployeesResponseType {
  data: Array<Profile>;
  total: number;
}

export interface getEmployeesPayload {
  tagId: string | number;
}

export interface getTagUsersPayload {
  filterType?: string | null;
  pagination?: { page: number; perPage: number };
  tagId: string | number;
}

export interface getTagUsersResponseType {
  data: Array<UserTag>;
  total: number;
}

export interface getTagUsersSuccessPayload {
  data: Array<UserTag>;
  total: number;
}

export interface getEmployeesSuccessPayload {
  data: Array<Profile>;
  total: number;
}

export interface GetNftsPayload {
  resource?: string;
  filter?: any;
  sort?: any;
  pagination?: {
    page: number;
    perPage: number;
  };
}

export interface GetNftPayload {
  id: string;
}

export interface getRelatedItemsPayload {
  resource: string;
  key: string;
  item: string;
  pagination?: {
    page: number;
    perPage: number;
  };
}

export interface getRelatedItemsResponse {
  items: Array<Problem | Solution | Application | Product>;
  count: number;
}

export interface getRelatedItemsSuccessPayload {
  item: string;
  items: Array<Problem | Solution | Application | Product>;
  count: number;
}

export interface UserTag extends PsRecord {
  actionType: string;
  solutionCount?: number;
  tagId: string;
  type: string;
  userId?: string;
  userType: string;
}

export interface Commons {
  activity: Problem | Solution | Product | Application;
  activityCount: number;
  activityLoading: boolean;
  aiAnswer: { type: string; answer: string };
  aiImage: { contentType: string; title: string; url: string };
  aiTitle: { text: string; origin: string };
  aiTitleLoader: boolean;
  commonsErrorMessage: string;
  createEmployeeLoading: boolean;
  downloadPatentLoader: boolean;
  editTagLoading: boolean;
  employees: Array<Profile>;
  employeesCount: number;
  getAiImageloading: boolean;
  getFollowingTagsCount: any;
  getFollowingTagsCountLoader: boolean;
  getInventionsAcceptedByManufacturerCount: number;
  getInventionsOpenToQuoteCount: number;
  getOwnedCommunityLoader: boolean;
  getProblem: Problem;
  getProduct: Product;
  getTagUsersLoader: boolean;
  inventions: Array<Application>;
  inventionsAcceptedByManufacturer: Array<Application>;
  inventionsCount: number;
  inventionsOpenToQuote: Array<Application>;
  isModalClosable: boolean;
  loading: boolean;
  multiplierIdeaPoints: number;
  ownedCommunity: Tag | null;
  problems: Array<Problem>;
  problemsCount: number;
  products: Array<Product>;
  productsCount: number;
  relatedCompanies: any;
  relationPrompt: string;
  relationPromptLoader: boolean;
  solutions: Array<Solution>;
  solutionsCount: number;
  statusCode: number;
  tag: Tag;
  tagActivity: Problem | Solution | Product | Application;
  tagActivityCount: number;
  tagActivityLoading: boolean;
  tagFollowersCount: number;
  tagUserCount: number;
  tagUsers: Array<Profile>;
  toggleAuthModal: boolean;
  toggleCreditsTopUpModal: boolean;
  toggleInviteUserModal: boolean;
  toggleLeadCommModal: boolean;
  toggleSubscriptionModal: boolean;
  togglJoinMindminerModal: boolean;
  listedNfts: Token[];
  getListedNftsLoader: boolean;
  nft: Token;
  getNftLoader: boolean;
}

export interface CommonsState {
  commons: Commons;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
// export interface CommonsPayload extends Tag {}
