/* eslint-disable */
import React, {
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState
} from 'react';
import { colorPalette, useIsMediumScreen } from 'theme';
import {
  GetDownloadPatentLoader,
  GetNftDeployStartLoader,
  GetTokenURI,
  GetTxApprovalModalObj,
  GetUser
} from 'redux-state/selectors';
import { useDispatch } from 'react-redux';
import { IoClose } from 'react-icons/io5';
import Actions from 'redux-state/actions';
import {
  Box,
  CircularProgress,
  Grid,
  IconButton,
  Link,
  Typography
} from '@mui/material';
import { CloudUpload } from '@mui/icons-material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import {
  Accordion,
  AccordionSummary,
  AccordionDetails,
  LinearProgress,
  Button
} from '@mui/material';
import { MoreVert as MoreVertIcon } from '@mui/icons-material';
import MintPatentLogo from 'assets/icons/MintPatent.svg';
import PurpleHexagonIcon from 'assets/icons/PurpleHexagon.svg';
import OpenSeaLogo from 'assets/icons/OpenSea-Full-Logo.svg';
import { EntityIcon } from 'components/TreeGraph/EntityIcon';
import { hasNoSolutions } from 'components/ConceptsButton/helpers';
import DataContext from 'contexts/DataContext';
import dataProvider from 'dataPrvider';
import { useRemoveQueryParams } from 'helpers';
import getQueryParams from 'helpers/getQueryParams';
import { getBasePath } from 'helpers/common';
import { deployNft } from 'helpers/blockchain';
import { AnimatePresence, motion } from 'framer-motion';
import { MakePatentPendingModal } from 'modals/MakePatentPending';
import { DownloadPatentAppModal } from 'modals/DownloadPatentApplication';
import { UploadFilingReceiptModal } from 'modals/UploadFillingReceiptModal';
import { FinalizeConceptModal } from 'modals/FinalizeConceptModal';
import { LockConceptModal } from 'modals/LockConceptModal';
import { TxApprovalModal } from 'modals/TxApprovalModal';
import { ConceptNodeTypes } from 'pages/newIdeaMap/ConceptTab';
import {
  ASSET_TYPES,
  CHANNELS,
  Constants,
  ERRORS,
  VARIANT
} from 'utilities/constants';
import pusher from '../../config/pusherConfig';
import { ConceptCheckList } from '../common/ConceptCheckList';
import { useChecklist } from '../common/CheckListData';
import { CustomButton } from '../common/buttons/InventionLargeButton';
import { TagInfo } from '../CardTag';
import { LogoMindminer } from '../icons/LogoMindminer';
import {
  ProblemContainer,
  ProblemIcon,
  ProbSolContainer,
  SolutionBar,
  SolutionContainer,
  SolutionIcon,
  StyledAccordion,
  StyledDetailBox,
  StyledGrid,
  StyledIdeaPointsCount,
  StyledIdeaPointsText,
  StyledImageBox,
  StyledLinearProgress,
  StyledMintButton,
  StyledParentContainer,
  StyledPatentText,
  StyledPoweredByBox,
  StyledProgressAccordion,
  StyledStakingInternalBox,
  StyledStakingMainBox,
  StyledStakingNumericTextBox,
  StyledStakingSimpleTextBox,
  StyledTitle,
  StyledVideoMainBox,
  TeaserTypo
} from './styles';
import { ChipList } from '../Tag';
import { StyledIcons, VotingBox } from 'pages/home/StyledComponents';
import Vote from '../common/Vote';

export interface ProgressStatus {
  descriptionAndTitleGeneratedFromAI: boolean;
  enoughNumberOfSolutionRelationship: boolean;
  enoughNumberOfSolutions: boolean;
  nameAndAdressOfInventorSaved: boolean;
  solutionRelationshipsDuplicate: boolean;
  solutionsDuplicate: boolean;
}

