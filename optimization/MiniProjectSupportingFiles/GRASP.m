
% initialize some variables
c_max = 1000;
n_servers = 10;
r = 3;

% load data
nodes   = load('Nodes2.txt');
links   = load('Links2.txt');
lengths = load('L2.txt');

num_nodes = size(nodes,1);
num_links = size(links,1);

% create the graph
G = graph(lengths);

% Run 10 times your metaheuristic method(s) with the best settings with a runtime limit of 30 seconds 
% on each run, and register the minimum, average and maximum objective values obtained among all 10 runs.

all_best_solutions = [];

for time = 1:10

    % GRASP implementation
    initial_solution = greedy_randomized(G, num_nodes, n_servers, c_max, r);
    
    [best_solution, best_solution_SP] = adaptive_search(G, initial_solution, num_nodes);
    
    elapsedTime = 0;    % the stopping criteria is by runtime limit
    tic;                % Start measuring the elapsed time
    
    while elapsedTime < 30
        solution = greedy_randomized(G, num_nodes, n_servers, c_max, r);
    
        [new_solution, new_solution_SP] = adaptive_search(G, solution, num_nodes);
        
        if new_solution_SP < best_solution_SP
            best_solution = new_solution;
            best_solution_SP = new_solution_SP;
        end
    
        elapsedTime = elapsedTime + toc;
        tic;
    
    end

    all_best_solutions(time) = best_solution_SP;
    
    % disp("to minimize the average shortest path length from each switch to its closest controller, the best controllers are:");
    % disp(best_solution);
    % fprintf("with average shortest path = %f\n", best_solution_sp);
    
    % plot the network with best server nodes:
    % figure(time)
    % plotTopology(nodes,links,best_solution);

end

disp("GRASP results among all 10 runs:");
fprintf("minimum = %f\n", min(all_best_solutions));
fprintf("average = %f\n", mean(all_best_solutions));
fprintf("maximum = %f\n", max(all_best_solutions));


% implementation of a greedy randomized method and return an initial random
% possible solution
function [s] = greedy_randomized(G, num_nodes, n, c_max, r)
    all_nodes = 1:num_nodes;
    s = [];

    for i = 1:n
        R = [];
        for node = all_nodes
            [asp_len, max_asp] = AverageSP_v2(G,[s node]);
            if max_asp > c_max
                continue
            end
            R = [R ; node asp_len];
        end
        R = sortrows(R,2);
        e = R(randi(r),1);
        s = [s e];
        all_nodes = setdiff(all_nodes,e);
    end

end

% implementation of Steepest Ascent Hill Climbing
function [s_best, s_best_SP] = adaptive_search(G, s, num_nodes)
    s_best = s;
    s_best_SP = calc_avgSP(G, s);

    improved = true;
    while improved
        neighbors = get_neighbors(s_best, num_nodes);
        [best_neighbor, best_neighbor_value] = get_best_neighbor(G, neighbors);

        if best_neighbor_value < s_best_SP
            s_best = best_neighbor;
            s_best_SP = best_neighbor_value;

        else
            improved = false;
        end

    end

end

% get all possible neighbors solutions of s
function [neighbors] = get_neighbors(s, num_nodes) 
    neighbors = [];
    
    for i = 1:length(s) 
        new_solution = s;
        for k = 1:num_nodes
            if ~any(s == k) % check if the node is already in s, not repeat nodes!!!
                new_solution(i) = k;
                neighbors = [neighbors; new_solution];
            end
        end
    end
end

% the best neighbor of neighbors is selected, i.e., the neighbor with the
% less average shorthest path
function [best_neighbor, best_neighbor_SP] = get_best_neighbor(G, neighbors)
    best_neighbor = neighbors(1, :);
    best_neighbor_SP = calc_avgSP(G, best_neighbor);

    for i = 2:size(neighbors, 1)
        neighbor = neighbors(i, :);
        neighbor_SP = calc_avgSP(G, neighbor);

        if neighbor_SP < best_neighbor_SP
            best_neighbor = neighbor;
            best_neighbor_SP = neighbor_SP;
        end
    end
end

% calculate the average shorthest path of a possible solution
function [value] = calc_avgSP(G, solution) 
    value = AverageSP_v2(G,solution);
end

