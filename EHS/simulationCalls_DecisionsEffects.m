function [] = simulationCalls_DecisionsEffects(nobs, nhid)

  % nobs = 12; nhid = 5;
  % nobs = 102; nhid = 20;

  mypath = './Results/';
  figpath = './Results/figures/';


% -----------------------------------------------------------------------------
if ( (nobs==7 || nobs==12) )
  if (1)

    % calculate estimates and save them
    outputs = cell(4,1);
    estimates = cell(4,1);

    % various tasks
    filename = strcat(mypath,'Res_Gauss_task1_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename); % output, para_gen, para_alg, para_sim
    output1 = output;
    out_est1 = main_simulations_DecisionsEffects(output, para_gen, para_sim)
    outputs{1} = output1;
    estimates{1} = out_est1;

    filename = strcat(mypath,'Res_Gauss_task2_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename);
    output2 = output;
    out_est2 = main_simulations_DecisionsEffects(output, para_gen, para_sim)
    outputs{2} = output2;
    estimates{2} = out_est2;

    filename = strcat(mypath,'Res_Gauss_task3_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename);
    output3 = output;
    out_est3 = main_simulations_DecisionsEffects(output, para_gen, para_sim)
    outputs{3} = output3;
    estimates{3} = out_est3;

    filename = strcat(mypath,'Res_Gauss_task4_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename);
    output4 = output;
    out_est4 = main_simulations_DecisionsEffects(output, para_gen, para_sim)
    outputs{4} = output4;
    estimates{4} = out_est4;

    fprintf('Results saved under:')
    filename = strcat(mypath,'Est_Gauss_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000', '.mat')
    save(filename, 'estimates');

  else

    % load results
    outputs = cell(4,1);

    % various tasks, outputs
    filename = strcat(mypath,'Res_Gauss_task1_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename); % output, para_gen, para_alg, para_sim
    outputs{1} = output;

    filename = strcat(mypath,'Res_Gauss_task2_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename);
    outputs{2} = output;

    filename = strcat(mypath,'Res_Gauss_task3_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename);
    outputs{3} = output;

    filename = strcat(mypath,'Res_Gauss_task4_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000.mat');
    load(filename);
    outputs{4} = output;

    % estimates
    fprintf('Results loaded from:')
    filename = strcat(mypath,'Est_Gauss_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000', '.mat')
    load(filename);

  end
end


% -----------------------------------------------------------------------------
if (nobs==102)
  if (1)

    % calculate estimates and save them
    outputs = cell(2,1);
    estimates = cell(2,1);

    % task 9
    filename = strcat(mypath,'Res_Gauss_task9_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000_part1', '.mat');
    load(filename); % output, para_gen, para_alg, para_sim
    out1 = output;
    para_sim1 = para_sim;

    filename = strcat(mypath,'Res_Gauss_task9_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000_part2', '.mat');
    load(filename); % output, para_gen, para_alg, para_sim
    out2 = output;
    para_sim2 = para_sim;  
  
    clear output;
    [output, para_sim] = mergeOutputs(out1, out2, para_sim1, para_sim2);

    para_sim.possDsep = 'false'; % this takes too long computationally
    out_est = main_simulations_DecisionsEffects(output, para_gen, para_sim)
    outputs{1,1} = output;
    estimates{1,1} = out_est;
   
    % save intermediate results
    fprintf('Intermediate results saved under:')
    filename = strcat(mypath,'Est_Gauss_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000', '.mat')
    save(filename, 'estimates');

 
    % task 10
    filename = strcat(mypath,'Res_Gauss_task10_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000_part1', '.mat');
    load(filename); % output, para_gen, para_alg, para_sim
    out1 = output;
    para_sim1 = para_sim;

    filename = strcat(mypath,'Res_Gauss_task10_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000_part2', '.mat');
    load(filename); % output, para_gen, para_alg, para_sim
    out2 = output;
    para_sim2 = para_sim; 

    clear output;
    [output, para_sim] = mergeOutputs(out1, out2, para_sim1, para_sim2);

    para_sim.possDsep = 'false'; % this takes too long computationally
    out_est = main_simulations_DecisionsEffects(output, para_gen, para_sim)
    outputs{2,1} = output;
    estimates{2,1} = out_est;

    % when plotting, only need this in addition to estimates, so save it too in
    % same file so that I do not need to load the whole output files again
    temp1 = outputs{1}.trueEffect;
    temp2 = outputs{2}.trueEffect;  
    outputs = cell(2,1);
    outputs{1}.trueEffect = temp1;
    outputs{2}.trueEffect = temp2;

    fprintf('Results saved under:')
    filename = strcat(mypath,'Est_Gauss_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000', '.mat')
    save(filename, 'estimates', 'outputs');

  else

    % load results: estimates and outputs containing only true effects
    fprintf('Results loaded from:')
    filename = strcat(mypath,'Est_Gauss_nobs', int2str(nobs), '_nhid', int2str(nhid), '_100_1000_10000', '.mat')
    load(filename);
    
  end
end



% -----------------------------------------------------------------------------
% PLOTTING RESULTS and saving them as eps

ntasks = length(estimates);

% ---
if ( (nobs==7 || nobs==12) )

  % FIGURE 2

  % plot for each task separately how often D1, D2 and D3 was made and what
  % is the true solution
  colvec = [1 1 0.3; 0.2 0.3 1; 1 0.3 0.3];
  
  figure(1)
  clf
  set(gcf, 'color', [1 1 1])
  set(gcf, 'Position', [0, 30, 400, 300])
  set(gcf, 'PaperPositionMode', 'auto')
  trueD1D2D3 = zeros(3,4); % D1,D2,D3 for each task (true solution)
  estD1D2D3 = zeros(3,3,4); % D1,D2,D3 for each sample size and each task
  for i=1:ntasks
    trueD1D2D3(1,i) = sum( outputs{i}.trueD1D2D3==1 );
    trueD1D2D3(2,i) = sum( outputs{i}.trueD1D2D3==2 );
    trueD1D2D3(3,i) = sum( outputs{i}.trueD1D2D3==3 );
    for n=1:3
      estD1D2D3(n,1,i) = sum( estimates{i}.decisions(:,n)==1 );
      estD1D2D3(n,2,i) = sum( estimates{i}.decisions(:,n)==2 );
      estD1D2D3(n,3,i) = sum( estimates{i}.decisions(:,n)==3 | estimates{i}.decisions(:,n)==4); % said D3 immediately, or D1 but then estiamtes were not similar, so decision is marked with 4
    end
    
    clf
    bar1 = bar((1:4)*2, [estD1D2D3(:,:,i)', trueD1D2D3(:,i)]', 'stacked');
    set(gca, 'XTickLabel',''); set(gca,'YTickLabel',''); 
    set(bar1(1),'FaceColor',colvec(1,:));%[1 1 0]); %[1 0.8 0]
    set(bar1(2),'FaceColor',colvec(2,:));%[0 1 1]); %[0 0.8 0.8]
    set(bar1(3),'FaceColor',colvec(3,:));%[1 0 1]); %[0.8 0.2 1]
    
    filename = strcat(figpath, 'fig_decisions_nobs', int2str(nobs), '_nhid', int2str(nhid), '_task', int2str(i)); 

    saveas(gcf,strcat(filename,'.eps'), 'epsc2')

  end
  
  % save legend in separate plot where everything else is invisible
  clf
  bar1 = bar(1:4, [estD1D2D3(:,:,i)', trueD1D2D3(:,i)]', 'stacked','Visible','off');
  set(bar1(1),'FaceColor',colvec(1,:)); set(bar1(2),'FaceColor',colvec(2,:));
  set(bar1(3),'FaceColor',colvec(3,:));
  legend({'D1', 'D2', 'D3'},'Location','NortheastOutside')

  filename = strcat(figpath, 'fig_decisions_nobs', int2str(nobs), '_nhid', int2str(nhid), '_legend'); 

  saveas(gcf,strcat(filename,'.eps'), 'epsc2')


  % plot the same for (C)FCI
  figure(2)
  clf
  set(gcf, 'color', [1 1 1])
  set(gcf, 'Position', [0, 30, 400, 300])
  set(gcf, 'PaperPositionMode', 'auto')
  trueD1D2D3 = zeros(3,4); % D1,D2,D3 for each task (true solution)
  estD1D2D3 = zeros(3,3,4); % D1,D2,D3 for each sample size and each task
  for i=1:ntasks
    trueD1D2D3(1,i) = sum( outputs{i}.trueD1D2D3==1 );
    trueD1D2D3(2,i) = sum( outputs{i}.trueD1D2D3==2 );
    trueD1D2D3(3,i) = sum( outputs{i}.trueD1D2D3==3 );
    for n=1:3
      estD1D2D3(n,1,i) = sum( estimates{i}.decisions_FCI(:,n)==1 );
      estD1D2D3(n,2,i) = sum( estimates{i}.decisions_FCI(:,n)==2 );
      estD1D2D3(n,3,i) = sum( estimates{i}.decisions_FCI(:,n)==3 );
    end
    
    clf
    bar1 = bar((1:4)*2, [estD1D2D3(:,:,i)', trueD1D2D3(:,i)]', 'stacked');
    set(gca, 'XTickLabel',''); set(gca,'YTickLabel',''); 
    set(bar1(1),'FaceColor',colvec(1,:));
    set(bar1(2),'FaceColor',colvec(2,:));
    set(bar1(3),'FaceColor',colvec(3,:));

    filename = strcat(figpath, 'fig_decisions_CFCI_nobs', int2str(nobs), '_nhid', int2str(nhid), '_task', int2str(i)); 

    saveas(gcf,strcat(filename,'.eps'), 'epsc2')

  end

end


% ---
if ( (nobs==7 || nobs==12) )

  % FIGURE 3

  % calculate bias and make boxplots

  fig1 = figure();
  clf
  set(gcf, 'color', [1 1 1]) % background color is white
  set(gcf, 'Position', [0, 30, 1400, 500]) % x, y, width, height
  set(gcf, 'PaperPositionMode', 'auto')

  m = 6; % how many methods do we compare to
  markervec = {'>', '<', '^', 'v', 'o', 'x', 's', 'd'};
  colvec = lines(m);

  for n=1:3 % number of sample sizes
    for i=1:ntasks
    
      bias = zeros(m,length(estimates{i}.estimatesR123(:,n)));
      bias(1,:) = outputs{i}.trueEffect - estimates{i}.estimates_none(:,n);
      bias(2,:) = outputs{i}.trueEffect - estimates{i}.estimates_acc(:,n);
      bias(3,:) = outputs{i}.trueEffect - estimates{i}.estimates_all(:,n);
      bias(4,:) = outputs{i}.trueEffect - estimates{i}.estimates_vw(:,n);
      bias(5,:) = outputs{i}.trueEffect - estimates{i}.estimates_FCI(:,n);  
      bias(6,:) = outputs{i}.trueEffect - estimates{i}.estimatesR123(:,n);

      madeDec = sum(~isnan(bias'));

      subplot(3, ntasks, (n-1)*ntasks+i)
      boxplot(bias','colors',colvec,'orientation','horizontal','symbol','k+');
      set(gca,'YTick',1:6,'YTickLabel',madeDec,'FontSize',16)
      set(gca, 'XTickLabel','')
      set(gca, 'ColorOrder', lines(m));
      xlim(gca,[-1,1]);

      pa = get(gca,'Position'); % x, y, width, height
      hold on
      plot([0,0],[pa(2),pa(2)+m+.5],'k:')                                                

    end
  end
  
  % save figure without legend
  filename = strcat(figpath, 'fig_nobs', int2str(nobs), '_nhid', int2str(nhid), '_boxplots'); 

  saveas(gcf,strcat(filename,'.eps'), 'epsc2')

  % add legend and save again
  clf
  b1 = boxplot(bias','colors',colvec,'orientation','horizontal','symbol','k+');
  labels = {'including none of the variables','including associated variables','including all variables','VanderWeele and Shpitser','FCI based approach','Inference Rules'};
  labels = labels(end:-1:1);
  legend(findobj(gca,'Tag','Box'),labels)
  set(b1,'visible','off')
  set(gca,'visible','off')

  filename = strcat(figpath, 'fig_nobs', int2str(nobs), '_nhid', int2str(nhid), '_boxplots_legend');

  saveas(gcf,strcat(filename,'.eps'), 'epsc2')

end


% ---
if (nobs==102)

  % FIGURE 4, appendix

  % plot true versus estiamted effect - for the case where true effect is 
  % non-zero (for nobs=102 this is the combination of task 1 and task 2)
  figure()
  set(gcf, 'color', [1 1 1]) % background color is white
  set(gcf, 'Position', [0, 30, 1000, 250]) % x, y, width, height
  set(gcf, 'PaperPositionMode', 'auto')

  for n=1:3 % number of sample sizes
    subplot(1,3,n)
    plot(outputs{1}.trueEffect, estimates{1}.estimatesR123(:,n),'x','Markersize',10, 'LineWidth',2);
    h = refline(1,0);
    set(h,'Color','k')
    set(gca, 'XTickLabel','')
    set(gca, 'YTickLabel','')
  end

    filename = strcat(figpath, 'fig_nobs', int2str(nobs), '_nhid', int2str(nhid), '_estimates_nonzero'); 

    saveas(gcf,strcat(filename,'.eps'), 'epsc2')

end

close all
fprintf('Figures saved in folder Results/figures/ \n')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [output, para_sim] = mergeOutputs(out1, out2, para_sim1, para_sim2)

  output = cell(0);
  output.nobs = out1.nobs;
  output.samples = [100,1000,10000];
  output.theSeeds = [out1.theSeeds; out2.theSeeds];
  output.R1_Z = NaN;
  output.R23_Z = NaN;
  output.trueEffect = [out1.trueEffect; out2.trueEffect];
  output.genSkel = [out1.genSkel; out2.genSkel];
  output.genOrder = [out1.genOrder; out2.genOrder];
  output.algOut = [out1.algOut; out2.algOut];

  para_sim = para_sim1;
  para_sim.runs = para_sim1.runs + para_sim2.runs;
  para_sim.theSeeds = [para_sim1.theSeeds; para_sim2.theSeeds];

  SeedsAreSame = all(para_sim.theSeeds==output.theSeeds) % sanity check
