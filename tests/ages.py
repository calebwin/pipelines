from multiprocessing import Process, Queue
from ages_utils import age_segment as age_segment
from ages_utils import is_under_age as is_under_age
from ages_utils import ages as ages
from ages_utils import print_age as print_age
class PLPipeSentinel: pass
def run_ages(stream, out_queue):
	for data in stream:
		out_queue.put(data)
	out_queue.put(PLPipeSentinel())
def run_age_segment(in_queue, out_queue):
	while 1:
		inp = in_queue.get()
		if isinstance(inp, PLPipeSentinel):
			outp = PLPipeSentinel()
		if not isinstance(inp, PLPipeSentinel):
			outp = age_segment(inp)
		if out_queue is not None:
			out_queue.put(outp)
		if isinstance(inp, PLPipeSentinel):
			break
def run_is_under_age(in_queue, out_queue):
	while 1:
		inp = in_queue.get()
		if isinstance(inp, PLPipeSentinel):
			outp = PLPipeSentinel()
		if not isinstance(inp, PLPipeSentinel):
			result = is_under_age(inp)
			if result:
				outp = inp
			else:
				continue
		if out_queue is not None:
			out_queue.put(outp)
		if isinstance(inp, PLPipeSentinel):
			break
def run_print_age(in_queue, out_queue):
	while 1:
		inp = in_queue.get()
		if isinstance(inp, PLPipeSentinel):
			outp = PLPipeSentinel()
		if not isinstance(inp, PLPipeSentinel):
			outp = print_age(inp)
		if out_queue is not None:
			out_queue.put(outp)
		if isinstance(inp, PLPipeSentinel):
			break
if __name__ == "__main__":
	data = ages()
	in_age_segment = Queue()
	in_is_under_age = Queue()
	in_print_age = Queue()
	ages_process = Process(target=run_ages, args=(data, in_age_segment))
	age_segment_process = Process(target=run_age_segment, args=(in_age_segment,in_is_under_age,))
	is_under_age_process = Process(target=run_is_under_age, args=(in_is_under_age,in_print_age,))
	print_age_process = Process(target=run_print_age, args=(in_print_age,None,))
	ages_process.start()
	age_segment_process.start()
	is_under_age_process.start()
	print_age_process.start()
	age_segment_process.join()
	is_under_age_process.join()
	print_age_process.join()
