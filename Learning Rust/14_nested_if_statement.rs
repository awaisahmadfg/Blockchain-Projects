fn main (){
    let num = 10;
    if num > 0{
        println!("{} number is greater than zero",num);

        if num % 2 == 0{
            println!("{} number MOD is zero",num);
        }
    }
    println!("outside nested if number is: {}",num);
}