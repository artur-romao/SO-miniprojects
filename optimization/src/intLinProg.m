% Load data
nodes   = load('Nodes2.txt');
links   = load('Links2.txt');
lengths = load('L2.txt');

G     = graph(lengths); % create the graph
D     = distances(G);   % create the distances matrix
N     = numnodes(G);    % get the total number of nodes
n     = 10;             % number of nodes that the solution will have
c_max = 1000;           % max distance between two server nodes
fid   = fopen('ILP.lpt', 'wt');

fprintf(fid, 'min\n');

% the objective is to minimize this sum
for i = 1:N
    for j = 1:N
        fprintf(fid, '+ %d l%d_%d ', D(i,j), i, j);
    end
end

fprintf(fid, '\nsubject to\n');

% first constraint: there should be exactly 10 nodes selected
for i = 1:N
    fprintf(fid, '+ n%d ', i);
end
fprintf(fid, '= %d\n', n);

% second constraint: a node can only be connected to a server 
for i = 1:N
    for j = 1:N
        fprintf(fid, '+ l%d_%d ', j, i); 
    end
    fprintf(fid, '= 1\n');
end

% third constraint: do not consider pairs of nodes whose distance overpasses c_max
for i = 1:N
    for j = 1:N
        if D(i, j) > c_max
            fprintf(fid, 'n%d + n%d <= 1\n', i, j);
        end
    end
end

% fourth constraint: the server assigned to each node must be a server node
for i = 1:N
    for j = 1:N
        fprintf(fid, 'l%d_%d - n%d <= 0\n', i, j, i);
    end
end

fprintf(fid, '\nbinary\n');

% each node will be a binary variable
for i = 1:N
    fprintf(fid, 'n%d ', i);
end

% each link will be a binary variable
for i = 1:N
    for j = 1:N
        fprintf(fid, 'l%d_%d ', i, j);
    end
end

fprintf(fid, '\nend');
fclose(fid);