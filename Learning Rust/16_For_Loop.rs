fn main(){
    for x in 1..11 { // 11 is not inclusive
        if x == 5{ // 5 will also be not inclusive
            continue;
        }
        println!("x is {}",x );
    }
}