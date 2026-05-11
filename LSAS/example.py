import re
from LSAS import alg_LSAS
import pandas as pd

# load data
path = 'data/example_data_5000.csv'
data_V = pd.read_csv(path)
data_O = data_V[[col for col in data_V.columns if not re.match(r'^L\d+$', col)]] # Remove the latent variables
Tr_X = 'X'
Out_Y = 'Y'
result = alg_LSAS(data_O, Tr_X, Out_Y)

print(result)