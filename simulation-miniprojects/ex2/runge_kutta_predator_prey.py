import matplotlib.pyplot as plt
import argparse

def initialize(x0, y0, alpha, beta, delta, gamma, delta_t, tfinal):
    global x, y, a, b, d, g, dt, tf, result_x, result_y
    x        = x0
    y        = y0
    a        = alpha
    b        = beta
    d        = delta
    g        = gamma
    dt       = delta_t
    tf       = tfinal
    result_x = [x]
    result_y = [y]

def observe():
    global x, y, result_x, result_y
    result_x.append(x)
    result_y.append(y)

def update():
    global x, y, a, b, d, g, dt
    
    k1_x = dt * (a * x - b * x * y)
    k1_y = dt * (d * x * y - g * y)

    k2_x = dt * (a * (x + dt / 2) - b * (x + dt / 2) * (y + k1_y / 2))
    k2_y = dt * (d * (x + dt / 2) * (y + k1_y / 2) - g * (y + k1_y / 2))

    k3_x = dt * (a * (x + dt / 2) - b * (x + dt / 2) * (y + k2_y / 2))
    k3_y = dt * (d * (x + dt / 2) * (y + k2_y / 2) - g * (y + k2_y / 2))

    k4_x = dt * (a * (x + dt) - b * (x + dt) * (y + k3_y))
    k4_y = dt * (d * (x + dt) * (y + k3_y) - g * (y + k3_y))

    x    = x + (k1_x + 2 * k2_x + 2 * k3_x + k4_x) / 6
    y    = y + (k1_y + 2 * k2_y + 2 * k3_y + k4_y) / 6


# Initialize the parser and parse the arguments from CLI
parser = argparse.ArgumentParser()

parser.add_argument("--x0", type=int, default=10, help="Parameter x0")
parser.add_argument("--y0", type=int, default=10, help="Parameter y0")
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
            params["a"] = float(f.readline().split("=")[1])
            params["b"] = float(f.readline().split("=")[1])
            params["d"] = float(f.readline().split("=")[1])
            params["g"] = float(f.readline().split("=")[1])
            params["dt"] = float(f.readline().split("=")[1])
            params["tf"] = int(f.readline().split("=")[1])
    except FileNotFoundError:
        print("The file you specified does not exist.")
        exit(1)
    f.close()

# Initialize the system with the given parameters
initialize(x0=params["x0"], y0=params["y0"], alpha=params["a"], beta=params["b"], delta=params["d"], gamma=params["g"], delta_t=params["dt"], tfinal=params["tf"])

# Perform the simulation
for t in range(tf):
    update()
    observe()

# Plot the results
plt.title("Predator-prey simulation using the Runge-Kutta method")
plt.plot(result_x, label="Prey population (x)")
plt.plot(result_y, label="Predator population (y)")
plt.xlabel("Time")
plt.ylabel("Population")
plt.legend()
plt.show()