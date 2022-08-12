fn main(){
    
    let mut count = 0;

    for num in 0..21{
        if num % 2 == 0 {
            continue;
        }
        count += 1;

    }
    println!("The count for Odd Values between 0 to 20 is {}", count);

    // outputs 10


}