
% START MAIN
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

% initialize the results variables 
execution_time = 0;
all_best_solutions = [];

min_best_solution = [];
min_best_solution_SP = 9999999;

max_best_solution = [];
max_best_solution_SP = 0;

% run 10 times the GRASP method
for time = 1:10
    tic;
    % GRASP implementation
    initial_solution = greedy_randomized(G, num_nodes, n_servers, c_max, r);
    
    [best_solution, best_solution_SP] = adaptive_search(G, initial_solution, num_nodes, c_max);
    
    execution_time = execution_time + toc;
    elapsedTime = 0;    % the stopping criteria is by runtime limit
    tic;
    
    while elapsedTime < 30
        solution = greedy_randomized(G, num_nodes, n_servers, c_max, r);
    
        [new_solution, new_solution_SP] = adaptive_search(G, solution, num_nodes, c_max);
        
        % updating the best solution
        if new_solution_SP < best_solution_SP
            best_solution = new_solution;
            best_solution_SP = new_solution_SP;
        end
    
        elapsedTime = elapsedTime + toc;
        tic;
    
    end

    % save the best solution avg shortest path found
    all_best_solutions(time) = best_solution_SP;
    execution_time = execution_time + elapsedTime;

    best_solution

    % save the best solution with the minimum avg shortest path
    if best_solution_SP < min_best_solution_SP
        min_best_solution = best_solution;
        min_best_solution_SP = best_solution_SP;
    end

    % save the best solution with the maximum avg shortest path
    if best_solution_SP > max_best_solution_SP
        max_best_solution = best_solution;
        max_best_solution_SP = best_solution_SP;
    end
end

fprintf("GRASP results among all 10 runs (execution time = %f):\n", execution_time);
fprintf("minimum = %f\n", min(all_best_solutions));
fprintf("average = %f\n", mean(all_best_solutions));
fprintf("maximum = %f\n", max(all_best_solutions));

% plot the network with best server nodes
figure(1)
plotTopology(nodes,links, min_best_solution);

figure(2)
plotTopology(nodes,links, max_best_solution);
% END MAIN


% implementation of a greedy randomized method and return an initial random
% possible solution
function [s] = greedy_randomized(G, num_nodes, n, c_max, r)
    all_nodes = 1:num_nodes;
    s = [];

    for i = 1:n
        R = [];
        for node = all_nodes
            [asp_len, max_asp] = AverageSP_v2(G,[s node]);
            if max_asp < c_max       % guaranteeing that the shortest path length between any pair of SDN controllers is not higher than c_max
                R = [R ; node asp_len]; % 
            end
        end
        R = sortrows(R,2);
        e = R(randi(r),1);
        s = [s e];
        all_nodes = setdiff(all_nodes,e);
    end

end

% implementation of Steepest Ascent Hill Climbing
function [s_best, s_best_SP] = adaptive_search(G, s, num_nodes, c_max)
    s_best = s;
    s_best_SP = calc_avgSP(G, s);

    improved = true;
    while improved
        neighbors = get_neighbors(s_best, num_nodes);   % get neighbors solutions of s
        [best_neighbor, best_neighbor_value] = get_best_neighbor(G, neighbors, c_max);  % get the best neighbor solution

        % updating the best solution found
        if best_neighbor_value < s_best_SP
            s_best = best_neighbor;
            s_best_SP = best_neighbor_value;

        else
            improved = false;
        end

    end

end

% get all possible neighbors solutions of a solution s
function [neighbors] = get_neighbors(s, num_nodes) 
    neighbors = [];
    
    for i = 1:length(s) 
        new_solution = s;
        for k = 1:num_nodes
            if ~any(s == k)  % check if the node is already in s, not repeat nodes!!!
                new_solution(i) = k;
                neighbors = [neighbors; new_solution];
            end
        end
    end
end

% the best neighbor of neighbors is selected, i.e., the neighbor with the
% minimum average shorthest path between the neighbors
function [best_neighbor, best_neighbor_SP] = get_best_neighbor(G, neighbors, c_max)
    best_neighbor = neighbors(1, :);
    best_neighbor_SP = calc_avgSP(G, best_neighbor);

    for i = 2:size(neighbors, 1)
        neighbor = neighbors(i, :);
        [neighbor_SP, neighbor_max_SP] = calc_avgSP(G, neighbor);

        if neighbor_max_SP < c_max   % guaranteeing that the shortest path length between any pair of SDN controllers is not higher than c_max
            if neighbor_SP < best_neighbor_SP
                best_neighbor = neighbor;
                best_neighbor_SP = neighbor_SP;
            end
        end
    end
end

% calculate the average shorthest path of a possible solution
function [value, max_sp] = calc_avgSP(G, solution) 
    [value, max_sp] = AverageSP_v2(G,solution);
end
