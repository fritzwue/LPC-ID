# ✨LSAS: Local Search Adjustment Set

## Overview

This repository implements the LSAS (Local Search Adjustment Set). The main entry point is the [`alg_LSAS`](LSAS.py) function in [LSAS.py](LSAS.py).

## Main Function

### `alg_LSAS`

**Parameters:**
- `data` (`pd.DataFrame`): Input dataset as a pandas DataFrame with column names.
- `Tr_X` (`str`): The treatment variable.
- `Out_Y` (`str`): The outcome variable.

**Returns:**
- `dict`: A dictionary containing:
  - `VASs`: The identified valid adjustment sets.
  - `ATE`: The average treatment effect estimated using the adjustment sets.
  - `CI_num`: The number of conditional independence tests performed.

## Usage Example

See [example.py](example.py) for a complete usage example:

```python
import re
from LSAS import alg_LSAS
import pandas as pd

# Load data
path = 'Data/example_data_5000.csv'
data_V = pd.read_csv(path)
# Remove latent variables (columns starting with 'L' followed by digits)
data_O = data_V[[col for col in data_V.columns if not re.match(r'^L\d+$', col)]]
Tr_X = 'X'
Out_Y = 'Y'

result = alg_LSAS(data_O, Tr_X, Out_Y)
print(result)
```

## Package requirements:
  - numpy
  - pandas
  - math
  - scipy
  - itertools
  - sklearn
  - statsmodels
  - pandas
  - re


## 📝 Citation
If you use this code, please cite the following paper:

```
@inproceedings{li2025local,
title={Local Learning for Covariate Selection in Nonparametric Causal Effect Estimation with Latent Variables},
author={Zheng Li, Xichen Guo, Feng Xie, Yan Zeng, Hao Zhang, and Zhi Geng},
booktitle={The Thirty-ninth Annual Conference on Neural Information Processing Systems},
year={2025}
}
```

If you have problems or questions, do not hesitate to send an email to zhengli0060@gmail.com