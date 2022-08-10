/*
1. String Object(String): The String object type can be used to represent string values that are provided at runtime.
1.1 String is a growable collection. It is mutable and UTF-8 encoded type
1.2 String object is allocated in the heap.
 */

fn main(){
    let empty_string = String::new();
    println!("length is {}",empty_string.len());
 
    let content_string = String::from("TutorialsPoint");
    println!("length is {}",content_string.len());
 }