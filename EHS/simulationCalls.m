function [] = simulationCalls(setting)

% call simulations

% -----------------------------------------------------------------------------
if (setting == 1) % small models

  nobs = 12;
  nhid = 5;
  samples = [100, 1000, 10000];

  datatype = 'Gauss';
  indis = 1:100; % can run all simulations at once
  mypath = './Results/';

  % task 1
  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 1, datatype, indis);
  filename = strcat(mypath,'Res_Gauss_task1_nobs12_nhid5_100_1000_10000.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

  % task 2
  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 2, datatype, indis);
  filename = strcat(mypath,'Res_Gauss_task2_nobs12_nhid5_100_1000_10000.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

  % task 3
  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 3, datatype, indis);
  filename = strcat(mypath,'Res_Gauss_task3_nobs12_nhid5_100_1000_10000.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

  % task 4
  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 4, datatype, indis);
  filename = strcat(mypath,'Res_Gauss_task4_nobs12_nhid5_100_1000_10000.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

end


% -----------------------------------------------------------------------------
if (setting == 2) % large models

  nobs = 102; % 100 covariates + x and y
  nhid = 20;
  samples = [100, 1000, 10000];

  datatype = 'Gauss';
  mypath = './Results/';

  % split simulations in 2, cannot save all results at once

  % task 9
  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 9, datatype, 1:50);
  filename = strcat(mypath,'Res_Gauss_task9_nobs102_nhid20_100_1000_10000_part1.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 9, datatype, 51:100);
  filename = strcat(mypath,'Res_Gauss_task9_nobs102_nhid20_100_1000_10000_part2.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

  % task 10
  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 10, datatype, 1:50);
  filename = strcat(mypath,'Res_Gauss_task10_nobs102_nhid20_100_1000_10000_part1.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

  [output, para_gen, para_alg, para_sim] = ...
      simulationCommands(nobs, nhid, samples, 10, datatype, 51:100);
  filename = strcat(mypath,'Res_Gauss_task10_nobs102_nhid20_100_1000_10000_part2.mat');
  save(filename, 'output', 'para_gen', 'para_alg', 'para_sim');

end









