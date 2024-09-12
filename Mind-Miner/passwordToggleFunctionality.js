import React from 'react';
import { InputAdornment, IconButton } from '@mui/material';
import { Constants, VARIANT, INPUT_TYPES} from 'utilities/constants';
import { colorPalette } from 'theme';
import { FieldWrapper, StyledTextField, VisibilityIcon, VisibilityOffIcon } from './styledComponents';

interface TextFieldWithIconProps {
  borderColorOnHover: string;
  error: boolean;
  fillColor: string;
  fullWidth?: boolean;
  helperText: string;
  Icon: React.FC<React.SVGProps<SVGSVGElement>>;
  onChange?: any;
  placeholder?: string;
  type?: string;
  value?: string;
}

export const TextFieldWithIcon: React.FC<TextFieldWithIconProps> = ({
  borderColorOnHover,
  error,
  fillColor,
  fullWidth = true,
  helperText,
  Icon,
  onChange,
  placeholder,
  type,
  value
}) => {
  const [showPassword, setShowPassword] = React.useState(false);
  const handleTogglePasswordVisibility = () => setShowPassword((prevShowPassword) => !prevShowPassword);
  const inputType = type === INPUT_TYPES.PASSWORD ? (showPassword ? INPUT_TYPES.TEXT : INPUT_TYPES.PASSWORD) : type;

  return (
    <FieldWrapper>
      <StyledTextField
        borderColorOnHover={borderColorOnHover}
        fillColor={fillColor}
        fullWidth={fullWidth}
        value={value}
        onChange={onChange}
        InputProps={{
          startAdornment: (
            <InputAdornment position={Constants.INPUT_ADORNMENT_POSITION_START}>
              <Icon />
            </InputAdornment>
          ),
          endAdornment: type === INPUT_TYPES.PASSWORD && (
            <InputAdornment position={VARIANT.END}>
              <IconButton  sx={{ '& .MuiSvgIcon-root': { fontSize: '1.25rem' } }}
                onClick={handleTogglePasswordVisibility}
              >
                {showPassword ? <VisibilityIcon /> : <VisibilityOffIcon />}
              </IconButton>
            </InputAdornment>
          ),
          style: {
            backgroundColor: fillColor,
            fontSize: 12,
            fontWeight: 400,
            color: colorPalette.black,
            borderRadius: '1rem',
            width: '100%',
            height: '3.25rem',
            marginBottom: '0.2rem'
          }
        }}
        placeholder={placeholder}
        type={inputType}
        variant={VARIANT.OUTLINED}
        error={error}
        helperText={helperText}
      />
    </FieldWrapper>
  );
};
