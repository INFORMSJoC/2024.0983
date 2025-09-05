# [![INFORMS Journal on Computing Logo](https://INFORMSJoC.github.io/logos/INFORMS_Journal_on_Computing_Header.jpg)](https://pubsonline.informs.org/journal/ijoc)

# A Restarted Primal-Dual Hybrid Conjugate Gradient Method for Large-Scale Quadratic Programming

This archive is distributed in association with the [INFORMS Journal on
Computing](https://pubsonline.informs.org/journal/ijoc) under the [MIT License](LICENSE).

The software and data in this repository are a snapshot of the software and data
that were used in the research reported on in the paper 
[A Restarted Primal-Dual Hybrid Conjugate Gradient Method for Large-Scale Quadratic Programming](https://doi.org/10.1287/ijoc.2024.0983) by Y. Huang, W. Zhang, H. Li, H. Liu, D. Ge and Y. Ye. 


**Important: This code is being developed on an on-going basis at 
https://github.com/COPT-Public/PDHCG. Please go there if you would like to
get a more recent version or would like support**

## Cite

To cite the contents of this repository, please cite both the paper and this repo, using their respective DOIs.

https://doi.org/10.1287/ijoc.2024.0983

https://doi.org/10.1287/ijoc.2024.0983.cd

Below is the BibTex for citing this snapshot of the repository.

```
@misc{CacheTest,
  author =        {Y. Huang, W. Zhang, H. Li, H. Liu, D. Ge and Y. Ye},
  publisher =     {INFORMS Journal on Computing},
  title =         {A Restarted Primal-Dual Hybrid Conjugate Gradient Method for Large-Scale Quadratic Programming},
  year =          {2025},
  doi =           {10.1287/ijoc.2024.0983.cd},
  url =           {https://github.com/INFORMSJoC/2024.0983},
  note =          {Available for download at https://github.com/INFORMSJoC/2024.0983},
}  
```

## Description

The goal of this software is to demonstrate the effect of cache optimization.

## Building

In Linux, to build the version that multiplies all elements of a vector by a
constant (used to obtain the results in [Figure 1](results/mult-test.png) in the
paper), stepping K elements at a time, execute the following commands.

```
make mult
```

Alternatively, to build the version that sums the elements of a vector (used
to obtain the results [Figure 2](results/sum-test.png) in the paper), stepping K
elements at a time, do the following.

```
make clean
make sum
```

Be sure to make clean before building a different version of the code.

## Results

### Theoretical Advantage

| Method | outer loop complexity | extra CG steps |
| :--- | :--- | :--- |
| rAPDHG | $\mathcal{O}\left(\left(\|A\|+\sqrt{\|Q\|}+\frac{\|Q\|}{\|A\|}\right) \log \frac{1}{\epsilon}\right)$ | - |
| PDHCG-fixed | $\mathcal{O}\left(\left(\|A\|+\sqrt{\gamma_K^N\|Q\|}+\frac{\gamma_K^N\|Q\|}{\|A\|}\right) \log \frac{1}{\epsilon}\right)$ | $N$ |
| PDHCG-adaptive | $\mathcal{O}\left(\|A\| \cdot \log \frac{1}{\epsilon}\right)$ | $\log_{r} \frac{\zeta}{2(1+\tau\|A\|)(1+\tau\|Q\|)}$ |

$^1$The constants $\gamma_K \in (0, 1), r, \tau, \zeta$ are constant numbers and will be specified in the paper.

**Compared to rAPDHG, PDHCG algorithm significantly reduces the dependency on $Q$.**

### Numerical Advantege


## Replicating

To replicate the results in [Figure 1](results/mult-test), do either

```
make mult-test
```
or
```
python test.py mult
```
To replicate the results in [Figure 2](results/sum-test), do either

```
make sum-test
```
or
```
python test.py sum
```

## Ongoing Development

This code is being developed on an on-going basis at the author's
[Github site](https://github.com/COPT-Public/PDHCG).

## Support

For support in using this software, submit an
[issue](https://github.com/tkralphs/JoCTemplate/issues/new).