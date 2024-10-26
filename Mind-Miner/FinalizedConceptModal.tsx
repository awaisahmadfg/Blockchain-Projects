FinalizeConceptModal
index.tsx:
import React, { useCallback } from 'react';
import { BaseModal } from 'modals/Common/BaseModal';
import { ContentSection } from '../Common/ContentSection';
import { HeaderSection } from '../Common/HeaderSection';
import { Breakpoints, Constants, VARIANT } from 'utilities/constants';
import {
  ButtonBox,
  StyledButton,
  StyledText,
  Title
} from './StyledComponent';


interface FinalizeConceptModalProps {
  approveImprovements?: () => void;
  approveMintToken?: () => void;
  open?: boolean;
}

export const FinalizeConceptModal: React.FC<FinalizeConceptModalProps> = ({
  open,
  approveImprovements,
  approveMintToken,
}) => {
  const handleMint = useCallback(() => {
    approveMintToken?.();
  }, [approveMintToken]);

  const handleImprove = useCallback(() => {
    approveImprovements?.();
  }, [approveImprovements]);

  return (
    <BaseModal
      open={open}
      onClose={handleMint}
      maxWidth={Breakpoints.EXTRA_SMALL}
    >
      <HeaderSection>
        <Title>{Constants.FINALIZE_CONCEPT_TEXT}</Title>
      </HeaderSection>
      <ContentSection>
          <StyledText>
            {Constants.IMPROVE_YOUR_CONCEPT_TEXT}
          </StyledText>
        <ButtonBox>
          <StyledButton variant={VARIANT.CONTAINED} onClick={() => handleImprove()}>
            {Constants.IMPROVE_BUTTON_TEXT}
          </StyledButton>
          <StyledButton variant={VARIANT.OUTLINED} onClick={() => handleMint()}>
            {Constants.MINT_PATENT_BUTTON_TEXT}
          </StyledButton>
        </ButtonBox>
      </ContentSection>
    </BaseModal>
  );
};
