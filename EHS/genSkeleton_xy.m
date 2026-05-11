function [B_skel, p] = genSkeleton_xy(nobs, nhid, indegree, prob0, ...
                              prob_conf, randseed, admissible, cyclic)

  % create an lvLiNGAM model in canonical form
  % in B are first nobs-2 observed variables (covariates), then x and y, then
  % the hidden variables; X is in the same order

  % INPUT
  % nobs ... number of observed variables in graph
  % nhid ... number of hidden variables
  % indegree ... maximum indegree of each node
  % prob0 ... probability that the effect of x on y is zero
  % prob_conf ... probability of adding a confounder between x and y
  % randseed ... random seed
  % admissible ... (optional) if 0, there must not be an admissible set, i.e.
  %                just generate some model and we are fine. if 1, then get
  %                model with admissible set, maybe have to try a few times. 
  %                default = 0
  % cyclic ... (optional) if 0 generate a DAG (i.e. no cyclces), if 1 allow
  %            cycles among the nobs-2 observed covariates, default = 0 = no
  %            NOTE: data generation not provided in code package

  % OUTPUT
  % B_skel ... Skeleton, arranged such that first are the observed variables
  %            (first n-2 covariates in causal order p, then x, then y), and
  %            then the nhid hidden variables
  % p ... causal order among observed variables, x and y last two variables
  %            k = [nobs+1:nvar,p];
  %            B_skel_tri = B_skel(k,k); % B_skel arranged in a causal order
  %            k1 = [iperm(p)+nhid,1:nhid];
  %            B_skel = B_skel_tri(k1,k1); % in random causal order with hvs last

  if ~exist('randseed'),
    rand('seed',sum(100*clock));
    randseed = floor(rand*100000);
  end
  fprintf('Using randseed: %d\n',randseed)
  rand('seed',randseed);
  randn('seed',randseed);

  if ~exist('admissible')
    admissible = 0;
  end
  if ~exist('cyclic')
    cyclic = 0;
  end

  nvar = nobs + nhid;
  flag = 0;

  while (flag==0)

    if (admissible==0)
      % don't need admissible set, return first generated model
      flag = 1;
    end

    B_skel = zeros(nvar,nvar);

    if (~cyclic)

      % Go trough each observed node in the turn, except x and y
      for i=1:nobs-2
	% pick at most indegree parents among variables predeeding i
	if (i<=indegree)
	  temp = floor(rand(1)*i); % choose number of parents between 0 and i-1
	  par = randperm((i-1));
	  B_skel(i,par(1:temp)) = 1;
	else
	  temp = floor(rand(1)*(indegree+1)); % choose number of parents between 0 and indegree
	  par = randperm((i-1));
	  B_skel(i,par(1:temp)) = 1;
	end
      end
      
    else
    
      for i=1:nobs-2
	% pick at most indegree parents among all covariates
	temp = floor(rand(1)*(indegree+1)); % choose number of parents between 0 and indegree
	par = randsample(setdiff(1:nobs-2,i),temp); % among all other covariates
	B_skel(i,par) = 1;
      end
       
    end % if (~cyclic)

    % Get connections to x and y
    x = nobs-1;
    y = nobs;

    temp = floor(rand(1)*min(nobs-1,indegree+1)); % choose number of parents
    if (temp==0)
      temp = 1; % x has at least one parent
    end
    par = randperm((nobs-2));
    B_skel(x,par(1:temp)) = 1;

    temp = floor(rand(1)*min(nobs-1,indegree)); % choose number of parents, use
	  % one less than indegree, and add connection from x to y
    par = randperm((nobs-2)); % other parents than x
    B_skel(y,par(1:temp)) = 1;

    % add connection from x to y with probability 1-prob0
    if (rand(1) > prob0)
      B_skel(y,x) = 1; % x to y
    end

    % Get random permutation among the observed variables, leave x and y last
    p = [randperm(nobs-2) x y];
    B_skel(1:nobs,1:nobs) = B_skel(p,p);

    % add with prob_conf % chance a hidden variable between x and y
    start_val = 1;
    
    if (nhid > 0)  
      temp = rand(1);
      if (temp < prob_conf)
	B_skel([x,y],nobs+1) = 1;
	start_val = 2;
      end
    end
    
    % add connections from (other) latent variables to observed variables
    for i=start_val:nhid 
      temp = 2; %2 children 
      % add confounder between any two variables except x and y
      if (rand(1) < 0.5)
	% children of confounder, any observed except y
	chi = randperm(nobs-1);
	B_skel(chi(1:temp), nobs+i) = 1;
      else
	% children of confounder, any observed except x
	chi = randperm(nobs-1);
	indi = find(chi==x); % index of x
	chi(indi) = y; % replace x with y
	B_skel(chi(1:temp), nobs+i) = 1;
      end
    end
    
    p = iperm(p);
    k = [nobs+1:nvar,p];
    B_skel_tri = B_skel(k,k); % in causal order
    % check if really lower triangular, if we generate a acylic graph
    if (~all(all( triu(B_skel_tri) == 0)) && ~cyclic)
      fprintf('error in genSkeleton_xy.m: matrix not lower triangular, go to keyboard\n')
      keyboard
    end

    % check if we want an admissible set if there actually is one
    if (admissible==1)
      flag = existsAdmissibleSet(B_skel,nobs);
      % flag = 1 if there exists an admissible set, i.e. stop while loop
      % flag = 0 if there is no admissible set, i.e. generate new model - note:
      %          there is no need to set a new random seed since we will not
      %          generate the same model again when leaving the seed as it is,
      %          since it is set all the way in the beginning, so just continue
    end

  end % while (flag==0)
