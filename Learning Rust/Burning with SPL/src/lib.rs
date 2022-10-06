use anchor_lang::prelude::*;
use anchor_spl::token::{self, MintTo, Transfer, Burn}; // CPI

declare_id!("59bT2ncyzQhbCFVUdWKem5sNuC7D5Cu1LtwZK1LAQ9QR"); // Program ID

#[program] // Business Logic
pub mod burning {
    use super::*;

    // Instruction
    pub fn transfering_to(ctx: Context<TransferingTo>, amount: u64) -> Result<()> {
        token::transfer(ctx.accounts.into(), amount)
    }
    
    pub fn minting_to(ctx: Context<MintingTo>, amount: u64) -> Result<()> {
        token::mint_to(ctx.accounts.into(), amount)
    }

    pub fn burning_to(ctx: Context<BurningTo>, amount: u64) -> Result<()> {
        token::burn(ctx.accounts.into(), amount)
    } 

}


// Defining the Instructions
#[derive(Accounts)]
pub struct TransferingTo<'info> {
    /// CHECK:
    #[account(signer)]
    pub authority: AccountInfo<'info>,
    #[account(mut)]
    /// CHECK:
    pub from:AccountInfo<'info>,
    #[account(mut)]
    /// CHECK:
    pub to: AccountInfo<'info>,
    /// CHECK:
    pub token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct MintingTo<'info> {
    /// CHECK:
    #[account(signer)]
    pub authority: AccountInfo<'info>,
    /// CHECK:
    #[account(mut)]
    pub mint: AccountInfo<'info>,
    /// CHECK:
    #[account(mut)]
    pub to: AccountInfo<'info>,
    /// CHECK:
    pub token_program: AccountInfo<'info>,
}

#[derive(Accounts)]
pub struct BurningTo<'info> {
    /// CHECK:
    #[account(signer)]
    pub authority: AccountInfo<'info>,
    /// CHECK:
    #[account(mut)]
    pub mint: AccountInfo<'info>,
    /// CHECK:
    #[account(mut)]
    pub to: AccountInfo<'info>,
    /// CHECK:
    pub token_program: AccountInfo<'info>,
}


// Implementing some functionality for a type.
impl<'a, 'b, 'c, 'info> From<&mut TransferingTo<'info>> for CpiContext<'a, 'b, 'c, 'info, Transfer<'info>>
{
    fn from(accounts: &mut TransferingTo<'info>) -> CpiContext<'a, 'b, 'c, 'info, Transfer<'info>> {
        let cpi_accounts = Transfer {from: accounts.from.clone(), to: accounts.to.clone(),authority: accounts.authority.clone(),};
        let cpi_program = accounts.token_program.clone();
        // Calling 
        CpiContext::new(cpi_program, cpi_accounts)
    }
}

impl<'a, 'b, 'c, 'info> From<&mut MintingTo<'info>> for CpiContext<'a, 'b, 'c, 'info, MintTo<'info>>
{
    fn from(accounts: &mut MintingTo<'info>) -> CpiContext<'a, 'b, 'c, 'info, MintTo<'info>> {
        let cpi_accounts = MintTo {mint: accounts.mint.clone(), to: accounts.to.clone(),authority: accounts.authority.clone(),};
        let cpi_program = accounts.token_program.clone();
        // Calling  
        CpiContext::new(cpi_program, cpi_accounts)
    }
}

impl<'a, 'b, 'c, 'info> From<&mut BurningTo<'info>> for CpiContext<'a, 'b, 'c, 'info, Burn<'info>> {
    fn from(accounts: &mut BurningTo<'info>) -> CpiContext<'a, 'b, 'c, 'info, Burn<'info>> {
        let cpi_accounts = Burn {mint: accounts.mint.clone(), from: accounts.to.clone(), authority: accounts.authority.clone(),};
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
    }
}
