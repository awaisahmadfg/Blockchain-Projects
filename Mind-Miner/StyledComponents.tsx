import { Box, Button, styled, Typography } from '@mui/material';

export const Title = styled(Typography)({
  fontSize: '1.75rem',
  fontWeight: '700',
  lineHeight: '1'
});

export const ButtonBox = styled(Box)(({ theme }) => ({
  display: 'flex',
  justifyContent: 'space-between',
  width: '100%',
  [theme.breakpoints.down('sm')]: {
    flexDirection: 'column',
  },
}));

export const StyledButton = styled(Button)(({ theme }) => ({
  fontWeight: 'bold',
  padding: '0.625rem',
  textTransform: 'none',
  width: '48%',
  [theme.breakpoints.down('sm')]: {
    width: '100%',
    marginBottom: '0.625rem',
  },
  ':last-child': {
    marginBottom: 0,
  }
}));

export const StyledText = styled(Box)({
  alignItems: 'center',
  justifyContent: 'center',
  marginBottom: '3.25rem'
});
