def generator():
	for number in range(1, 100):
		yield number

def fizzbuzz(number):
	if number % 15 == 0:
		return "FizzBuzz"
	elif number % 3 == 0:
		return "Fizz"
	elif number % 5 == 0:
		return "Buzz"
	else:
		return number

def printer(number):
	print(number)