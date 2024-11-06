      {!isConcept && (
        <>
          {(() => {
            const awaitingText = Constants.AWAITING_PATENT_TEXT;
            const patentPendingText = Constants.PATENT_PENDING_TEXT;

            const formattedDate = new Date(
              concept?.createdAt
            ).toLocaleDateString(Constants.DATE_TEXT, {
              year: Constants.NUMERIC_TEXT,
              month: Constants.LONG_TEXT,
              day: Constants.NUMERIC_TEXT
            });
            return (
              <>
                <StyledTextBox>
                  <StyledBoxTypography>
                    {Constants.INITIALLY_CREATED_TEXT}{' '}
                    {concept?.ownerInfo?.username} on {formattedDate},{' '}
                    {concept?.nftTransactionUrl ? (
                      <StyledPatentText>{awaitingText}</StyledPatentText>
                    ) : (
                      <StyledPatentText>{patentPendingText}</StyledPatentText>
                    )}
                  </StyledBoxTypography>
                </StyledTextBox>
              </>
            );
          })()}
        </>
      )}
