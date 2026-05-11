function [nb] = learnDecisionRule_3classes(p_reject, p_accept, randseed)

  % p_reject = [0.01, 0.01, 0.001]
  % p_accept = [0.3, 0.2, 0.1]

  % learn decision rule with naive bayes classifier. Use three classes, D1,
  % D2, and D3, to get posterior probabilities over these 3 classes

  newR3 = 1; % take out condition (i) w not indep x given Z of R3

  nobs = [7, 12];
  nhid = [2, 4];
  samples = [100, 1000, 10000];
  datatype = 'Gauss';

  para_alg = struct('algtype', 'bf', 'thresholds', [0.05,0.2]);

  para_sim = struct('runs', 300, 'run_alg', 0, 'randseed', 1, ...
	    'getTrueEffect', 1, 'getTrueSolution', 0, ...
	    'getTrueSolutionD1D2D3', 1, ...
	    'comparing_methods', 0, 'plot_graph', 0); 

  para_gen = cell(1,2);
  switch datatype
    case 'Gauss'
      para_gen{1} = struct('indegree', 3, 'prob0', 0.35, 'prob_conf', 0.3, ... 
		    'datatype', 'Gauss', 'parminmax', [0.5, 1.5], ...
		    'errminmax', [0.5, 1.5], 'states', []);
      para_gen{2} = struct('indegree', 5, 'prob0', 0.35, 'prob_conf', 0.3, ... 
		    'datatype', 'Gauss', 'parminmax', [0.5, 1.5], ...
		    'errminmax', [0.5, 1.5], 'states', []);
    case 'discrete'
      para_gen{1} = struct('indegree', 3, 'prob0', 0.5, 'prob_conf', 0.3, ... 
		  'datatype', 'discrete');
      para_gen{2} = struct('indegree', 5, 'prob0', 0.5, 'prob_conf', 0.3, ... 
		  'datatype', 'discrete');
    end

  nvar = 2;
  ngen = 2;

  if (para_sim.run_alg)

    output_all = cell(2,2); %cell(2,4);
    time = zeros(2,2); %zeros(2,4);

    for i=1:nvar % different number of observed and hidden variables
    
      for j=1:ngen % different parameter setting for data generation

	if (strcmp(datatype,'discrete')) % have discrete variables, have to give states
	  para_gen{j}.states = 2*ones(1,nobs(i)+nhid(i));
	end

	tic
	output = main_simulations(nobs(i), nhid(i), samples, ...
		para_gen{j}, para_alg, para_sim);
	time(i,j) = toc
	output_all{i,j} = output;
	
	switch datatype
	  case 'Gauss'
	    filename = strcat('./Results/output_learnDecisionRule_Gauss_', int2str(i), '_', int2str(j), '.mat');
	    save(filename,'output')
	  case 'discrete'
	    filename = strcat('./Results/output_learnDecisionRule_discrete_', int2str(i), '_', int2str(j), '.mat')
	    save(filename,'output')
	end

      end
    end

  else

    output_all = cell(2,2); 
    for i=1:nvar % different number of observed and hidden variables  
      for j=1:ngen % different parameter setting for data generation
        filename = strcat('./Results/output_learnDecisionRule_Gauss_', int2str(i), '_', int2str(j), '.mat');
	load(filename)
	output_all{i,j} = output;
      end
    end

  end


  if ~exist('randseed'),
    rand('seed',sum(100*clock));
    randseed = floor(rand*100000);
  end
  fprintf('Using randseed: %d\n',randseed)
  mystream = RandStream.create('mt19937ar','Seed',randseed);
  RandStream.setDefaultStream(mystream);

  
  tt_all = cell(length(samples),1); % keep sample sizes separate, i.e. get 3 classifiers
  train_indi_all = cell(length(samples),1);
  test_indi_all = cell(length(samples),1);
  remember_indi_all = cell(length(samples),1);

  for nsamp = 1:length(samples)
    %leave separate for each sample size

    tt = [];
    train_indi = [];
    test_indi = [];
    remember_indi = [];

    for j=1:ngen

%        figure()

      for i=1:nvar

	ncov = nobs(i) - 2;
	para_alg.K = ncov;
	
	% get counts how often we decided D1 and D2 from p-values of R1 - R3
	  % first row has counts of D2, second row of D1, third row gives true
	  % result (1=non-zero effect, 2=zero effect in underlying model)

        % --- firs way of getting counts: just count how often our rules applied
	[counts_ij, counts_norm_ij] = getCountsFromPvalues(output_all{i,j}.algOut(:,nsamp), p_reject(nsamp), p_accept(nsamp));

	tt_ij = [counts_norm_ij; output_all{i,j}.trueD1D2D3'; output_all{i,j}.trueD1D2'];
	
