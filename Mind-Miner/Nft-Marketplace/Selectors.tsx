import { useSelector } from 'react-redux';
import { CommonsState } from './interface';

export const GetAiAnswer = () =>
  useSelector((state: CommonsState) => state.commons.aiAnswer);

export const GetTag = () =>
  useSelector((state: CommonsState) => state.commons.tag);

export const GetEditTagLoading = () =>
  useSelector((state: CommonsState) => state.commons.editTagLoading);

export const GetAiTitle = () =>
  useSelector((state: CommonsState) => state.commons.aiTitle);

export const GetAiTitleLoader = () =>
  useSelector((state: CommonsState) => state.commons.aiTitleLoader);

export const GetAiImage = () =>
  useSelector((state: CommonsState) => state.commons.aiImage);

export const GetAiImageloading = () =>
  useSelector((state: CommonsState) => state.commons.getAiImageloading);

export const GetLoader = () =>
  useSelector((state: CommonsState) => state.commons.loading);

export const GetActivityLoader = () =>
  useSelector((state: CommonsState) => state.commons.activityLoading);

export const GetTagActivityLoader = () =>
  useSelector((state: CommonsState) => state.commons.tagActivityLoading);

export const GetEmployees = () =>
  useSelector((state: CommonsState) => state.commons.employees);

export const GetActivityCount = () =>
  useSelector((state: CommonsState) => state.commons.activityCount);

export const GetTagActivityCount = () =>
  useSelector((state: CommonsState) => state.commons.tagActivityCount);

export const GetEmployeesCount = () =>
  useSelector((state: CommonsState) => state.commons.employeesCount);

export const GetCommonsStatusCode = () =>
  useSelector((state: CommonsState) => state.commons.statusCode);

export const GetCreateEmployeeLoading = () =>
  useSelector((state: CommonsState) => state.commons.createEmployeeLoading);

export const GetCommonsErrorMessage = () =>
  useSelector((state: CommonsState) => state.commons.commonsErrorMessage);

export const GetTagFollowersCount = () =>
  useSelector((state: CommonsState) => state.commons.tagFollowersCount);

export const GetRelatedProblems = () =>
  useSelector((state: CommonsState) => state.commons.problems);

export const GetRelatedProblemsCount = () =>
  useSelector((state: CommonsState) => state.commons.problemsCount);

export const GetRelatedSolutions = () =>
  useSelector((state: CommonsState) => state.commons.solutions);

export const GetRelatedSolutionsCount = () =>
  useSelector((state: CommonsState) => state.commons.solutionsCount);

export const GetRelatedInventions = () =>
  useSelector((state: CommonsState) => state.commons.inventions);

export const GetRelatedInventionsCount = () =>
  useSelector((state: CommonsState) => state.commons.inventionsCount);

export const GetRelatedProducts = () =>
  useSelector((state: CommonsState) => state.commons.products);

export const GetRelatedProductsCount = () =>
  useSelector((state: CommonsState) => state.commons.productsCount);

export const GetFeed = () =>
  useSelector((state: CommonsState) => state.commons.activity);

export const GetOwnedCommunity = () =>
  useSelector((state: CommonsState) => state.commons.ownedCommunity);

export const GetOwnedCommunityLoader = () =>
  useSelector((state: CommonsState) => state.commons.getOwnedCommunityLoader);

export const GetTagFeed = () =>
  useSelector((state: CommonsState) => state.commons.tagActivity);

export const GetTagLoader = () =>
  useSelector((state: any) => state.commons.loading);

export const GetTagUsers = () =>
  useSelector((state: CommonsState) => state.commons.tagUsers);

export const GetTagUsersCount = () =>
  useSelector((state: CommonsState) => state.commons.tagUserCount);

export const GetTagUsersLoader = () =>
  useSelector((state: CommonsState) => state.commons.getTagUsersLoader);

export const GetRelatedCompanies = () =>
  useSelector((state: CommonsState) => state.commons.relatedCompanies);

export const GetDownloadPatentLoader = () =>
  useSelector((state: CommonsState) => state.commons.downloadPatentLoader);

export const GetOpenAuthModal = () =>
  useSelector((state: CommonsState) => state.commons.toggleAuthModal);

export const GetFollowingTagsCount = () =>
  useSelector((state: CommonsState) => state.commons.getFollowingTagsCount);

export const GetFollowingTagsCountLoader = () =>
  useSelector(
    (state: CommonsState) => state.commons.getFollowingTagsCountLoader
  );

export const GetProduct = () =>
  useSelector((state: CommonsState) => state.commons.getProduct);

export const GetProblem = () =>
  useSelector((state: CommonsState) => state.commons.getProblem);

export const GetRelationPromptLoader = () =>
  useSelector((state: CommonsState) => state.commons.relationPromptLoader);

export const GetRelationPrompt = () =>
  useSelector((state: CommonsState) => state.commons.relationPrompt);
export const GetCalculateMultiplierIdeaPoints = () =>
  useSelector((state: CommonsState) => state.commons.multiplierIdeaPoints);

export const GetOpenSubscriptionModal = () =>
  useSelector((state: CommonsState) => state.commons.toggleSubscriptionModal);

export const GetOpenCredtisTopUpModal = () =>
  useSelector((state: CommonsState) => state.commons.toggleCreditsTopUpModal);

export const GetInventionsOpenToQuote = () =>
  useSelector((state: CommonsState) => state.commons.inventionsOpenToQuote);

export const GetInventionsOpenToQuoteCount = () =>
  useSelector(
    (state: CommonsState) => state.commons.getInventionsOpenToQuoteCount
  );

export const GetInventionsAcceptedByManufacturer = () =>
  useSelector(
    (state: CommonsState) => state.commons.inventionsAcceptedByManufacturer
  );
export const GetInventionsAcceptedByManufacturerCount = () =>
  useSelector(
    (state: CommonsState) =>
      state.commons.getInventionsAcceptedByManufacturerCount
  );
export const GetOpenInviteUserModal = () =>
  useSelector((state: CommonsState) => state.commons.toggleInviteUserModal);
export const GetOpenLeadCommunityModal = () =>
  useSelector((state: CommonsState) => state.commons.toggleLeadCommModal);
export const GetOpenJoinMindminerModal = () =>
  useSelector((state: CommonsState) => state.commons.togglJoinMindminerModal);
export const GetListedNfts = () =>
  useSelector((state: CommonsState) => state.commons.listedNfts);
export const GetListedNftsLoader = () =>
  useSelector((state: CommonsState) => state.commons.getListedNftsLoader);
export const GetNft = () =>
  useSelector((state: CommonsState) => state.commons.nft);
export const GetNftLoader = () =>
  useSelector((state: CommonsState) => state.commons.getNftLoader);
export const GetIsModalClosable = () =>
  useSelector((state: CommonsState) => state.commons.isModalClosable);
