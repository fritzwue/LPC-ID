function [out] = main_simulations_DecisionsEffects(out_sim, para_gen, para_sim)

  % output see at the bottom

  if ~isfield(para_gen,'cyclic')
    para_gen.cyclic = 0;
  end
  if ~isfield(para_sim,'allFCIrules')
    para_sim.allFCIrules = 'false';
  end
  if ~isfield(para_sim,'possDsep')
    para_sim.possDsep = 'true';
  end

  runs = para_sim.runs;
  nobs = out_sim.nobs;
  samples = out_sim.samples;

  len_samp = length(samples);
  x = nobs-1;
  y = nobs;
  
  estimates = zeros(runs, len_samp);
  decisions = zeros(runs, len_samp);
  post_prob = zeros(runs, 3, len_samp); % for each decision posterior prob

  estimates_none = zeros(runs, len_samp);
  estimates_all = zeros(runs, len_samp);
  estimates_cc = zeros(runs, len_samp);
  estimates_vw = zeros(runs, len_samp);
  estimates_acc = zeros(runs, len_samp);
  estimates_avw = zeros(runs, len_samp);

  estimates_FCI = zeros(runs, len_samp);
  decisions_FCI = zeros(runs, len_samp);

  theSeeds = out_sim.theSeeds;


  for i = 1:runs
    fprintf('------------ run %d --------------- \n', i)

    % ------------------------------------------------------------------------
    % get Skeleton
    B_skel = out_sim.genSkel{i};
    k = out_sim.genOrder{i};
    nvar = size(B_skel,1);
    nhid = nvar - nobs;

    % ------------------------------------------------------------------------
    % run algorithm on the various sample sizes
    for nsamp = 1:len_samp
      ns = samples(nsamp);

      % generate data
      switch para_gen.datatype
	case 'Gauss'
	  if (para_gen.cyclic == 0)
	    [D, Bp, cp, ep] = genData_gauss(B_skel, k, nobs, nhid, ns, para_gen.parminmax, para_gen.errminmax, theSeeds(i));
	  else
	    % cyclic data generation not provided in code package
	  end 

	case 'discrete'
	  fprintf('Not yet implemented for discrete data. Return.\n')
	  return
      end
      D = D(1:nobs,:); % only use data over observed variables

      % --------------------------------------------------------------------------- 
      % our new approach

      if (iscell(out_sim.R1_Z))
        R1_Z = out_sim.R1_Z;
      else
        R1_Z = out_sim.algOut{i,nsamp}.R1_Z;
      end

      if (iscell(out_sim.R23_Z))
        R3_Z = out_sim.R23_Z;
      else
        R3_Z = out_sim.algOut{i,nsamp}.R3_Z;
      end

      % make decision based on how often R1+R2, and R3 applied
      [est, Dec, pp, counts, counts_trans] = makeDecisionAndEstimateEffect_3classes(D, ...
                   para_gen.datatype, para_gen.states, ...
                   out_sim.algOut(i,nsamp), R3_Z, R1_Z);

      estimates(i, nsamp) = est;
      decisions(i, nsamp) = Dec;
      post_prob(i, :, nsamp) = pp;

      % ---------------------------------------------------------------------------
      % comparing methods
      if (para_sim.comparing_methods)
	% include none
	Zcell = cell(1); Zcell{1,1} = [];
	est_none =  calculateEstimatedEffect(D, Zcell, para_gen.datatype, para_gen.states);
	estimates_none(i, nsamp) = est_none;

	% include all
	Zcell = cell(1); Zcell{1,1} = 1:nobs-2;
	est_all =  calculateEstimatedEffect(D, Zcell, para_gen.datatype, para_gen.states);
	estimates_all(i, nsamp) = est_all;
	
	% include direct common causes (cc)
	Zcell = cell(1);
	Zcell{1,1} = intersect( find(B_skel(x,1:nobs-2)==1), find(B_skel(y,1:nobs-2)==1));
	if (all(size(Zcell{1,1})==[1,0])) Zcell{1,1} = []; end
	est_cc =  calculateEstimatedEffect(D, Zcell, para_gen.datatype, para_gen.states);
	estimates_cc(i, nsamp) = est_cc;

	% VanderWeele et al. (2011)
	Zcell = cell(1);
	Zcell{1,1} = setdiff(ancestors( B_skel(1:nobs,1:nobs), [x, y]), [x,y]);
	if (all(size(Zcell{1,1})==[1,0])) Zcell{1,1} = []; end
	est_vw =  calculateEstimatedEffect(D, Zcell, para_gen.datatype, para_gen.states);
	estimates_vw(i, nsamp) = est_vw;
	
	% associated covariates, with x, y
	Ax = associatedVariables(D,x,1:nobs-2);
	Ay = associatedVariables(D,y,1:nobs-2);
	
	% associated with both (corresponds to common cause criterion)
	Zcell = cell(1); Zcell{1,1} = intersect(Ax, Ay);
	if (all(size(Zcell{1,1})==[1,0])) Zcell{1,1} = []; end
	est_acc =  calculateEstimatedEffect(D, Zcell, para_gen.datatype, para_gen.states);
	estimates_acc(i, nsamp) = est_acc;

	% associated with x, with y, or with both (corresponds to VanderWeele)
	Zcell = cell(1); Zcell{1,1} = union(Ax, Ay);
	if (all(size(Zcell{1,1})==[1,0])) Zcell{1,1} = []; end
	est_avw =  calculateEstimatedEffect(D, Zcell, para_gen.datatype, para_gen.states);
	estimates_avw(i, nsamp) = est_avw;

	% FCI
	sig = [0.05,0.01,0.01];
	[dec_FCI, est_FCI] = findCausalEffectWithFCI(D, para_gen.datatype, sig(nsamp), para_gen.states,para_sim.allFCIrules,para_sim.possDsep);
	estimates_FCI(i, nsamp) = est_FCI;
	decisions_FCI(i, nsamp) = dec_FCI;

      end % if (comparing_methods)

    end % for nsamp
  end % for i

  out = struct;
  out.estimatesR123 = estimates;
  out.decisions = decisions; % NOTE: if decisions is 4, then naive bayes said
                             % decision D1 but estimates were not similar, so
                             % we do not make a decision
  out.post_prob = post_prob;

  out.estimates_none = estimates_none ;
  out.estimates_all = estimates_all; 
  out.estimates_cc = estimates_cc;
  out.estimates_vw = estimates_vw;
  out.estimates_acc = estimates_acc;
  out.estimates_avw = estimates_avw;
  out.estimates_FCI = estimates_FCI;
  out.decisions_FCI = decisions_FCI;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function A = associatedVariables(D,v,W);
  
  alpha = 0.05;
  A = [];
  Dv = D(v,:);
  
  for w=W
    [r,p] = corrcoef(Dv',D(w,:)');
    if (p(1,2) < alpha)
      A = [A, w];
    end
  end