%  	subplot(1,2,i)
%  	D1 = tt_ij(3,:)==1; % true answer is non-zero effect with admis set
%  	D2 = tt_ij(3,:)==2; % true answer is zero effect
%  	D3 = tt_ij(3,:)==3; % true answer is "I don't know"
%  	sig = 0.001; % to scatter points a bit, so they don't sit on top of each other
%  	plot(tt_ij(1,D1)+sig*randn(1,sum(D1)),tt_ij(2,D1)+sig*randn(1,sum(D1)),'c.')
%  	hold on
%  	plot(tt_ij(1,D2)+sig*randn(1,sum(D2)),tt_ij(2,D2)+sig*randn(1,sum(D2)),'m.')
%  	plot(tt_ij(1,D3)+sig*randn(1,sum(D3)),tt_ij(2,D3)+sig*randn(1,sum(D3)),'k.')
%  	title(['nvar=', int2str(nsamp),'j=',int2str(j)])
%  	xlim([-0.1,1])
%  	ylim([-0.1,1])
	
	temp = size(tt_ij,2); %sum(~bool);
	temp1 = floor(temp * 4/4); % use proportion of the data to train - or all

	indi_t = sort( randsample(temp, temp1));
	train_indi = [train_indi, size(tt,2) + indi_t'];
	test_indi = [test_indi, size(tt,2) + setdiff(1:temp, indi_t)];

	tt = [tt, tt_ij];
	
      end % for i           
    end % for j 

    tt_all{nsamp,1} = tt;
    train_indi_all{nsamp,1} = train_indi;
    test_indi_all{nsamp,1} = test_indi;
    remember_indi_all{nsamp,1} = remember_indi;

  end % for nsamp



  nb = cell(length(samples),1); % save calssifier here (either nb, or knn)
 
  for nsamp = 1:length(samples)

    tt = tt_all{nsamp,1};
    train_indi = train_indi_all{nsamp,1};
    test_indi = test_indi_all{nsamp,1};

%      figure(4)
    D1 = tt(3,:)==1; % true answer is D1
    D2 = tt(3,:)==2; % true answer is D2
    D3 = tt(3,:)==3; % true answer is D3
%      sig = 0.001; % to scatter points a bit, so they don't sit on top of each other
%      subplot(1,3,nsamp)
%      plot(tt(1,D1)+sig*randn(1,sum(D1)),tt(2,D1)+sig*randn(1,sum(D1)),'c.')
%      hold on
%      plot(tt(1,D2)+sig*randn(1,sum(D2)),tt(2,D2)+sig*randn(1,sum(D2)),'m.')
%      plot(tt(1,D3)+sig*randn(1,sum(D3)),tt(2,D3)+sig*randn(1,sum(D3)),'k.')
%      xlim([-0.1,1.1])
%      ylim([-0.1,1.1])

    % transfer data to separate the decisions D1, D2 and D3
    tt_trans = zeros(size(tt));
    tt_trans(3,:) = tt(3,:); % decisions
    tt_trans(1,:) = tt(1,:) - tt(2,:); % difference
    tt_trans(2,:) = atan2(tt(2,:),tt(1,:)) - pi/4; % angle, 45° mapped to 0
    bool = tt(1,:) == 0 & tt(2,:) == 0;
    tt_trans(2,bool) = 0; % point (0,0) is seen as 45° (not as 0°)

%      figure(5)
%      subplot(1,3,nsamp)
%      plot(tt_trans(1,D1)+sig*randn(1,sum(D1)),tt_trans(2,D1)+sig*randn(1,sum(D1)),'c.')
%      hold on
%      plot(tt_trans(1,D2)+sig*randn(1,sum(D2)),tt_trans(2,D2)+sig*randn(1,sum(D2)),'m.')
%      plot(tt_trans(1,D3)+sig*randn(1,sum(D3)),tt_trans(2,D3)+sig*randn(1,sum(D3)),'k.')

    figure(6)
    set(gcf, 'color', [1 1 1])
    subplot(1,3,nsamp)
    [n,x] = hist(tt_trans(1,D1));
    B = bar(x,n,'c');
    ch = get(B,'child'); set(ch,'facea',.4)
    hold on
    [n,x] = hist(tt_trans(1,D2));
    B = bar(x,n,'m');
    ch = get(B,'child'); set(ch,'facea',.3)   
    [n,x] = hist(tt_trans(1,D3));
    B = bar(x,n,'k');
    ch = get(B,'child'); set(ch,'facea',.2) 


  % learn naive bayes classifier and get confusion matrix

  % naive bayes on train data
  nb_tmp = NaiveBayes.fit(tt_trans(1,train_indi)', tt_trans(3,train_indi)'); % only differences, Gauss fit
  nb{nsamp} = nb_tmp;

  % classify test data using naive bayes - get posterior probabilities
  post_prob = posterior(nb_tmp,tt_trans(1,test_indi)'); % when only differences

  % decision - use maximum a posterior probability
  [maxi, indi] = max(post_prob,[],2);
  Dtt_trans = indi';
 
  conf_mat = confusionmat(tt(3,test_indi),Dtt_trans)

  end % for nsamp


  if (1)
    % save classifiers
    nb_save = nb;
    for i=1:3
      filename = strcat('nb_Gauss_', num2str(samples(i)), '_1dim_gaussfit_newR3', '.mat')
      nb = nb_save{i};
      save(filename, 'nb')
    end
  end