const Nodes = ({ concept }) => {
  const dispatch = useDispatch();
  const user = GetUser();

  const handleSolutionDelete = useCallback(
    (solutionId) => {
      const selected = concept.solutions
        .filter((solution) => solution.id !== solutionId)
        .map(({ id }) => id);

      const problems = concept.problems
        .filter((problem) =>
          problem?.children?.some((child) => selected?.includes(child.id))
        )
        .map(({ id }) => id);
      if (user) {
        dispatch(Actions.togLoadSolution(true));
        dispatch(Actions.updateConcept(concept.id, { selected, problems }));
      } else {
        dispatch(Actions.openAuthModal(true));
      }
    },
    [dispatch, concept?.id, concept?.problems, concept?.solutions, user]
  );

  return (
    <Accordion
      sx={{ borderRadius: '10px', boxShadow: '0px 4px 8px rgba(0, 0, 0, 0.2)' }}
    >
      <AccordionSummary
        expandIcon={<ExpandMoreIcon />}
        aria-controls="panel1a-content"
        id="panel1a-header"
      >
        <Typography
          sx={{
            fontSize: '16px',
            fontWeight: 600,
            color: colorPalette.lightgreyish
          }}
          variant="h6"
        >
          Problems & Solutions
        </Typography>
      </AccordionSummary>

      <AccordionDetails>
        <SolutionBar>
          {concept?.problems?.map((problem) => {
            const filteredSolutions = concept?.solutions?.filter((solution) =>
              problem?.children?.some((child) => child.id === solution.id)
            );

            return filteredSolutions?.length ? (
              <React.Fragment key={problem.id}>
                <ProblemContainer
                  onClick={() => {
                    window.open(
                      `/${Constants.PROBLEMS}/${problem.key}`,
                      '_blank'
                    );
                  }}
                >
                  <ProbSolContainer>
                    <ProblemIcon>
                      <EntityIcon type={ConceptNodeTypes.PROBLEM} />
                    </ProblemIcon>
                    <TeaserTypo>
                      {problem?.teaser ? problem.teaser : problem.title}
                    </TeaserTypo>
                  </ProbSolContainer>
                </ProblemContainer>

                {filteredSolutions.map((solution) => (
                  <AnimatePresence key={solution.id}>
                    <motion.div
                      initial={{ x: '100vw', opacity: 0 }}
                      animate={{ x: 0, opacity: 1 }}
                      exit={{ x: '-100vw', opacity: 0 }}
                      transition={{ duration: 0.5, ease: 'easeInOut' }}
                      key={solution.key}
                    >
                      <SolutionContainer
                        onClick={() => {
                          window.open(`/solutions/${solution.key}`, '_blank');
                        }}
                      >
                        <ProbSolContainer>
                          <SolutionIcon>
                            <EntityIcon type={ConceptNodeTypes.SOLUTION} />
                          </SolutionIcon>
                          <TeaserTypo>
                            {solution?.teaser
                              ? solution.teaser
                              : solution.title}
                          </TeaserTypo>
                        </ProbSolContainer>
                        {!concept.isFiled && (
                          <IconButton
                            aria-label="delete"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleSolutionDelete(solution?.id);
                            }}
                          >
                            <IoClose size={22} color={colorPalette.black} />
                          </IconButton>
                        )}
                      </SolutionContainer>
                    </motion.div>
                  </AnimatePresence>
                ))}
              </React.Fragment>
            ) : null;
          })}
        </SolutionBar>
      </AccordionDetails>
    </Accordion>
  );
};

