import sys
from multiprocessing import Process, Pipe
import threading
from collections import deque
import time
import numpy as np
import os
import tkinter as tk
from tkinter import ttk
from eeg_frame import EegFrame
from test_signal_generator import gen_sin_wave
from signal_thread import SignalThread

#sys.path.append('./')


class MainFrame(ttk.Frame):
	def __init__(self, parent):
		ttk.Frame.__init__(self, parent)
		self.flag = False
		self.data_q = deque()
		# self.data_history = list()

		containFrame = ttk.Frame(self)
		containFrame.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

		self.eeg_frame = EegFrame(containFrame, self.data_q)
		self.eeg_frame.grid(row=0, column=0, padx=5, pady=5)
		self.eeg_frame.grid_propagate(0)

		filtered_frame = FilteredFrame(containFrame)
		filtered_frame.grid(row=0, column=1, padx=5, pady=5)
		filtered_frame.grid_propagate(0)

		fft_frame = FftFrame(containFrame)
		fft_frame.grid(row=1, column=0, padx=5, pady=5)
		fft_frame.grid_propagate(0)

		spectrogram_frame = SpectrogramFrame(containFrame)
		spectrogram_frame.grid(row=1, column=1, padx=5, pady=5)
		spectrogram_frame.grid_propagate(0)

		sin_wave = tk.Button(self, text="Create Wave", command=self.gen_thread_callback)
		sin_wave.pack(side=tk.BOTTOM)

		print_q = tk.Button(self, text="Start Refresh", command=self.refresh_plots)
		print_q.pack(side=tk.BOTTOM)

	def gen_thread_callback(self):
		self.gen_id = SignalThread(self.data_q, self.flag)
		self.gen_thread = threading.Thread(target=self.gen_id.thread_sin_wave, name='Signal Thread', daemon=True)
		self.gen_thread.start()

	def refresh_thread(self):
		self.refresh = threading.Thread(target=self.refresh_plots, name='Refresh Thread', daemon=True)
		self.refresh.start()

	def refresh_plots(self):
		#self.eeg_frame.update_plot()
		while True:
			time.sleep(0.5)
			self.eeg_frame.update_plot()

	def print_queue(self):
		print(self.data_q)
		self.eeg_frame.update_plot()




class FilteredFrame(tk.Frame):
	def __init__(self, parent):
		tk.Frame.__init__(self, parent, bg='white', height=200, width=200)
		title = 'Filtered Data Plot'
		self.lbl = tk.Label(self, text=title)
		self.lbl.grid(row=0, sticky=tk.N, padx=9, pady=2)


class FftFrame(tk.Frame):
	def __init__(self, parent):
		tk.Frame.__init__(self, parent, bg='white', height=200, width=200)
		title = 'FFT Data Plot'
		self.lbl = tk.Label(self, text=title)
		self.lbl.grid(row=0, sticky=tk.W, padx=9, pady=2)


class SpectrogramFrame(tk.Frame):
	def __init__(self, parent):
		tk.Frame.__init__(self, parent, bg='white', height=200, width=200)
		title = 'Spectrogram Data Plot'
		self.lbl = tk.Label(self, text=title)
		self.lbl.grid(row=0, sticky=tk.W, padx=9, pady=2)


class App:
	def begin(self):
		self.root = tk.Tk()
		self.root.title("EEG Debug")
		MainFrame(self.root).pack(side="top", fill=tk.BOTH, expand=True, padx=5, pady=5)
		self.update()
		self.root.mainloop()

	def update(self):
		self.root.after(1000, self.update)


if __name__ == "__main__":
	print("Running EEG Debug Tool")
	print("PID: {}".format(os.getpid()))
	app = App()
	app.begin()
