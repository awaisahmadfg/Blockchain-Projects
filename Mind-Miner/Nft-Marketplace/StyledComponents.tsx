import { Box, Divider, Tab, styled } from '@mui/material';
import { colorPalette } from 'theme';

export const HeaderBox = styled(Box)({
  borderRadius: '0.375rem',
  boxShadow: `0 0.0625rem 0.4375rem ${colorPalette.ebb}`,
  boxSizing: 'border-box',
  height: '100%',
  marginLeft: 'auto',
  marginRight: 'auto',
  marginTop: '1.375rem',
  width: '97%'
});

export const StyledTab = styled(Tab)({
  borderRadius: '0.25rem',
  fontSize: '1.125rem',
  fontWeight: 500,
  textTransform: 'none',
  width: '18.75rem',
  '&.Mui-selected': {
    backgroundColor: colorPalette.lightPurple,
    fontWeight: 600
  }
});

export const StyledDivider = styled(Divider)({
  borderColor: colorPalette.alto,
  marginBottom: '1rem'
});
