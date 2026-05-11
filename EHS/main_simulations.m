function [output] = main_simulations(nobs,nhid,samples,para_gen,para_alg,para_sim)

  % run simulations with our rules R1-R3

  % INPUT:
  % nobs ... number of observed variables
  % nhid ... number of hidden variables
  % samples ... vector containing the sample sizes [ns_1, ns_2, ... ns_n]
  % para_gen ... struct containing parameters for model generation
  %   for continuous gaussian data:
%     para_gen = struct('indegree', 3, 'prob0', 0.3, 'prob_conf', 0.3, ... 
%                'datatype', 'Gauss', 'parminmax', [0.5, 1.5], ...
%                'errminmax', [0.5, 1.5], 'states', [], 'admissible', 0);
  %   for discrete data:
%     para_gen = struct('indegree', 3, 'prob0', 0.3, 'prob_conf', 0.3, ... 
%                'datatype', 'discrete', 'states', 2*ones(1,nobs+nhid), ...
%                'admissible', 0);
%     with
%     indegree ... maximum indegree of each node
%     prob0 ... probability of having a 0 effect between x and y
%     prob_conf ... probability of having a confounder between x and y
%     datatype ... 'Gauss' or 'discrete'
%     parminmax ... if datatype='Gauss', standard deviation owing to parents
%     errminmax ... if datatype='Gauss', standard deviation owing to errors
%     states ... if datatype='Gauss', set it to [], if datatype='discrete'
%                giving the number of states of each variable
%     admissible ... (optional) if 0, there must not be an admissible set,
%                    if 1, then only models with admissible set are used.
%                    default = 0
%     cyclic ... (optional) if 0 generate a DAG (i.e. no cyclces), if 1 allow
%                cycles among the nobs-2 observed covariates, default = 0 = no
%                NOTE: data generation file not provided in code package
  % para_alg ... struct containing parameters for algorithms
%     para_alg = struct('algtype', 'bf', 'thresholds', [0.05,0.2], 'K', ...
%                nobs-2);
  %   with
  %   algtype ... 'bf' brute force, 'randomly' random selection
  %   thresholds ... vector with two entries [thres_reject, thres_accept], the
  %                  thresholds for rejecting and accepting independence
  %   K ... (optional) maximal size of conditioning set in indep.tests, defaulf
  %         K = nobs-2 (no limit on conditioning set)
  % para_sim ... struct containing details for simulations
