def numbers():
	for number in range(1, 100):
		yield number

def even(number):
	return number % 2 == 0

def fizzbuzz(number):
	if number % 15 == 0: return "fizz" + "buzz"
	elif number % 3 == 0: return "fizz"
	elif number % 5 == 0: return "buzz"
	else: return number

def printer(number):
	print(number)