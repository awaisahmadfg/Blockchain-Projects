import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Close } from '@mui/icons-material';
import { Divider, IconButton } from '@mui/material';
import Config from 'config/config';
import { nftApproval } from 'helpers/blockchain';
import { Pagination, Token } from 'interface/common';
import { BaseModal } from 'modals/Common/BaseModal';
import { TxApprovalModal } from 'modals/TxApprovalModal';
import { useDispatch, useSelector } from 'react-redux';
import Actions from 'redux-state/actions';
import { setModalClosable } from 'redux-state/commons/actions';
import {
  GetIsModalClosable,
  GetTxApprovalModalObj,
  GetUser
} from 'redux-state/selectors';
import { colorPalette } from 'theme';
import { Constants, NUMBERS } from 'utilities/constants';
import ListNftForm from './ListNftForm/ListNftForm';
import { NftInfoView } from './NftInfo';
import { ContentBox, HeaderBox, HeaderText } from './styledComponents';
import { handleListNftApproval } from './utils';
import { getTxApprovalModalProps } from './utils/getTxApprovalModalProps';
import { estimateGasForListNFT } from './utils/estimateGasForList';

interface ListNftModalProps {
  filters?: any;
  nftContract?: string;
  open?: boolean;
  pagination?: Pagination;
  setOpen?: React.Dispatch<React.SetStateAction<boolean>>;
  token?: Token;
}

// eslint-disable-next-line max-lines-per-function
export const ListNftModal: React.FC<ListNftModalProps> = ({
  filters,
  nftContract,
  open,
  pagination,
  setOpen,
  token
}) => {
  const { tokenId } = token;
  const user = GetUser();
  const dispatch = useDispatch();
  const txApprovalModalObj = GetTxApprovalModalObj();
  const isModalClosable = useSelector(() => GetIsModalClosable());

  const [listPrice, setListPrice] = useState<number>(0);
  const [royaltyFeePercentage, setRoyaltyFeePercentage] = useState<number>(0);
  const [totalEarnings, setTotalEarnings] = useState<number>(0);
  const [showNftApprovalModal, setShowNftApprovalModal] =
    useState<boolean>(false);
  const [showListNftApprovalModal, setShowListNftApprovalModal] =
    useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [networkResponse, setNetworkResponse] = useState<{
    status: string;
    message: string | React.ReactElement;
  }>({ status: null, message: '' });
  const [errorMessage, setErrorMessage] = useState<string | null>('null');

  const handleCloseModal = useCallback(() => {
    if (isLoading) return;
    setOpen(false);
    setListPrice(0);
    setRoyaltyFeePercentage(0);
    setNetworkResponse({ status: null, message: '' });
  }, [
    setOpen,
    setListPrice,
    setRoyaltyFeePercentage,
    setNetworkResponse,
    isLoading
  ]);

  useEffect(() => {
    if (listPrice >= NUMBERS.MAX_LIST_PRICE) {
      setErrorMessage(
        `The amount cannot exceed ${NUMBERS.MAX_LIST_PRICE.toLocaleString()}`
      );
      return;
    }

    setErrorMessage(null);
    const serviceFee = listPrice * NUMBERS.SERVICE_FEE_PERCENTAGE;
    const royaltyFee = listPrice * (royaltyFeePercentage / 100);

    const total = listPrice - serviceFee - royaltyFee;

    setTotalEarnings(parseFloat(total.toFixed(NUMBERS.PRECISION)));
  }, [listPrice, royaltyFeePercentage]);

  const handleNftPriceChange = useCallback(
    (event) => {
      const newPrice = event.target.value.replace(/[^0-9.]/gu, '');
      if (/^\d*\.?\d{0,14}$/gu.test(newPrice)) {
        setListPrice(newPrice);
      }
    },
    [setListPrice]
  );

  const handleRoyaltyChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const rawInput = parseFloat(event.target.value);
    const input = isNaN(rawInput) ? 0 : rawInput;
    const clampedValue = Math.max(0, Math.min(10, input));
    setRoyaltyFeePercentage(clampedValue);
  };

  const handleListNftClick = async () => {
    await estimateGasForListNFT(
      user.privateKey,
      tokenId,
      Config.MARKETPLACE_CONTRACT_ADDRESS,
      dispatch,
      setIsLoading,
      setShowNftApprovalModal
    );
  };

  const nftApprovalTransaction = useCallback(async () => {
    setIsLoading(true);
    dispatch(setModalClosable(false));
    setShowNftApprovalModal(false);
    dispatch(
      Actions.openTxApprovalModal({
        txApprovalModalObj: {
          open: false,
          gasFee: '',
          type: ''
        }
      })
    );
    await nftApproval(user.privateKey, tokenId, setIsLoading);
    dispatch(setModalClosable(true));
    setIsLoading(false);
    await handleListNftApproval(
      setIsLoading,
      setShowListNftApprovalModal,
      user.privateKey,
      tokenId,
      listPrice,
      royaltyFeePercentage,
      dispatch
    );
  }, [dispatch, user.privateKey, tokenId, listPrice, royaltyFeePercentage]);

  const modalProps = useMemo(
    () =>
      getTxApprovalModalProps({
        showNftApprovalModal,
        showListNftApprovalModal,
        nftApprovalTransaction,
        dispatch,
        token,
        nftContract,
        listPrice,
        royaltyFeePercentage,
        txApprovalModalObj,
        user,
        setIsLoading,
        setShowNftApprovalModal,
        setShowListNftApprovalModal,
        setNetworkResponse,
        setListPrice,
        setRoyaltyFeePercentage,
        filters,
        pagination
      }),
    [
      showNftApprovalModal,
      showListNftApprovalModal,
      nftApprovalTransaction,
      dispatch,
      token,
      nftContract,
      listPrice,
      royaltyFeePercentage,
      txApprovalModalObj,
      user,
      filters,
      pagination
    ]
  );
  return (
    <BaseModal
      open={open}
      onClose={handleCloseModal}
      maxWidth={false}
      fullWidth={false}
    >
      <HeaderBox>
        <HeaderText>{Constants.QUICK_LIST}</HeaderText>
        <IconButton disabled={!isModalClosable}>
          <Close
            onClick={handleCloseModal}
            sx={{ color: colorPalette.charcoal, cursor: 'pointer' }}
          />
        </IconButton>
      </HeaderBox>
      <ContentBox>
        <NftInfoView token={token} price={listPrice} />
        <Divider sx={{ margin: '12px 0px 18px 0px' }} />
        <ListNftForm
          token={token}
          listPrice={listPrice}
          handleNftPriceChange={handleNftPriceChange}
          royaltyFeePercentage={royaltyFeePercentage}
          handleRoyaltyChange={handleRoyaltyChange}
          totalEarnings={totalEarnings}
          handleListNft={handleListNftClick}
          isLoading={isLoading}
          networkResponse={networkResponse}
          errorMessage={errorMessage}
        />
      </ContentBox>

      {modalProps.show && (
        <TxApprovalModal
          destAddress={Config.MARKETPLACE_CONTRACT_ADDRESS}
          from={user.walletAddress}
          gasFee={txApprovalModalObj.gasFee}
          onConfirm={modalProps.onConfirm}
          onReject={modalProps.onReject}
          open={txApprovalModalObj.open}
          transactionType={modalProps.transactionType}
          type={txApprovalModalObj.type}
        />
      )}
    </BaseModal>
  );
};
