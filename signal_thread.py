import time
import numpy as np
import threading as thrd


class SignalThread:
	def __init__(self, data_q, flag):
		self.data_q = data_q
		self.flag = flag

	def thread_sin_wave(self):
		start_time = time.perf_counter()
		#fs = 4800
		#fr = 20
		amplitude = 6 #twice +1 the value dictates the highest frequency component of the signal
		off_set = amplitude + 1
		count = 0
		thread_info = f"Current Thread: {thrd.currentThread().getName()} - Active Thread Count:{thrd.active_count()}"
		print(thread_info)
		while count < 500:
			time.sleep(0.1)
			tm = time.perf_counter() - start_time
			w = amplitude * np.sin(np.pi/8 * tm) + off_set
			x = np.sin(tm * w)
			count += 1
			self.data_q.append(x)
			if len(self.data_q) > 50:
				self.data_q.popleft()
