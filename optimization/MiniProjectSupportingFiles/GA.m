
% START MAIN
% initialize some variables
c_max = 1000;
n_servers = 10;
q = 0.1;
P_size = 15;

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

% run 10 times the Genetic Algorithm method
for time = 1:10
    tic;

    % implementation of Genetic Algorithm
    current_population = get_population(G, P_size, n_servers, num_nodes, c_max); % get the initial population (= P_size possible random solutions)
    
    execution_time = execution_time + toc;
    elapsedTime = 0;    % the stopping criteria is by runtime limit
    tic;
    
    while elapsedTime < 30
        new_population = [];  % initialize the next population
    
        for i = 1:P_size
            individual = crossover(G, current_population, c_max);   % get an individual (possible solution) that ascends the current population
        
            if rand < q
                individual = mutation(G, individual, q, num_nodes, c_max);  % the possible solution will suffer a mutation in his genes (nodes)
            end
        
            new_population = [ new_population; individual ]; % update the next population
        end
        
        current_population = new_population; % next population will be the current population
    
        elapsedTime = elapsedTime + toc;
        tic;
    end
    execution_time = execution_time + elapsedTime;
    tic;

    [best_solution, best_solution_SP] = get_best_solution(G, current_population);   % get the best solution between all solutions that are in the final population
    all_best_solutions(time) = best_solution_SP;    % save the avg shortest path of the best solution found

    execution_time = execution_time + toc;

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


fprintf("GA results among all 10 runs (execution time = %f):\n", execution_time);
fprintf("minimum = %f\n", min(all_best_solutions));
fprintf("average = %f\n", mean(all_best_solutions));
fprintf("maximum = %f\n", max(all_best_solutions));

% plot the network with best server nodes
figure(1)
plotTopology(nodes,links, min_best_solution);

figure(2)
plotTopology(nodes,links, max_best_solution);
% END MAIN


% population P is initialized with n random individuals
% all elements of P are valid solutions
function [P] = get_population(G, P_size, n, num_nodes, c_max)
    P = zeros(P_size, n);

    for i = 1:P_size
        duplicate = true;
        
        while duplicate
            possible_solution = randperm(num_nodes, n); % generate a random solution/individual

            [avgSP, max_sp] = calc_avgSP( G, possible_solution );
       
            if max_sp < c_max   % guaranteeing that the shortest path length between any pair of SDN controllers is not higher than c_max
                if ~ismember(possible_solution, P, 'rows')  % check if the possible solution isn't already in the population
                    P(i, :) = possible_solution;
                    duplicate = false;
                end
            end
            
        end
    end
end


% an individual is generated by the crossover operator, 
% that is composed by two steps: 1) parent selection and 2) gene combination
% the individual returned is always valid
function [individual] = crossover(G, P, c_max)
    valid_individual = false;

    while ~valid_individual
        % 1) parent selection
        fitness = get_fitness(G, P);    % get the fitness of all solutions
        parents = get_parents(fitness, P);  % get the parents that are actually crossover their genes(nodes)
    
        % 2) gene combination
        n = numel(parents(1,:));
        individual = zeros(1, n);   % initialing the son (or daughter :) ) of the parents
        
        for i = 1:n
            % select the allele from either parent with equal probability
            if rand() < 0.5
                individual(i) = parents(1, i);  % crossover genes 
            else
                individual(i) = parents(2, i);  % crossover genes 
            end
        end

        [avgSP, max_sp] = calc_avgSP( G, individual );
        if max_sp < c_max       % verifying if the individual created is valid
            valid_individual = true;
        end

        % ensure that all genes are different between them
        unique_genes = unique(individual);
        if numel(individual) == numel(unique_genes)
            valid_individual = true;
        end
    end
end

% this function returns a normalized fitness of a population
function [normalized_fitness] = get_fitness(G, population)
    fitness = [];

    for i = 1:size(population, 1)
        individual = population(i, :);
        fitness = [ fitness; calc_avgSP(G, individual) ];
    end

    normalized_fitness = fitness / sum(fitness);
end

% function that choose the parents to do the crossover
function [parents] = get_parents(fitness, P)
    % implementation of Fitness based selection: select each parent with a probability proportional to its fitness
    parents = zeros(2, size(P, 2));
    
    for i = 1:2
        rand_prob = rand();

        % accumulate fitness probabilities
        cum_fitness = cumsum(fitness);
        
        % select the parent based on the random probability
        selected_parent = find(cum_fitness >= rand_prob, 1, 'first');

        parents(i, :) = P(selected_parent, :);

        % remove the selected parent from the fitness and population arrays
        % to prevent the same parent from being chosen
        fitness(selected_parent) = [];
        P(selected_parent, :) = [];

        fitness = fitness / sum(fitness);
    end
end


% with probability q, individual suffers a Mutation
function [mutant] = mutation(G, individual, q, num_nodes, c_max)
    valid_individual = false;

    while ~valid_individual
        mutant = individual;
    
        n = numel(individual(1,:));
        
        for i = 1:n
            % check if mutation should occur for this gene
            if rand() < (q * 3)   % increase the probability of a mutation on a gene (authors' option)
                % generate a random value
                mutated_gene = randi(num_nodes);
                
                % ensure the mutated gene is different from other genes
                while any(mutated_gene == individual)
                    mutated_gene = randi(num_nodes);
                end
                
                % modify the node with the mutated gene
                mutant(i) = mutated_gene;
            end
        end

        [avgSP, max_sp] = calc_avgSP( G, mutant );
        if max_sp < c_max       % verifying if the mutant is valid
            valid_individual = true;
        end
    end
end

% get the best solution between a population
function [best_solution, min_avgSP] = get_best_solution(G, population)
    n = size(population, 1);
    min_avgSP = 9999999;
    best_solution = [];

    for i = 1:n
        [avgSP, max_sp] = calc_avgSP( G, population(i, :) );

        if avgSP < min_avgSP
            min_avgSP = avgSP;
            best_solution = population(i, :);
        end
    end

end


% calculate the average shorthest path of a possible solution
function [value, max_sp] = calc_avgSP(G, solution) 
    [value, max_sp] = AverageSP_v2(G, solution);
end
