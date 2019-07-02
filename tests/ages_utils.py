def ages():
	# read lines of data
	lines = []
	with open('ages_data.csv') as f:
		lines = f.read().splitlines()

	# get numbers from strings
	ages = [int(age) for age in lines]

	for age in ages:
		yield age

def age_segment(age):
    if age < 12: return 0
    elif age < 18: return 1
    elif age < 28: return 2
    elif age < 48: return 3
    elif age < 68: return 4
    elif age < 88: return 5
    else: return 6

def is_under_age(age_segment):
	if age_segment <= 1:
	    return True
	return False

def print_age(age_segment):
    if age_segment == 0: print("0-12")
    elif age_segment == 1: print("12-18")
    elif age_segment == 2: print("18-18")
    elif age_segment == 3: print("28-48")
    elif age_segment == 4: print("48-68")
    elif age_segment == 5: print("68-88")
    elif age_segment == 6: print("88+")