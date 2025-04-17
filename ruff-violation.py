def foo(name, age):
    # This function does something
    print(f"Name: {name}, Age: {age}")
    return name, age



def main():
    # This is the main function
    name = "John Doe"
    age = 30
    result = foo(name, age)
    print(f"Result: {result}")
    
if __name__ == "__main__":
    main()