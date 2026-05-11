function [output, para_gen, para_alg, para_sim] = simulationCommands(nobs, nhid, samples, task, datatype, indis)

% nobs = 7 or 12 or 102
% nhid = 3 or  5 or  20
% samples = [100, 1000, 10000];
% task = 1, 2, 3, or 4 (Fig 2 and 3), 9, 10 (Fig in supp. material)
% datatype ... 'Gauss' or 'discrete'
%           NOTE: for discrete data not yet implented
% indis ... when splitting simulations, indices of which of the 100 runs
%           should be performed (f.ex. 1:10)

para_alg = struct('algtype', 'bf', 'thresholds', [0.05,0.2]);
para_sim = struct('runs', 100, 'run_alg', 1, 'randseed', 123, ...
	  'getTrueEffect', 1, 'getTrueSolution', 0, ...
	  'getTrueSolutionD1D2D3', 1, 'plot_graph', 0, ...
	  'comparing_methods', 1);

switch datatype
  case 'Gauss'
    para_gen = struct('indegree', 4, 'prob0', 0, 'prob_conf', 0, ... 
	      'datatype', 'Gauss', 'parminmax', [0.5, 1.5], ...
	      'errminmax', [0.5, 1.5], 'states', [], 'admissible', 1);
end

% set the seed
mystream = RandStream.create('mt19937ar','Seed',para_sim.randseed);
RandStream.setDefaultStream(mystream);
savedState = mystream.State;

% generate 'runs' seeds, for when we split up simulations in several clusters
theSeeds = randsample(10000,para_sim.runs);

% when using cluster to split up 100 runs into smaller junks (to speed up
% calculation time), only use subset of indices, and less runs, and later
% combine results
para_sim.runs = length(indis);
para_sim.theSeeds = theSeeds(indis);


% -----------------------------------------------------------------------------
% TASK 1: non-zero effects with admissible set (D1)

if (task == 1)

  para_gen.prob0 = 0; % always non-zero effect
  para_gen.prob_conf = 0; % never hidden confounder
  para_gen.admissible = 1; % always admissible set

end


% -----------------------------------------------------------------------------
% TASK 2: non-zero effects without admissible set (D3)

if (task == 2)

  para_gen.prob0 = 0; % always non-zero effect
  para_gen.prob_conf = 1; % always hidden confounder, i.e. no admis set
  para_gen.admissible = 0; % no need for admissible set

end


% -----------------------------------------------------------------------------
% TASK 3: zero effects with admissible set (D2)

if (task == 3)

  para_gen.prob0 = 1; % always zero effect
  para_gen.prob_conf = 0; % never hidden confounder
  para_gen.admissible = 1; % always admissible set

end


% -----------------------------------------------------------------------------
% TASK 4: zero effects without admissible set (D2 or D3)

if (task == 4)

  para_gen.prob0 = 1; % always non-zero effect
  para_gen.prob_conf = 1; % always hidden confounder, i.e. no admis set
  para_gen.admissible = 0; % no need for admissible set

end


% -----------------------------------------------------------------------------
% TASK 9: for large models, (non-zero effect, with or without confounder)

if (task == 9)

  para_gen.prob0 = 0; % non-zero effect
  para_gen.prob_conf = 0.5; % 50% hidden confounder
  para_gen.admissible = 0; % no need for admissible set
  para_gen.indegree = 5; % maximal indegree

  para_alg.algtype = 'randomly';
  para_alg.n = 50000;
  para_alg.K = 10;

  para_sim.getTrueSolution = 0;
  para_sim.getTrueSolutionD1D2D3 = 0;

  para_sim

end


% -----------------------------------------------------------------------------
% TASK 10: for large models, (zero effect, with or without confounder)
if (task == 10)

  para_gen.prob0 = 1; % zero effect
  para_gen.prob_conf = 0.5; % 50% hidden confounder
  para_gen.admissible = 0; % no need for admissible set
  para_gen.indegree = 5; % maximal indegree

  para_alg.algtype = 'randomly';
  para_alg.n = 50000;
  para_alg.K = 10;

  para_sim.getTrueSolution = 0;
  para_sim.getTrueSolutionD1D2D3 = 0;

end


tic
output = main_simulations(nobs,nhid,samples,para_gen,para_alg,para_sim);
toc
