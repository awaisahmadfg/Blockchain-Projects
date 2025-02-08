import React, { useCallback, useEffect, useState } from 'react';
import { useDispatch } from 'react-redux';
import { GetPublicUser, GetUser } from 'redux-state/selectors';
import Actions from 'redux-state/actions';
import { Box, Grid, Tabs } from '@mui/material';
import { ConceptDetailView } from 'components/ConceptView/ConceptDetail';
import { NodeContentBase } from 'components/InteractiveNodeContainer/NodeContent/NodeContentBase';
import dataProvider from 'dataPrvider';
import getQueryParams from 'helpers/getQueryParams';
import { Node } from 'interface/common';
import SolutionModal from 'modals/AddSolution';
import AddToConceptModal from 'modals/AddToConceptModal';
import { colorPalette, useIsMediumScreen } from 'theme';
import { Constants } from 'utilities/constants';
import {
  StyledBoxContent,
  StyledGridItem,
  StyledProblemButton,
  StyledTab,
  StyledTabIcon,
  StyledTabLabel,
  StyledTabLabelCustom
} from './StyledComponents';
import { AddToBox } from 'modals/ImproveModal/NodeContent/StyledComponents';
import { HexPlusIcon } from 'components/icons/HexPlusIcon';

interface InventionPublicViewProps {
  inventionKey?: string;
  graphData?: any;
}

