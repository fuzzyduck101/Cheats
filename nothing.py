def is_armstrong_number(num):
    # Convert the number to a string to easily iterate over each digit
    num_str = str(num)
    num_length = len(num_str)
    
    # Calculate the sum of each digit raised to the power of the number of digits
    sum_of_powers = sum(int(digit) ** num_length for digit in num_str)
    
    # Check if the sum of the powers is equal to the original number
    return sum_of_powers == num

# Example usage
number = 153
if is_armstrong_number(number):
    print(f"{number} is an Armstrong number.")
else:
    print(f"{number} is not an Armstrong number.")
