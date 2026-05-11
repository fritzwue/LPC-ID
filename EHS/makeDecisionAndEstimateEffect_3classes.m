function [est, Dec, post_prob, counts, counts_trans] = makeDecisionAndEstimateEffect_3classes(D, datatype, states, outAlg, R3_Z, R1_Z, print_output)
  
  % INPUT
  % D ... data matrix, variables in rows, observations in columns
  % datatype
  % states
  % outAlg ... 1x1 cell output of algorithm_applyRules123.m
  % R3_Z ... mx1 cell, where m is the number of Z's for which we tested R3
  % R1_Z ... kx1 cell, where k is the number of Z's for which we tested R1
  % print_output ... if 0 do not print the results, if 1 print out the decision
  %                  and estiamtes
  % 
  % OUTPUT
  % est ... estiamte of the causal effect of x on y, or NaN
  % Dec ... decision: 1 for D1, 2 for D2, 3 for D3, 4 if Decision from Naive
  %         Bayes classifier was D1, but estimates were not similar enough, so
  %         we do not give an estimate of the causal effect of x on y, i.e. est
  %         is the following depending on Dec:
  %         if Decision is D1 (i.e. Dec=1) est is the estimate of the non-zero
  %         effect of x on y. For D2 (i.e. Dec=2), est = 0; For D3 (i.e.
  %         Dec=3), or Dec=4, est = NaN;
  % post_prob = class posterior probabilities of D1, D2, and D3 (in this order)
  
  if ~exist('print_output')
    print_output = 0;
  end
  
  newR3 = 1;
  
  [nobs, nsamp] = size(D);
  
  plot_graph = 0;

  if (nsamp < 500)
    % these were used to train the naive bayes classifier 'nb' for that sample size
    switch datatype
      case 'Gauss'
	p_reject = 0.01;
	p_accept = 0.3;
	load('nb_Gauss_100_1dim_gaussfit_newR3.mat'); % load nb

      case 'discrete'
        fprintf('Not yet implemented for discrete data. Return.\n')
        est = NaN; Dec = NaN; post_prob = NaN; counts = NaN; counts_trans = NaN;
        return
      
    end
  elseif (nsamp < 5000)
    switch datatype
      case 'Gauss'
	p_reject = 0.01;
	p_accept = 0.2;
	load('nb_Gauss_1000_1dim_gaussfit_newR3.mat'); % load nb

      case 'discrete'
        fprintf('Not yet implemented for discrete data. Return.\n')
        est = NaN; Dec = NaN; post_prob = NaN; counts = NaN; counts_trans = NaN;
        return

    end  
  else
    switch datatype
      case 'Gauss'
	p_reject = 0.001;
	p_accept = 0.1;
	load('nb_Gauss_10000_1dim_gaussfit_newR3.mat'); % load nb

      case 'discrete'
        fprintf('Not yet implemented for discrete data. Return.\n')
        est = NaN; Dec = NaN; post_prob = NaN; counts = NaN; counts_trans = NaN;
        return      
    end  
  end

  [dummy, counts_norm] = getCountsFromPvalues(outAlg, p_reject, p_accept, newR3);

  c1 = counts_norm(1,1); % how often R1 and R2 applied, in percentages
  c2 = counts_norm(2,1); % how often R3 applied, in percentages
  
  counts = [c1,c2];
  
%    % normalize counts to be between 0 and 1 - now done when getting counts!
%    % c1 has number how often we said D2, c2 how often D1
%    c1 = c1/( size(outAlg{1,1}.R1_p,1) + size(outAlg{1,1}.R2_p,1) );
%    c2 = c2/( size(outAlg{1,1}.R3_p,1) );

  % transform to get better separation for naive bayes classifier
  c1_trans = c1 - c2; % difference
  if (c2==0 && c1==0)
    c2_trans = 0;
  else
    c2_trans = atan2(c2,c1) - pi/4; % angle
  end

  counts_trans = [c1_trans, c2_trans];

  % make decision using trained classifier to get decision
  
  if exist('nb')
    % for naive bayes, get posterior probabilities of 
    % D1, D2, and D3 (in this order, in post_prob):
    post_prob = posterior(nb,[c1_trans]);

    [maxi, indi] = max(post_prob);
    Dec = indi;
  else
    fprintf('error in makeDecisionAndEstimateEffect_3classes.m, classifier did not load properly - keyboard\n')
    keyboard
  end

  % get effect
  if (Dec==3)
    est = NaN;

  elseif (Dec==2)
    est = 0;

  elseif (Dec==1)

    % estiamte effect for those sets Z where R3 applied
    temp = outAlg{1,1}.R3_p; % p-values of independence test of R3
    % check if conditions of R3 are fulfilled
    if (newR3)
      bool = temp(:,2) > p_accept & temp(:,3) < p_reject;
    else
      bool = temp(:,1) < p_reject & temp(:,2) > p_accept & temp(:,3) < p_reject;
    end

    if (sum(bool)==0)
      % if for some reason classifier thinks decision D1, although R3 did never
      % apply, set decision to 4
      est = NaN;
      Dec = 4;
    end

    Zcell = R3_Z(bool); % R3 applied with these sets Z
    [ests, CIs] = calculateEstimatedEffect(D, Zcell, datatype, states);
      
    % check if effects are similar
    val = areEstiamtesSimilar_Clusters(ests, CIs);
    if (val < 0.5) % estiamtes not similar
      est = NaN;
      Dec = 4;
    else
%      est = mean(ests(out.R3_d)); % if using std or mean absolute dev for val
      est = median(ests); % if using median absolute dev for val
    end
  end


  if (print_output)
    % !!! THIS IS NEW NOTATION FOR R1 AND R2 (AS IN PAPER), i.e.
    % !!! HERE R1 CORRESPONDS TO WHAT IS USED IN CODE AS R3
    % !!!      R2 CORRESPONDS TO WHAT IS USED IN CODE AS R1 AND R2
    total1 = size(outAlg{1}.R1_p,1) + size(outAlg{1}.R2_p,1);
    total2 = size(outAlg{1}.R3_p,1);
    fprintf('Tested R1 %d times; R1 was true %d time(s); in percentages: %f.\n',total2, dummy(2),c2)
    fprintf('Tested R2 %d times; R2 was true %d time(s); in percentages: %f.\n',total1, dummy(1),c1)
    fprintf('Suggested decision by classifier is D%d.\n', Dec)
    fprintf('Posterior probabilities for decisions D1, D2, and D3: (%f, %f, %f).\n', post_prob(1), post_prob(2), post_prob(3))
    if ~isnan(est)
    fprintf('Estimated effect is %f.\n', est)
    end
  end

