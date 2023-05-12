import matplotlib.pyplot as plt
import argparse

def initialize(x0, y0, alpha, beta, delta, gamma, delta_t, tfinal):
    global x, y, a, b, d, g, dt, tf, xresult, yresult
    x        = x0
    y        = y0
    a        = alpha
    b        = beta
    d        = delta
    g        = gamma
    dt       = delta_t
    tf       = tfinal
    xresult  = [x]
    yresult  = [y]

def observe():
    global x, y, xresult, yresult
    xresult.append(x)
    yresult.append(y)

def update():
    global x, y, a, b, d, g, dt
    x_new = x + (a * x - b * x * y) * dt
    y_new = y + (d * x * y - g * y) * dt
    x, y  = x_new, y_new


# Initialize the parser and parse the arguments from CLI
parser = argparse.ArgumentParser()

parser.add_argument("--x0", type=int, default=10, help="Initial population of prey")
parser.add_argument("--y0", type=int, default=10, help="Initial population of predators")
parser.add_argument("--a", type=float, default=0.1, help="Parameter alpha")
parser.add_argument("--b", type=float, default=0.02, help="Parameter beta")
parser.add_argument("--d", type=float, default=0.02, help="Parameter delta")
parser.add_argument("--g", type=float, default=0.4, help="Parameter gamma")
parser.add_argument("--dt", type=float, default=0.1, help="Parameter delta_t")
parser.add_argument("--tf", type=int, default=5000, help="Parameter tfinal")
parser.add_argument("--f", type=str, default=None, help="Path to the input file")

args = parser.parse_args()

params = vars(args) # Turn the parsed arguments into a dictionary

if params["f"]: # If the user specified a file, read the parameters from the file
    try:
        with open(params["f"], "r") as f:
            params["x0"] = int(f.readline().split("=")[1])
            params["y0"] = int(f.readline().split("=")[1])
            params["a"]  = float(f.readline().split("=")[1])
            params["b"]  = float(f.readline().split("=")[1])
            params["d"]  = float(f.readline().split("=")[1])
            params["g"]  = float(f.readline().split("=")[1])
            params["dt"] = float(f.readline().split("=")[1])
            params["tf"] = int(f.readline().split("=")[1])
    except FileNotFoundError:
        print("The file you specified does not exist.")
        exit(1)
    f.close()

# Initialize the system with the given parameters
initialize(params["x0"], params["y0"], params["a"], params["b"], params["d"], params["g"], params["dt"], params["tf"])

# Perform the simulation
for t in range(tf):
    update()
    observe()

# Plot the evolution of the populations over time
plt.title("Predator-prey simulation using the Forward Euler method")
plt.plot(xresult, label="Prey population (x)")
plt.plot(yresult, label="Predator population (y)")
plt.xlabel("Time")
plt.ylabel("Population")
plt.legend()
plt.show()

# Plot the evolution of the populations in the phase space
plt.title("Predator-prey simulation using the Forward Euler method")
plt.plot(xresult, yresult)
plt.xlabel('Number of Preys (x)')
plt.ylabel('Number of Predators (y)')
plt.show()