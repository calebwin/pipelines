from multiprocessing import Process, Queue
from fizzbuzz_utils import fizzbuzz as fizzbuzz
from fizzbuzz_utils import printer as printer
from fizzbuzz_utils import even as even
from fizzbuzz_utils import numbers as numbers
class PLPipeSentinel: pass
def pl_run_numbers(pl_stream, pl_out_queue):
	for pl_data in pl_stream:
		pl_out_queue.put(pl_data)
	pl_out_queue.put(PLPipeSentinel())
def pl_run_even(pl_in_queue, pl_out_queue):
	is_even = None
	count = None
	while 1:
		pl_inp = pl_in_queue.get()
		if isinstance(pl_inp, PLPipeSentinel):
			pl_outp = PLPipeSentinel()
		if not isinstance(pl_inp, PLPipeSentinel):
			pl_result = even(number=pl_inp, counter=count)
			is_even, count = pl_result
			if is_even:
				pl_outp = pl_inp
			else:
				continue
		if pl_out_queue is not None:
			pl_out_queue.put(pl_outp)
		if isinstance(pl_inp, PLPipeSentinel):
			break
def pl_run_fizzbuzz(pl_in_queue, pl_out_queue):
	number = None
	while 1:
		pl_inp = pl_in_queue.get()
		if isinstance(pl_inp, PLPipeSentinel):
			pl_outp = PLPipeSentinel()
		if not isinstance(pl_inp, PLPipeSentinel):
			pl_outp = fizzbuzz(number=pl_inp, fizz="fizz", buzz="buzz")
			number = pl_outp
		if pl_out_queue is not None:
			pl_out_queue.put(pl_outp)
		if isinstance(pl_inp, PLPipeSentinel):
			break
def pl_run_printer(pl_in_queue, pl_out_queue):
	while 1:
		pl_inp = pl_in_queue.get()
		number = pl_inp
		if isinstance(pl_inp, PLPipeSentinel):
			pl_outp = PLPipeSentinel()
		if not isinstance(pl_inp, PLPipeSentinel):
			pl_outp = printer(number=number)
		if pl_out_queue is not None:
			pl_out_queue.put(pl_outp)
		if isinstance(pl_inp, PLPipeSentinel):
			break
if __name__ == "__main__":
	pl_data = numbers()
	pl_in_even = Queue()
	pl_in_fizzbuzz = Queue()
	pl_in_printer = Queue()
	pl_numbers_process = Process(target=pl_run_numbers, args=(pl_data, pl_in_even))
	pl_even_process = Process(target=pl_run_even, args=(pl_in_even,pl_in_fizzbuzz,))
	pl_fizzbuzz_process = Process(target=pl_run_fizzbuzz, args=(pl_in_fizzbuzz,pl_in_printer,))
	pl_printer_process = Process(target=pl_run_printer, args=(pl_in_printer,None,))
	pl_numbers_process.start()
	pl_even_process.start()
	pl_fizzbuzz_process.start()
	pl_printer_process.start()
	pl_even_process.join()
	pl_fizzbuzz_process.join()
	pl_printer_process.join()