%     para_sim = struct('runs', 100, 'run_alg', 1, 'randseed', 123, ...
%                'getTrueEffect', 1, 'getTrueSolution', 1, ...
%                'getTrueSolutionD1D2D3', 1);
  %   runs ... how many different models are used
  %   run_alg ... if 1 run algorithm and save results, if 0 load results from previous runs
  %   randseed ... (optional) seed, to reproduce results
  %   getTrueEffect ... (optional) calculate true effect (default = 1 = yes);
  %   getTrueSolution ... (optional) apply R1-R3 with d-separation (default = 0 = no);
  %   getTrueSolutionD1D2D3 ... (optional) get true solution on the decisions
  %                             D1, D2 or D3. This is a more efficient way to
  %                             get the true decision than using getTrueSolution
  %                             which applies rules R1-R3 to all subsets (i.e.
  %                             testing all w's and sets Z's). This only trys to
  %                             find one such w and Z, and then stops.
  %                             (default = 1 = calculate this solution)
  %
  % OUTPUT
  % output ... structure

  if (0)
    addpath ./tetrad
  end

  % setting the seed
  if ~isfield(para_sim,'randseed'),
    rand('seed',sum(100*clock));
    para_sim.randseed = floor(rand*100000);
  end
  fprintf('Using randseed: %d\n',para_sim.randseed)
  mystream = RandStream.create('mt19937ar','Seed',para_sim.randseed);
  RandStream.setDefaultStream(mystream);
  savedState = mystream.State;

  if ~isfield(para_sim,'getTrueEffect') 
    para_sim.getTrueEffect = 1;
  end
  if ~isfield(para_sim,'getTrueSolution') 
    para_sim.getTrueSolution = 0;
  end
  if ~isfield(para_sim,'getTrueSolutionD1D2D3') 
    para_sim.getTrueSolutionD1D2D3 = 1;
  end

  runs = para_sim.runs
  para_alg.states = para_gen.states;

  if ~isfield(para_sim,'theSeeds')
    theSeeds = randsample(10000,runs);
  else
    theSeeds = para_sim.theSeeds;
  end

  if ~isfield(para_gen,'admissible')
    para_gen.admissible = 0;
  end
  if ~isfield(para_gen,'cyclic')
    para_gen.cyclic = 0;
  end
  if ~isfield(para_alg,'K')
    para_alg.K = nobs-2;
  end

  % some information for the user
  nobs
  nhid
  samples
  para_gen
  para_alg

  % prepare the output
  len_samp = length(samples);

  output = struct;

  algOut = cell(runs, len_samp);

  trueD1D2 = zeros(runs,1); % this is 1 if non-zero effect, 2 if 0 effect
  trueD1D2D3 = zeros(runs,1); % this is 1 if true decision was D1 (i.e. non-zero
               % effect and admissible set, 2 if D2 (zero effect), 3 if D3 (there
               % is no way to say what the effect is)                                                                            
  trueOut = cell(runs,1);
  trueEffect = zeros(runs,1);

  genSkel = cell(runs,1);
  genOrder = cell(runs,1);

  nvar = nobs + nhid;
  x = nobs-1; % index of x variable in D
  y = nobs; % index of y variable in D

  if (para_sim.run_alg)

    % start simulations
    for i = 1:runs
      fprintf('------------ run %d --------------- \n', i)

      % ------------------------------------------------------------------------
      % generate Skeleton
      [B_skel, p] = genSkeleton_xy(nobs, nhid, para_gen.indegree, ...
			para_gen.prob0, para_gen.prob_conf, theSeeds(i), ...
			para_gen.admissible, para_gen.cyclic);
      k = [nobs+1:nvar,p]; % to permute B_skel to lower triangular B_skel_tri
  %      B_skel_tri = B_skel(k,k);
  %      k1 = [iperm(p)+nhid,1:nhid]; % to permute B_skel_tri to B_skel'
      genSkel{i} = B_skel;
      genOrder{i} = k;
      fprintf('model generated\n')
      
      % get true solution, o or non-zero effect
      if (B_skel(y,x) == 0) %true effect is 0
	trueD1D2(i) = 2; % there is a zero effect
      else
	trueD1D2(i) = 1; %there is a non-zero effect
      end

      % ------------------------------------------------------------------------
      % get true solutions for all w's and Z's for R1, R2 and R3 - using
      % d-separation in graph (can be quite time consuming in larger models)
      if (para_sim.getTrueSolution)

	% run our rules R1-R3
	out_dsep = algorithm_applyRules123_dsep(B_skel, nobs, para_alg.K);
	out_dsep = rmfield(out_dsep,'R1_Z');
	out_dsep = rmfield(out_dsep,'R23_w');
	out_dsep = rmfield(out_dsep,'R23_Z');

	trueOut{i} = out_dsep;
	fprintf('true solution calculated\n')
        
      end % if (para_sim.getTrueSolution)


      % ------------------------------------------------------------------------
      % get true solutions for decision D1, D2 and D3 (only find one w and Z
      % so that R1, R2 or R3 holds, then return 1 (for D1), 2 (D2) or 3 (D3))
      if (para_sim.getTrueSolutionD1D2D3)
        
        if (para_sim.getTrueSolution)
          % have calculated for every set Z (and w) whether R1, R2, R3 apply
          % get true decision from there
          
	  tmp = out_dsep.R1_p;
	  D2_1 = any(tmp==1); % if 1, R1 applies
	  tmp = out_dsep.R2_p;
	  D2_2 = any(tmp(:,1)==0 & tmp(:,2)==1); % if 1, R2 applies
	  tmp = out_dsep.R3_p;                 
	  D1 = any(tmp(:,1)==0 & tmp(:,2)==1 & tmp(:,3)==0); % if 1, R3 applies
	  
	  if (D2_1 || D2_2)
	    out_dec = 2;
	  elseif (D1)
	    out_dec = 1;
	  else
	    out_dec = 3;
	  end
	  if ( (D2_1 || D2_2) && D1)
	    fprintf('ERROR in main_simulations, getTrueSolutionD1D2D3. keyboard\n')
	    keyboard
	  end

        else

	  % run our rules R1-R3, stop if we found one of them to hold
	  out_dec = algorithm_applyRules123_dsep(B_skel, nobs, para_alg.K, 1);

	end

	trueD1D2D3(i) = out_dec; % decision D1, D2 or D3
	fprintf('true decision made\n')

      end % if (para_sim.getTrueSolutionD1D2D3)


      % ------------------------------------------------------------------------
      % run algorithm on the various sample sizes
      for nsamp = 1:len_samp
	ns = samples(nsamp);

	% ----------------------------------------------------------------------
	% generate data D, arranged in causal order as B_skel: first the nobs-2
	% covariates, then x, then y, then the hidden variables.
	% Bp (connection matrix) and CPT (conditional probability tables) are in
	% same causal order
	if (para_gen.cyclic == 0)
	  % have an acyclic model

	  switch para_gen.datatype
	    case 'Gauss'
	      [D, Bp, cp, ep] = genData_gauss(B_skel, k, nobs, nhid, ns, para_gen.parminmax, para_gen.errminmax, theSeeds(i));
	      
	    case 'discrete'
	      fprintf('Not yet implemented for discrete data. Return.\n')
	      return
	  end
	  
	else
	  % have a cyclic model
	  
	  switch para_gen.datatype
	    case 'Gauss'
	      % cyclic data generation not provided in code package
	  end
	end

	D = D(1:nobs,:); % only use data over observed variables

	% ----------------------------------------------------------------------
	% run our rules R1-R3
	switch para_alg.algtype
	  case 'bf'
	    out = algorithm_applyRules123(D, para_gen.datatype, para_alg);
	    if (i==runs && nsamp==len_samp)
	      % only save sets Z, and (w,Z) once, the same for all runs
	      output.R1_Z = out.R1_Z;
	      output.R23_w = out.R23_w;
	      output.R23_Z = out.R23_Z;
	    end
	    out = rmfield(out,'R1_Z');
	    out = rmfield(out,'R23_w');
	    out = rmfield(out,'R23_Z');
	  case 'randomly'
	    out = algorithm_applyRules123_random(D, para_gen.datatype, para_alg);
	    if (i==runs && nsamp==len_samp)
	      % have Z and (w,Z) saved in out, so do not save them again;
	      % different for each run
	      output.R1_Z = NaN;
	      output.R23_w = NaN;
	      output.R23_Z = NaN;
	    end
	  otherwise
	    fprintf('Algorithm type must be bf, or randomly - STOP.\n')
	    return
	end

	algOut{i,nsamp} = out;

      end % for nsamp


      if (para_sim.getTrueEffect)

	% get true causal effect
	switch para_gen.datatype
	  case 'Gauss'
	    % get edge coefficient of x->y
	    effect_true = Bp(y,x); % = regression coefficient of x in the regression of
		  % y on x when including an admissible set Z (exists among all
		  % observed and unobserved variables)
	    trueEffect(i) = effect_true;

	  case 'discrete'
	  
	    if (B_skel(y,x) == 0)
	      trueEffect(i) = 0;
	    else
	    
	      fprintf('Not yet implemented for discrete data. true effect set to NaN.\n')
	      trueEffect(i) = NaN;

	    end

	end %switch
      end %if (para_sim.getTrueEffect)

    end % for i=1:runs

  else

    % do nothing...

  end % if (para_sim.run_alg)

  output.algOut = algOut; % results from algorithm R1, R2, R3 (no estiamtes yet)

  output.trueD1D2 = trueD1D2; % true non-zero effect (1) or 0 effect (2) 
  output.trueD1D2D3 = trueD1D2D3; % true decision D1 (1) or D2 (2), or D3 (3) 
  output.trueOut = trueOut; % true result when applying R1-R3 with d-sep 
  output.trueEffect = trueEffect; % true causal effect/ACE

  output.genSkel = genSkel; % generating skeletons, to make it easy to gen data again
  output.genOrder = genOrder; % generating causal order

  output.theSeeds = theSeeds;
  output.nobs = nobs;
  output.samples = samples;

  output
