
Mynt Token Adoption Amplifier test Cases
Test Case 1: Enter without a Referrer
Test Case ID: TC001
Title: Enter Lobby Without Referrer
Description: Verify that a user entering the lobby without specifying a referrer address, receives their base share of MYNT tokens without any additional referral bonuses.
Preconditions: User has to pay ETH to enter the lobby; the lobby is open for entries.
Steps to Reproduce:
Call the xfLobbyEnter function with referrerAddr set to 0x0000000000000000000000000000000000000000.
Enter some amount of ETH to pay, in order to enter the lobby.
Wait for the round to complete.
Call xfLobbyExit function to leave the lobby.
Expected Results: Users receive only their base share of MYNT tokens, with no additional bonuses.
Utility:
Since there's no referrer, the member/you won't be eligible for the 10% referral bonus.
Additionally, the 20% referral bonus is for the referrer's address, which is absent in this case.
Test Case 2: Enter with Another's Referrer
Test Case ID: TC002
Title: Enter Lobby With Another's Referrer Addresss
Description: Verify that a user entering the lobby with another person's address as their referrer receives an extra 10% MYNT as a referral bonus, and the specified referrer receives 20% of the user's MYNT amount as a referrer bonus.
Preconditions: User has ETH to enter the lobby; lobby is open for entries; a valid referrer address is available.
Steps to Reproduce:
Call the xfLobbyEnter function with a valid referrerAddr that is different from the user's address.
Wait for the round to complete.
Call the xfLobbyExit function to leave the lobby.
Expected Results:
The member/You get an extra 10% MYNT for the referral bonus. The referrer gets 20% of your MYNT amount as a referrer bonus
Utility:
It ensures the member gets their base share and the additional 10% bonus for referral.
It confirms that the referrer receives the designated 20% bonus on the member's total share, incentivizing user referrals.
Test Case 3: Enter with Your Own Referrer
Test Case ID: TC003
Title: Enter Lobby With Own Referrer Address
Description: Verify that a member entering the lobby using their own address as the referrer receives a 30% extra share of MYNT tokens, comprising both the referral bonus and the cumulative base share bonus.
Preconditions: User has ETH to enter the lobby; lobby is open for entries.
Steps to Reproduce:
Call xfLobbyEnter function with referrerAddr set to the member's own address.
Wait for the round to complete.
Call xfLobbyExit function to leave the lobby.
Expected Results: The member receives 30% extra MYNT tokens over their base share, including a 10% referral bonus and a 20% cumulative base share bonus, by being both the entrant and the referrer.
Utility:
The member (self-referred) will receive 10% of xfAmount as a referral bonus.
The member (referrer) will also receive a cumulative referrer bonus of 20% of xfAmount.
Test Case 4: Multiple Entries with Different Referrers on Same Day
Test Case ID: TC004
Title: Multiple Lobby Entries With Different Referrers in a Single Day
Description: Verify that the member can enter the lobby multiple times with different referrers, getting base MYNT + 10% bonus if referrer specified, and each referrer gets 20% bonus for their referred entries.
Preconditions: Member has ETH to make multiple entries into the lobby; lobby is open for entries.
Steps to Reproduce:
Call xfLobbyEnter function with referrerAddr set to the first referrer's address.
Repeat step 1 for additional entries using different referrer addresses.
Wait for the round to complete.
Call xfLobbyExit function to leave the lobby for each entry made.
Expected Results: For each entry, you receive the MYNT amount for that entry plus a 10% referral bonus if a referrer is specified. Each referrer gets a 20% bonus of the MYNT amount for entries they referred
Utility:
Ensures the system processes multiple entries from the same member on the same day, awarding base share and 10% referral bonuses (if applicable) for each entry.
It confirms that the system tracks referrals accurately and awards the designated 20% bonus to the correct referrer for each entry.
Test Case 5: Multiple Entries on Different Days
Test Case ID: TC005
Title: Enter Lobby on Successive Days
Description: Verify that a member can enter the lobby on different days, ensuring they receive MYNT tokens for each entry. Referral and referrer bonuses should be applied according to the system's rules, similarly to entries with specific referrers on the same day.
Preconditions: User has ETH to enter the lobby; lobby is open for entries.
Steps to Reproduce:
Call xfLobbyEnter function with or without specifying a referrerAddr, ensuring entry is made on different days.
Wait for the round to complete.
Call xfLobbyExit function to leave the lobby.
Expected Results:  For each entry, you get MYNT tokens. Referral and referrer bonuses apply as per entries with specific referrers.
Utility:
Verifies that referral and referrer bonuses are applied consistently across entries on different days, following the same logic as described in previous test cases (awarding 10% to member and 20% to referrer if valid addresses are provided.
Test Case 6: Try to Leave Too Early
Test Case ID: TC006
Title: Try to leave the lobby on the same day you entered.
Description: Verify that a member cannot leave the lobby on the same day.
Preconditions: User has ETH to enter the lobby; lobby is open for entries.
Steps to Reproduce:
Call xfLobbyEnter function with or without specifying a referrerAddr, ensuring entry is made on the same or different days.
Don’t Wait for the round to complete.
Call xfLobbyExit function to leave the lobby.
Expected Results:  You receive an error message: “MYNT: Round is not complete”. Because the code checks that you can only leave after the current day has passed since your entry, ensuring the round is complete



Test Case 7: Try Leave All Entries
Test Case ID: TC007
Title: Try to leave the lobby all at once.
Description: Verify that a member can leave all the entries by giving 0 as a count. 
Preconditions: User has ETH to enter the lobby; lobby is open for entries.
Steps to Reproduce:
Call xfLobbyEnter function with or without specifying a referrerAddr, ensuring entry is made on the same days.
Wait for the round to complete.
Call xfLobbyExit function to leave the lobby.
Expected Results: Upon leaving, MYNT tokens are distributed for each entry, with a 10% referral bonus for entries with a referrer, and each referrer receives a 20% bonus on the MYNT amount their referrals earned


Test Case 8: Try Leave Entries one by one
Test Case ID: TC008
Title: Try to leave the lobby one by one.
Description: Verify that a member can leave the entries one by one. 
Preconditions: User has ETH to enter the lobby; lobby is open for entries.
Steps to Reproduce:
Call xfLobbyEnter function with or without specifying a referrerAddr, ensuring entry is made on the same days.
Wait for the round to complete.
Call xfLobbyExit function to leave the lobby.
Expected Results: If a user has a total 10 entries and he gives 2 as a count then the first two entries will exit, now 8 entries are left, now the user wants to exit next 2 entries he will give 2 as a count, the user cannot give 4 as a count otherwise error will show “MYNT: count invalid”. Similalry if the user has a total 2 entries and he gives 2 as a count then all the entries will exit.
