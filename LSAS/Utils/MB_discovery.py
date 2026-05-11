import pandas as pd
import numpy as np
import math
from typing import Union, Set, Tuple, Dict, List
from .CI_test import CItest_method
from sklearn.linear_model import Lasso
"""
This file contains the implementation of the MB discovery algorithm.
The MB discovery algorithm is used to find the Markov blanket of a given variable in a network.
"""
def standardize_data(data: np.ndarray) -> np.ndarray:
    """Standardize the data to have zero mean and unit variance."""
    mean = np.mean(data, axis=0)
    std = np.std(data, axis=0)
    return (data - mean) / std



def lasso_S(S: List[Union[int, str]], Y: Union[int, str], target: Union[int, str], data: pd.DataFrame, alpha: float = 0.05) -> List[str]:
    """
    Perform Lasso regression to select relevant features from S for both the target and Y.

    Parameters:
        S (List[str]): List of candidate features.
        Y (str): The variable to condition on.
        data (pd.DataFrame): The dataset containing the variables.
        target (str): The target variable.
        alpha (float): Regularization strength for Lasso regression.

    Returns:
        List[str]: Combined set of selected features for both target and Y.
    """

    def perform_lasso(X: np.ndarray, y: np.ndarray, alpha: float) -> List[int]:
        """Fit Lasso regression and return indices of selected features."""
        lasso_model = Lasso(alpha=alpha)
        lasso_model.fit(X, y)
        return np.where(lasso_model.coef_ != 0)[0].tolist()

    con_set_data = data.loc[:, S].values
    con_set_standardized = standardize_data(con_set_data)

    # Perform Lasso for the target variable
    target_selected_indices = perform_lasso(con_set_standardized, data.loc[:, target].values, alpha)
    con1 = [S[i] for i in target_selected_indices]

    # Perform Lasso for the Y variable
    y_selected_indices = perform_lasso(con_set_standardized, data.loc[:, Y].values, alpha)
    con2 = [S[i] for i in y_selected_indices]

    # Combine and deduplicate selected features
    con_set = list(set(con1 + con2))

    return con_set



def TC_mb(data: pd.DataFrame, target: Union[int, str], alpha: float=0.05, method_type: str = 'FisherZ', use_lasso: bool = False) -> list:
    """
    TC Algorithm for Markov Blanket Discovery.

    Parameters:
        data (pd.DataFrame): The dataset as a pandas DataFrame.
        target (str): The target variable.
        alpha (float): Significance level for independence tests.
        method_type (str): Method type for CI test. Options are 'FisherZ', 'G_sq', or 'D_sep'.

    Returns:
        list: The Markov blanket of the target variable.
        int: The number of conditional independence tests performed.
    References:
        - Pellet J P, Elisseeff A. Using markov blankets for causal structure learning[J]. Journal of Machine Learning Research, 2008, 9(7).
    """



    sample_size = data.shape[0]  # Get the number of samples
    do_n = sample_size / 10
    ceil_result = math.floor(do_n)
    if ceil_result > 0:
        alpha = alpha/(ceil_result*10)
    MB = []  # Initialize the candidate Markov blanket as empty
    ntest = 0  # Initialize the number of tests performed

    
    Candidate = list(data.columns.difference([target]))  # Initialize the candidate set of variables


    cit = CItest_method(data, method_type=method_type,alpha=alpha)
 

    for Y in Candidate:
        ntest += 1
        """
        Total conditioning
        """
        S = [var for var in Candidate if var != Y]  # Create a copy of MB and remove Y from it
        if len(S) > 30 and use_lasso:
            S = lasso_S(S, Y, target, data, alpha)  # Perform lasso regression to select features
        if not cit(target, Y, S)[0]:
            MB.append(Y)

    return MB, ntest




