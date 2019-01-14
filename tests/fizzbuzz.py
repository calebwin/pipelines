def numbers():
	for number in range(1, 101):
		yield number

def even(number, counter):
	return number % 2 == 0, 0 if counter is None else counter + 1

def fizzbuzz(number, fizz, buzz):
	if number % 15 == 0: return fizz + buzz
	elif number % 3 == 0: return fizz
	elif number % 5 == 0: return buzz
	else: return number

def printer(number):
	print(number)