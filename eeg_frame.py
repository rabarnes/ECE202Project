import tkinter as tk
import matplotlib
import numpy as np
from matplotlib.figure import Figure
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg


class EegFrame(tk.Frame):
	def __init__(self, parent, data_q):
		tk.Frame.__init__(self, parent)
		self.data_q = data_q
		title = 'EEG Data Plot'
		self.lbl = tk.Label(self, text=title)
		self.lbl.pack(side=tk.TOP)
		#self.plot()
		self.initialize_plot()

	def initialize_plot(self):
		self.canvasFig = plt.figure(1)
		Fig = matplotlib.figure.Figure(figsize=(5, 4), dpi=100)
		FigSubPlot = Fig.add_subplot(111)
		x = []
		y = []
		self.line1, = FigSubPlot.plot(x, y, 'r-')
		self.canvas = matplotlib.backends.backend_tkagg.FigureCanvasTkAgg(Fig, master=self)
		self.canvas.draw()
		self.canvas.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=1)
		self.canvas._tkcanvas.pack(side=tk.TOP, fill=tk.BOTH, expand=1)
		#self.resizable(True, False)

	def refresh_figure(self, x, y):
		try:
			self.line1.set_data(x, y)
			ax = self.canvas.figure.axes[0]
			ax.set_xlim(x.min(), x.max())
			ax.set_ylim(y.min(), y.max())
			self.canvas.draw()
		except:
			print("Failed to Refresh EEG Figure")

	def update_plot(self):
		Y = np.array(self.data_q)
		x = []
		for num in range(0, len(Y)):
			x.append(num)
		X = np.array(x)
		print(f"X: {X}")
		print(f"Y: {Y}")
		self.refresh_figure(X, Y)

	def plot(self):
		y = [i ** 2 for i in range(101)]                                # Create random data Y axis
		x = [i for i in range(101)]                                     # Create random data X axis
		fig = plt.Figure(figsize=(3, 3), dpi=100)                       # the figure that will contain the plot
		plot1 = fig.add_subplot(111)                                    # adding the subplot
		plot1.plot(x, y)                                                # plotting the graph
		tk_plot1 = FigureCanvasTkAgg(fig, self)                         # creating the Tkinter canvas with Matplot fig
		tk_plot1.get_tk_widget().pack(side=tk.BOTTOM, fill=tk.BOTH)


if __name__ == '__main__':
	root = tk.Tk()
	root.title("EEG Frame")
	frame1 = EegFrame(root)
	frame1.pack()
	root.mainloop()
