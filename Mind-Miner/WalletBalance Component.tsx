import React, { useEffect, useState } from 'react';
import { CircularProgress, Typography } from '@mui/material';
import { getBalanceByType } from 'helpers/blockchain';
import { ERRORS } from 'utilities/constants';

interface BalanceProps {
  type: 'matic' | 'ideaCoin';
  address: string;
}

const Balance: React.FC<BalanceProps> = ({ type, address }) => {
  const [balance, setBalance] = useState<number | string>('0');
  const [loading, setLoading] = useState<boolean>(false);

  useEffect(() => {
    setLoading(true);
    getBalanceByType(type, address)
      .then((balance) => {
        if (balance !== undefined) {
          setBalance(balance);
        }
      })
      .catch((error) => {
        console.error(`${ERRORS.FETCH_BALANCE} ${type}:`, error.message);
      })
      .finally(() => {
        setLoading(false);
      });
  }, [type, address]);

  return loading ? (
    <CircularProgress size="1.375rem" />
  ) : (
    <Typography>{balance}</Typography>
  );
};

export default Balance;

