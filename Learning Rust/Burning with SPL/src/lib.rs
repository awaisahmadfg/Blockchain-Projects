use anchor_lang::prelude::*;
use anchor_spl::token::{self, Burn, MintTo, Transfer}; // CPI


declare_id!("Bk3gXQgCqQxefEHiqhsNTGTN9uFn5tyrK3NJD2DgKZxA"); // Program ID

// Business Logic
#[program]
pub mod mymoney {
    use super::*;

    // Instructions
    pub fn proxy_transfer(ctx: Context<ProxyTransfer>, amount: u64) -> ProgramResult {
        token::transfer(ctx.accounts.into(), amount)
    }
    
    pub fn proxy_mint_to(ctx: Context<ProxyMintTo>, amount: u64) -> ProgramResult {
        token::mint_to(ctx.accounts.into(), amount)
    }
    
    pub fn proxy_burn(ctx: Context<ProxyBurn>, amount: u64) -> ProgramResult {
        token::burn(ctx.accounts.into(), amount)
    }
    
// Defining Instructions with Structs
#[derive(Accounts)]
pub struct ProxyTransfer<'info> {
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
pub struct ProxyMintTo<'info> {
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
pub struct ProxyBurn<'info> {
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



// CPI
// Implementing some functionality for a type.
impl <'a, 'b, 'c, 'info> From<&mut ProxyTransfer<'info>> 
    for CpiContext<'a, 'b, 'c, 'info, Transfer<'info>>
{
    fn from(accounts: &mut ProxyTransfer<'info>) -> CpiContext<'a, 'b, 'c, 'info, Transfer<'info>> {
        let cpi_accounts = Transfer {from: accounts.from.clone(), to: accounts.to.clone(), authority: accounts.authority.clone(),};
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
    }
}


impl<'a, 'b, 'c, 'info> From<&mut ProxyMintTo<'info>>
    for CpiContext<'a, 'b, 'c, 'info, MintTo<'info>>
{
    fn from(accounts: &mut ProxyMintTo<'info>) -> CpiContext<'a, 'b, 'c, 'info, MintTo<'info>> {
        let cpi_accounts = MintTo {mint: accounts.mint.clone(), to: accounts.to.clone(), authority: accounts.authority.clone(),};
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
    }
}

impl<'a, 'b, 'c, 'info> From<&mut ProxyBurn<'info>> for CpiContext<'a, 'b, 'c, 'info, Burn<'info>> {
    fn from(accounts: &mut ProxyBurn<'info>) -> CpiContext<'a, 'b, 'c, 'info, Burn<'info>> {
        let cpi_accounts = Burn {mint: accounts.mint.clone(), to: accounts.to.clone(), authority: accounts.authority.clone(),};
        let cpi_program = accounts.token_program.clone();
        CpiContext::new(cpi_program, cpi_accounts)
    }
}



}