import time
import numpy as np
import threading as thrd


class SignalThread:
	def __init__(self, data_q, flag):
		self.data_q = data_q
		self.flag = flag

	def thread_sin_wave(self):
		start_time = time.perf_counter()
		fs = 4800
		fr = 20
		count = 0
		thread_info = f"Current Thread: {thrd.currentThread().getName()} - Active Thread Count:{thrd.active_count()}"
		print(thread_info)
		while count < 500:
			time.sleep(0.1)
			tm = time.perf_counter() - start_time
			x = np.sin(2 * np.pi * fr * fs * tm)
			count += 1
			self.data_q.append(x)
			if len(self.data_q) > 10:
				self.data_q.popleft()
