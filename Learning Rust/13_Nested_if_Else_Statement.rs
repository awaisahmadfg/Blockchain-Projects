/*
The else…if ladder is useful to test multiple conditions. The syntax is as shown below −
*/
fn main(){
    let num = 20;
    if num > 20{
        println!("{} is greater than zero", num)
    }
    else if
        num % 2 != 0{
            println!("{} Mod is equal to 0",num)
        }

        else{
            println!("{} is niether greater than zero nor its MOD is Zero",num)
        }

    }