/* eslint-disable max-lines-per-function */
const InventionPublicView = ({
  inventionKey,
  graphData
}: InventionPublicViewProps) => {
  const currentTab = getQueryParams('currentTab');
  const isMediumScreen = useIsMediumScreen();
  const user = GetUser();
  const dispatch = useDispatch();
  const tabMapper = { Problems: 0, Solutions: 1 };
  const initialTab =
    currentTab && tabMapper[currentTab] ? tabMapper[currentTab] : 0;
  const [activeTab, setActiveTab] = useState<number>(initialTab);
  const [invention, setInvention] = useState<any>();
  const [isSolModalOpen, setIsSolModalOpen] = useState<boolean>(false);
  const [isAddToConceptModalOpen, setIsAddToConceptModalOpen] =
    useState<boolean>(false);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) =>
    setActiveTab(newValue);

  const openAddToConceptModal = useCallback(
    (item) => {
      if (user) {
        setSelectedNode(item);
        setIsAddToConceptModalOpen(true);
      } else {
        dispatch(Actions.openAuthModal(true));
      }
    },
    [dispatch, user]
  );

  const closeAddToConceptModal = useCallback(() => {
    setIsAddToConceptModalOpen(false);
  }, []);

  const ProblemButton = {
    component: () => (
      <StyledProblemButton>{Constants.SOLVE}</StyledProblemButton>
    ),
    onClick: () => setIsSolModalOpen(true)
  };

  const SolutionButton = (item) => ({
    component: () => (
      <AddToBox>
        <HexPlusIcon />
      </AddToBox>
    ),
    onClick: () => openAddToConceptModal(item)
  });

  const handleDrawer = useCallback(() => {
    dispatch(Actions.toggleConceptCart(true));
  }, [dispatch]);

  //un-used code for now
  // const SolutionButton = [
  //   {
  //     component: ({ node }) => (
  //       <Button>
  //         {isSolutionSelected(node.id) ? <HexDoneIcon /> : <HexPlusIcon />}
  //       </Button>
  //     ),
  //     onClick: (event, node) => {
  //       if (!isSolutionSelected(node.id)) {
  //         event.stopPropagation();
  //         const { id: solutionId, problem } = node;
  //         if (isObjectEmpty(activeConcept)) {
  //           const appInfo = {
  //             title: '',
  //             selected: [solutionId],
  //             problems: [problem]
  //           };
  //           dispatch(Actions.createConcept(appInfo));
  //         } else {
  //           const existingProbIds = activeConcept.problems.map(({ id }) => id);

  //           const newProblems = existingProbIds.includes(problem)
  //             ? existingProbIds
  //             : [...existingProbIds, problem];

  //           const data = {
  //             selected: [solutionId, ...activeConcept.selected],
  //             problems: newProblems
  //           };

  //           dispatch(Actions.updateConcept(activeConcept.id, data));
  //         }
  //         toastify(
  //           `${Constants.SOLUTION_ADDED_TO} ${Constants.CONCEPT}`,
  //           VARIANT.SUCCESS,
  //           VARIANT.BOTTOM_LEFT,
  //           TOASTIFY_DURATION
  //         );
  //       }
  //     }
  //   }
  // ];

  const NodesView = ({ type }) => {
    const items =
      type === Constants.PROBLEMS
        ? invention?.problems
        : type === Constants.SOLUTIONS
          ? invention?.solutions
          : [];

    return items?.map((item) => (
      <Box key={item?.id} sx={{ marginBottom: '0.625rem' }}>
        <NodeContentBase
          node={item}
          showAvatar={false}
          buttonList={[
            type === Constants.PROBLEMS ? ProblemButton : SolutionButton(item)
          ]}
          tags={graphData?.tags}
        />
      </Box>
    ));
  };
  const tabs = [
    {
      title: (
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <StyledTabIcon active={0} isMediumScreen={isMediumScreen}>
            {invention?.problems.length}
          </StyledTabIcon>
          <StyledTabLabelCustom active={activeTab === 0}>
            {Constants.SOLVED_PROBLEMS}
          </StyledTabLabelCustom>
        </Box>
      ),
      content: <NodesView type={Constants.PROBLEMS} />,
      key: Constants.PROBLEM
    },
    {
      title: (
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <StyledTabIcon active={1} isMediumScreen={isMediumScreen}>
            {invention?.selected?.length}
          </StyledTabIcon>
          <StyledTabLabelCustom active={activeTab === 1}>
            {Constants.SOLUTION_ADDED}
          </StyledTabLabelCustom>
        </Box>
      ),
      content: <NodesView type={Constants.SOLUTIONS} />,
      key: Constants.SOLUTIONS
    }
  ];

  useEffect(() => {
    const fetchData = async () => {
      try {
        const { data: applicationData } = await dataProvider.getOneByKey(
          'applications',
          { key: inventionKey as string }
        );
        setInvention(applicationData);
      } catch (error) {
        console.error('Error fetching application data:', error);
      }
    };
    if (inventionKey) fetchData();
  }, [inventionKey]);

  const profile = GetPublicUser();

  return graphData && Object.keys(graphData).length ? (
    <>
      <Grid
        container
        spacing={0}
        sx={{
          width: '90%',
          margin: 'auto',
          marginTop: '35px',
          border: '1px solid lightgrey',
          borderRadius: '10px',
          overflow: 'hidden'
        }}
      >
        <StyledGridItem item lg={6} sm={12} isMediumScreen={isMediumScreen}>
          <ConceptDetailView
            selectedConceptId={null}
            publicViewInvetion={invention}
            profile={profile}
            archiveStatus={null}
            pagination={null}
            fetchProfileConcepts={null}
            isConcept={false}
            showShareOption={false}
            showMoreVertIcon={false}
          />
        </StyledGridItem>
        <Grid
          item
          lg={6}
          sm={12}
          sx={{
            overflowY: 'auto',
            maxHeight: 'calc(100vh - 70px)',
            padding: '0'
          }}
        >
          <Tabs
            orientation="horizontal"
            aria-label="secondary tabs example"
            indicatorColor="primary"
            onChange={handleTabChange}
            scrollButtons={true}
            TabIndicatorProps={{
              style: {
                backgroundColor: colorPalette.purple
              }
            }}
            value={activeTab}
            variant="fullWidth"
          >
            {tabs.map((tab, index) => (
              <StyledTab
                key={tab.key}
                label={<StyledTabLabel>{tab.title}</StyledTabLabel>}
                active={index === activeTab}
              />
            ))}
          </Tabs>
          <StyledBoxContent>{tabs[activeTab].content}</StyledBoxContent>
        </Grid>
      </Grid>
      {isSolModalOpen && (
        <SolutionModal
          open={isSolModalOpen}
          onClose={() => setIsSolModalOpen(false)}
        />
      )}

      {isAddToConceptModalOpen && (
        <AddToConceptModal
          handleDrawer={handleDrawer}
          isFeed={true}
          node={selectedNode}
          onClose={closeAddToConceptModal}
          open={isAddToConceptModalOpen}
        />
      )}
    </>
  ) : null;
};
/* eslint-disable max-lines-per-function */

export default InventionPublicView;