const ConceptDetailView = ({
  concept,
  profile,
  archiveStatus,
  pagination,
  fetchProfileConcepts,
  isConcept
}) => {
  const isMediumScreen = useIsMediumScreen();
  const dispatch = useDispatch();
  const user = GetUser();
  const removeQueryParams = useRemoveQueryParams();
  const patentFileFlow = getQueryParams(Constants.PATENT_FILE_FLOW);
  const { setAlertContent } = useContext(DataContext);
  const downloadLoader: boolean = GetDownloadPatentLoader();
  const deployNFTLoader = GetNftDeployStartLoader();
  const txApprovalModalObj = GetTxApprovalModalObj();
  const tokenURI = GetTokenURI();
  const { showToast } = useContext(DataContext);

  const [checkListData, setCheckListData] = useState<ProgressStatus>(null);
  const [openDownloadPatentAppModal, setOpenDownloadPatentAppModal] =
    useState<boolean>(false);
  const [openPatentPendingModal, setOpenPatentPendingModal] =
    useState<boolean>(false);
  const [openLockConceptModal, setOpenLockConceptModal] =
    useState<boolean>(false);
  const [openFilingReceiptModal, setOpenFilingReceiptModal] =
    useState<boolean>(false);
  const [isFinalizeModalOpen, setIsFinalizeModalOpen] =
    useState<boolean>(false);
  const [deployingId, setDeployingId] = useState<string | null>(null);
  const showTxApprovalModal =
    txApprovalModalObj?.open && txApprovalModalObj?.type == ASSET_TYPES.NFT;

  console.log('Invention Concept Data: ', concept);

  const getVoteStatus = useCallback((concept) => {
    return concept.liked ? '1' : concept.disliked ? '-1' : null;
  }, []);

  useEffect(() => {
    const channel = pusher.subscribe(CHANNELS.VIDEO_GENERATION_CHANNEL);
    channel.bind(Constants.VIDEOS, function (data) {
      fetchProfileConcepts();
    });
    return () => {
      channel.unbind(Constants.VIDEOS);
      pusher.unsubscribe(CHANNELS.VIDEO_GENERATION_CHANNEL);
    };
  }, [dispatch, profile.id, pagination, archiveStatus]);

  const isDisabled = useCallback(
    (item) => {
      return concept?.envelopeId || concept?.isFiled || downloadLoader;
    },
    [downloadLoader]
  );

  useEffect(() => {
    const fetchProgress = async () => {
      try {
        if (concept) {
          const response = await dataProvider.checkImprovedProgress(
            concept?.id
          );
          setCheckListData(response ?? null);
        }
      } catch (error) {
        console.error(ERRORS.ERROR_FETCHING_PROGRESS_DATA, error);
      }
    };

    fetchProgress();
  }, [concept?.id]);

  const setOpenDownloadAndPatentPendingModal = (
    isOpenDownloadModal,
    isOpenPatentPendingModal
  ) => {
    setOpenDownloadPatentAppModal(isOpenDownloadModal);
    setOpenPatentPendingModal(isOpenPatentPendingModal);
  };

  const beforeLockConceptModalClose = useCallback(() => {
    removeQueryParams([Constants.PATENT_FILE_FLOW]);
  }, []);

  const openModalAfterLockConcept = useCallback(() => {
    if (patentFileFlow && patentFileFlow == Constants.VIA_SELF) {
      setOpenDownloadPatentAppModal(true);
    } else {
      setOpenPatentPendingModal(true);
    }
  }, [patentFileFlow]);

  useEffect(() => {
    dispatch(
      Actions.getProfileConcepts(profile.id, pagination, null, archiveStatus)
    );
  }, [openDownloadPatentAppModal]);

  const makePatentApplication = useCallback(() => {
    if (hasNoSolutions(concept)) {
      setAlertContent(<>{Constants.YOU_NEED_TO_ADD_ATLEAST_ONE_SOLUTION}</>);
      return;
    }

    if (concept?.isLocked) {
      if (concept?.isDownloaded) {
        setOpenDownloadAndPatentPendingModal(true, false);
      } else {
        setOpenPatentPendingModal(true);
      }
    } else {
      setOpenLockConceptModal(true);
    }
    fetchProfileConcepts();
  }, [setAlertContent, concept]);

  const onTaskCompletion = useCallback(() => {
    dispatch(
      Actions.getProfileConcepts(profile.id, pagination, null, archiveStatus)
    );
  }, [dispatch, profile.id, pagination, archiveStatus]);

  const handleImprove = () => {};

  const handleVideoGenerateFromAI = async () => {
    try {
      await dataProvider.processVideoExample(
        Constants.TEXT_TO_VIDEO,
        concept.id
      );
      dispatch(
        Actions.getProfileConcepts(profile.id, pagination, null, archiveStatus)
      );
    } catch (error) {
      console.error(ERRORS.VIDEO_GENERATION_FAILED, error);
    }
  };

  const openTxApprovalModal = useCallback(
    (gasFeeEstimate, type) => {
      dispatch(
        Actions.openTxApprovalModal({
          txApprovalModalObj: {
            gasFee: gasFeeEstimate,
            open: true,
            type
          }
        })
      );
    },
    [dispatch]
  );

  const deployNFT = useCallback(
    (application: { _id: string }) => {
      if (user) {
        setDeployingId(application._id);
        dispatch(
          Actions.nftDeployStart({
            id: application._id,
            onDeployStartSuccess: openTxApprovalModal,
            privateKey: user.privateKey
          })
        );
      }
    },
    [dispatch, openTxApprovalModal, user]
  );

  const onTxConfirm = useCallback(async () => {
    try {
      if (user) {
        if (!concept) return;
        dispatch(Actions.toggleDeployNftLoader({ deployNFTLoader: true }));
        const [transactionHash, tokenId] = await deployNft(
          user.privateKey,
          tokenURI
        );
        dispatch(
          Actions.nftDeployFinish({
            id: concept.id,
            isArchived: archiveStatus,
            pagination,
            privateKey: user.privateKey,
            tokenId,
            transactionHash,
            userId: user.id,
            walletAddress: user.walletAddress
          })
        );
      }
    } catch (error) {
      dispatch(Actions.toggleDeployNftLoader({ deployNFTLoader: false }));
      showToast(ERRORS.DEPLOY_NFT, { variant: VARIANT.ERROR });
    }
  }, [
    archiveStatus,
    deployingId,
    dispatch,
    pagination,
    showToast,
    tokenURI,
    user
  ]);

  const isDeployingNFT = useMemo(() => {
    return (item) => {
      return deployNFTLoader && deployingId === item._id;
    };
  }, [deployNFTLoader, deployingId]);

  const UploadFilingReceipt = useCallback((item) => {
    setOpenFilingReceiptModal(true);
  }, []);

  const handleNFTButton = (concept) => {
    if (concept.nftTransactionUrl !== undefined) {
      window.open(concept.nftTransactionUrl, '_blank');
    } else {
      deployNFT(concept);
    }
  };

  const { fulfilled, warnings } = useChecklist(checkListData);

  const totalChecks = fulfilled.length + warnings.length;
  const passedChecks = fulfilled.length;
  const progressPercentage = Math.round((passedChecks / totalChecks) * 100);

  if (!concept) {
    return (
      <Typography
        sx={{
          fontSize: isMediumScreen ? '0.7963rem' : '1.125rem',
          fontWeight: 600,
          fontFamily: 'Montserrat, sans-serif'
        }}
      >
        {isConcept
          ? Constants.SELECT_A_CONCEPT_TO_VIEW_DETAILS
          : Constants.SELECT_A_INVENTION_TO_VIEW_DETAILS}
      </Typography>
    );
  }

  const VideoSection = () => {
    if (isConcept) {
      return (
        <Box height={250} mb={2}>
          {concept.isDownloaded ? (
            concept.videoUrl ? (
              <>
                <StyledVideoMainBox>
                  <video src={concept.videoUrl} controls />
                </StyledVideoMainBox>
                <SolutionImages concept={concept} />
              </>
            ) : (
              <StyledVideoMainBox>
                {concept.videoIsProcessing ? (
                  <CircularProgress />
                ) : (
                  <Button
                    variant={VARIANT.CONTAINED}
                    color="primary"
                    onClick={handleVideoGenerateFromAI}
                  >
                    Generate Video
                  </Button>
                )}
              </StyledVideoMainBox>
            )
          ) : (
            <>
              <StyledVideoMainBox>
                <Typography variant="body1">
                  {Constants.TO_GENERATE_VIDEO_PATENT_THIS_CONCEPT_FIRST}
                </Typography>
              </StyledVideoMainBox>
              <SolutionImages concept={concept} />
            </>
          )}
        </Box>
      );
    } else {
      return (
        <Box>
          {concept.videoUrl ? (
            <StyledVideoMainBox>
              <video
                src={concept.videoUrl}
                controls
                width="100%"
                height="300px"
              />
            </StyledVideoMainBox>
          ) : (
            <StyledVideoMainBox>
              <Typography variant="body1">
                {Constants.NO_VIDEO_AVAILABLE}
              </Typography>
            </StyledVideoMainBox>
          )}
        </Box>
      );
    }
  };

  const SolutionImages = ({ concept }) => {
    return (
      <StyledImageBox>
        {concept.solutions.map((solution) =>
          solution.files.map((file, index) => (
            <img
              key={index}
              src={file.url}
              alt={`Solution Image ${index + 1}`}
            />
          ))
        )}
      </StyledImageBox>
    );
  };

  return (
    <StyledDetailBox>
      <StyledParentContainer>
        <StyledTitle>{concept.title}</StyledTitle>
        <StyledIcons>
          <Box>
            <VotingBox>
              <Vote
                item={concept.itemId}
                itemType={concept.itemType}
                pagination={pagination}
                voteStatus={getVoteStatus(concept)}
              />
            </VotingBox>
          </Box>
        <IconButton edge="end">
          <MoreVertIcon sx={{ fontSize: 30 }} />
        </IconButton>
        </StyledIcons>
      </StyledParentContainer>
      {!isConcept && (
        <>
          {(() => {
            const formattedDate = new Date(
              concept?.createdAt
            ).toLocaleDateString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric'
            });

            const awaitingText = Constants.AWAITING_PATENT_TEXT;
            const patentPendingText = Constants.PATENT_PENDING_TEXT;

            return (
              <>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <Typography
                    sx={{
                      fontSize: '12px',
                      fontWeight: 700,
                      marginBottom: '10px'
                    }}
                  >
                    {Constants.INITIALLY_CREATED_TEXT}{' '}
                    {concept?.ownerInfo?.username} on {formattedDate},{' '}
                    {concept?.nftTransactionUrl ? (
                      <StyledPatentText>{awaitingText}</StyledPatentText>
                    ) : (
                      <StyledPatentText>{patentPendingText}</StyledPatentText>
                    )}
                  </Typography>
                </Box>
              </>
            );
          })()}
        </>
      )}
      <VideoSection />
      {!isConcept && (
        <>
          <SolutionImages concept={concept} />
        </>
      )}
      {concept?.isFiled && (
        <>
          <Box sx={{ paddingTop: 2 }}>
            <CustomButton
              goldenButton={true}
              centerText={Constants.EARN_JACKPOT}
              endText="$--"
              startIcon={
                <LogoMindminer
                  fill={colorPalette.white}
                  width={45}
                  height={45}
                />
              }
              startText={Constants.CROWDFUND_AND_MANUFACTURE}
              onClick={() => console.log(Constants.CROWDFUND_AND_MANUFACTURE)}
              sx={{ mb: 1 }}
            />
          </Box>
          <Box display={'flex'} flexDirection={'row'}>
            <Box display="flex" alignItems="center" width="95%">
              <StyledLinearProgress
                colorGreen={false}
                variant="determinate"
                value={progressPercentage >= 100 ? 100 : progressPercentage}
              />
            </Box>
            <Box display="flex" alignItems="center">
              {concept && checkListData ? (
                <Typography
                  variant="subtitle1"
                  sx={{
                    color: colorPalette.silverGrey,
                    fontWeight: 500,
                    fontSize: '1.125rem'
                  }}
                >
                  {progressPercentage >= 100 ? 100 : progressPercentage}%
                </Typography>
              ) : (
                <CircularProgress size={24} />
              )}
            </Box>
          </Box>
          <Typography sx={{ fontSize: '13px', fontWeight: 500 }} mb={2}>
            {Constants.STAKE_TEXT}
          </Typography>
          <StyledStakingMainBox>
            <LogoMindminer fill={colorPalette.amberOrange} />
            <StyledStakingInternalBox>
              <StyledStakingSimpleTextBox>
                {Constants.IDEA_COINS_STACKING_JACKPOT}
              </StyledStakingSimpleTextBox>
              <StyledStakingNumericTextBox>
                87.5 {Constants.COINS}
                <StyledStakingNumericTextBox className={VARIANT.NORMAL}>
                  {Constants.SLASH_UNIT}
                </StyledStakingNumericTextBox>
              </StyledStakingNumericTextBox>
            </StyledStakingInternalBox>
          </StyledStakingMainBox>
        </>
      )}
      <StyledAccordion>
        <AccordionSummary
          expandIcon={<ExpandMoreIcon />}
          aria-controls="panel1a-content"
          id="panel1a-header"
        >
          <Typography
            sx={{
              fontSize: '16px',
              fontWeight: 600,
              color: colorPalette.lightgreyish
            }}
          >
            {Constants.TAGS_AND_DETAILS_TEXT}
          </Typography>
        </AccordionSummary>
        <AccordionDetails>
          <Box>
            <StyledGrid container spacing={2}>
              <Grid item xs={12}>
                <Box display="flex" alignItems="center">
                  <LogoMindminer
                    fill={colorPalette.purple}
                    width={20}
                    height={20}
                  />
                  <StyledIdeaPointsCount>
                    {concept.ideaPoints}
                  </StyledIdeaPointsCount>
                  <StyledIdeaPointsText>
                    Idea Points Generated
                  </StyledIdeaPointsText>
                </Box>
              </Grid>
              <Grid item xs={12}>
                <ChipList
                  list={concept?.tagsInfo}
                  max={10}
                  getName={(tag) => {
                    const name = (tag as TagInfo).name || '';
                    return name.length > 10 ? `${name.slice(0, 10)}...` : name;
                  }}
                  getUrl={(tagUrl) => {
                    const basePath = getBasePath(tagUrl);
                    return `/${basePath}/${(tagUrl as TagInfo).key || (tagUrl as TagInfo).id}`;
                  }}
                />
              </Grid>
            </StyledGrid>

            <Typography variant="body2" color="textSecondary" mt={2}>
              {concept.description}
            </Typography>
          </Box>
        </AccordionDetails>
      </StyledAccordion>
      <Box mt={2} mb={2}>
        <Nodes concept={concept} />
      </Box>
      {!concept.isFiled && (
        <StyledProgressAccordion>
          <AccordionSummary
            expandIcon={<ExpandMoreIcon />}
            aria-controls="panel1a-content"
            id="panel1a-header"
            sx={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              '& .MuiLinearProgress-bar': {
                backgroundColor: colorPalette.green
              }
            }}
          >
            <Box
              display="flex"
              alignItems="center"
              justifyContent="space-between"
              width="100%"
            >
              <Box display="flex" alignItems="center" width="50%">
                <StyledLinearProgress
                  colorGreen={true}
                  variant="determinate"
                  value={progressPercentage >= 100 ? 100 : progressPercentage}
                />
              </Box>
              <Box display="flex" alignItems="center">
                {concept && checkListData ? (
                  <Typography variant="subtitle1" fontWeight="bold">
                    {progressPercentage >= 100 ? 100 : progressPercentage}%
                    Improved
                  </Typography>
                ) : (
                  <CircularProgress size={24} />
                )}
              </Box>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Box display="flex" justifyContent="flex-end" mb={2}>
              <Link
                href="#"
                color="primary"
                underline="hover"
                fontSize="0.875rem"
              >
                {Constants.IMPROVE_YOUR_CONCEPT_WITH_THE_HELP_OF_AI_CHAT} &rarr;
              </Link>
            </Box>
            {concept && checkListData ? (
              <ConceptCheckList fulfilled={fulfilled} warnings={warnings} />
            ) : (
              <LinearProgress />
            )}
          </AccordionDetails>
        </StyledProgressAccordion>
      )}
      {concept.isFiled ? (
        <>
          <CustomButton
            goldenButton={false}
            startIcon={
              <img src={PurpleHexagonIcon} alt={Constants.HEXAGON_ICON} />
            }
            startText={
              isDeployingNFT(concept)
                ? Constants.DEPLOYING
                : concept.nftTransactionUrl
                  ? Constants.LIST_YOUR_NFT
                  : Constants.DEPLOY_NFT
            }
            centerText={''}
            endText="$--"
            onClick={() => handleNFTButton(concept)}
            sx={{ mt: 1 }}
          />
          <StyledPoweredByBox>
            <Typography mr={1}>{Constants.POWERED_BY}</Typography>
            <img src={OpenSeaLogo}></img>
          </StyledPoweredByBox>
        </>
      ) : (
        <>
          <StyledMintButton
            variant="contained"
            disabled={concept?.generatingPatentApplication}
            color="success"
            fullWidth
            onClick={
              concept?.isDownloaded
                ? makePatentApplication
                : () => setIsFinalizeModalOpen(true)
            }
          >
            <img src={MintPatentLogo} alt={Constants.MINT_PATENT_LOGO} />
            <Typography variant="h6" marginLeft={1}>
              {concept.isDownloaded
                ? Constants.DOWNLOAD_PATENT_APPLICATION
                : concept?.generatingPatentApplication
                  ? Constants.DOWNLOADING_PATENT
                  : Constants.MAKE_PATENT_APPLICATION}
            </Typography>
          </StyledMintButton>
          {concept.isDownloaded && !concept.envelopeId && (
            <StyledMintButton
              variant="contained"
              disabled={isDisabled(concept)}
              color="success"
              fullWidth
              onClick={() => UploadFilingReceipt(concept)}
            >
              <CloudUpload />
              <Typography variant="h6" marginLeft={1}>
                {Constants.E_FILE_PATENT}
              </Typography>
            </StyledMintButton>
          )}
        </>
      )}
      {concept && (
        <LockConceptModal
          archiveStatus={archiveStatus}
          concept={concept}
          open={openLockConceptModal}
          pagination={pagination}
          profileId={profile.id}
          setOpen={setOpenLockConceptModal}
          setOpenNextModal={openModalAfterLockConcept}
          beforeClose={beforeLockConceptModalClose}
          onTaskComplete={onTaskCompletion}
        />
      )}
      <MakePatentPendingModal
        concept={concept}
        onPatentDownloadClick={setOpenDownloadAndPatentPendingModal}
        open={openPatentPendingModal}
        pagination={pagination}
        setOpen={setOpenPatentPendingModal}
      />
      <DownloadPatentAppModal
        application={concept}
        onFileViaMindMiner={setOpenDownloadAndPatentPendingModal}
        open={openDownloadPatentAppModal}
        pagination={pagination}
        profile={profile}
        setOpen={setOpenDownloadPatentAppModal}
      />
      <UploadFilingReceiptModal
        concept={concept}
        open={openFilingReceiptModal}
        setOpen={setOpenFilingReceiptModal}
        pagination={pagination}
        profileId={profile.id}
      />
      <FinalizeConceptModal
        approveImprovements={handleImprove}
        approveMintToken={makePatentApplication}
        open={isFinalizeModalOpen}
        setOpen={setIsFinalizeModalOpen}
      />
      {showTxApprovalModal && (
        <TxApprovalModal
          gasFee={txApprovalModalObj.gasFee}
          onConfirm={onTxConfirm}
          open={txApprovalModalObj.open}
          type={txApprovalModalObj.type}
        />
      )}
    </StyledDetailBox>
  );
};

export { ConceptDetailView };
