import React, { useState } from 'react';
import { Box, IconButton, Menu, MenuItem, Tabs } from '@mui/material';
import MarketplaceSearchBar from '../MarketplaceSearchBar/MarketplaceSearchBar';
import { ListedNftView } from '../ListedNftView/ListedNftView';
import { NftCollectionView } from '../NftCollectionView/NftCollectionView';
import { ASSET_TYPES, Constants, VARIANT } from 'utilities/constants';
import { HeaderBox, StyledDivider, StyledTab } from './StyledComponents';
import { TransactionsView } from '../MyWallet/tabs/TransactionsView';
import MenuRoundedIcon from '@mui/icons-material/MenuRounded';
import { useIsMediumScreen } from 'theme';

export const MarketplaceView = () => {
  const [activeTabIndex, setActiveTabIndex] = useState(0);
  const [searchValue, setSearchValue] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [triggerRefresh] = useState(0);
  const isMediumScreen = useIsMediumScreen();

  const tabs = [
    {
      title: Constants.MARKETPLACE_TEXT,
      content: <ListedNftView searchQuery={searchValue} />
    },
    {
      title: Constants.MY_COLLECTIONS_TEXT,
      content: <NftCollectionView searchQuery={searchValue} />
    },
    {
      title: Constants.HISTORY_TEXT,
      content: (
        <TransactionsView
          refresh={triggerRefresh}
          walletType={ASSET_TYPES.NFT}
        />
      )
    }
  ];

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTabIndex(newValue);
  };

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleMenuItemClick = (index: number) => {
    setActiveTabIndex(index);
    handleMenuClose();
  };

  return (
    <HeaderBox>
      {isMediumScreen ? (
        <>
          <IconButton onClick={handleMenuClick}>
            <MenuRoundedIcon />
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
          >
            {tabs.map((tab, index) => (
              <MenuItem
                key={tab.title}
                onClick={() => handleMenuItemClick(index)}
              >
                {tab.title}
              </MenuItem>
            ))}
          </Menu>
        </>
      ) : (
        <Tabs
          value={activeTabIndex}
          onChange={handleTabChange}
          aria-label="basic tabs"
          indicatorColor={VARIANT.PRIMARY}
          textColor={VARIANT.PRIMARY}
          variant={VARIANT.STANDARD}
        >
          {tabs.map((tab) => (
            <StyledTab key={tab.title} label={tab.title} />
          ))}
        </Tabs>
      )}
      <StyledDivider />
      {tabs[activeTabIndex].title !== Constants.HISTORY_TEXT && (
        <MarketplaceSearchBar
          searchValue={searchValue}
          setSearchValue={setSearchValue}
        />
      )}
      <Box sx={{ marginTop: '1rem' }}>{tabs[activeTabIndex].content}</Box>
    </HeaderBox>
  );
};
