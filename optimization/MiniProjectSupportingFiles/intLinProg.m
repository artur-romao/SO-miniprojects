% Nodes2.txt : Each line is a node, represented by two coordinates x, y.
% Links2.txt : Each line is a link, represented by two nodes indices i, j that it connects.
% L2.txt     : Each line is a node, represented by its associated lengths to other nodes.

% Load data
nodes   = load('Nodes2.txt');
links   = load('Links2.txt');
lengths = load('L2.txt');

G   = graph(lengths);
D   = distances(G);
N = size(nodes, 1); % number of nodes
c_max = 1000;

% ILP problem
f = sum(lengths, 2); % we want to minimize total distance (returns the sum of each row)
A = []; b = []; % no linear inequalities
Aeq = ones(1, N); % we need to select exactly n nodes
beq = 10; % n = 10
lb = zeros(N, 1); ub = ones(N, 1); % binary decision variables
intcon = 1:N; % all variables are integer (binary)



% Call lpsolve
lp = mxlpsolve('make_lp', 0, N);
mxlpsolve('set_obj_fn', lp, f);
mxlpsolve('add_constraint', lp, Aeq, 'EQ', beq);
mxlpsolve('add_constraint', lp, A, 'LE', c_max);
mxlpsolve('set_lowbo', lp, lb);
mxlpsolve('set_upbo', lp, ub);

for i = 1:N
    mxlpsolve('set_int', lp, i, 1);
end

mxlpsolve('set_minim', lp);

mxlpsolve('solve', lp);
x = mxlpsolve('get_variables', lp);

% Selected nodes are those with x(i) == 1
selected_nodes = find(x == 1);
